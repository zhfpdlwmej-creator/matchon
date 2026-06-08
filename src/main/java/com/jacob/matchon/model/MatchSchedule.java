package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/** 경기 일정. */
@Entity
@Table(name = "match_schedule")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchSchedule {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(nullable = false, length = 60)
	private String title;

	@Column(name = "match_date", nullable = false)
	private LocalDate matchDate;

	@Column(name = "start_time", nullable = false)
	private LocalTime startTime;

	@Column(name = "end_time")
	private LocalTime endTime;

	@Column(length = 120)
	private String place;

	@Column(nullable = false)
	private int fee;

	/** 목표 인원 (0 = 미사용) */
	@Column(name = "target_headcount", nullable = false)
	private int targetHeadcount;

	/** 선착순 마감: true 면 참석 인원이 목표 인원에 차면 추가 참석 불가 */
	@Column(name = "limit_attendance", nullable = false)
	private boolean limitAttendance;

	@Column(length = 500)
	private String memo;

	/** 포메이션 배치 JSON ({preset, tokens:[{label,x,y}]}) */
	@Column(columnDefinition = "text")
	private String formation;

	@Column(name = "created_by", nullable = false)
	private Long createdBy;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;

	/** 경기 시작 시각(날짜+시작시간) */
	@Transient
	public LocalDateTime startsAt() {
		return LocalDateTime.of(matchDate, startTime);
	}
}
