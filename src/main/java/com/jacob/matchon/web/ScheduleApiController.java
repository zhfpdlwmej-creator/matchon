package com.jacob.matchon.web;

import com.jacob.matchon.dto.ScheduleForm;
import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.AttendanceService;
import com.jacob.matchon.service.PositionRequestService;
import com.jacob.matchon.service.ResultService;
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
	private final ResultService resultService;
	private final PositionRequestService positionRequestService;

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

	// ---------- 경기 결과 / 득점·도움 / MOM ----------

	/** 결과+득점+MOM 조회 (팀 멤버) */
	@GetMapping("/{id}/result")
	public Map<String, Object> getResult(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		return resultService.view(id, uid);
	}

	/** 결과 저장 (팀장/운영진) */
	@PostMapping("/{id}/result")
	public Map<String, Object> saveResult(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		resultService.saveResult(id, uid, num(body.get("our")), num(body.get("opp")), str(body.get("opponentName")));
		return Map.of("ok", true);
	}

	/** 득점/도움 추가 (팀장/운영진) */
	@PostMapping("/{id}/event")
	public Map<String, Object> addEvent(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		resultService.addEvent(id, uid,
				lng(body.get("scorerUserId")), str(body.get("scorerName")),
				lng(body.get("assistUserId")), str(body.get("assistName")));
		return Map.of("ok", true);
	}

	/** 득점/도움 삭제 (팀장/운영진) */
	@DeleteMapping("/event/{eventId}")
	public Map<String, Object> deleteEvent(@PathVariable Long eventId) {
		Long uid = CurrentUser.required();
		resultService.deleteEvent(eventId, uid);
		return Map.of("ok", true);
	}

	/** MOM 투표 (팀 멤버) */
	@PostMapping("/{id}/mom")
	public Map<String, Object> voteMom(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		resultService.voteMom(id, uid, lng(body.get("targetUserId")));
		return Map.of("ok", true);
	}

	// ---------- 선호 포지션 신청 ----------

	/** 선호 포지션 신청 현황 + 내 신청 */
	@GetMapping("/{id}/positions")
	public Map<String, Object> positions(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		return positionRequestService.list(id, uid);
	}

	/** 내 선호 포지션 신청/변경 */
	@PostMapping("/{id}/position")
	public Map<String, Object> applyPosition(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		positionRequestService.apply(id, uid, str(body.get("position")), str(body.get("note")));
		return Map.of("ok", true);
	}

	/** 내 선호 포지션 신청 취소 */
	@DeleteMapping("/{id}/position")
	public Map<String, Object> cancelPosition(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		positionRequestService.cancel(id, uid);
		return Map.of("ok", true);
	}

	private int num(Object o) { return o == null ? 0 : Integer.parseInt(String.valueOf(o)); }
	private Long lng(Object o) { return (o == null || String.valueOf(o).isBlank()) ? null : Long.valueOf(String.valueOf(o)); }
	private String str(Object o) { return o == null ? null : String.valueOf(o); }

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
		m.put("lat", s.getLat());
		m.put("lng", s.getLng());
		m.put("fee", s.getFee());
		m.put("targetHeadcount", s.getTargetHeadcount());
		m.put("limitAttendance", s.isLimitAttendance());
		m.put("memo", s.getMemo());
		m.put("isPast", s.getMatchDate().isBefore(LocalDate.now()));
		return m;
	}
}
