package com.jacob.matchon.web;

import com.jacob.matchon.dto.MatchForm;
import com.jacob.matchon.model.*;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.MatchCommentService;
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
	private final MatchCommentService matchCommentService;

	/** 매칭 등록/신청에 쓸 수 있는 내 팀(팀장/운영진) 목록 */
	@GetMapping("/my-teams")
	public Map<String, Object> myTeams() {
		Long uid = CurrentUser.required();
		List<Map<String, Object>> teams = teamService.leaderTeams(uid).stream()
				.map(t -> teamMap(t.getId(), t.getName())).toList();
		return Map.of("ok", true, "teams", teams);
	}

	/** 모집중 목록 (지역 필터). guest=true 면 용병모집글, 아니면 팀 매칭만. teamId = 현재 팀 */
	@GetMapping("/list")
	public Map<String, Object> list(@RequestParam(required = false) String region,
									@RequestParam(required = false) Long teamId,
									@RequestParam(required = false) String sport,
									@RequestParam(required = false) Boolean guest) {
		CurrentUser.required();
		boolean wantGuest = guest != null && guest;
		Set<Long> mine = teamId == null ? Set.of() : Set.of(teamId);
		com.jacob.matchon.model.Sport sp = (sport == null || sport.isBlank()) ? null : com.jacob.matchon.model.Sport.parse(sport);
		List<Map<String, Object>> rows = matchService.listOpen(region, sp).stream()
				.filter(p -> p.isRecruitGuest() == wantGuest)
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

		List<Map<String, Object>> hosting = matchService.hostingByTeam(teamId).stream()
				.filter(p -> !p.isRecruitGuest())   // 용병모집글은 용병모집 탭에서 관리
				.map(p -> {
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
			boolean isHostManager = matchService.isGuestHostManager(p, uid);
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
		res.putAll(matchService.ratingInfo(id, uid));   // canRate / targetTeamName / alreadyRated
		return res;
	}

	/** 매칭 댓글(소통) 조회 — 모집팀=전체 스레드, 신청팀=본인 스레드 */
	@GetMapping("/{id}/comments")
	public Map<String, Object> comments(@PathVariable Long id, @RequestParam(required = false) Long teamId) {
		Long uid = CurrentUser.required();
		return matchCommentService.list(id, uid, teamId);
	}

	/** 매칭 댓글/대댓글 작성 */
	@PostMapping("/{id}/comments")
	public Map<String, Object> addComment(@PathVariable Long id, @RequestParam(required = false) Long teamId,
										  @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		Long applicantTeamId = parseLong(body.get("applicantTeamId"));
		Long applicantUserId = parseLong(body.get("applicantUserId"));
		Long parentId = parseLong(body.get("parentId"));
		matchCommentService.add(id, uid, teamId, applicantTeamId, applicantUserId, parentId, String.valueOf(body.getOrDefault("content", "")));
		return Map.of("ok", true);
	}

	/** 매칭 댓글 삭제 (작성자/모집팀) */
	@DeleteMapping("/comment/{commentId}")
	public Map<String, Object> deleteComment(@PathVariable Long commentId, @RequestParam(required = false) Long teamId) {
		Long uid = CurrentUser.required();
		matchCommentService.delete(commentId, uid, teamId);
		return Map.of("ok", true);
	}

	/** 용병(개인) 매너 평가 + 후기 (모집팀 팀장/운영진) */
	@PostMapping("/{id}/rate-guest")
	public Map<String, Object> rateGuest(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		Long targetUserId = parseLong(body.get("targetUserId"));
		int manner = body.get("manner") == null ? 0 : Integer.parseInt(String.valueOf(body.get("manner")));
		String comment = body.get("comment") == null ? null : String.valueOf(body.get("comment"));
		matchService.rateGuest(id, uid, targetUserId, manner, comment);
		return Map.of("ok", true);
	}

	/** 상대팀 매너/실력 평가 */
	@PostMapping("/{id}/rate")
	public Map<String, Object> rate(@PathVariable Long id, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		int manner = body.get("manner") == null ? 0 : Integer.parseInt(String.valueOf(body.get("manner")));
		String skill = body.get("skill") == null ? null : String.valueOf(body.get("skill"));
		String comment = body.get("comment") == null ? null : String.valueOf(body.get("comment"));
		matchService.rateOpponent(id, uid, manner, skill, comment);
		return Map.of("ok", true);
	}

	/** 매칭 등록 */
	@PostMapping
	public Map<String, Object> create(@RequestParam Long teamId, @RequestBody MatchForm form) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.create(uid, teamId, form);
		return Map.of("ok", true, "id", p.getId());
	}

	/** 개인 오픈매치(픽업) 등록 — 팀 없이 개인 주최 */
	@PostMapping("/open-match")
	public Map<String, Object> openMatch(@RequestBody MatchForm form) {
		Long uid = CurrentUser.required();
		MatchPost p = matchService.createOpenMatch(uid, form);
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
		boolean openMatch = p.getHostTeamId() == null;
		String hostNick = userService.findById(p.getHostUserId()).map(User::getNickname).orElse("?");
		Map<String, Object> m = new HashMap<>();
		m.put("id", p.getId());
		m.put("hostTeamId", p.getHostTeamId());
		m.put("openMatch", openMatch);
		m.put("hostTeamName", openMatch ? (hostNick + " (개인)") : teamService.get(p.getHostTeamId()).getName());
		m.put("hostName", hostNick);
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
		m.put("mine", p.getHostTeamId() != null && mine.contains(p.getHostTeamId()));
		double[] mn = openMatch ? matchService.userMannerSummary(p.getHostUserId()) : matchService.mannerSummary(p.getHostTeamId());
		m.put("mannerAvg", mn[1] > 0 ? mn[0] : null);
		m.put("mannerCount", (int) mn[1]);
		return m;
	}

	private Long parseLong(Object o) {
		return (o == null || String.valueOf(o).isBlank()) ? null : Long.valueOf(String.valueOf(o));
	}

	private Map<String, Object> teamMap(Long id, String name) {
		Map<String, Object> m = new HashMap<>();
		m.put("id", id);
		m.put("name", name);
		return m;
	}
}
