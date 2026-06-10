package com.jacob.matchon.model;

/**
 * 팀 회비 관리 방식.
 * NONE     — 구분 안 함(회비를 따로 관리하지 않음)
 * MONTHLY  — 회비회원제(매월 정기 회비, 월별 납부 관리)
 * PER_GAME — 참가회원제(경기마다 일정 금액 납부)
 */
public enum FeeMode {
	NONE, MONTHLY, PER_GAME;

	public String label() {
		return switch (this) {
			case NONE -> "구분 안 함";
			case MONTHLY -> "회비회원제";
			case PER_GAME -> "참가회원제";
		};
	}

	public static FeeMode parse(String v) {
		try {
			return v == null || v.isBlank() ? NONE : FeeMode.valueOf(v);
		} catch (Exception e) {
			return NONE;
		}
	}
}
