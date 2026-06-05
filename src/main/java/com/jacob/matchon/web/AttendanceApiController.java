package com.jacob.matchon.web;

import com.jacob.matchon.dto.AttendanceSummary;
import com.jacob.matchon.model.AttendanceStatus;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 참석 여부 REST API. */
@RestController
@RequestMapping("/api/attendance")
@RequiredArgsConstructor
public class AttendanceApiController {

	private final AttendanceService attendanceService;

	/** 참석 상태 변경 (버튼 클릭) */
	@PostMapping
	public Map<String, Object> setStatus(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Long scheduleId = Long.valueOf(body.get("scheduleId"));
		AttendanceStatus status = AttendanceStatus.valueOf(body.get("status"));
		attendanceService.setStatus(scheduleId, uid, status);
		return Map.of("ok", true, "status", status.name());
	}

	/** 참석 현황 집계 + 목록 */
	@GetMapping("/list")
	public Map<String, Object> list(@RequestParam Long scheduleId) {
		CurrentUser.required();
		AttendanceSummary s = attendanceService.summary(scheduleId);
		Long uid = CurrentUser.id();
		return Map.of(
				"ok", true,
				"summary", s,
				"myStatus", attendanceService.myStatus(scheduleId, uid).name());
	}

	/** 회비 납부 여부 토글 (팀장/운영진) */
	@PostMapping("/paid")
	public Map<String, Object> setPaid(@RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		Long scheduleId = Long.valueOf(String.valueOf(body.get("scheduleId")));
		Long targetUserId = Long.valueOf(String.valueOf(body.get("userId")));
		boolean paid = Boolean.parseBoolean(String.valueOf(body.get("paid")));
		attendanceService.setPaid(scheduleId, uid, targetUserId, paid);
		return Map.of("ok", true);
	}
}
