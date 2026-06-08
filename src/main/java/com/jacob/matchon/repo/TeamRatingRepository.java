package com.jacob.matchon.repo;

import com.jacob.matchon.model.TeamRating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TeamRatingRepository extends JpaRepository<TeamRating, Long> {
	List<TeamRating> findByTargetTeamId(Long targetTeamId);
	boolean existsByMatchPostIdAndRaterTeamIdAndTargetTeamId(Long matchPostId, Long raterTeamId, Long targetTeamId);
}
