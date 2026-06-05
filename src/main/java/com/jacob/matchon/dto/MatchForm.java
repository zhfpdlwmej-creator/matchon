package com.jacob.matchon.dto;

import lombok.Getter;
import lombok.Setter;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;
import java.time.LocalTime;

/** 매칭 등록 폼. */
@Getter @Setter
public class MatchForm {
	private String level;      // HIGH/MID/LOW
	private Integer headcount;
	private String region;
	private String placeName;
	private Double lat;
	private Double lng;

	@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
	private LocalDate matchDate;

	@DateTimeFormat(pattern = "HH:mm")
	private LocalTime startTime;

	private String memo;
}
