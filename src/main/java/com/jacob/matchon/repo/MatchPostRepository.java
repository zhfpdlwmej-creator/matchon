package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchPost;
import com.jacob.matchon.model.MatchStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MatchPostRepository extends JpaRepository<MatchPost, Long> {
	List<MatchPost> findByStatusOrderByCreatedAtDesc(MatchStatus status);
	List<MatchPost> findByStatusAndRegionContainingOrderByCreatedAtDesc(MatchStatus status, String region);
	List<MatchPost> findByHostTeamIdInOrderByCreatedAtDesc(List<Long> teamIds);
}
