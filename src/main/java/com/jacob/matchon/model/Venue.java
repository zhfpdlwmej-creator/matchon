package com.jacob.matchon.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/** 팀 즐겨찾기 구장. */
@Entity
@Table(name = "venue")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Venue {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "team_id", nullable = false)
	private Long teamId;

	@Column(nullable = false, length = 120)
	private String name;

	@Column(length = 200)
	private String address;

	private Double lat;
	private Double lng;

	@Column(length = 300)
	private String memo;

	@Column(name = "created_at", insertable = false, updatable = false)
	private LocalDateTime createdAt;
}
