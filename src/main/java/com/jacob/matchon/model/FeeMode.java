package com.jacob.matchon.model;

/**
 * 팀 회비 관리 방식.
 * NONE     — 구분 안 함(회비를 따로 관리하지 않음)
 * MONTHLY  — 회비회원제(매월 정기 회비, 월별 납부 관리)
 * PER_GAME — 참가회원제(경기마다 일정 금액 납부)
 * MIXED    — 회비회원 + 참가회원 혼합(팀원별로 유형 구분 → 팀원관리에 유형 콤보박스 노출)
 */
public enum FeeMode {
	NONE, MONTHLY, PER_GAME, MIXED;

	public String label() {
		return switch (this) {
			case NONE -> "구분 안 함";
			case MONTHLY -> "회비회원제";
			case PER_GAME -> "참가회원제";
			case MIXED -> "회비 + 참가 혼합";
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
