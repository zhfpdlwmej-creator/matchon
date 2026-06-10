package com.jacob.matchon.model;

/**
 * 팀 내 회원 유형 — 권한(Role)과는 별개 축.
 * DUES(회비회원): 회비를 납부하는 정회원. 참석 투표 우선권을 가진다.
 * GUEST(참가회원): 회비 없이 경기에만 참가하는 회원. 회비회원 마감 후 잔여석에 참가.
 */
public enum MembershipType {
	DUES, GUEST;

	public String label() {
		return this == DUES ? "회비회원" : "참가회원";
	}
}
