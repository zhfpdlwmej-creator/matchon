package com.jacob.matchon.repo;

import com.jacob.matchon.model.TeamPost;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TeamPostRepository extends JpaRepository<TeamPost, Long> {
	List<TeamPost> findByTeamIdOrderByNoticeDescIdDesc(Long teamId);
}
