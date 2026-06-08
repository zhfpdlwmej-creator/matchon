package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 경기 결과 (일정당 1건). */
@Entity
@Table(name = "match_result")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchResult {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false, unique = true)
	private Long scheduleId;

	@Column(name = "our_score", nullable = false)
	private int ourScore;

	@Column(name = "opp_score", nullable = false)
	private int oppScore;

	@Column(name = "opponent_name", length = 60)
	private String opponentName;

	@Column(name = "created_by", nullable = false)
	private Long createdBy;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
