package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 매칭 신청 댓글(소통). 신청팀별 스레드 + 대댓글. */
@Entity
@Table(name = "match_comment")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MatchComment {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "match_post_id", nullable = false)
	private Long matchPostId;

	/** 팀 매칭: 어느 신청팀 스레드인지 (용병 모집이면 null) */
	@Column(name = "applicant_team_id")
	private Long applicantTeamId;

	/** 용병 모집: 어느 신청 개인 스레드인지 (팀 매칭이면 null) */
	@Column(name = "applicant_user_id")
	private Long applicantUserId;

	@Column(name = "author_user_id", nullable = false)
	private Long authorUserId;

	@Column(name = "author_team_id", nullable = false)
	private Long authorTeamId;

	/** 작성자가 모집팀(호스트) 측인지 */
	@Column(name = "is_host", nullable = false)
	private boolean host;

	/** 대댓글이면 부모 댓글 id */
	@Column(name = "parent_id")
	private Long parentId;

	@Column(nullable = false, length = 500)
	private String content;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
