package com.jacob.matchon.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;
import java.util.Map;

/** 참석 현황 집계 결과. */
@Getter
@AllArgsConstructor
public class AttendanceSummary {
	private long attend;        // 참석 인원(팀원)
	private long absent;        // 불참 인원
	private long pending;       // 미정 인원
	private long guestCount;    // 용병 인원 합계
	private long totalCount;    // 참석 + 용병 (실제 모인 인원)
	private Map<String, Long> byPosition;   // (미사용) 포지션별 인원
	private List<MemberRow> attendList;     // 참석자 목록
	private List<MemberRow> absentList;     // 불참자 목록
	private List<MemberRow> pendingList;    // 미정자 목록
	private List<Guest> guests;             // 용병 목록
	private long waitlist;                  // 예비(대기) 인원 수
	private List<MemberRow> waitlistList;   // 예비(대기) 목록 (등록 순 = 예비 1번부터)

	/** 목록 한 행 */
	@Getter
	@AllArgsConstructor
	public static class MemberRow {
		private Long userId;
		private String nickname;
		private String position;  // (미사용)
		private boolean paid;
		private boolean noShow;
	}

	/** 용병 한 행 */
	@Getter
	@AllArgsConstructor
	public static class Guest {
		private Long id;
		private String name;
		private int headcount;
	}
}
