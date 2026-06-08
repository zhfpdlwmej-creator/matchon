package com.jacob.matchon.service;

import com.jacob.matchon.dto.AttendanceSummary;
import com.jacob.matchon.model.*;
import com.jacob.matchon.repo.AttendanceRepository;
import com.jacob.matchon.repo.MatchGuestRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttendanceService {

	private final AttendanceRepository attendanceRepo;
	private final MatchGuestRepository guestRepo;
	private final ScheduleService scheduleService;
	private final TeamService teamService;
	private final UserService userService;
	private final NotificationService notificationService;

	/** 용병 추가 (팀 멤버면 가능) */
	@Transactional
	public MatchGuest addGuest(Long scheduleId, Long userId, String name, int headcount) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), userId);
		if (name == null || name.isBlank()) throw new ApiException(400, "용병 이름을 입력해주세요.");
		int hc = Math.max(1, headcount);
		return guestRepo.save(MatchGuest.builder()
				.scheduleId(scheduleId).name(name.trim().length() > 40 ? name.trim().substring(0, 40) : name.trim())
				.headcount(hc).addedBy(userId).build());
	}

	/** 용병 삭제 (추가자 또는 운영진) */
	@Transactional
	public void removeGuest(Long guestId, Long userId) {
		MatchGuest g = guestRepo.findById(guestId)
				.orElseThrow(() -> new ApiException(404, "용병을 찾을 수 없습니다."));
		MatchSchedule s = scheduleService.get(g.getScheduleId());
		boolean manager = teamService.membership(s.getTeamId(), userId).getRole().canManage();
		if (!g.getAddedBy().equals(userId) && !manager) {
			throw new ApiException(403, "삭제 권한이 없습니다.");
		}
		guestRepo.delete(g);
	}

	/** 참석 상태 변경(버튼 클릭). 멤버면 누구나 본인 상태 변경 가능. */
	@Transactional
	public Attendance setStatus(Long scheduleId, Long userId, AttendanceStatus status) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), userId); // 팀 멤버 확인

		Attendance att = attendanceRepo.findByScheduleIdAndUserId(scheduleId, userId)
				.orElseGet(() -> Attendance.builder()
						.scheduleId(scheduleId)
						.userId(userId)
						.status(AttendanceStatus.PENDING)
						.paid(false)
						.build());

		// 선착순 마감: 새로 '참석'하려는데 이미 정원이 찼으면 차단
		if (status == AttendanceStatus.ATTEND && s.isLimitAttendance() && s.getTargetHeadcount() > 0
				&& att.getStatus() != AttendanceStatus.ATTEND) {
			long attendMembers = attendanceRepo.countByScheduleIdAndStatus(scheduleId, AttendanceStatus.ATTEND);
			long guests = guestRepo.findByScheduleIdOrderByCreatedAtAsc(scheduleId).stream()
					.mapToInt(MatchGuest::getHeadcount).sum();
			if (attendMembers + guests >= s.getTargetHeadcount()) {
				throw new ApiException(409, "선착순 마감되었습니다. (정원 " + s.getTargetHeadcount() + "명)");
			}
		}

		att.setStatus(status);
		att = attendanceRepo.save(att);

		// 인원부족 알림 체크
		checkLowAttendance(s);
		return att;
	}

	/** 회비 납부 토글 (팀장/운영진) */
	@Transactional
	public void setPaid(Long scheduleId, Long actorId, Long targetUserId, boolean paid) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.requireManager(s.getTeamId(), actorId);
		Attendance att = attendanceRepo.findByScheduleIdAndUserId(scheduleId, targetUserId)
				.orElseThrow(() -> new ApiException(404, "참석 정보가 없습니다."));
		att.setPaid(paid);
	}

	/** 참석 현황 집계 + 목록 + 포지션별 인원 */
	public AttendanceSummary summary(Long scheduleId) {
		MatchSchedule s = scheduleService.get(scheduleId);
		List<Attendance> all = attendanceRepo.findByScheduleId(scheduleId);

		// 팀 멤버 전체를 기준으로, 응답 없는 멤버는 미정 처리
		List<TeamMember> members = teamService.members(s.getTeamId());
		Map<Long, Attendance> attByUser = all.stream()
				.collect(Collectors.toMap(Attendance::getUserId, a -> a));
		Map<Long, User> users = userService.mapByIds(
				members.stream().map(TeamMember::getUserId).toList());

		List<AttendanceSummary.MemberRow> attendList = new ArrayList<>();
		List<AttendanceSummary.MemberRow> absentList = new ArrayList<>();
		List<AttendanceSummary.MemberRow> pendingList = new ArrayList<>();
		Map<String, Long> byPosition = new LinkedHashMap<>();
		for (String p : List.of("GK", "DF", "MF", "FW")) byPosition.put(p, 0L);

		for (TeamMember m : members) {
			User u = users.get(m.getUserId());
			if (u == null) continue;
			Attendance a = attByUser.get(m.getUserId());
			AttendanceStatus st = a == null ? AttendanceStatus.PENDING : a.getStatus();
			String pos = u.getPosition() == null ? null : u.getPosition().name();
			boolean paid = a != null && a.isPaid();
			AttendanceSummary.MemberRow row =
					new AttendanceSummary.MemberRow(u.getId(), u.getNickname(), pos, paid);
			switch (st) {
				case ATTEND -> {
					attendList.add(row);
					if (pos != null) byPosition.merge(pos, 1L, Long::sum);
				}
				case ABSENT -> absentList.add(row);
				default -> pendingList.add(row);
			}
		}
		// 용병 집계
		List<MatchGuest> guestEntities = guestRepo.findByScheduleIdOrderByCreatedAtAsc(s.getId());
		long guestCount = guestEntities.stream().mapToLong(MatchGuest::getHeadcount).sum();
		List<AttendanceSummary.Guest> guests = guestEntities.stream()
				.map(g -> new AttendanceSummary.Guest(g.getId(), g.getName(), g.getHeadcount()))
				.toList();
		long totalCount = attendList.size() + guestCount;

		return new AttendanceSummary(
				attendList.size(), absentList.size(), pendingList.size(),
				guestCount, totalCount,
				byPosition, attendList, absentList, pendingList, guests);
	}

	/** 내 참석 상태 조회 */
	public AttendanceStatus myStatus(Long scheduleId, Long userId) {
		return attendanceRepo.findByScheduleIdAndUserId(scheduleId, userId)
				.map(Attendance::getStatus)
				.orElse(AttendanceStatus.PENDING);
	}

	private void checkLowAttendance(MatchSchedule s) {
		Team team = teamService.get(s.getTeamId());
		if (team.getMinAttendees() <= 0) return;
		long attending = attendanceRepo.countByScheduleIdAndStatus(s.getId(), AttendanceStatus.ATTEND);
		if (attending < team.getMinAttendees()) {
			notificationService.lowAttendance(team, s, attending);
		}
	}
}
