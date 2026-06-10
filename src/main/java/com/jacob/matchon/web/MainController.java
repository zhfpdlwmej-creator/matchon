package com.jacob.matchon.web;

import com.jacob.matchon.model.*;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.ScheduleService;
import com.jacob.matchon.service.TeamService;
import com.jacob.matchon.service.UserService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Optional;

/** JSP 화면 라우팅. 데이터는 대부분 JS 가 /api 로 비동기 로드. */
@Controller
@RequiredArgsConstructor
public class MainController {

	private final UserService userService;
	private final TeamService teamService;
	private final ScheduleService scheduleService;

	@GetMapping("/login")
	public String login() {
		return CurrentUser.id() != null ? "redirect:/" : "login";
	}

	/** 약관·개인정보처리방침 (비로그인 접근 가능) */
	@GetMapping("/terms")
	public String terms() { return "legal/terms"; }

	@GetMapping("/privacy")
	public String privacy() { return "legal/privacy"; }

	@GetMapping("/welcome")
	public String welcome(Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		model.addAttribute("user", userService.get(uid));
		return "welcome";
	}

	/** 홈 — 로그인/설정/팀 가입 상태에 따라 분기 */
	@GetMapping("/")
	public String home(HttpServletRequest req, HttpServletResponse res) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		User user = userService.get(uid);
		// 닉네임 설정 단계 없이 카카오 닉네임 그대로 사용 (welcome 생략)

		// 초대 링크(/join?code=...)로 들어온 경우 → "현재 계정 확인" 화면으로
		// (단톡방 링크는 카카오톡 인앱 브라우저로 열려 이전 계정 쿠키가 남아있을 수 있어, 자동 가입 대신 본인 확인)
		String invite = readCookie(req, "pending_invite");
		if (invite != null && !invite.isBlank()) {
			return "redirect:/join/confirm";
		}

		List<Team> teams = teamService.myTeams(uid);
		if (teams.isEmpty()) return "redirect:/teams";
		// 마지막으로 보던 팀(쿠키) 기준, 없으면 첫 팀
		return "redirect:/team/" + currentTeamId(req, uid);
	}

	/**
	 * 초대 링크 진입점. code 를 쿠키에 저장 후 홈으로 보냄.
	 * - 비로그인: 홈→로그인→카카오 인증 후 홈으로 돌아오면 쿠키로 자동 가입
	 * - 로그인: 홈에서 즉시 자동 가입
	 */
	@GetMapping("/join")
	public String join(@RequestParam(name = "code", required = false) String code, HttpServletResponse res) {
		if (code != null && !code.isBlank()) {
			Cookie c = new Cookie("pending_invite", code.trim().toUpperCase());
			c.setPath("/");
			c.setMaxAge(3600); // 1시간 유효
			res.addCookie(c);
		}
		return "redirect:/";
	}

	/** 초대 링크 진입 시 현재 로그인 계정 확인 화면 (다른 사람 쿠키로 잘못 가입 방지) */
	@GetMapping("/join/confirm")
	public String joinConfirm(HttpServletRequest req, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		String invite = readCookie(req, "pending_invite");
		if (invite == null || invite.isBlank()) return "redirect:/";
		Team t = teamService.findByInviteCode(invite).orElse(null);
		if (t == null) { clearCookie(res, "pending_invite"); return "redirect:/teams"; }
		if (teamService.isMember(t.getId(), uid)) { clearCookie(res, "pending_invite"); return "redirect:/team/" + t.getId(); }
		model.addAttribute("user", userService.get(uid));
		model.addAttribute("teamName", t.getName());
		return "join_confirm";
	}

	/** 확인 화면에서 "이 계정으로 가입" 선택 → 가입 신청 */
	@GetMapping("/join/accept")
	public String joinAccept(HttpServletRequest req, HttpServletResponse res) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		String invite = readCookie(req, "pending_invite");
		clearCookie(res, "pending_invite");
		if (invite == null || invite.isBlank()) return "redirect:/";
		try {
			teamService.requestJoin(uid, invite);
			return "redirect:/teams?req=sent";
		} catch (ApiException e) {
			Team t = teamService.findByInviteCode(invite).orElse(null);
			if (t != null && teamService.isMember(t.getId(), uid)) return "redirect:/team/" + t.getId();
			return "redirect:/teams";
		}
	}

	private String readCookie(HttpServletRequest req, String name) {
		if (req.getCookies() == null) return null;
		for (Cookie c : req.getCookies()) {
			if (name.equals(c.getName())) return c.getValue();
		}
		return null;
	}

	private void clearCookie(HttpServletResponse res, String name) {
		Cookie c = new Cookie(name, "");
		c.setPath("/");
		c.setMaxAge(0);
		res.addCookie(c);
	}

	private static final String CUR_TEAM_COOKIE = "cur_team";

	/** 현재 보고 있는 팀을 쿠키에 기억 */
	private void setCurrentTeam(HttpServletResponse res, Long teamId) {
		Cookie c = new Cookie(CUR_TEAM_COOKIE, String.valueOf(teamId));
		c.setPath("/");
		c.setMaxAge(60 * 60 * 24 * 365);
		res.addCookie(c);
	}

	/** 쿠키의 현재 팀(내가 속한 팀이면) → 없으면 첫 팀. 팀 없으면 null */
	private Long currentTeamId(HttpServletRequest req, Long uid) {
		List<Team> teams = teamService.myTeams(uid);
		if (teams.isEmpty()) return null;
		String v = readCookie(req, CUR_TEAM_COOKIE);
		if (v != null && !v.isBlank()) {
			try {
				Long id = Long.valueOf(v.trim());
				if (teams.stream().anyMatch(t -> t.getId().equals(id))) return id;
			} catch (NumberFormatException ignore) {
			}
		}
		return teams.get(0).getId();
	}

	@GetMapping("/teams")
	public String teams(HttpServletRequest req, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		putNavContext(uid, req, model);
		return "team/teams";
	}

	@GetMapping("/team/{teamId}")
	public String teamHome(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		Optional<MatchSchedule> nearest = scheduleService.nearest(teamId);
		model.addAttribute("nearest", nearest.orElse(null));
		return "home";
	}

	@GetMapping("/team/{teamId}/schedules")
	public String schedules(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		return "schedule/list";
	}

	@GetMapping("/team/{teamId}/schedule/{scheduleId}")
	public String scheduleDetail(@PathVariable Long teamId, @PathVariable Long scheduleId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		model.addAttribute("scheduleId", scheduleId);
		return "schedule/detail";
	}

	@GetMapping("/team/{teamId}/schedule/{scheduleId}/formation")
	public String formation(@PathVariable Long teamId, @PathVariable Long scheduleId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		model.addAttribute("scheduleId", scheduleId);
		return "schedule/formation";
	}

	@GetMapping("/team/{teamId}/venues")
	public String venues(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		return "venue/list";
	}

	@GetMapping("/team/{teamId}/settings")
	public String teamSettings(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		if (!teamService.isLeader(teamId, uid) && !teamService.members(teamId).stream()
				.anyMatch(m -> m.getUserId().equals(uid) && m.getRole().canManage())) {
			return "redirect:/team/" + teamId;
		}
		setCurrentTeam(res, teamId);
		return "team/settings";
	}

	@GetMapping("/team/{teamId}/board")
	public String board(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		return "board/list";
	}

	@GetMapping("/team/{teamId}/members")
	public String members(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		return "member/list";
	}

	@GetMapping("/team/{teamId}/dues")
	public String dues(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		if (!teamService.isTreasurer(teamId, uid)) return "redirect:/team/" + teamId;
		// 회비 구분 안 함(NONE) 팀은 회비 관리 미사용
		if (teamService.get(teamId).getFeeMode() == FeeMode.NONE) return "redirect:/team/" + teamId;
		setCurrentTeam(res, teamId);
		return "dues/list";
	}

	@GetMapping("/team/{teamId}/stats")
	public String stats(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		return "stats/list";
	}

	@GetMapping("/team/{teamId}/admin")
	public String admin(@PathVariable Long teamId, HttpServletResponse res, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		if (!putTeamContext(teamId, uid, model)) return "redirect:/";
		setCurrentTeam(res, teamId);
		// 권한 표시는 화면에서 myRole 로 제어
		return "admin/index";
	}

	/** 팀 매칭 목록 (지역별 친선경기 모집) */
	@GetMapping("/matches")
	public String matches(HttpServletRequest req, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		putNavContext(uid, req, model);
		return "match/list";
	}

	/** 매칭 상세 */
	@GetMapping("/matches/{matchId}")
	public String matchDetail(@PathVariable Long matchId, HttpServletRequest req, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		putNavContext(uid, req, model);
		model.addAttribute("matchId", matchId);
		return "match/detail";
	}

	/** 하단 메뉴용 컨텍스트(현재 선택 팀) 주입 — 팀이 없으면 nav 는 /teams 로 폴백 */
	private void putNavContext(Long uid, HttpServletRequest req, Model model) {
		model.addAttribute("user", userService.get(uid));
		List<Team> teams = teamService.myTeams(uid);
		model.addAttribute("teams", teams);
		Long cur = currentTeamId(req, uid);
		boolean isLeader = false;
		boolean isTreasurer = false;
		if (cur != null) {
			model.addAttribute("team", teamService.get(cur));
			isLeader = teamService.isLeader(cur, uid);
			isTreasurer = teamService.isTreasurer(cur, uid);
		}
		model.addAttribute("isLeader", isLeader);
		model.addAttribute("isTreasurer", isTreasurer);
	}

	@GetMapping("/profile")
	public String profile(HttpServletRequest req, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		putNavContext(uid, req, model);
		return "profile";
	}

	/** 공통 팀 컨텍스트 주입. 해당 팀의 멤버가 아니면 false (uid 는 호출부에서 이미 검증) */
	private boolean putTeamContext(Long teamId, Long uid, Model model) {
		User user = userService.get(uid);
		TeamMember me = teamService.members(teamId).stream()
				.filter(m -> m.getUserId().equals(uid)).findFirst().orElse(null);
		if (me == null) return false;
		Team team = teamService.get(teamId);
		model.addAttribute("user", user);
		model.addAttribute("team", team);
		model.addAttribute("myRole", me.getRole().name());
		model.addAttribute("canManage", me.getRole().canManage());
		model.addAttribute("isLeader", me.getRole() == Role.LEADER);
		model.addAttribute("isTreasurer", me.isTreasurer() || me.getRole() == Role.LEADER);
		model.addAttribute("teams", teamService.myTeams(uid));
		return true;
	}
}
