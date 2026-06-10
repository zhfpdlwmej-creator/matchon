package com.jacob.matchon.web;

import com.jacob.matchon.model.Notification;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.NotificationService;
import com.jacob.matchon.service.StatsService;
import com.jacob.matchon.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** 통계/알림 이력 REST API. */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class StatsApiController {

	private final StatsService statsService;
	private final NotificationService notificationService;
	private final TeamService teamService;
	private final com.jacob.matchon.service.UserService userService;

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM-dd HH:mm");

	/** 팀 출석률 통계 */
	@GetMapping("/stats")
	public Map<String, Object> stats(@RequestParam Long teamId) {
		Long uid = CurrentUser.required();
		teamService.membership(teamId, uid);
		return Map.of("ok", true, "stats", statsService.teamStats(teamId));
	}

	/** 팀/개인 통계 대시보드 (경기결과·득점·도움·MOM) */
	@GetMapping("/stats/dashboard")
	public Map<String, Object> dashboard(@RequestParam Long teamId) {
		Long uid = CurrentUser.required();
		return statsService.teamDashboard(teamId, uid);
	}

	/** 내 개인 전적 (전 활동 팀 통합) */
	@GetMapping("/me/stats")
	public Map<String, Object> myStats() {
		return statsService.personalStats(CurrentUser.required());
	}

	/** 내 실력 레벨 설정 */
	@PostMapping("/me/level")
	public Map<String, Object> setLevel(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		userService.setSkillLevel(uid, body.get("level"));
		return Map.of("ok", true);
	}

	/** 알림 발송 이력 */
	@GetMapping("/notification/list")
	public Map<String, Object> notifications(@RequestParam Long teamId) {
		Long uid = CurrentUser.required();
		teamService.requireManager(teamId, uid);
		List<Map<String, Object>> rows = notificationService.history(teamId).stream().map(n -> {
			Map<String, Object> m = new HashMap<>();
			m.put("id", n.getId());
			m.put("type", n.getType().name());
			m.put("message", n.getMessage());
			m.put("sent", n.isSent());
			m.put("createdAt", n.getCreatedAt() == null ? "" : n.getCreatedAt().format(FMT));
			return m;
		}).toList();
		return Map.of("ok", true, "notifications", rows);
	}
}
