package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 상대팀 매너/실력 상호 평점 (매칭당 평가팀-대상팀 1건). */
@Entity
@Table(name = "team_rating",
		uniqueConstraints = @UniqueConstraint(name = "uq_team_rating", columnNames = {"match_post_id", "rater_team_id", "target_team_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TeamRating {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "match_post_id")
	private Long matchPostId;

	@Column(name = "rater_user_id", nullable = false)
	private Long raterUserId;

	@Column(name = "rater_team_id", nullable = false)
	private Long raterTeamId;

	@Column(name = "target_team_id", nullable = false)
	private Long targetTeamId;

	/** 매너 1~5 */
	@Column(nullable = false)
	private int manner;

	/** 실력 HIGH/MID/LOW */
	@Column(length = 8)
	private String skill;

	@Column(length = 300)
	private String comment;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
