package com.jacob.matchon.service;

import com.jacob.matchon.dto.StatRow;
import com.jacob.matchon.model.*;
import com.jacob.matchon.repo.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

/** 출석률 통계 + 팀/개인 통계 대시보드. */
@Service
@RequiredArgsConstructor
public class StatsService {

	private final StatsRepository statsRepo;
	private final TeamService teamService;
	private final UserService userService;
	private final ScheduleService scheduleService;
	private final MatchResultRepository resultRepo;
	private final MatchEventRepository eventRepo;
	private final MomVoteRepository momRepo;
	private final AttendanceRepository attendanceRepo;

	public List<StatRow> teamStats(Long teamId) {
		LocalDate today = LocalDate.now();
		YearMonth thisMonth = YearMonth.from(today);
		LocalDate monthFrom = thisMonth.atDay(1);
		LocalDate monthTo = thisMonth.atEndOfMonth();
		LocalDate recent3From = today.minusMonths(3);

		long monthTotal = statsRepo.totalMatches(teamId, monthFrom, monthTo);
		long recent3Total = statsRepo.totalMatches(teamId, recent3From, today);
		long allTotal = statsRepo.totalMatches(teamId, null, null);

		List<TeamMember> members = teamService.members(teamId);
		Map<Long, User> users = userService.mapByIds(
				members.stream().map(TeamMember::getUserId).toList());

		List<StatRow> rows = new ArrayList<>();
		for (TeamMember m : members) {
			User u = users.get(m.getUserId());
			if (u == null) continue;
			long monthAtt = statsRepo.attendedMatches(teamId, u.getId(), monthFrom, monthTo);
			long recent3Att = statsRepo.attendedMatches(teamId, u.getId(), recent3From, today);
			long allAtt = statsRepo.attendedMatches(teamId, u.getId(), null, null);
			rows.add(new StatRow(
					u.getId(), u.getNickname(),
					u.getPosition() == null ? null : u.getPosition().name(),
					rate(monthAtt, monthTotal),
					rate(recent3Att, recent3Total),
					rate(allAtt, allTotal),
					allAtt, allTotal));
		}
		rows.sort((a, b) -> Integer.compare(b.getTotalRate(), a.getTotalRate()));
		return rows;
	}

	private int rate(long attended, long total) {
		if (total <= 0) return 0;
		return (int) Math.round(attended * 100.0 / total);
	}

	// ---------- 통계 대시보드 (경기결과/득점/도움/MOM) ----------

	public Map<String, Object> teamDashboard(Long teamId, Long uid) {
		teamService.membership(teamId, uid);

		List<MatchSchedule> schedules = scheduleService.list(teamId);
		List<Long> ids = schedules.stream().map(MatchSchedule::getId).toList();
		Map<Long, MatchSchedule> schById = schedules.stream()
				.collect(Collectors.toMap(MatchSchedule::getId, s -> s));

		List<MatchResult> results = ids.isEmpty() ? List.of() : resultRepo.findByScheduleIdIn(ids);
		results = results.stream()
				.sorted((a, b) -> schById.get(b.getScheduleId()).getMatchDate()
						.compareTo(schById.get(a.getScheduleId()).getMatchDate()))
				.collect(Collectors.toList());

		int gf = 0, ga = 0;
		for (MatchResult r : results) { gf += r.getOurScore(); ga += r.getOppScore(); }

		int w = 0, d = 0, l = 0;
		List<Map<String, Object>> recent = new ArrayList<>();
		for (MatchResult r : results) {
			String outcome = r.getOurScore() > r.getOppScore() ? "W"
					: r.getOurScore() < r.getOppScore() ? "L" : "D";
			if (recent.size() < 5) {
				if ("W".equals(outcome)) w++; else if ("L".equals(outcome)) l++; else d++;
				MatchSchedule s = schById.get(r.getScheduleId());
				Map<String, Object> m = new HashMap<>();
				m.put("scheduleId", r.getScheduleId());
				m.put("date", s.getMatchDate().toString());
				m.put("title", s.getTitle());
				m.put("our", r.getOurScore());
				m.put("opp", r.getOppScore());
				m.put("opponent", r.getOpponentName() == null ? "" : r.getOpponentName());
				m.put("outcome", outcome);
				recent.add(m);
			}
		}

		Map<String, Object> team = new HashMap<>();
		team.put("played", results.size());
		team.put("w", w); team.put("d", d); team.put("l", l);
		team.put("gf", gf); team.put("ga", ga);
		team.put("recent", recent);

		List<MatchEvent> events = eventRepo.findByTeamId(teamId);
		List<Map<String, Object>> scorers = rankByName(events.stream()
				.map(MatchEvent::getScorerName).filter(Objects::nonNull).collect(Collectors.toList()));
		List<Map<String, Object>> assisters = rankByName(events.stream()
				.map(MatchEvent::getAssistName).filter(Objects::nonNull).collect(Collectors.toList()));

		List<Attendance> atts = ids.isEmpty() ? List.of()
				: attendanceRepo.findByScheduleIdInAndStatus(ids, AttendanceStatus.ATTEND);
		Map<Long, Long> attCount = atts.stream()
				.collect(Collectors.groupingBy(Attendance::getUserId, Collectors.counting()));

		Map<Long, Long> momCount = momRepo.findByTeamId(teamId).stream()
				.collect(Collectors.groupingBy(MomVote::getTargetUserId, Collectors.counting()));

		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("team", team);
		res.put("scorers", scorers);
		res.put("assisters", assisters);
		res.put("attendance", rankByUser(attCount));
		res.put("mom", rankByUser(momCount));
		return res;
	}

	/** 개인 전적 (모든 활동 팀 통합) */
	public Map<String, Object> personalStats(Long uid) {
		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("attend", attendanceRepo.countByUserIdAndStatus(uid, AttendanceStatus.ATTEND));
		res.put("goals", eventRepo.countByScorerUserId(uid));
		res.put("assists", eventRepo.countByAssistUserId(uid));
		res.put("mom", momRepo.countByTargetUserId(uid));
		res.put("noShow", attendanceRepo.countByUserIdAndNoShowTrue(uid));
		return res;
	}

	private List<Map<String, Object>> rankByName(List<String> names) {
		Map<String, Long> counts = names.stream()
				.collect(Collectors.groupingBy(n -> n, Collectors.counting()));
		return counts.entrySet().stream()
				.sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
				.limit(5)
				.map(e -> {
					Map<String, Object> m = new HashMap<>();
					m.put("name", e.getKey());
					m.put("count", e.getValue());
					return m;
				}).collect(Collectors.toList());
	}

	private List<Map<String, Object>> rankByUser(Map<Long, Long> counts) {
		Map<Long, User> users = userService.mapByIds(new ArrayList<>(counts.keySet()));
		return counts.entrySet().stream()
				.sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
				.limit(5)
				.map(e -> {
					Map<String, Object> m = new HashMap<>();
					User u = users.get(e.getKey());
					m.put("name", u == null ? "?" : u.getNickname());
					m.put("count", e.getValue());
					return m;
				}).collect(Collectors.toList());
	}
}
