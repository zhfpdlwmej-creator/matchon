package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/** 팀 매칭(친선경기 모집) 글. */
@Entity
@Table(name = "match_post")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchPost {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "host_team_id", nullable = false)
	private Long hostTeamId;

	@Column(name = "host_user_id", nullable = false)
	private Long hostUserId;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 12)
	private Sport sport;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 8)
	private MatchLevel level;

	/** 매치 타입: FUTSAL_5 / SOCCER_8 / SOCCER_11 (null=무관) */
	@Column(name = "match_type", length = 12)
	private String matchType;

	/** 연령대: AGE_20 / AGE_30 / AGE_40 / ANY(null=무관) */
	@Column(name = "age_group", length = 8)
	private String ageGroup;

	/** 용병(개인) 모집글 여부 */
	@Column(name = "recruit_guest", nullable = false)
	private boolean recruitGuest;

	/** 용병 모집글이 연동된 우리 팀 일정 id */
	@Column(name = "source_schedule_id")
	private Long sourceScheduleId;

	@Column(nullable = false)
	private int headcount;

	@Column(length = 60)
	private String region;

	@Column(name = "place_name", length = 120)
	private String placeName;

	private Double lat;
	private Double lng;

	@Column(name = "match_date")
	private LocalDate matchDate;

	@Column(name = "start_time")
	private LocalTime startTime;

	@Column(length = 500)
	private String memo;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 10)
	private MatchStatus status;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
