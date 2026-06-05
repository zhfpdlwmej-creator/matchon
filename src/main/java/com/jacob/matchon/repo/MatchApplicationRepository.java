package com.jacob.matchon.repo;

import com.jacob.matchon.model.ApplicationStatus;
import com.jacob.matchon.model.MatchApplication;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MatchApplicationRepository extends JpaRepository<MatchApplication, Long> {
	List<MatchApplication> findByMatchPostIdOrderByCreatedAtAsc(Long matchPostId);
	boolean existsByMatchPostIdAndApplicantTeamId(Long matchPostId, Long applicantTeamId);
	long countByMatchPostId(Long matchPostId);
	long countByMatchPostIdAndStatus(Long matchPostId, ApplicationStatus status);
	List<MatchApplication> findByApplicantTeamIdInOrderByCreatedAtDesc(List<Long> teamIds);
}
