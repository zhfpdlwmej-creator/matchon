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

	// ---------- 조회 ----------

	public MatchPost get(Long id) {
		return postRepo.findById(id)
				.orElseThrow(() -> new ApiException(404, "매칭을 찾을 수 없습니다."));
	}

	/** 모집중 매칭 목록 (지역 필터 옵션) */
	public List<MatchPost> listOpen(String region) {
		if (region != null && !region.isBlank()) {
			return postRepo.findByStatusAndRegionContainingOrderByCreatedAtDesc(MatchStatus.OPEN, region.trim());
		}
		return postRepo.findByStatusOrderByCreatedAtDesc(MatchStatus.OPEN);
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
				.level(level)
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
