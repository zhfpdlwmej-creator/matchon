package com.jacob.matchon.notification;

import com.google.gson.Gson;
import com.jacob.matchon.model.PushSubscription;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.repo.PushSubscriptionRepository;
import com.jacob.matchon.repo.TeamMemberRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import nl.martijndwars.webpush.Notification;
import nl.martijndwars.webpush.PushService;
import org.apache.http.HttpResponse;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.Security;
import java.util.List;
import java.util.Map;

/** 웹 푸시(VAPID) 발송. */
@Service
@RequiredArgsConstructor
public class WebPushService {

	private static final Logger log = LoggerFactory.getLogger(WebPushService.class);

	private final PushSubscriptionRepository subRepo;
	private final TeamMemberRepository memberRepo;
	private final Gson gson = new Gson();

	@Value("${app.push.vapid.public-key:}")
	private String publicKey;
	@Value("${app.push.vapid.private-key:}")
	private String privateKey;
	@Value("${app.push.vapid.subject:mailto:admin@matchon.app}")
	private String subject;

	private PushService pushService;

	@PostConstruct
	void init() {
		if (publicKey == null || publicKey.isBlank() || privateKey == null || privateKey.isBlank()) {
			log.warn("VAPID 키 미설정 — 웹 푸시 비활성화");
			return;
		}
		if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
			Security.addProvider(new BouncyCastleProvider());
		}
		try {
			pushService = new PushService(publicKey, privateKey, subject);
			log.info("웹 푸시(VAPID) 활성화");
		} catch (Exception e) {
			log.error("PushService 초기화 실패", e);
		}
	}

	public String getPublicKey() {
		return publicKey;
	}

	/** 구독 저장(있으면 갱신) */
	@Transactional
	public void saveSubscription(Long userId, String endpoint, String p256dh, String auth) {
		subRepo.findByEndpoint(endpoint).ifPresentOrElse(
				s -> { s.setUserId(userId); s.setP256dh(p256dh); s.setAuth(auth); },
				() -> subRepo.save(PushSubscription.builder()
						.userId(userId).endpoint(endpoint).p256dh(p256dh).auth(auth).build()));
	}

	/** 팀 전체 멤버에게 발송 */
	public void sendToTeam(Long teamId, String title, String body, String url) {
		if (pushService == null) return;
		List<Long> userIds = memberRepo.findByTeamId(teamId).stream().map(TeamMember::getUserId).toList();
		String payload = gson.toJson(Map.of("title", title, "body", body, "url", url == null ? "/" : url));
		for (Long uid : userIds) {
			sendToUser(uid, payload);
		}
	}

	/** 특정 유저에게 제목/본문/링크로 발송 */
	public void sendToUser(Long userId, String title, String body, String url) {
		if (pushService == null) return;
		String payload = gson.toJson(Map.of("title", title, "body", body, "url", url == null ? "/" : url));
		sendToUser(userId, payload);
	}

	/** 특정 유저의 모든 기기에 발송 */
	public void sendToUser(Long userId, String payload) {
		if (pushService == null) return;
		for (PushSubscription s : subRepo.findByUserId(userId)) {
			try {
				Notification n = new Notification(s.getEndpoint(), s.getP256dh(), s.getAuth(),
						payload.getBytes(StandardCharsets.UTF_8));
				HttpResponse res = pushService.send(n);
				int code = res.getStatusLine().getStatusCode();
				if (code == 404 || code == 410) {
					subRepo.deleteById(s.getId()); // 만료된 구독 제거
				}
			} catch (Exception e) {
				log.warn("푸시 전송 실패 user={} : {}", userId, e.getMessage());
			}
		}
	}
}
