package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 팀 게시판 글 (공지/자유). */
@Entity
@Table(name = "team_post")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TeamPost {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(name = "author_user_id", nullable = false)
	private Long authorUserId;

	/** 공지 여부 (팀장/운영진만 작성) */
	@Column(nullable = false)
	private boolean notice;

	@Column(nullable = false, length = 120)
	private String title;

	@Column(length = 2000)
	private String content;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
