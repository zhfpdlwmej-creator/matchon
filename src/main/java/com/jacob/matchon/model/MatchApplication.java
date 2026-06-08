package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 매칭 신청(다른 팀이 신청). */
@Entity
@Table(name = "match_application",
		uniqueConstraints = @UniqueConstraint(name = "uq_application", columnNames = {"match_post_id", "applicant_team_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchApplication {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "match_post_id", nullable = false)
	private Long matchPostId;

	/** 팀 매칭이면 신청 팀 id, 용병(개인) 지원이면 null */
	@Column(name = "applicant_team_id")
	private Long applicantTeamId;

	@Column(name = "applicant_user_id", nullable = false)
	private Long applicantUserId;

	@Column(length = 300)
	private String message;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 10)
	private ApplicationStatus status;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
