package com.jacob.matchon.repo;

import com.jacob.matchon.model.PositionRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PositionRequestRepository extends JpaRepository<PositionRequest, Long> {
	List<PositionRequest> findByScheduleIdOrderByIdAsc(Long scheduleId);
	Optional<PositionRequest> findByScheduleIdAndUserId(Long scheduleId, Long userId);
	void deleteByScheduleIdAndUserId(Long scheduleId, Long userId);
}
