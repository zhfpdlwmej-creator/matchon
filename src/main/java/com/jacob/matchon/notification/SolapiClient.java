package com.jacob.matchon.notification;

import com.google.gson.Gson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * Solapi(쿨에스엠에스) 카카오 알림톡 발송 클라이언트.
 * 알림톡(ATA) 발송 + 실패 시 SMS/LMS 자동 대체.
 *
 * 사전 준비(외부): Solapi 가입 → 카카오 비즈니스 채널 연동(pfId) →
 * 알림톡 템플릿 승인(templateId, 본문에 #{내용} 변수 1개) → 발신번호 등록.
 * 인증 방식: HMAC-SHA256 (date + salt 를 apiSecret 으로 서명).
 */
@Component
public class SolapiClient {

	private static final Logger log = LoggerFactory.getLogger(SolapiClient.class);
	private static final String ENDPOINT = "https://api.solapi.com/messages/v4/send-many";
	private static final String SALT_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

	private final Gson gson = new Gson();
	private final SecureRandom random = new SecureRandom();
	private final HttpClient http = HttpClient.newBuilder()
			.connectTimeout(Duration.ofSeconds(5)).build();

	@Value("${app.notify.kakao.api-key:}")
	private String apiKey;
	@Value("${app.notify.kakao.api-secret:}")
	private String apiSecret;
	@Value("${app.notify.kakao.pf-id:}")
	private String pfId;
	@Value("${app.notify.kakao.template-id:}")
	private String templateId;
	@Value("${app.notify.kakao.from:}")
	private String from;

	public boolean isConfigured() {
		return notBlank(apiKey) && notBlank(apiSecret) && notBlank(pfId)
				&& notBlank(templateId) && notBlank(from);
	}

	/**
	 * 여러 수신자에게 동일 내용의 알림톡 발송.
	 * @param phones 수신 휴대폰 번호(숫자만)
	 * @param content 템플릿 #{내용} 변수에 들어갈 본문 (승인 템플릿과 형식 일치 필요)
	 */
	public void sendAlimtalk(List<String> phones, String content) {
		if (!isConfigured()) {
			log.warn("[알림톡] Solapi 설정 미완료 — 발송 생략");
			return;
		}
		if (phones == null || phones.isEmpty()) return;

		List<Map<String, Object>> messages = phones.stream().map(to -> {
			Map<String, Object> kakao = Map.of(
					"pfId", pfId,
					"templateId", templateId,
					"variables", Map.of("#{내용}", content),
					"disableSms", false);
			return (Map<String, Object>) Map.of(
					"to", to,
					"from", from,
					"type", "ATA",        // 알림톡 (실패 시 SMS/LMS 대체)
					"text", content,      // 대체 발송용 본문
					"kakaoOptions", kakao);
		}).toList();

		String body = gson.toJson(Map.of("messages", messages));

		try {
			String date = Instant.now().toString();
			String salt = randomSalt();
			String signature = hmacSha256(apiSecret, date + salt);
			String auth = String.format("HMAC-SHA256 apiKey=%s, date=%s, salt=%s, signature=%s",
					apiKey, date, salt, signature);

			HttpRequest req = HttpRequest.newBuilder(URI.create(ENDPOINT))
					.timeout(Duration.ofSeconds(10))
					.header("Authorization", auth)
					.header("Content-Type", "application/json")
					.POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
					.build();

			HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
			if (res.statusCode() / 100 == 2) {
				log.info("[알림톡] 발송 요청 성공 ({}건)", phones.size());
			} else {
				log.warn("[알림톡] 발송 실패 status={} body={}", res.statusCode(), res.body());
			}
		} catch (Exception e) {
			log.warn("[알림톡] 발송 예외: {}", e.getMessage());
		}
	}

	private String randomSalt() {
		StringBuilder sb = new StringBuilder(32);
		for (int i = 0; i < 32; i++) sb.append(SALT_CHARS.charAt(random.nextInt(SALT_CHARS.length())));
		return sb.toString();
	}

	private String hmacSha256(String secret, String data) throws Exception {
		Mac mac = Mac.getInstance("HmacSHA256");
		mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
		byte[] raw = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
		StringBuilder hex = new StringBuilder(raw.length * 2);
		for (byte b : raw) hex.append(String.format("%02x", b));
		return hex.toString();
	}

	private boolean notBlank(String s) { return s != null && !s.isBlank(); }
}
