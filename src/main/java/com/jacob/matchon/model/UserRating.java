package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 개인(용병) 매너 평가 + 후기. */
@Entity
@Table(name = "user_rating",
		uniqueConstraints = @UniqueConstraint(name = "uq_user_rating", columnNames = {"match_post_id", "rater_user_id", "target_user_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class UserRating {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "target_user_id", nullable = false)
	private Long targetUserId;

	@Column(name = "rater_user_id", nullable = false)
	private Long raterUserId;

	@Column(name = "rater_team_id")
	private Long raterTeamId;

	@Column(name = "match_post_id")
	private Long matchPostId;

	/** 매너 1~5 */
	@Column(nullable = false)
	private int manner;

	@Column(length = 300)
	private String comment;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
