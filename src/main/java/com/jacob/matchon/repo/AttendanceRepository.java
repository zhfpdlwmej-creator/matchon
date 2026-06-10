package com.jacob.matchon.repo;

import com.jacob.matchon.model.Attendance;
import com.jacob.matchon.model.AttendanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
	List<Attendance> findByScheduleId(Long scheduleId);
	Optional<Attendance> findByScheduleIdAndUserId(Long scheduleId, Long userId);
	long countByScheduleIdAndStatus(Long scheduleId, AttendanceStatus status);
	List<Attendance> findByUserId(Long userId);
	List<Attendance> findByScheduleIdAndStatus(Long scheduleId, AttendanceStatus status);
	List<Attendance> findByScheduleIdInAndStatus(List<Long> scheduleIds, AttendanceStatus status);
	long countByUserIdAndStatus(Long userId, AttendanceStatus status);
}
