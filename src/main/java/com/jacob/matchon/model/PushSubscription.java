package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 웹 푸시 구독 (브라우저 PushManager 구독 정보). */
@Entity
@Table(name = "push_subscription")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class PushSubscription {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false, length = 500)
	private String endpoint;

	@Column(nullable = false, length = 255)
	private String p256dh;

	@Column(nullable = false, length = 255)
	private String auth;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
