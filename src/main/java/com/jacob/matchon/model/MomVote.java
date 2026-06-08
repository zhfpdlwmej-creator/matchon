package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** MOM(Man of the Match) 투표 (일정당 1인 1표). */
@Entity
@Table(name = "mom_vote",
		uniqueConstraints = @UniqueConstraint(name = "uq_mom", columnNames = {"schedule_id", "voter_user_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MomVote {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(name = "voter_user_id", nullable = false)
	private Long voterUserId;

	@Column(name = "target_user_id", nullable = false)
	private Long targetUserId;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
