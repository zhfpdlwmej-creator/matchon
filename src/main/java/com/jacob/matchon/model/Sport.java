package com.jacob.matchon.model;

/** 종목. 축구 / 야구 / 농구. */
public enum Sport {
	SOCCER, BASEBALL, BASKETBALL;

	public String label() {
		return switch (this) {
			case SOCCER -> "축구";
			case BASEBALL -> "야구";
			case BASKETBALL -> "농구";
		};
	}

	public String emoji() {
		return switch (this) {
			case SOCCER -> "⚽";
			case BASEBALL -> "⚾";
			case BASKETBALL -> "🏀";
		};
	}

	/** 종목별 포지션 코드 */
	public String[] positions() {
		return switch (this) {
			case SOCCER -> new String[] {"GK", "DF", "MF", "FW"};
			case BASEBALL -> new String[] {"투수", "포수", "내야", "외야"};
			case BASKETBALL -> new String[] {"가드", "포워드", "센터"};
		};
	}

	public static Sport parse(String v) {
		try {
			return v == null || v.isBlank() ? SOCCER : Sport.valueOf(v);
		} catch (Exception e) {
			return SOCCER;
		}
	}
}
