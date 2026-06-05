package com.jacob.matchon.repo;

import com.jacob.matchon.model.Notification;
import com.jacob.matchon.model.NotificationType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
	boolean existsByScheduleIdAndType(Long scheduleId, NotificationType type);
	List<Notification> findByTeamIdOrderByCreatedAtDesc(Long teamId);
}
