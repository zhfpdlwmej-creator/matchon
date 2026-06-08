package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchGuest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MatchGuestRepository extends JpaRepository<MatchGuest, Long> {
	List<MatchGuest> findByScheduleIdOrderByCreatedAtAsc(Long scheduleId);
}
