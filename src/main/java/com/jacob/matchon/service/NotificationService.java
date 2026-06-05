package com.jacob.matchon.service;

import com.jacob.matchon.model.*;
import com.jacob.matchon.notification.NotificationSender;
import com.jacob.matchon.repo.NotificationRepository;
import com.jacob.matchon.repo.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

	private final NotificationRepository notiRepo;
	private final TeamRepository teamRepo;
	private final NotificationSender sender;

	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("M월 d일 a h시 m분");

	/** 알림 생성 + 즉시 발송 (중복 타입은 1회만) */
	@Transactional
	public void notifyOnce(Long teamId, Long scheduleId, NotificationType type, String message) {
		if (scheduleId != null && notiRepo.existsByScheduleIdAndType(scheduleId, type)) {
			return; // 이미 발송됨
		}
		Notification n = Notification.builder()
				.teamId(teamId)
				.scheduleId(scheduleId)
				.type(type)
				.message(message)
				.sent(false)
				.build();
		n = notiRepo.save(n);
		sender.send(n);
		n.setSent(true);
		n.setSentAt(LocalDateTime.now());
	}

	/** 일정 등록 알림 */
	public void onScheduleCreated(Team team, MatchSchedule s) {
		String msg = String.format("[%s]%n새 경기 일정이 등록되었습니다.%n%s (%s)%n참석 여부를 확인해주세요.",
				team.getName(), s.getTitle(), s.startsAt().format(TIME_FMT));
		notifyOnce(team.getId(), s.getId(), NotificationType.SCHEDULE_CREATED, msg);
	}

	/** 리마인드 알림(하루전/3시간전/30분전) */
	public void remind(Team team, MatchSchedule s, NotificationType type) {
		String when = switch (type) {
			case D_1 -> "내일";
			case H_3 -> "약 3시간 뒤";
			case M_30 -> "약 30분 뒤";
			default -> "곧";
		};
		String msg = String.format("[%s]%n%s 경기가 예정되어 있습니다.%n%s (%s)%n참석 여부를 확인해주세요.",
				team.getName(), when, s.getTitle(), s.startsAt().format(TIME_FMT));
		notifyOnce(team.getId(), s.getId(), type, msg);
	}

	/** 인원 부족 알림 */
	public void lowAttendance(Team team, MatchSchedule s, long attending) {
		String msg = String.format("[%s]%n현재 참석 인원이 부족합니다. (%d명 / 기준 %d명)%n%s%n참석 부탁드립니다!",
				team.getName(), attending, team.getMinAttendees(), s.getTitle());
		notifyOnce(team.getId(), s.getId(), NotificationType.LOW_ATTENDANCE, msg);
	}

	public List<Notification> history(Long teamId) {
		return notiRepo.findByTeamIdOrderByCreatedAtDesc(teamId);
	}
}
