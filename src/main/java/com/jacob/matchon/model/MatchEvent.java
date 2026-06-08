package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 득점/도움 이벤트 (골 1개당 1행). */
@Entity
@Table(name = "match_event")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchEvent {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(name = "scorer_user_id")
	private Long scorerUserId;

	@Column(name = "scorer_name", nullable = false, length = 60)
	private String scorerName;

	@Column(name = "assist_user_id")
	private Long assistUserId;

	@Column(name = "assist_name", length = 60)
	private String assistName;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
