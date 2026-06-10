package com.jacob.matchon.web;

import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.model.User;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.DuesService;
import com.jacob.matchon.service.TeamService;
import com.jacob.matchon.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.*;

/** 월별 회비 관리 REST API — 총무/팀장 전용. */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class DuesApiController {

	private final DuesService duesService;
	private final TeamService teamService;
	private final UserService userService;

	/** 해당 월 회비 납부 현황 */
	@GetMapping("/team/{teamId}/dues")
	public Map<String, Object> dues(@PathVariable Long teamId,
									@RequestParam(required = false) String period) {
		Long uid = CurrentUser.required();
		duesService.requireTreasurer(teamId, uid);
		String p = (period == null || period.isBlank()) ? YearMonth.now().toString() : period;

		Set<Long> paid = duesService.paidUserIds(teamId, p);
		List<TeamMember> ms = teamService.members(teamId);
		Map<Long, User> users = userService.mapByIds(ms.stream().map(TeamMember::getUserId).toList());

		List<Map<String, Object>> rows = ms.stream().map(m -> {
			User u = users.get(m.getUserId());
			Map<String, Object> row = new HashMap<>();
			row.put("userId", m.getUserId());
			row.put("nickname", u == null ? "?" : u.getNickname());
			row.put("membershipLabel", m.getMembershipType().label());
			row.put("paid", paid.contains(m.getUserId()));
			return row;
		}).toList();

		return Map.of("ok", true, "period", p,
				"members", rows, "paidCount", paid.size(), "total", ms.size());
	}

	/** 회비 납부 체크 토글 */
	@PostMapping("/team/{teamId}/dues")
	public Map<String, Object> setPaid(@PathVariable Long teamId, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		Long userId = Long.valueOf(String.valueOf(body.get("userId")));
		String period = String.valueOf(body.get("period"));
		boolean paid = Boolean.parseBoolean(String.valueOf(body.get("paid")));
		duesService.setPaid(teamId, uid, userId, period, paid);
		return Map.of("ok", true, "userId", userId, "paid", paid);
	}
}
