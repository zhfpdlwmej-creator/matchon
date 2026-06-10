package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 참석 여부 + 회비 납부 상태. */
@Entity
@Table(name = "attendance",
		uniqueConstraints = @UniqueConstraint(name = "uq_attendance", columnNames = {"schedule_id", "user_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Attendance {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "schedule_id", nullable = false)
	private Long scheduleId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 8)
	private AttendanceStatus status;

	@Column(nullable = false)
	private boolean paid;

	/** 노쇼: 참석 확정 후 안 옴 (팀장/운영진이 표시) */
	@Column(name = "no_show", nullable = false)
	private boolean noShow;

	/** 예비(대기) 등록 시각 — 선착순 승급 순서(FIFO) 기준. 참석/불참이면 null. */
	@Column(name = "waitlist_at")
	private LocalDateTime waitlistAt;

	@Column(name = "updated_at", insertable = false, updatable = false)
	private LocalDateTime updatedAt;
}
