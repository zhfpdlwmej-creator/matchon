package com.jacob.matchon.repo;

import com.jacob.matchon.model.MomVote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MomVoteRepository extends JpaRepository<MomVote, Long> {
	List<MomVote> findByScheduleId(Long scheduleId);
	List<MomVote> findByTeamId(Long teamId);
	Optional<MomVote> findByScheduleIdAndVoterUserId(Long scheduleId, Long voterUserId);
	long countByTargetUserId(Long targetUserId);
}
