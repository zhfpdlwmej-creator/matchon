package com.jacob.matchon.web;

import com.jacob.matchon.dto.ScheduleForm;
import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.AttendanceService;
import com.jacob.matchon.service.ScheduleService;
import com.jacob.matchon.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** 경기 일정 REST API. */
@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
public class ScheduleApiController {

	private final ScheduleService scheduleService;
	private final TeamService teamService;
	private final AttendanceService attendanceService;

	/** 내 다가오는 경기 + 내 참석 상태 (홈 개인 탭) */
	@GetMapping("/my-upcoming")
	public Map<String, Object> myUpcoming(@RequestParam Long teamId) {
		Long uid = CurrentUser.required();
		teamService.membership(teamId, uid);
		List<Map<String, Object>> rows = scheduleService.list(teamId).stream()
				.filter(s -> !s.getMatchDate().isBefore(LocalDate.now()))
				.map(s -> {
					Map<String, Object> m = view(s);
					m.put("myStatus", attendanceService.myStatus(s.getId(), uid).name());
					return m;
				}).toList();
		return Map.of("ok", true, "schedules", rows);
	}

	/** 일정 목록 (월별 옵션) */
	@GetMapping("/list")
	public Map<String, Object> list(
			@RequestParam Long teamId,
			@RequestParam(required = false) Integer year,
			@RequestParam(required = false) Integer month) {
		Long uid = CurrentUser.required();
		teamService.membership(teamId, uid);
		List<MatchSchedule> list = (year != null && month != null)
				? scheduleService.listByMonth(teamId, year, month)
				: scheduleService.list(teamId);
		return Map.of("ok", true, "schedules", list.stream().map(this::view).toList());
	}

	/** 일정 상세 */
	@GetMapping("/{id}")
	public Map<String, Object> detail(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		MatchSchedule s = scheduleService.get(id);
		teamService.membership(s.getTeamId(), uid);
		return Map.of("ok", true, "schedule", view(s));
	}

	/** 일정 등록 (팀장/운영진) */
	@PostMapping
	public Map<String, Object> create(@RequestParam Long teamId, @RequestBody ScheduleForm form) {
		Long uid = CurrentUser.required();
		MatchSchedule s = scheduleService.create(teamId, uid, form);
		return Map.of("ok", true, "schedule", view(s));
	}

	/** 일정 수정 */
	@PutMapping("/{id}")
	public Map<String, Object> update(@PathVariable Long id, @RequestBody ScheduleForm form) {
		Long uid = CurrentUser.required();
		MatchSchedule s = scheduleService.update(id, uid, form);
		return Map.of("ok", true, "schedule", view(s));
	}

	/** 일정 삭제 */
	@DeleteMapping("/{id}")
	public Map<String, Object> delete(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		scheduleService.delete(id, uid);
		return Map.of("ok", true);
	}

	/** 포메이션 조회 */
	@GetMapping("/{id}/formation")
	public Map<String, Object> getFormation(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		MatchSchedule s = scheduleService.get(id);
		teamService.membership(s.getTeamId(), uid);
		Map<String, Object> m = new HashMap<>();
		m.put("ok", true);
		m.put("formation", s.getFormation());
		m.put("title", s.getTitle());
		m.put("sport", teamService.get(s.getTeamId()).getSport().name());
		return m;
	}

	/** 포메이션 저장 (팀장/운영진) */
	@PostMapping("/{id}/formation")
	public Map<String, Object> saveFormation(@PathVariable Long id, @RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		scheduleService.saveFormation(id, uid, body.get("data"));
		return Map.of("ok", true);
	}

	/** 다가오는 가장 가까운 일정 1건 (홈 화면) */
	@GetMapping("/nearest")
	public Map<String, Object> nearest(@RequestParam Long teamId) {
		Long uid = CurrentUser.required();
		teamService.membership(teamId, uid);
		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("schedule", scheduleService.nearest(teamId).map(this::view).orElse(null));
		return res;
	}

	private Map<String, Object> view(MatchSchedule s) {
		Map<String, Object> m = new HashMap<>();
		m.put("id", s.getId());
		m.put("teamId", s.getTeamId());
		m.put("title", s.getTitle());
		m.put("matchDate", s.getMatchDate().toString());
		m.put("startTime", s.getStartTime().toString());
		m.put("endTime", s.getEndTime() == null ? null : s.getEndTime().toString());
		m.put("place", s.getPlace());
		m.put("fee", s.getFee());
		m.put("targetHeadcount", s.getTargetHeadcount());
		m.put("memo", s.getMemo());
		m.put("isPast", s.getMatchDate().isBefore(LocalDate.now()));
		return m;
	}
}
