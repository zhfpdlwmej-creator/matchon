package com.jacob.matchon.repo;

import com.jacob.matchon.model.Venue;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VenueRepository extends JpaRepository<Venue, Long> {
	List<Venue> findByTeamIdOrderByIdDesc(Long teamId);
}
