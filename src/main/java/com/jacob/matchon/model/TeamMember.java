package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 팀 가입 관계 + 권한. */
@Entity
@Table(name = "team_member",
		uniqueConstraints = @UniqueConstraint(name = "uq_team_member", columnNames = {"team_id", "user_id"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TeamMember {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 12)
	private Role role;

	/** 회원 유형(회비회원/참가회원) — 선착순 우선권 등에 사용. 권한(role)과 별개. */
	@Enumerated(EnumType.STRING)
	@Column(name = "membership_type", nullable = false, length = 8)
	@Builder.Default
	private MembershipType membershipType = MembershipType.DUES;

	/** 총무 여부 — 회비 관리 화면 접근 권한. 팀장이 지정. */
	@Column(nullable = false)
	@Builder.Default
	private boolean treasurer = false;

	@Column(name = "back_number")
	private Integer backNumber;

	@Column(name = "joined_at", insertable = false, updatable = false)
	private LocalDateTime joinedAt;
}
