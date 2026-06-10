package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 월별 회비 납부 기록. 행이 존재하면 해당 월(period) 납부 완료로 본다. */
@Entity
@Table(name = "dues_payment",
		uniqueConstraints = @UniqueConstraint(name = "uq_dues", columnNames = {"team_id", "user_id", "period"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class DuesPayment {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	/** 납부 대상 월 (YYYY-MM) */
	@Column(nullable = false, length = 7)
	private String period;

	@Column(name = "marked_by", nullable = false)
	private Long markedBy;

	@Column(name = "paid_at", insertable = false, updatable = false)
	private LocalDateTime paidAt;
}
