package com.jacob.matchon.dto;

import lombok.Getter;
import lombok.Setter;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;
import java.time.LocalTime;

/** 경기 일정 등록/수정 폼. */
@Getter @Setter
public class ScheduleForm {
	private String title;

	@DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
	private LocalDate matchDate;

	@DateTimeFormat(pattern = "HH:mm")
	private LocalTime startTime;

	@DateTimeFormat(pattern = "HH:mm")
	private LocalTime endTime;

	private String place;
	private Integer fee;
	private String memo;
}
