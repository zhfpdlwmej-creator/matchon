package com.jacob.matchon.repo;

import com.jacob.matchon.model.ApplicationStatus;
import com.jacob.matchon.model.JoinRequest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface JoinRequestRepository extends JpaRepository<JoinRequest, Long> {
	List<JoinRequest> findByTeamIdAndStatusOrderByCreatedAtAsc(Long teamId, ApplicationStatus status);
	List<JoinRequest> findByUserIdAndStatusOrderByCreatedAtDesc(Long userId, ApplicationStatus status);
	Optional<JoinRequest> findByTeamIdAndUserId(Long teamId, Long userId);
	long countByTeamIdAndStatus(Long teamId, ApplicationStatus status);
}
