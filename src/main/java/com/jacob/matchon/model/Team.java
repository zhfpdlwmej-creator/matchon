package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 동호회(팀). */
@Entity
@Table(name = "team")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Team {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false, length = 40)
	private String name;

	@Column(length = 255)
	private String description;

	@Column(name = "invite_code", nullable = false, unique = true, length = 12)
	private String inviteCode;

	@Column(length = 255)
	private String emblem;

	/** 인원부족 알림 기준 인원 (0 = 미사용) */
	@Column(name = "min_attendees", nullable = false)
	private int minAttendees;

	@Column(name = "owner_id", nullable = false)
	private Long ownerId;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
