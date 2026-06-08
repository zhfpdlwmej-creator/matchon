package com.jacob.matchon.web;

import com.jacob.matchon.model.Position;
import com.jacob.matchon.model.Role;
import com.jacob.matchon.model.Sport;
import com.jacob.matchon.model.Team;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.model.User;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.TeamService;
import com.jacob.matchon.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/** 사용자/팀 REST API. */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TeamApiController {

	private final UserService userService;
	private final TeamService teamService;

	// ---------- 사용자 ----------

	/** 현재 로그인 사용자 정보 */
	@GetMapping("/me")
	public Map<String, Object> me() {
		Long uid = CurrentUser.id();
		if (uid == null) return Map.of("ok", true, "loggedIn", false);
		User u = userService.get(uid);
		return Map.of("ok", true, "loggedIn", true, "user", userView(u));
	}

	/** 최초 닉네임/포지션 설정 */
	@PostMapping("/user/setup")
	public Map<String, Object> setup(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		User u = userService.completeSetup(uid, body.get("nickname"), parsePos(body.get("position")));
		return Map.of("ok", true, "user", userView(u));
	}

	/** 프로필 수정 */
	@PostMapping("/user/profile")
	public Map<String, Object> profile(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		User u = userService.updateProfile(uid, body.get("nickname"), parsePos(body.get("position")));
		return Map.of("ok", true, "user", userView(u));
	}

	// ---------- 팀 ----------

	/** 내가 속한 팀 목록 */
	@GetMapping("/team/list")
	public Map<String, Object> teamList() {
		Long uid = CurrentUser.required();
		List<Map<String, Object>> teams = teamService.myTeams(uid).stream()
				.map(t -> teamView(t, uid)).toList();
		return Map.of("ok", true, "teams", teams);
	}

	/** 팀 생성 */
	@PostMapping("/team")
	public Map<String, Object> createTeam(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Team t = teamService.create(uid, body.get("name"), body.get("description"), Sport.parse(body.get("sport")));
		return Map.of("ok", true, "team", teamView(t, uid));
	}

	/** 초대코드로 가입 */
	@PostMapping("/team/join")
	public Map<String, Object> join(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Team t = teamService.joinByCode(uid, body.get("inviteCode"));
		return Map.of("ok", true, "team", teamView(t, uid));
	}

	/** 팀 탈퇴 (팀장 제외) */
	@PostMapping("/team/{teamId}/leave")
	public Map<String, Object> leave(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		teamService.leaveTeam(teamId, uid);
		return Map.of("ok", true);
	}

	/** 팀 해체 (팀장만) */
	@PostMapping("/team/{teamId}/disband")
	public Map<String, Object> disband(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		teamService.disband(teamId, uid);
		return Map.of("ok", true);
	}

	/** 초대코드 재발급 */
	@PostMapping("/team/{teamId}/invite-code")
	public Map<String, Object> regenCode(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		String code = teamService.regenerateCode(teamId, uid);
		return Map.of("ok", true, "inviteCode", code);
	}

	/** 팀원 목록 */
	@GetMapping("/team/{teamId}/members")
	public Map<String, Object> members(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		teamService.membership(teamId, uid);
		List<TeamMember> ms = teamService.members(teamId);
		Map<Long, User> users = userService.mapByIds(ms.stream().map(TeamMember::getUserId).toList());
		List<Map<String, Object>> rows = ms.stream().map(m -> {
			User u = users.get(m.getUserId());
			Map<String, Object> row = new HashMap<>();
			row.put("userId", m.getUserId());
			row.put("nickname", u == null ? "?" : u.getNickname());
			row.put("position", u == null || u.getPosition() == null ? null : u.getPosition().name());
			row.put("role", m.getRole().name());
			row.put("backNumber", m.getBackNumber());
			return row;
		}).toList();
		return Map.of("ok", true, "members", rows);
	}

	/** 권한 변경 (팀장) */
	@PostMapping("/team/{teamId}/role")
	public Map<String, Object> changeRole(@PathVariable Long teamId, @RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Long targetUserId = Long.valueOf(body.get("userId"));
		Role role = Role.valueOf(body.get("role"));
		teamService.changeRole(teamId, uid, targetUserId, role);
		return Map.of("ok", true);
	}

	/** 인원부족 알림 기준 설정 */
	@PostMapping("/team/{teamId}/min-attendees")
	public Map<String, Object> minAttendees(@PathVariable Long teamId, @RequestBody Map<String, Integer> body) {
		Long uid = CurrentUser.required();
		int min = body.getOrDefault("minAttendees", 0);
		teamService.setMinAttendees(teamId, uid, min);
		return Map.of("ok", true, "minAttendees", min);
	}

	// ---------- view helpers ----------

	private Map<String, Object> userView(User u) {
		Map<String, Object> m = new HashMap<>();
		m.put("id", u.getId());
		m.put("nickname", u.getNickname());
		m.put("position", u.getPosition() == null ? null : u.getPosition().name());
		m.put("setupDone", u.isSetupDone());
		return m;
	}

	private Map<String, Object> teamView(Team t, Long uid) {
		Map<String, Object> m = new HashMap<>();
		m.put("id", t.getId());
		m.put("name", t.getName());
		m.put("sport", t.getSport() == null ? "SOCCER" : t.getSport().name());
		m.put("sportLabel", t.getSportLabel());
		m.put("sportEmoji", t.getSportEmoji());
		m.put("description", t.getDescription());
		m.put("inviteCode", t.getInviteCode());
		m.put("minAttendees", t.getMinAttendees());
		m.put("memberCount", teamService.members(t.getId()).size());
		TeamMember me = teamService.members(t.getId()).stream()
				.filter(x -> x.getUserId().equals(uid)).findFirst().orElse(null);
		m.put("myRole", me == null ? null : me.getRole().name());
		return m;
	}

	private Position parsePos(String v) {
		try {
			return v == null || v.isBlank() ? null : Position.valueOf(v);
		} catch (Exception e) {
			return null;
		}
	}
}
