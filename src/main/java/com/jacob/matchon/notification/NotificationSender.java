package com.jacob.matchon.notification;

import com.jacob.matchon.model.Notification;

/** 알림 발송 추상화. log(개발) 또는 kakao(실발송) 구현. */
public interface NotificationSender {
	void send(Notification notification);
}
