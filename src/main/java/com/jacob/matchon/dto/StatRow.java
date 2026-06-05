package com.jacob.matchon.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** 회원별 출석률 통계 한 행. */
@Getter
@AllArgsConstructor
public class StatRow {
	private Long userId;
	private String nickname;
	private String position;
	private int monthRate;    // 이번 달 참석률(%)
	private int recent3Rate;  // 최근 3개월 참석률(%)
	private int totalRate;    // 전체 참석률(%)
	private long totalAttended;
	private long totalMatches;
}
