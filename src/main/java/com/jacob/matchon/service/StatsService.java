package com.jacob.matchon.service;

import com.jacob.matchon.dto.StatRow;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.StatsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** 출석률 통계: 이번 달 / 최근 3개월 / 전체. */
@Service
@RequiredArgsConstructor
public class StatsService {

	private final StatsRepository statsRepo;
	private final TeamService teamService;
	private final UserService userService;

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
		// 전체 참석률 내림차순
		rows.sort((a, b) -> Integer.compare(b.getTotalRate(), a.getTotalRate()));
		return rows;
	}

	private int rate(long attended, long total) {
		if (total <= 0) return 0;
		return (int) Math.round(attended * 100.0 / total);
	}
}
