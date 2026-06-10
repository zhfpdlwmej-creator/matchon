package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MatchEventRepository extends JpaRepository<MatchEvent, Long> {
	List<MatchEvent> findByScheduleIdOrderByIdAsc(Long scheduleId);
	List<MatchEvent> findByTeamId(Long teamId);
	long countByScorerUserId(Long scorerUserId);
	long countByAssistUserId(Long assistUserId);
	void deleteByScheduleId(Long scheduleId);
}
