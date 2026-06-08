package com.jacob.matchon.service;

import com.jacob.matchon.dto.MatchForm;
import com.jacob.matchon.model.*;
import com.jacob.matchon.repo.MatchApplicationRepository;
import com.jacob.matchon.repo.MatchPostRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MatchService {

	private final MatchPostRepository postRepo;
	private final MatchApplicationRepository appRepo;
	private final TeamService teamService;
	private final ScheduleService scheduleService;
	private final AttendanceService attendanceService;
	private final UserService userService;

	// ---------- 조회 ----------

	public MatchPost get(Long id) {
		return postRepo.findById(id)
				.orElseThrow(() -> new ApiException(404, "매칭을 찾을 수 없습니다."));
	}

	/** 모집중 매칭 목록 (지역·종목 필터 옵션) */
	public List<MatchPost> listOpen(String region, Sport sport) {
		List<MatchPost> base = (region != null && !region.isBlank())
				? postRepo.findByStatusAndRegionContainingOrderByCreatedAtDesc(MatchStatus.OPEN, region.trim())
				: postRepo.findByStatusOrderByCreatedAtDesc(MatchStatus.OPEN);
		if (sport != null) {
			return base.stream().filter(p -> p.getSport() == sport).toList();
		}
		return base;
	}

	public List<MatchApplication> applications(Long postId) {
		return appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId);
	}

	public long applicationCount(Long postId) {
		return appRepo.countByMatchPostId(postId);
	}

	public long pendingCount(Long postId) {
		return appRepo.countByMatchPostIdAndStatus(postId, ApplicationStatus.PENDING);
	}

	/** 특정 팀이 올린 매칭 */
	public List<MatchPost> hostingByTeam(Long teamId) {
		return postRepo.findByHostTeamIdInOrderByCreatedAtDesc(List.of(teamId));
	}

	/** 특정 팀이 신청한 매칭 신청들 */
	public List<MatchApplication> applicationsByTeam(Long teamId) {
		return appRepo.findByApplicantTeamIdInOrderByCreatedAtDesc(List.of(teamId));
	}

	// ---------- 등록 ----------

	@Transactional
	public MatchPost create(Long userId, Long hostTeamId, MatchForm form) {
		teamService.requireLeader(hostTeamId, userId); // 팀장/운영진만
		MatchLevel level = parseLevel(form.getLevel());
		if (level == null) throw new ApiException(400, "팀 수준(상/중/하)을 선택해주세요.");

		MatchPost p = MatchPost.builder()
				.hostTeamId(hostTeamId)
				.hostUserId(userId)
				.sport(teamService.get(hostTeamId).getSport())
				.level(level)
				.matchType(blankToNull(form.getMatchType()))
				.ageGroup(blankToNull(form.getAgeGroup()))
				.headcount(form.getHeadcount() == null ? 0 : form.getHeadcount())
				.region(form.getRegion())
				.placeName(form.getPlaceName())
				.lat(form.getLat())
				.lng(form.getLng())
				.matchDate(form.getMatchDate())
				.startTime(form.getStartTime())
				.memo(form.getMemo())
				.status(MatchStatus.OPEN)
				.build();
		return postRepo.save(p);
	}

	/** 일정 인원 부족 → 용병(개인) 모집글 원터치 등록 */
	@Transactional
	public MatchPost createGuestRecruit(Long userId, Long scheduleId) {
		com.jacob.matchon.model.MatchSchedule s = scheduleService.get(scheduleId);
		teamService.requireLeader(s.getTeamId(), userId);
		postRepo.findFirstBySourceScheduleIdAndStatus(scheduleId, MatchStatus.OPEN).ifPresent(p -> {
			throw new ApiException(409, "이미 이 일정의 용병 모집글이 등록되어 있습니다.");
		});
		var sum = attendanceService.summary(scheduleId);
		int shortage = (int) Math.max(1, s.getTargetHeadcount() - sum.getTotalCount());
		MatchPost p = MatchPost.builder()
				.hostTeamId(s.getTeamId())
				.hostUserId(userId)
				.sport(teamService.get(s.getTeamId()).getSport())
				.level(MatchLevel.MID)
				.recruitGuest(true)
				.sourceScheduleId(scheduleId)
				.headcount(shortage)
				.placeName(s.getPlace())
				.matchDate(s.getMatchDate())
				.startTime(s.getStartTime())
				.memo(s.getTitle() + " · 용병 " + shortage + "명 모집")
				.status(MatchStatus.OPEN)
				.build();
		return postRepo.save(p);
	}

	/** 용병(개인) 지원 */
	@Transactional
	public MatchApplication applyGuest(Long userId, Long postId, String message) {
		MatchPost post = get(postId);
		if (!post.isRecruitGuest()) throw new ApiException(400, "용병 모집글이 아닙니다.");
		if (post.getStatus() != MatchStatus.OPEN) throw new ApiException(409, "마감된 모집입니다.");
		if (post.getHostUserId().equals(userId)) throw new ApiException(400, "내가 올린 모집글에는 지원할 수 없습니다.");
		if (appRepo.existsByMatchPostIdAndApplicantUserId(postId, userId)) throw new ApiException(409, "이미 지원했습니다.");
		return appRepo.save(MatchApplication.builder()
				.matchPostId(postId)
				.applicantTeamId(null)
				.applicantUserId(userId)
				.message(message)
				.status(ApplicationStatus.PENDING)
				.build());
	}

	/** 용병 지원 수락 → 우리 일정에 용병으로 자동 추가 (모집글은 계속 열어둠) */
	@Transactional
	public void acceptGuest(Long applicationId, Long userId) {
		MatchApplication app = appRepo.findById(applicationId)
				.orElseThrow(() -> new ApiException(404, "지원을 찾을 수 없습니다."));
		MatchPost post = get(app.getMatchPostId());
		teamService.requireLeader(post.getHostTeamId(), userId);
		app.setStatus(ApplicationStatus.ACCEPTED);
		if (post.getSourceScheduleId() != null) {
			String name = userService.findById(app.getApplicantUserId())
					.map(User::getNickname).orElse("용병");
			attendanceService.addGuest(post.getSourceScheduleId(), userId, name + " (지원)", 1);
		}
	}

	private String blankToNull(String s) {
		return (s == null || s.isBlank() || "ANY".equals(s)) ? null : s;
	}

	@Transactional
	public void close(Long postId, Long userId) {
		MatchPost p = get(postId);
		teamService.requireLeader(p.getHostTeamId(), userId);
		p.setStatus(MatchStatus.CLOSED);
	}

	// ---------- 신청 ----------

	@Transactional
	public MatchApplication apply(Long userId, Long postId, Long applicantTeamId, String message) {
		MatchPost post = get(postId);
		if (post.getStatus() != MatchStatus.OPEN) {
			throw new ApiException(409, "이미 마감되었거나 성사된 매칭입니다.");
		}
		teamService.requireLeader(applicantTeamId, userId); // 신청도 팀장/운영진
		if (applicantTeamId.equals(post.getHostTeamId())) {
			throw new ApiException(400, "내 팀이 올린 매칭에는 신청할 수 없습니다.");
		}
		if (appRepo.existsByMatchPostIdAndApplicantTeamId(postId, applicantTeamId)) {
			throw new ApiException(409, "이미 신청한 매칭입니다.");
		}
		return appRepo.save(MatchApplication.builder()
				.matchPostId(postId)
				.applicantTeamId(applicantTeamId)
				.applicantUserId(userId)
				.message(message)
				.status(ApplicationStatus.PENDING)
				.build());
	}

	/** 호스트가 신청 수락 → 매칭 성사, 나머지 신청은 거절 */
	@Transactional
	public void accept(Long applicationId, Long userId) {
		MatchApplication app = appRepo.findById(applicationId)
				.orElseThrow(() -> new ApiException(404, "신청을 찾을 수 없습니다."));
		MatchPost post = get(app.getMatchPostId());
		teamService.requireLeader(post.getHostTeamId(), userId); // 호스트 권한

		app.setStatus(ApplicationStatus.ACCEPTED);
		post.setStatus(MatchStatus.MATCHED);
		// 나머지 대기중 신청 거절
		for (MatchApplication other : appRepo.findByMatchPostIdOrderByCreatedAtAsc(post.getId())) {
			if (!other.getId().equals(applicationId) && other.getStatus() == ApplicationStatus.PENDING) {
				other.setStatus(ApplicationStatus.REJECTED);
			}
		}
	}

	private MatchLevel parseLevel(String v) {
		try {
			return v == null || v.isBlank() ? null : MatchLevel.valueOf(v);
		} catch (Exception e) {
			return null;
		}
	}
}
