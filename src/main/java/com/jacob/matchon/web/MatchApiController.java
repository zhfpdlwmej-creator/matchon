package com.jacob.matchon.web;

import com.jacob.matchon.dto.MatchForm;
import com.jacob.matchon.model.*;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.MatchService;
import com.jacob.matchon.service.TeamService;
import com.jacob.matchon.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/** 팀 매칭 REST API. */
@RestController
@RequestMapping("/api/match")
@RequiredArgsConstructor
public class MatchApiController {

	private final MatchService matchService;
	private final TeamService teamService;
	private final UserService userService;

	/** 매칭 등록/신청에 쓸 수 있는 내 팀(팀장/운영진) 목록 */
	@GetMapping("/my-teams")
	public Map<String, Object> myTeams() {
		Long uid = CurrentUser.required();
		List<Map<String, Object>> teams = teamService.leaderTeams(uid).stream()
				.map(t -> teamMap(t.getId(), t.getName())).toList();
		return Map.of("ok", true, "teams", teams);
	}

	/** 모집중 매칭 목록 (지역 필터) */
	@GetMapping("/list")
	public Map<String, Object> list(@RequestParam(required = false) String region) {
		Long uid = CurrentUser.required();
		Set<Long> mine = teamService.leaderTeams(uid).stream()
				.map(Team::getId).collect(Collectors.toSet());
		List<Map<String, Object>> rows = matchService.listOpen(region).stream()
				.map(p -> postView(p, mine)).toList();
		return Map.of("ok", true, "matches", rows);
	}

	/** 매칭 상세 */
	@GetMapping("/{id}")
	public Map<String, Object> detail(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.get(id);
		List<Team> manage = teamService.leaderTeams(uid);
		Set<Long> mine = manage.stream().map(Team::getId).collect(Collectors.toSet());
		boolean isHost = mine.contains(p.getHostTeamId());

		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("match", postView(p, mine));
		res.put("isHost", isHost);

		// 호스트면 신청 목록 노출
		if (isHost) {
			List<MatchApplication> apps = matchService.applications(id);
			Map<Long, User> users = userService.mapByIds(apps.stream().map(MatchApplication::getApplicantUserId).toList());
			res.put("applications", apps.stream().map(a -> {
				Team t = teamService.get(a.getApplicantTeamId());
				User u = users.get(a.getApplicantUserId());
				Map<String, Object> m = new HashMap<>();
				m.put("id", a.getId());
				m.put("teamName", t.getName());
				m.put("applicant", u == null ? "?" : u.getNickname());
				m.put("message", a.getMessage());
				m.put("status", a.getStatus().name());
				return m;
			}).toList());
		} else {
			// 신청자면: 신청 가능한 내 팀(호스트팀 제외)
			List<Map<String, Object>> applicable = manage.stream()
					.filter(t -> !t.getId().equals(p.getHostTeamId()))
					.map(t -> teamMap(t.getId(), t.getName())).toList();
			res.put("applicableTeams", applicable);
		}
		return res;
	}

	/** 매칭 등록 */
	@PostMapping
	public Map<String, Object> create(@RequestParam Long teamId, @RequestBody MatchForm form) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.create(uid, teamId, form);
		return Map.of("ok", true, "id", p.getId());
	}

	/** 신청 */
	@PostMapping("/{id}/apply")
	public Map<String, Object> apply(@PathVariable Long id, @RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Long teamId = Long.valueOf(body.get("teamId"));
		matchService.apply(uid, id, teamId, body.get("message"));
		return Map.of("ok", true);
	}

	/** 신청 수락 (호스트) */
	@PostMapping("/application/{appId}/accept")
	public Map<String, Object> accept(@PathVariable Long appId) {
		Long uid = CurrentUser.required();
		matchService.accept(appId, uid);
		return Map.of("ok", true);
	}

	/** 매칭 마감 (호스트) */
	@PostMapping("/{id}/close")
	public Map<String, Object> close(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		matchService.close(id, uid);
		return Map.of("ok", true);
	}

	// ---------- view helpers ----------

	private Map<String, Object> postView(MatchPost p, Set<Long> mine) {
		Team host = teamService.get(p.getHostTeamId());
		Map<String, Object> m = new HashMap<>();
		m.put("id", p.getId());
		m.put("hostTeamId", p.getHostTeamId());
		m.put("hostTeamName", host.getName());
		m.put("hostName", userService.findById(p.getHostUserId()).map(User::getNickname).orElse("?"));
		m.put("level", p.getLevel().name());
		m.put("levelLabel", p.getLevel().label());
		m.put("headcount", p.getHeadcount());
		m.put("region", p.getRegion());
		m.put("placeName", p.getPlaceName());
		m.put("lat", p.getLat());
		m.put("lng", p.getLng());
		m.put("matchDate", p.getMatchDate() == null ? null : p.getMatchDate().toString());
		m.put("startTime", p.getStartTime() == null ? null : p.getStartTime().toString());
		m.put("memo", p.getMemo());
		m.put("status", p.getStatus().name());
		m.put("applications", matchService.applicationCount(p.getId()));
		m.put("mine", mine.contains(p.getHostTeamId()));
		return m;
	}

	private Map<String, Object> teamMap(Long id, String name) {
		Map<String, Object> m = new HashMap<>();
		m.put("id", id);
		m.put("name", name);
		return m;
	}
}
