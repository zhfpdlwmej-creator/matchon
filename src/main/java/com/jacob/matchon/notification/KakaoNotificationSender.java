package com.jacob.matchon.notification;

import com.jacob.matchon.model.Notification;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.TeamMemberRepository;
import com.jacob.matchon.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 카카오 알림톡(비즈메시지) 실발송 구현.
 * 팀 멤버 중 휴대폰 번호를 등록한 사용자에게 Solapi 를 통해 알림톡을 발송한다.
 * (app.notify.mode=kakao 일 때만 활성화)
 *
 * 실발송 전제: Solapi 가입 + 카카오 채널 연동(pfId) + 템플릿 승인(template-id) +
 * 발신번호 등록 + 각 사용자 휴대폰 번호 수집. 미설정 시 발송은 조용히 생략된다.
 */
@Component
@ConditionalOnProperty(name = "app.notify.mode", havingValue = "kakao")
@RequiredArgsConstructor
public class KakaoNotificationSender implements NotificationSender {

	private static final Logger log = LoggerFactory.getLogger(KakaoNotificationSender.class);

	private final SolapiClient solapi;
	private final TeamMemberRepository memberRepo;
	private final UserRepository userRepo;

	@Override
	public void send(Notification n) {
		try {
			List<Long> userIds = memberRepo.findByTeamId(n.getTeamId()).stream()
					.map(TeamMember::getUserId).toList();
			if (userIds.isEmpty()) return;

			List<String> phones = userRepo.findByIdIn(userIds).stream()
					.map(User::getPhone)
					.filter(p -> p != null && !p.isBlank())
					.distinct()
					.toList();

			if (phones.isEmpty()) {
				log.info("[알림톡] type={} 팀{} 수신 가능한 번호 없음 — 생략", n.getType(), n.getTeamId());
				return;
			}
			solapi.sendAlimtalk(phones, n.getMessage());
		} catch (Exception e) {
			// 알림 발송 실패가 본 트랜잭션(알림 저장)을 깨지 않도록 흡수
			log.warn("[알림톡] 발송 처리 실패 type={} : {}", n.getType(), e.getMessage());
		}
	}
}
