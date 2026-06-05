package com.jacob.matchon.service;

import com.jacob.matchon.model.Role;
import com.jacob.matchon.model.Team;
import com.jacob.matchon.model.TeamMember;
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
			throw new ApiException(400, "팀장은 탈퇴할 수 없습니다. 운영진/회원만 탈퇴 가능합니다.");
		}
		memberRepo.delete(m);
	}

	// --- 생성/가입 ---

	@Transactional
	public Team create(Long ownerId, String name, String description) {
		if (name == null || name.isBlank()) {
			throw new ApiException(400, "팀명을 입력해주세요.");
		}
		Team team = Team.builder()
				.name(name.trim())
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
