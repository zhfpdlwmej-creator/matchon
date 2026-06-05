package com.jacob.matchon.repo;

import com.jacob.matchon.model.TeamMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TeamMemberRepository extends JpaRepository<TeamMember, Long> {
	List<TeamMember> findByTeamId(Long teamId);
	List<TeamMember> findByUserId(Long userId);
	Optional<TeamMember> findByTeamIdAndUserId(Long teamId, Long userId);
	boolean existsByTeamIdAndUserId(Long teamId, Long userId);
	long countByTeamId(Long teamId);
}
