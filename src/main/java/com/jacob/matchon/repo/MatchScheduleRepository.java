package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface MatchScheduleRepository extends JpaRepository<MatchSchedule, Long> {

	List<MatchSchedule> findByTeamIdOrderByMatchDateAscStartTimeAsc(Long teamId);

	List<MatchSchedule> findByTeamIdAndMatchDateBetweenOrderByMatchDateAscStartTimeAsc(
			Long teamId, LocalDate from, LocalDate to);

	/** 다가오는 일정(오늘 이후) 가장 가까운 1건 */
	List<MatchSchedule> findByTeamIdAndMatchDateGreaterThanEqualOrderByMatchDateAscStartTimeAsc(
			Long teamId, LocalDate today);
}
