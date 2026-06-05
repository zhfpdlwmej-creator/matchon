package com.jacob.matchon.repo;

import com.jacob.matchon.model.Team;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TeamRepository extends JpaRepository<Team, Long> {
	Optional<Team> findByInviteCode(String inviteCode);
	boolean existsByInviteCode(String inviteCode);
}
