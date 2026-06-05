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
		if (!user.isSetupDone()) return "redirect:/welcome";

		// 초대 링크(/join?code=...)로 들어온 경우 자동 가입 처리
		String invite = readCookie(req, "pending_invite");
		if (invite != null && !invite.isBlank()) {
			clearCookie(res, "pending_invite");
			try {
				Team t = teamService.joinByCode(uid, invite);
				return "redirect:/team/" + t.getId();
			} catch (ApiException e) {
				// 이미 가입했거나 잘못된 코드 → 해당 팀이면 그 팀으로, 아니면 정상 흐름
				Team t = teamService.findByInviteCode(invite).orElse(null);
				if (t != null && teamService.isMember(t.getId(), uid)) {
					return "redirect:/team/" + t.getId();
				}
			}
		}

		List<Team> teams = teamService.myTeams(uid);
		if (teams.isEmpty()) return "redirect:/teams";
		return "redirect:/team/" + teams.get(0).getId();
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

	@GetMapping("/teams")
	public String teams(Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		model.addAttribute("user", userService.get(uid));
		return "team/teams";
	}

	@GetMapping("/team/{teamId}")
	public String teamHome(@PathVariable Long teamId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		Optional<MatchSchedule> nearest = scheduleService.nearest(teamId);
		model.addAttribute("nearest", nearest.orElse(null));
		return "home";
	}

	@GetMapping("/team/{teamId}/schedules")
	public String schedules(@PathVariable Long teamId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		return "schedule/list";
	}

	@GetMapping("/team/{teamId}/schedule/{scheduleId}")
	public String scheduleDetail(@PathVariable Long teamId, @PathVariable Long scheduleId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		model.addAttribute("scheduleId", scheduleId);
		return "schedule/detail";
	}

	@GetMapping("/team/{teamId}/members")
	public String members(@PathVariable Long teamId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		return "member/list";
	}

	@GetMapping("/team/{teamId}/stats")
	public String stats(@PathVariable Long teamId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		return "stats/list";
	}

	@GetMapping("/team/{teamId}/admin")
	public String admin(@PathVariable Long teamId, Model model) {
		if (!putTeamContext(teamId, model)) return "redirect:/login";
		// 권한 표시는 화면에서 myRole 로 제어
		return "admin/index";
	}

	@GetMapping("/profile")
	public String profile(Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return "redirect:/login";
		List<Team> teams = teamService.myTeams(uid);
		model.addAttribute("user", userService.get(uid));
		model.addAttribute("teams", teams);
		// 하단 네비가 team.id 를 사용하므로 대표 팀 1개를 컨텍스트로 제공
		if (!teams.isEmpty()) model.addAttribute("team", teams.get(0));
		return "profile";
	}

	/** 공통 팀 컨텍스트 주입. 미로그인/비멤버면 false */
	private boolean putTeamContext(Long teamId, Model model) {
		Long uid = CurrentUser.id();
		if (uid == null) return false;
		User user = userService.get(uid);
		if (!user.isSetupDone()) {
			model.addAttribute("redirectWelcome", true);
		}
		TeamMember me = teamService.members(teamId).stream()
				.filter(m -> m.getUserId().equals(uid)).findFirst().orElse(null);
		if (me == null) return false;
		Team team = teamService.get(teamId);
		model.addAttribute("user", user);
		model.addAttribute("team", team);
		model.addAttribute("myRole", me.getRole().name());
		model.addAttribute("canManage", me.getRole().canManage());
		model.addAttribute("teams", teamService.myTeams(uid));
		return true;
	}
}
