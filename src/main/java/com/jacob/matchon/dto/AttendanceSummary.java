package com.jacob.matchon.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;
import java.util.Map;

/** 참석 현황 집계 결과. */
@Getter
@AllArgsConstructor
public class AttendanceSummary {
	private long attend;        // 참석 인원
	private long absent;        // 불참 인원
	private long pending;       // 미정 인원
	private Map<String, Long> byPosition;   // 참석자 포지션별 인원 (GK/DF/MF/FW)
	private List<MemberRow> attendList;     // 참석자 목록
	private List<MemberRow> absentList;     // 불참자 목록
	private List<MemberRow> pendingList;    // 미정자 목록

	/** 목록 한 행 */
	@Getter
	@AllArgsConstructor
	public static class MemberRow {
		private Long userId;
		private String nickname;
		private String position;  // GK/DF/MF/FW or null
		private boolean paid;     // 회비 납부 여부
	}
}
