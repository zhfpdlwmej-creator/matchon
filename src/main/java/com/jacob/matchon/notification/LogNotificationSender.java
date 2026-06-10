package com.jacob.matchon.notification;

import com.jacob.matchon.model.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 알림 발송 이력을 콘솔에 출력한다.
 * (인앱 알림 + 웹 푸시는 별도로 동작하며, 외부 메시지 발송은 사용하지 않는다.)
 */
@Component
public class LogNotificationSender implements NotificationSender {

	private static final Logger log = LoggerFactory.getLogger(LogNotificationSender.class);

	@Override
	public void send(Notification n) {
		log.info("[알림발송:LOG] team={} schedule={} type={} | {}",
				n.getTeamId(), n.getScheduleId(), n.getType(), n.getMessage());
	}
}
