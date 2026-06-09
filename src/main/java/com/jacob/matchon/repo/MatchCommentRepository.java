package com.jacob.matchon.repo;

import com.jacob.matchon.model.MatchComment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MatchCommentRepository extends JpaRepository<MatchComment, Long> {
	List<MatchComment> findByMatchPostIdOrderByIdAsc(Long matchPostId);
	List<MatchComment> findByMatchPostIdAndApplicantTeamIdOrderByIdAsc(Long matchPostId, Long applicantTeamId);
	List<MatchComment> findByMatchPostIdAndApplicantUserIdOrderByIdAsc(Long matchPostId, Long applicantUserId);
}
