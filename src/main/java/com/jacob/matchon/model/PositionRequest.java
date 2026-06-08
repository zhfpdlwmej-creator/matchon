package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 포메이션 선호 포지션 신청 (일정당 1인 1건). */
@Entity
@Table(name = "position_request",
		uniqueConstraints = @UniqueConstraint(name = "uq_position_request", columnNames = {"schedule_id", "user_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class PositionRequest {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	/** GK / DF / MF / FW */
	@Column(nullable = false, length = 8)
	private String position;

	@Column(length = 200)
	private String note;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
