package com.jacob.matchon.scheduler;

import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.model.NotificationType;
import com.jacob.matchon.model.Team;
import com.jacob.matchon.repo.MatchScheduleRepository;
import com.jacob.matchon.repo.TeamRepository;
import com.jacob.matchon.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 경기 리마인드 알림 스케줄러.
 * 매 10분마다 다가오는 일정을 점검해서:
 *  - 하루 전(D_1): 경기 24시간 전 ±30분 윈도우
 *  - 3시간 전(H_3): 3시간 전 ±15분 윈도우
 *  - 30분 전(M_30): 30분 전 ±10분 윈도우
 * 각 알림은 NotificationService.notifyOnce 로 중복 발송 방지.
 */
@Component
@RequiredArgsConstructor
public class ReminderScheduler {

	private static final Logger log = LoggerFactory.getLogger(ReminderScheduler.class);

	private final MatchScheduleRepository scheduleRepo;
	private final TeamRepository teamRepo;
	private final NotificationService notificationService;

	/** 매 10분 — 전체 팀을 돌며 임박 일정 리마인드 */
	@Scheduled(cron = "0 */10 * * * *")
	public void remindAll() {
		LocalDateTime now = LocalDateTime.now();
		Map<Long, Team> teamCache = new HashMap<>();
		List<MatchSchedule> upcoming = scheduleRepo.findAll().stream()
				.filter(s -> {
					LocalDateTime start = s.startsAt();
					return start.isAfter(now) && start.isBefore(now.plusDays(2));
				})
				.toList();

		for (MatchSchedule s : upcoming) {
			Duration d = Duration.between(now, s.startsAt());
			long min = d.toMinutes();
			NotificationType type = null;
			if (within(min, 24 * 60, 30)) type = NotificationType.D_1;
			else if (within(min, 3 * 60, 15)) type = NotificationType.H_3;
			else if (within(min, 30, 10)) type = NotificationType.M_30;
			if (type == null) continue;

			Team team = teamCache.computeIfAbsent(s.getTeamId(),
					id -> teamRepo.findById(id).orElse(null));
			if (team == null) continue;
			notificationService.remind(team, s, type);
		}
		if (!upcoming.isEmpty()) {
			log.debug("리마인드 점검: {}건 임박 일정 확인", upcoming.size());
		}
	}

	/** target 분 기준 ±window 분 이내인가 */
	private boolean within(long actualMin, long targetMin, long window) {
		return Math.abs(actualMin - targetMin) <= window;
	}
}
