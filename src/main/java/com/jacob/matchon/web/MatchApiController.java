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

	/** 모집중 매칭 목록 (지역 필터). teamId = 현재 팀(내 팀 배지 기준) */
	@GetMapping("/list")
	public Map<String, Object> list(@RequestParam(required = false) String region,
									@RequestParam(required = false) Long teamId,
									@RequestParam(required = false) String sport) {
		CurrentUser.required();
		Set<Long> mine = teamId == null ? Set.of() : Set.of(teamId);
		com.jacob.matchon.model.Sport sp = (sport == null || sport.isBlank()) ? null : com.jacob.matchon.model.Sport.parse(sport);
		List<Map<String, Object>> rows = matchService.listOpen(region, sp).stream()
				.map(p -> postView(p, mine)).toList();
		return Map.of("ok", true, "matches", rows);
	}

	/** 내 매칭 — 현재 팀이 올린 것(신청 현황) + 현재 팀이 신청한 것(상태) */
	@GetMapping("/mine")
	public Map<String, Object> mine(@RequestParam(required = false) Long teamId) {
		Long uid = CurrentUser.required();
		if (teamId == null) return Map.of("ok", true, "hosting", List.of(), "applied", List.of());
		teamService.membership(teamId, uid); // 현재 팀 멤버 확인
		Set<Long> mineSet = Set.of(teamId);

		List<Map<String, Object>> hosting = matchService.hostingByTeam(teamId).stream().map(p -> {
			Map<String, Object> m = postView(p, mineSet);
			m.put("pending", matchService.pendingCount(p.getId()));
			return m;
		}).toList();

		List<Map<String, Object>> applied = matchService.applicationsByTeam(teamId).stream().map(a -> {
			MatchPost p = matchService.get(a.getMatchPostId());
			Team host = teamService.get(p.getHostTeamId());
			Team myTeam = teamService.get(a.getApplicantTeamId());
			Map<String, Object> m = new HashMap<>();
			m.put("matchId", p.getId());
			m.put("hostTeamName", host.getName());
			m.put("myTeamName", myTeam.getName());
			m.put("region", p.getRegion());
			m.put("level", p.getLevel().name());
			m.put("levelLabel", p.getLevel().label());
			m.put("postStatus", p.getStatus().name());
			m.put("myStatus", a.getStatus().name());
			return m;
		}).toList();

		return Map.of("ok", true, "hosting", hosting, "applied", applied);
	}

	/** 매칭 상세. teamId = 현재(활동) 팀 기준으로 호스트/신청 판정 */
	@GetMapping("/{id}")
	public Map<String, Object> detail(@PathVariable Long id, @RequestParam(required = false) Long teamId) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.get(id);
		Set<Long> mine = teamId == null ? Set.of() : Set.of(teamId);
		boolean isHost = teamId != null && teamId.equals(p.getHostTeamId());

		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("match", postView(p, mine));

		List<MatchApplication> apps = matchService.applications(id);

		// 용병(개인) 모집글: 팀이 아닌 개인 지원 흐름
		if (p.isRecruitGuest()) {
			boolean isHostManager = teamService.isLeader(p.getHostTeamId(), uid);
			res.put("isGuestRecruit", true);
			res.put("isHost", isHostManager);
			if (isHostManager) {
				Map<Long, User> users = userService.mapByIds(apps.stream().map(MatchApplication::getApplicantUserId).toList());
				res.put("applications", apps.stream().map(a -> {
					User u = users.get(a.getApplicantUserId());
					Map<String, Object> m = new HashMap<>();
					m.put("id", a.getId());
					m.put("applicant", u == null ? "?" : u.getNickname());
					m.put("message", a.getMessage());
					m.put("status", a.getStatus().name());
					return m;
				}).toList());
			}
			boolean alreadyApplied = apps.stream().anyMatch(a -> uid.equals(a.getApplicantUserId()));
			res.put("canApplyGuest", p.getStatus() == MatchStatus.OPEN && !isHostManager && !alreadyApplied);
			res.put("applicableTeams", List.of());
			return res;
		}

		res.put("isGuestRecruit", false);
		res.put("isHost", isHost);
		Set<Long> appliedTeams = apps.stream().map(MatchApplication::getApplicantTeamId).collect(Collectors.toSet());

		// 현재 팀이 호스트면 신청 목록(수락 관리) 노출
		if (isHost) {
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
		}

		// 현재 팀으로 신청 가능: 호스트 아님 + 미신청 + 내가 그 팀 팀장
		List<Map<String, Object>> applicable = new ArrayList<>();
		if (teamId != null && !teamId.equals(p.getHostTeamId())
				&& !appliedTeams.contains(teamId)
				&& teamService.isLeader(teamId, uid)) {
			applicable.add(teamMap(teamId, teamService.get(teamId).getName()));
		}
		res.put("applicableTeams", applicable);
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

	/** 일정 인원부족 → 용병 모집글 원터치 등록 (팀장/운영진) */
	@PostMapping("/recruit-guest")
	public Map<String, Object> recruitGuest(@RequestParam Long scheduleId) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.createGuestRecruit(uid, scheduleId);
		return Map.of("ok", true, "id", p.getId());
	}

	/** 용병(개인) 지원 */
	@PostMapping("/{id}/apply-guest")
	public Map<String, Object> applyGuest(@PathVariable Long id, @RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		matchService.applyGuest(uid, id, body.get("message"));
		return Map.of("ok", true);
	}

	/** 용병 지원 수락 (호스트) → 일정에 용병 자동 추가 */
	@PostMapping("/application/{appId}/accept-guest")
	public Map<String, Object> acceptGuest(@PathVariable Long appId) {
		Long uid = CurrentUser.required();
		matchService.acceptGuest(appId, uid);
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
		m.put("sport", p.getSport() == null ? "SOCCER" : p.getSport().name());
		m.put("sportLabel", p.getSport() == null ? "" : p.getSport().label());
		m.put("sportEmoji", p.getSport() == null ? "" : p.getSport().emoji());
		m.put("level", p.getLevel().name());
		m.put("levelLabel", p.getLevel().label());
		m.put("matchType", p.getMatchType());
		m.put("ageGroup", p.getAgeGroup());
		m.put("recruitGuest", p.isRecruitGuest());
		m.put("sourceScheduleId", p.getSourceScheduleId());
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
