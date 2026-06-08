package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchPost;
import com.jacob.matchon.model.MatchStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MatchPostRepository extends JpaRepository<MatchPost, Long> {
	List<MatchPost> findByStatusOrderByCreatedAtDesc(MatchStatus status);
	List<MatchPost> findByStatusAndRegionContainingOrderByCreatedAtDesc(MatchStatus status, String region);
	List<MatchPost> findByHostTeamIdInOrderByCreatedAtDesc(List<Long> teamIds);
	Optional<MatchPost> findFirstBySourceScheduleIdAndStatus(Long sourceScheduleId, MatchStatus status);
}
