package com.jacob.matchon.service;

import com.jacob.matchon.model.DuesPayment;
import com.jacob.matchon.model.Role;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.repo.DuesPaymentRepository;
import com.jacob.matchon.repo.TeamMemberRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/** 월별 회비 납부 관리 — 총무(또는 팀장)만 접근. */
@Service
@RequiredArgsConstructor
public class DuesService {

	private final DuesPaymentRepository duesRepo;
	private final TeamMemberRepository memberRepo;

	private static final Pattern PERIOD = Pattern.compile("^\\d{4}-(0[1-9]|1[0-2])$");

	/** 총무 또는 팀장만 통과 */
	public TeamMember requireTreasurer(Long teamId, Long userId) {
		TeamMember m = memberRepo.findByTeamIdAndUserId(teamId, userId)
				.orElseThrow(() -> new ApiException(403, "팀 멤버가 아닙니다."));
		if (!m.isTreasurer() && m.getRole() != Role.LEADER) {
			throw new ApiException(403, "총무만 접근할 수 있습니다.");
		}
		return m;
	}

	/** 해당 월에 납부 완료한 회원 id 집합 */
	public Set<Long> paidUserIds(Long teamId, String period) {
		validatePeriod(period);
		return duesRepo.findByTeamIdAndPeriod(teamId, period).stream()
				.map(DuesPayment::getUserId).collect(Collectors.toSet());
	}

	/** 납부 체크 토글 (총무/팀장) */
	@Transactional
	public boolean setPaid(Long teamId, Long actorId, Long targetUserId, String period, boolean paid) {
		requireTreasurer(teamId, actorId);
		validatePeriod(period);
		if (!memberRepo.existsByTeamIdAndUserId(teamId, targetUserId)) {
			throw new ApiException(404, "팀 멤버가 아닙니다.");
		}
		var existing = duesRepo.findByTeamIdAndUserIdAndPeriod(teamId, targetUserId, period);
		if (paid) {
			if (existing.isEmpty()) {
				duesRepo.save(DuesPayment.builder()
						.teamId(teamId).userId(targetUserId).period(period).markedBy(actorId).build());
			}
		} else {
			existing.ifPresent(duesRepo::delete);
		}
		return paid;
	}

	private void validatePeriod(String period) {
		if (period == null || !PERIOD.matcher(period).matches()) {
			throw new ApiException(400, "올바른 월(YYYY-MM)이 아닙니다.");
		}
	}
}
