package com.jacob.matchon.notification;

import com.jacob.matchon.model.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 개발용 알림 발송 — 콘솔에 출력만 한다.
 * 실제 카카오 알림톡(비즈메시지) 연동 전 단계에서 흐름을 검증.
 */
@Component
@ConditionalOnProperty(name = "app.notify.mode", havingValue = "log", matchIfMissing = true)
public class LogNotificationSender implements NotificationSender {

	private static final Logger log = LoggerFactory.getLogger(LogNotificationSender.class);

	@Override
	public void send(Notification n) {
		log.info("[알림발송:LOG] team={} schedule={} type={} | {}",
				n.getTeamId(), n.getScheduleId(), n.getType(), n.getMessage());
	}
}
