package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 일정 댓글. */
@Entity
@Table(name = "comment")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Comment {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false, length = 300)
	private String content;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
