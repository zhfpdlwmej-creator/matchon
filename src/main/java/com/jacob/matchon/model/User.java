package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 카카오 로그인 사용자. */
@Entity
@Table(name = "users")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class User {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "kakao_id", nullable = false, unique = true, length = 64)
	private String kakaoId;

	@Column(nullable = false, length = 20)
	private String nickname;

	@Enumerated(EnumType.STRING)
	@Column(length = 8)
	private Position position;

	@Column(name = "profile_image", length = 255)
	private String profileImage;

	/** 휴대폰 번호(숫자만, 알림톡 수신용). 미설정 시 알림톡 미발송. */
	@Column(length = 20)
	private String phone;

	@Column(name = "setup_done", nullable = false)
	private boolean setupDone;

	/** 실력 자기등급: BEG(입문)/NOV(초급)/INT(중급)/ADV(상급) */
	@Column(name = "skill_level", length = 8)
	private String skillLevel;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;

	@Column(name = "updated_at", insertable = false, updatable = false)
	private LocalDateTime updatedAt;
}
