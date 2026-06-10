package com.jacob.matchon.service;

import com.jacob.matchon.model.ApplicationStatus;
import com.jacob.matchon.model.JoinRequest;
import com.jacob.matchon.model.MembershipType;
import com.jacob.matchon.model.Role;
import com.jacob.matchon.model.Sport;
import com.jacob.matchon.model.Team;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.repo.JoinRequestRepository;
import com.jacob.matchon.repo.TeamMemberRepository;
import com.jacob.matchon.repo.TeamRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TeamService {

	private final TeamRepository teamRepo;
	private final TeamMemberRepository memberRepo;
	private final JoinRequestRepository joinRepo;

	private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 헷갈리는 0/O/1/I 제외
	private final SecureRandom random = new SecureRandom();

	// --- 조회 ---

	public Team get(Long teamId) {
		return teamRepo.findById(teamId)
				.orElseThrow(() -> new ApiException(404, "팀을 찾을 수 없습니다."));
	}

	/** 내가 속한 팀 목록 */
	public List<Team> myTeams(Long userId) {
		List<Long> teamIds = memberRepo.findByUserId(userId).stream()
				.map(TeamMember::getTeamId).toList();
		if (teamIds.isEmpty()) return List.of();
		return teamRepo.findAllById(teamIds);
	}

	/** 내가 팀장/운영진인 팀 목록 (매칭 등록·신청용) */
	public List<Team> manageableTeams(Long userId) {
		List<Long> teamIds = memberRepo.findByUserId(userId).stream()
				.filter(m -> m.getRole().canManage())
				.map(TeamMember::getTeamId).toList();
		if (teamIds.isEmpty()) return List.of();
		return teamRepo.findAllById(teamIds);
	}

	public List<TeamMember> members(Long teamId) {
		return memberRepo.findByTeamId(teamId);
	}

	/** 초대코드로 팀 조회 (가입 여부 무관) */
	public java.util.Optional<Team> findByInviteCode(String code) {
		if (code == null || code.isBlank()) return java.util.Optional.empty();
		return teamRepo.findByInviteCode(code.trim().toUpperCase());
	}

	public boolean isMember(Long teamId, Long userId) {
		return memberRepo.existsByTeamIdAndUserId(teamId, userId);
	}

	public boolean isLeader(Long teamId, Long userId) {
		return memberRepo.findByTeamIdAndUserId(teamId, userId)
				.map(m -> m.getRole() == Role.LEADER).orElse(false);
	}

	public TeamMember membership(Long teamId, Long userId) {
		return memberRepo.findByTeamIdAndUserId(teamId, userId)
				.orElseThrow(() -> new ApiException(403, "팀 멤버가 아닙니다."));
	}

	/** 권한 검사 — 팀장/운영진만 통과 */
	public TeamMember requireManager(Long teamId, Long userId) {
		TeamMember m = membership(teamId, userId);
		if (!m.getRole().canManage()) {
			throw new ApiException(403, "팀장 또는 운영진만 가능합니다.");
		}
		return m;
	}

	/** 권한 검사 — 팀장(팀 생성자)만 통과 */
	public TeamMember requireLeader(Long teamId, Long userId) {
		TeamMember m = membership(teamId, userId);
		if (m.getRole() != Role.LEADER) {
			throw new ApiException(403, "팀장만 가능합니다.");
		}
		return m;
	}

	/** 내가 팀장인 팀 목록 (매칭 등록/신청용) */
	public List<Team> leaderTeams(Long userId) {
		List<Long> teamIds = memberRepo.findByUserId(userId).stream()
				.filter(m -> m.getRole() == Role.LEADER)
				.map(TeamMember::getTeamId).toList();
		if (teamIds.isEmpty()) return List.of();
		return teamRepo.findAllById(teamIds);
	}

	/** 팀 탈퇴 — 팀장은 탈퇴 불가(운영진/회원만) */
	@Transactional
	public void leaveTeam(Long teamId, Long userId) {
		TeamMember m = membership(teamId, userId);
		if (m.getRole() == Role.LEADER) {
			throw new ApiException(400, "팀장은 탈퇴할 수 없습니다. 팀을 해체하거나 운영진/회원만 탈퇴 가능합니다.");
		}
		memberRepo.delete(m);
	}

	/** 팀 프로필/설정 수정 (팀장/운영진) */
	@Transactional
	public Team updateSettings(Long teamId, Long userId, String name, String description,
							   String ageGroup, String level, String region, Integer minAttendees) {
		requireManager(teamId, userId);
		Team t = get(teamId);
		if (name != null && !name.isBlank()) t.setName(name.trim().length() > 40 ? name.trim().substring(0, 40) : name.trim());
		t.setDescription(description == null || description.isBlank() ? null : description.trim());
		t.setAgeGroup(blankUpper(ageGroup));
		t.setLevel(blankUpper(level));
		t.setRegion(region == null || region.isBlank() ? null : region.trim());
		if (minAttendees != null) t.setMinAttendees(Math.max(0, minAttendees));
		return t;
	}

	private String blankUpper(String s) { return (s == null || s.isBlank()) ? null : s.trim().toUpperCase(); }

	/** 팀 해체 (팀장만) — 팀원·일정·매칭 등 관련 데이터 전부 삭제(FK CASCADE) */
	@Transactional
	public void disband(Long teamId, Long userId) {
		requireLeader(teamId, userId);
		teamRepo.deleteById(teamId);
	}

	// --- 생성/가입 ---

	@Transactional
	public Team create(Long ownerId, String name, String description, Sport sport) {
		if (name == null || name.isBlank()) {
			throw new ApiException(400, "팀명을 입력해주세요.");
		}
		Team team = Team.builder()
				.name(name.trim())
				.sport(sport == null ? Sport.SOCCER : sport)
				.description(description)
				.inviteCode(generateUniqueCode())
				.ownerId(ownerId)
				.minAttendees(0)
				.build();
		team = teamRepo.save(team);
		// 생성자는 팀장
		memberRepo.save(TeamMember.builder()
				.teamId(team.getId())
				.userId(ownerId)
				.role(Role.LEADER)
				.build());
		return team;
	}

	@Transactional
	public Team joinByCode(Long userId, String inviteCode) {
		Team team = teamRepo.findByInviteCode(inviteCode == null ? "" : inviteCode.trim().toUpperCase())
				.orElseThrow(() -> new ApiException(404, "초대코드가 올바르지 않습니다."));
		if (memberRepo.existsByTeamIdAndUserId(team.getId(), userId)) {
			throw new ApiException(409, "이미 가입한 팀입니다.");
		}
		memberRepo.save(TeamMember.builder()
				.teamId(team.getId())
				.userId(userId)
				.role(Role.MEMBER)
				.build());
		return team;
	}

	/** 초대코드로 가입 신청 (팀장 승인 대기) */
	@Transactional
	public Team requestJoin(Long userId, String inviteCode) {
		Team team = teamRepo.findByInviteCode(inviteCode == null ? "" : inviteCode.trim().toUpperCase())
				.orElseThrow(() -> new ApiException(404, "초대코드가 올바르지 않습니다."));
		if (memberRepo.existsByTeamIdAndUserId(team.getId(), userId)) {
			throw new ApiException(409, "이미 가입한 팀입니다.");
		}
		JoinRequest existing = joinRepo.findByTeamIdAndUserId(team.getId(), userId).orElse(null);
		if (existing != null) {
			if (existing.getStatus() == ApplicationStatus.PENDING) {
				throw new ApiException(409, "이미 가입 신청했습니다. 팀장 승인을 기다려주세요.");
			}
			existing.setStatus(ApplicationStatus.PENDING); // 거절 후 재신청
		} else {
			joinRepo.save(JoinRequest.builder()
					.teamId(team.getId()).userId(userId).status(ApplicationStatus.PENDING).build());
		}
		return team;
	}

	/** 가입 신청 승인 (팀장/운영진) → 팀원 추가 */
	@Transactional
	public void approveRequest(Long requestId, Long approverId) {
		JoinRequest jr = joinRepo.findById(requestId)
				.orElseThrow(() -> new ApiException(404, "가입 신청을 찾을 수 없습니다."));
		requireManager(jr.getTeamId(), approverId);
		if (!memberRepo.existsByTeamIdAndUserId(jr.getTeamId(), jr.getUserId())) {
			memberRepo.save(TeamMember.builder()
					.teamId(jr.getTeamId()).userId(jr.getUserId()).role(Role.MEMBER).build());
		}
		joinRepo.delete(jr);
	}

	/** 가입 신청 거절 (팀장/운영진) */
	@Transactional
	public void rejectRequest(Long requestId, Long approverId) {
		JoinRequest jr = joinRepo.findById(requestId)
				.orElseThrow(() -> new ApiException(404, "가입 신청을 찾을 수 없습니다."));
		requireManager(jr.getTeamId(), approverId);
		joinRepo.delete(jr);
	}

	public List<JoinRequest> pendingRequests(Long teamId) {
		return joinRepo.findByTeamIdAndStatusOrderByCreatedAtAsc(teamId, ApplicationStatus.PENDING);
	}

	public long pendingCount(Long teamId) {
		return joinRepo.countByTeamIdAndStatus(teamId, ApplicationStatus.PENDING);
	}

	public List<JoinRequest> myPendingRequests(Long userId) {
		return joinRepo.findByUserIdAndStatusOrderByCreatedAtDesc(userId, ApplicationStatus.PENDING);
	}

	/** 초대코드 재발급 (팀장/운영진) */
	@Transactional
	public String regenerateCode(Long teamId, Long userId) {
		requireManager(teamId, userId);
		Team team = get(teamId);
		team.setInviteCode(generateUniqueCode());
		return team.getInviteCode();
	}

	/** 권한 변경 (팀장만) */
	@Transactional
	public void changeRole(Long teamId, Long actorId, Long targetUserId, Role role) {
		TeamMember actor = membership(teamId, actorId);
		if (actor.getRole() != Role.LEADER) {
			throw new ApiException(403, "팀장만 권한을 변경할 수 있습니다.");
		}
		TeamMember target = membership(teamId, targetUserId);
		target.setRole(role);
	}

	/** 회원 유형 변경 — 회비회원/참가회원 (팀장/운영진) */
	@Transactional
	public void changeMembership(Long teamId, Long actorId, Long targetUserId, MembershipType type) {
		requireManager(teamId, actorId);
		TeamMember target = membership(teamId, targetUserId);
		target.setMembershipType(type);
	}

	/**
	 * 멤버 강퇴 (팀장/운영진).
	 * - 팀장은 강퇴 불가, 본인은 강퇴 불가(탈퇴 사용)
	 * - 운영진은 다른 운영진을 강퇴할 수 없음(팀장만 가능)
	 */
	@Transactional
	public void kickMember(Long teamId, Long actorId, Long targetUserId) {
		TeamMember actor = requireManager(teamId, actorId);
		if (actorId.equals(targetUserId)) {
			throw new ApiException(400, "본인은 강퇴할 수 없습니다. 탈퇴를 이용해주세요.");
		}
		TeamMember target = membership(teamId, targetUserId);
		if (target.getRole() == Role.LEADER) {
			throw new ApiException(400, "팀장은 강퇴할 수 없습니다.");
		}
		if (target.getRole() == Role.MANAGER && actor.getRole() != Role.LEADER) {
			throw new ApiException(403, "운영진 강퇴는 팀장만 가능합니다.");
		}
		// 대기 중인 재가입 신청도 함께 정리
		joinRepo.findByTeamIdAndUserId(teamId, targetUserId).ifPresent(joinRepo::delete);
		memberRepo.delete(target);
	}

	/** 인원부족 알림 기준 설정 (팀장/운영진) */
	@Transactional
	public void setMinAttendees(Long teamId, Long userId, int min) {
		requireManager(teamId, userId);
		get(teamId).setMinAttendees(Math.max(0, min));
	}

	private String generateUniqueCode() {
		for (int attempt = 0; attempt < 20; attempt++) {
			StringBuilder sb = new StringBuilder(6);
			for (int i = 0; i < 6; i++) {
				sb.append(CODE_CHARS.charAt(random.nextInt(CODE_CHARS.length())));
			}
			String code = sb.toString();
			if (!teamRepo.existsByInviteCode(code)) {
				return code;
			}
		}
		throw new ApiException(500, "초대코드 생성에 실패했습니다.");
	}
}
