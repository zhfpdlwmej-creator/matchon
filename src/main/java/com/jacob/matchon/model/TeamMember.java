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

	@Column(name = "back_number")
	private Integer backNumber;

	@Column(name = "joined_at", insertable = false, updatable = false)
	private LocalDateTime joinedAt;
}
