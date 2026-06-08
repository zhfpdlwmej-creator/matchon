package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchResult;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MatchResultRepository extends JpaRepository<MatchResult, Long> {
	Optional<MatchResult> findByScheduleId(Long scheduleId);
	List<MatchResult> findByScheduleIdIn(List<Long> scheduleIds);
}
