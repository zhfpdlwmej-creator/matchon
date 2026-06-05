package com.jacob.matchon.repo;

import com.jacob.matchon.model.Comment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {
	List<Comment> findByScheduleIdOrderByCreatedAtAsc(Long scheduleId);
	long countByScheduleId(Long scheduleId);
}
