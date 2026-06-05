package com.jacob.matchon.model;

/** 알림 종류. */
public enum NotificationType {
	SCHEDULE_CREATED,  // 일정 등록 시
	D_1,               // 경기 하루 전
	H_3,               // 경기 3시간 전
	M_30,              // 경기 시작 30분 전
	LOW_ATTENDANCE     // 인원 부족
}
