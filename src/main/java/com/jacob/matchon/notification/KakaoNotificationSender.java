package com.jacob.matchon.notification;

import com.jacob.matchon.model.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 카카오 알림톡(비즈메시지) 실발송 구현 자리.
 * 실제 운영에서는 카카오 비즈니스 채널 + 알림톡 템플릿 승인 후
 * 발송 대행(NHN Toast, 알리고, 솔라피 등) API 를 호출한다.
 *
 * MVP 에서는 보조 서비스 컨셉에 맞춰 "카카오톡 공유/나에게 보내기" 또는
 * 알림톡 대행 연동으로 확장 가능하도록 인터페이스만 맞춰 둔다.
 */
@Component
@ConditionalOnProperty(name = "app.notify.mode", havingValue = "kakao")
public class KakaoNotificationSender implements NotificationSender {

	private static final Logger log = LoggerFactory.getLogger(KakaoNotificationSender.class);

	@Override
	public void send(Notification n) {
		// TODO: 알림톡 대행 API 연동 (템플릿 코드, 수신자 매핑)
		log.info("[알림발송:KAKAO(stub)] type={} | {}", n.getType(), n.getMessage());
	}
}
