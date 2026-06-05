package com.jacob.matchon.repo;

import com.jacob.matchon.model.AttendanceStatus;
import com.jacob.matchon.model.QAttendance;
import com.jacob.matchon.model.QMatchSchedule;
import com.querydsl.core.types.dsl.BooleanExpression;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;

/**
 * QueryDSL 기반 출석률 통계.
 * 분모 = 해당 기간 팀 일정 수, 분자 = 그 중 ATTEND 한 수.
 */
@Repository
@RequiredArgsConstructor
public class StatsRepository {

	private final JPAQueryFactory query;

	/** 기간 내 팀 전체 경기 수 */
	public long totalMatches(Long teamId, LocalDate from, LocalDate to) {
		QMatchSchedule s = QMatchSchedule.matchSchedule;
		Long cnt = query.select(s.count())
				.from(s)
				.where(s.teamId.eq(teamId), dateBetween(s, from, to))
				.fetchOne();
		return cnt == null ? 0 : cnt;
	}

	/** 기간 내 특정 회원의 ATTEND 수 */
	public long attendedMatches(Long teamId, Long userId, LocalDate from, LocalDate to) {
		QMatchSchedule s = QMatchSchedule.matchSchedule;
		QAttendance a = QAttendance.attendance;
		Long cnt = query.select(a.count())
				.from(a)
				.join(s).on(a.scheduleId.eq(s.id))
				.where(s.teamId.eq(teamId),
						a.userId.eq(userId),
						a.status.eq(AttendanceStatus.ATTEND),
						dateBetween(s, from, to))
				.fetchOne();
		return cnt == null ? 0 : cnt;
	}

	private BooleanExpression dateBetween(QMatchSchedule s, LocalDate from, LocalDate to) {
		if (from != null && to != null) return s.matchDate.between(from, to);
		if (from != null) return s.matchDate.goe(from);
		if (to != null) return s.matchDate.loe(to);
		return null;
	}
}
