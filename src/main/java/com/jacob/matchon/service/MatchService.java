package com.jacob.matchon.service;

import com.jacob.matchon.dto.MatchForm;
import com.jacob.matchon.model.*;
import com.jacob.matchon.repo.MatchApplicationRepository;
import com.jacob.matchon.repo.MatchPostRepository;
import com.jacob.matchon.repo.TeamRatingRepository;
import com.jacob.matchon.repo.UserRatingRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class MatchService {

	private final MatchPostRepository postRepo;
	private final MatchApplicationRepository appRepo;
	private final TeamService teamService;
	private final ScheduleService scheduleService;
	private final AttendanceService attendanceService;
	private final UserService userService;
	private final TeamRatingRepository teamRatingRepo;
	private final UserRatingRepository userRatingRepo;

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

	/** 개인 오픈매치(픽업) 등록 — 팀 없이 개인이 주최 */
	@Transactional
	public MatchPost createOpenMatch(Long userId, MatchForm form) {
		MatchLevel level = parseLevel(form.getLevel());
		MatchPost p = MatchPost.builder()
				.hostTeamId(null)
				.hostUserId(userId)
				.title(form.getTitle() == null || form.getTitle().isBlank() ? null : form.getTitle().trim())
				.sport(Sport.SOCCER)
				.level(level == null ? MatchLevel.MID : level)
				.matchType(blankToNull(form.getMatchType()))
				.recruitGuest(true)
				.headcount(form.getHeadcount() == null ? 1 : form.getHeadcount())
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

	/** 용병 신청 보장 — 댓글(소통) 남길 때 지원 레코드가 없으면 생성 (이미 있으면 그대로) */
	@Transactional
	public void ensureGuestApplication(Long userId, Long postId, String message) {
		MatchPost post = get(postId);
		if (!post.isRecruitGuest()) throw new ApiException(400, "용병 모집글이 아닙니다.");
		if (post.getStatus() != MatchStatus.OPEN) throw new ApiException(409, "마감된 모집입니다.");
		if (post.getHostUserId().equals(userId)) throw new ApiException(400, "내가 올린 모집글에는 지원할 수 없습니다.");
		if (appRepo.existsByMatchPostIdAndApplicantUserId(postId, userId)) return;
		appRepo.save(MatchApplication.builder()
				.matchPostId(postId).applicantTeamId(null).applicantUserId(userId)
				.message(message).status(ApplicationStatus.PENDING).build());
	}

	/** 용병 지원 수락 → 우리 일정에 용병으로 자동 추가 (모집글은 계속 열어둠) */
	@Transactional
	public void acceptGuest(Long applicationId, Long userId) {
		MatchApplication app = appRepo.findById(applicationId)
				.orElseThrow(() -> new ApiException(404, "지원을 찾을 수 없습니다."));
		MatchPost post = get(app.getMatchPostId());
		requireGuestHost(post, userId);
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

	// ---------- 용병모집/오픈매치 주최자 판별 (팀 또는 개인) ----------

	/** 주최자 권한 확인 — 팀 모집글=팀장/운영진, 개인 오픈매치=본인 */
	public void requireGuestHost(MatchPost post, Long uid) {
		if (post.getHostTeamId() != null) teamService.requireLeader(post.getHostTeamId(), uid);
		else if (!post.getHostUserId().equals(uid)) throw new ApiException(403, "주최자만 할 수 있습니다.");
	}

	/** 주최 측 구성원인지(스레드 열람) */
	public boolean isGuestHost(MatchPost post, Long uid) {
		return post.getHostTeamId() != null ? teamService.isMember(post.getHostTeamId(), uid)
				: uid.equals(post.getHostUserId());
	}

	/** 확정/평가 권한자인지(팀=운영권, 개인=본인) */
	public boolean isGuestHostManager(MatchPost post, Long uid) {
		if (post.getHostTeamId() == null) return uid.equals(post.getHostUserId());
		return teamService.isMember(post.getHostTeamId(), uid)
				&& teamService.membership(post.getHostTeamId(), uid).getRole().canManage();
	}

	// ---------- 상대팀 매너/실력 평점 ----------

	/** 성사된 매칭의 상대팀 평가 (두 팀의 팀장/운영진만, 팀당 1회) */
	@Transactional
	public void rateOpponent(Long postId, Long uid, int manner, String skill, String comment) {
		MatchPost post = get(postId);
		if (post.getStatus() != MatchStatus.MATCHED && post.getStatus() != MatchStatus.CLOSED) {
			throw new ApiException(409, "성사된 경기만 평가할 수 있습니다.");
		}
		if (manner < 1 || manner > 5) throw new ApiException(400, "매너 점수는 1~5 입니다.");
		MatchApplication accepted = appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
				.filter(a -> a.getStatus() == ApplicationStatus.ACCEPTED).findFirst()
				.orElseThrow(() -> new ApiException(409, "상대 팀 정보가 없습니다."));
		Long hostTeam = post.getHostTeamId();
		Long oppTeam = accepted.getApplicantTeamId();
		Long raterTeam, targetTeam;
		if (teamService.isLeader(hostTeam, uid)) { raterTeam = hostTeam; targetTeam = oppTeam; }
		else if (teamService.isLeader(oppTeam, uid)) { raterTeam = oppTeam; targetTeam = hostTeam; }
		else throw new ApiException(403, "두 팀의 팀장/운영진만 평가할 수 있습니다.");
		if (teamRatingRepo.existsByMatchPostIdAndRaterTeamIdAndTargetTeamId(postId, raterTeam, targetTeam)) {
			throw new ApiException(409, "이미 평가했습니다.");
		}
		teamRatingRepo.save(TeamRating.builder()
				.matchPostId(postId).raterUserId(uid).raterTeamId(raterTeam).targetTeamId(targetTeam)
				.manner(manner).skill(skill)
				.comment(comment == null || comment.isBlank() ? null : comment.trim())
				.build());
	}

	/** 용병(개인) 매너 평가 — 모집팀(팀장/운영진)이 확정된 용병을 평가 */
	@Transactional
	public void rateGuest(Long postId, Long raterUid, Long targetUserId, int manner, String comment) {
		MatchPost post = get(postId);
		if (!post.isRecruitGuest()) throw new ApiException(400, "용병 모집글이 아닙니다.");
		requireGuestHost(post, raterUid);
		if (manner < 1 || manner > 5) throw new ApiException(400, "매너 점수는 1~5 입니다.");
		boolean accepted = appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
				.anyMatch(a -> targetUserId.equals(a.getApplicantUserId()) && a.getStatus() == ApplicationStatus.ACCEPTED);
		if (!accepted) throw new ApiException(409, "확정된 용병만 평가할 수 있습니다.");
		if (userRatingRepo.existsByMatchPostIdAndRaterUserIdAndTargetUserId(postId, raterUid, targetUserId)) {
			throw new ApiException(409, "이미 평가했습니다.");
		}
		userRatingRepo.save(UserRating.builder()
				.targetUserId(targetUserId).raterUserId(raterUid).raterTeamId(post.getHostTeamId())
				.matchPostId(postId).manner(manner)
				.comment(comment == null || comment.isBlank() ? null : comment.trim())
				.build());
	}

	/** 개인의 평균 매너 [avg, count] */
	public double[] userMannerSummary(Long userId) {
		List<UserRating> rs = userRatingRepo.findByTargetUserIdOrderByIdDesc(userId);
		if (rs.isEmpty()) return new double[]{0, 0};
		double sum = rs.stream().mapToInt(UserRating::getManner).sum();
		return new double[]{ Math.round(sum / rs.size() * 10) / 10.0, rs.size() };
	}

	/** 이미 평가했는지 */
	public boolean ratedGuest(Long postId, Long raterUid, Long targetUserId) {
		return userRatingRepo.existsByMatchPostIdAndRaterUserIdAndTargetUserId(postId, raterUid, targetUserId);
	}

	/** 대상 팀의 평균 매너 [avg, count] */
	public double[] mannerSummary(Long teamId) {
		List<TeamRating> rs = teamRatingRepo.findByTargetTeamId(teamId);
		if (rs.isEmpty()) return new double[]{0, 0};
		double sum = rs.stream().mapToInt(TeamRating::getManner).sum();
		return new double[]{ Math.round(sum / rs.size() * 10) / 10.0, rs.size() };
	}

	/** 상세 화면 평점 컨텍스트 (평가 가능 여부 + 상대팀) */
	public Map<String, Object> ratingInfo(Long postId, Long uid) {
		Map<String, Object> info = new HashMap<>();
		info.put("canRate", false);
		MatchPost post = get(postId);
		if (post.isRecruitGuest()) return info;
		if (post.getStatus() != MatchStatus.MATCHED && post.getStatus() != MatchStatus.CLOSED) return info;
		MatchApplication accepted = appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
				.filter(a -> a.getStatus() == ApplicationStatus.ACCEPTED).findFirst().orElse(null);
		if (accepted == null) return info;
		Long hostTeam = post.getHostTeamId();
		Long oppTeam = accepted.getApplicantTeamId();
		Long raterTeam = null, targetTeam = null;
		if (teamService.isLeader(hostTeam, uid)) { raterTeam = hostTeam; targetTeam = oppTeam; }
		else if (teamService.isLeader(oppTeam, uid)) { raterTeam = oppTeam; targetTeam = hostTeam; }
		if (raterTeam != null) {
			boolean rated = teamRatingRepo.existsByMatchPostIdAndRaterTeamIdAndTargetTeamId(postId, raterTeam, targetTeam);
			info.put("canRate", !rated);
			info.put("alreadyRated", rated);
			info.put("targetTeamId", targetTeam);
			info.put("targetTeamName", teamService.get(targetTeam).getName());
		}
		return info;
	}

	@Transactional
	public void close(Long postId, Long userId) {
		MatchPost p = get(postId);
		if (p.isRecruitGuest()) requireGuestHost(p, userId);
		else teamService.requireLeader(p.getHostTeamId(), userId);
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

		// 성사 → 양 팀 일정에 자동 등록 (달력 표시 + 출석 등 일반 일정과 동일). 날짜·시간 있을 때만.
		if (post.getMatchDate() != null && post.getStartTime() != null) {
			Team host = teamService.get(post.getHostTeamId());
			Team opp = teamService.get(app.getApplicantTeamId());
			scheduleService.createDirect(post.getHostTeamId(), userId, "⚔️ vs " + opp.getName(),
					post.getMatchDate(), post.getStartTime(), post.getPlaceName(), post.getLat(), post.getLng(), post.getHeadcount(),
					post.getId(), opp.getId());
			scheduleService.createDirect(app.getApplicantTeamId(), app.getApplicantUserId(), "⚔️ vs " + host.getName(),
					post.getMatchDate(), post.getStartTime(), post.getPlaceName(), post.getLat(), post.getLng(), post.getHeadcount(),
					post.getId(), host.getId());
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
