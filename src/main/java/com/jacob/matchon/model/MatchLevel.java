package com.jacob.matchon.model;

/** 팀 수준. HIGH(상) / MID(중) / LOW(하) */
public enum MatchLevel {
	HIGH, MID, LOW;

	public String label() {
		return switch (this) {
			case HIGH -> "상";
			case MID -> "중";
			case LOW -> "하";
		};
	}
}
