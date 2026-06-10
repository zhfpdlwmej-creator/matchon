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

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 12)
	private Sport sport;

	@Column(length = 255)
	private String description;

	@Column(name = "invite_code", nullable = false, unique = true, length = 12)
	private String inviteCode;

	@Column(length = 255)
	private String emblem;

	/** 인원부족 알림 기준 인원 (0 = 미사용) */
	@Column(name = "min_attendees", nullable = false)
	private int minAttendees;

	/** 회비 관리 방식: NONE/MONTHLY/PER_GAME */
	@Enumerated(EnumType.STRING)
	@Column(name = "fee_mode", nullable = false, length = 10)
	@Builder.Default
	private FeeMode feeMode = FeeMode.NONE;

	/** 연령대: AGE_20/AGE_30/AGE_40/MIX */
	@Column(name = "age_group", length = 8)
	private String ageGroup;

	/** 팀 실력: HIGH/MID/LOW */
	@Column(length = 8)
	private String level;

	/** 활동 지역 */
	@Column(length = 60)
	private String region;

	@Column(name = "owner_id", nullable = false)
	private Long ownerId;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;

	@Transient
	public String getSportEmoji() { return sport == null ? "" : sport.emoji(); }

	@Transient
	public String getSportLabel() { return sport == null ? "" : sport.label(); }
}
