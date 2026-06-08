package com.jacob.matchon.service;

import com.jacob.matchon.dto.ScheduleForm;
import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.model.Team;
import com.jacob.matchon.repo.MatchScheduleRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ScheduleService {

	private final MatchScheduleRepository scheduleRepo;
	private final TeamService teamService;
	private final NotificationService notificationService;

	public MatchSchedule get(Long scheduleId) {
		return scheduleRepo.findById(scheduleId)
				.orElseThrow(() -> new ApiException(404, "일정을 찾을 수 없습니다."));
	}

	/** 팀 전체 일정 */
	public List<MatchSchedule> list(Long teamId) {
		return scheduleRepo.findByTeamIdOrderByMatchDateAscStartTimeAsc(teamId);
	}

	/** 월별 달력용 일정 */
	public List<MatchSchedule> listByMonth(Long teamId, int year, int month) {
		YearMonth ym = YearMonth.of(year, month);
		return scheduleRepo.findByTeamIdAndMatchDateBetweenOrderByMatchDateAscStartTimeAsc(
				teamId, ym.atDay(1), ym.atEndOfMonth());
	}

	/** 가장 가까운 다가오는 일정 1건 (홈 화면) */
	public Optional<MatchSchedule> nearest(Long teamId) {
		return scheduleRepo
				.findByTeamIdAndMatchDateGreaterThanEqualOrderByMatchDateAscStartTimeAsc(teamId, LocalDate.now())
				.stream().findFirst();
	}

	@Transactional
	public MatchSchedule create(Long teamId, Long userId, ScheduleForm form) {
		teamService.requireManager(teamId, userId); // 팀장/운영진만
		validate(form);
		MatchSchedule s = MatchSchedule.builder()
				.teamId(teamId)
				.title(form.getTitle().trim())
				.matchDate(form.getMatchDate())
				.startTime(form.getStartTime())
				.endTime(form.getEndTime())
				.place(form.getPlace())
				.fee(form.getFee() == null ? 0 : form.getFee())
				.targetHeadcount(form.getTargetHeadcount() == null ? 0 : form.getTargetHeadcount())
				.limitAttendance(Boolean.TRUE.equals(form.getLimitAttendance()))
				.memo(form.getMemo())
				.createdBy(userId)
				.build();
		s = scheduleRepo.save(s);

		// 일정 등록 알림 발송
		Team team = teamService.get(teamId);
		notificationService.onScheduleCreated(team, s);
		return s;
	}

	@Transactional
	public MatchSchedule update(Long scheduleId, Long userId, ScheduleForm form) {
		MatchSchedule s = get(scheduleId);
		teamService.requireManager(s.getTeamId(), userId);
		validate(form);
		s.setTitle(form.getTitle().trim());
		s.setMatchDate(form.getMatchDate());
		s.setStartTime(form.getStartTime());
		s.setEndTime(form.getEndTime());
		s.setPlace(form.getPlace());
		s.setFee(form.getFee() == null ? 0 : form.getFee());
		s.setTargetHeadcount(form.getTargetHeadcount() == null ? 0 : form.getTargetHeadcount());
		s.setLimitAttendance(Boolean.TRUE.equals(form.getLimitAttendance()));
		s.setMemo(form.getMemo());
		return s;
	}

	/** 포메이션 저장 (팀장/운영진) */
	@Transactional
	public void saveFormation(Long scheduleId, Long userId, String json) {
		MatchSchedule s = get(scheduleId);
		teamService.requireManager(s.getTeamId(), userId);
		s.setFormation(json);
	}

	@Transactional
	public void delete(Long scheduleId, Long userId) {
		MatchSchedule s = get(scheduleId);
		teamService.requireManager(s.getTeamId(), userId);
		scheduleRepo.delete(s);
	}

	private void validate(ScheduleForm form) {
		if (form.getTitle() == null || form.getTitle().isBlank()) {
			throw new ApiException(400, "경기명을 입력해주세요.");
		}
		if (form.getMatchDate() == null || form.getStartTime() == null) {
			throw new ApiException(400, "경기 날짜와 시작시간을 입력해주세요.");
		}
		if (form.getEndTime() != null && form.getEndTime().isBefore(form.getStartTime())) {
			throw new ApiException(400, "종료시간이 시작시간보다 빠를 수 없습니다.");
		}
	}
}
