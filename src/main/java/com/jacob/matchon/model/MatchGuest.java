package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 용병(게스트) — 팀원이 아닌 외부 참석 인원. */
@Entity
@Table(name = "match_guest")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchGuest {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(nullable = false, length = 40)
	private String name;

	@Column(nullable = false)
	private int headcount;

	@Column(name = "added_by", nullable = false)
	private Long addedBy;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
