package com.jacob.matchon.model;

/** 팀 내 권한. LEADER(팀장) > MANAGER(운영진) > MEMBER(일반회원) */
public enum Role {
	LEADER, MANAGER, MEMBER;

	/** 일정 등록/수정 권한(팀장·운영진) */
	public boolean canManage() {
		return this == LEADER || this == MANAGER;
	}
}
