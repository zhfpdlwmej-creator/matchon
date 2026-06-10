package com.jacob.matchon.service;

import com.jacob.matchon.model.Position;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.UserRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

	private final UserRepository userRepo;

	public Optional<User> findByKakaoId(String kakaoId) {
		return userRepo.findByKakaoId(kakaoId);
	}

	public Optional<User> findById(Long id) {
		return userRepo.findById(id);
	}

	public User get(Long id) {
		return userRepo.findById(id)
				.orElseThrow(() -> new ApiException(404, "사용자를 찾을 수 없습니다."));
	}

	@Transactional
	public User createFromKakao(String kakaoId, String nickname) {
		// 별도 닉네임 설정 단계 없이 카카오 닉네임을 바로 사용 (setupDone=true)
		User u = User.builder()
				.kakaoId(kakaoId)
				.nickname(nickname == null || nickname.isBlank() ? "축구인" : nickname)
				.setupDone(true)
				.build();
		return userRepo.save(u);
	}

	/** 최초 로그인 시 닉네임/포지션 설정 완료 */
	@Transactional
	public User completeSetup(Long userId, String nickname, Position position) {
		User u = get(userId);
		if (nickname != null && !nickname.isBlank()) {
			u.setNickname(nickname.length() > 20 ? nickname.substring(0, 20) : nickname.trim());
		}
		u.setPosition(position);
		u.setSetupDone(true);
		return u;
	}

	/** 로그인 때마다 카카오 이름으로 동기화 (실명 고정) */
	/** 실력 자기등급 설정 (BEG/NOV/INT/ADV, 빈값=해제) */
	@Transactional
	public void setSkillLevel(Long userId, String level) {
		User u = get(userId);
		if (level == null || level.isBlank()) { u.setSkillLevel(null); return; }
		String v = level.trim().toUpperCase();
		if (!java.util.List.of("BEG", "NOV", "INT", "ADV").contains(v)) {
			throw new com.jacob.matchon.web.ApiException(400, "올바른 레벨이 아닙니다.");
		}
		u.setSkillLevel(v);
	}

	@Transactional
	public void syncName(Long userId, String kakaoName) {
		if (kakaoName == null || kakaoName.isBlank()) return;
		User u = get(userId);
		String n = kakaoName.trim();
		if (n.length() > 20) n = n.substring(0, 20);
		if (!n.equals(u.getNickname())) {
			u.setNickname(n);
		}
	}

	@Transactional
	public User updateProfile(Long userId, String nickname, Position position) {
		User u = get(userId);
		if (nickname != null && !nickname.isBlank()) {
			u.setNickname(nickname.trim());
		}
		if (position != null) {
			u.setPosition(position);
		}
		return u;
	}

	/** 연락처 휴대폰 번호 설정 (숫자만 보관, 빈값=해제) */
	@Transactional
	public void setPhone(Long userId, String phone) {
		User u = get(userId);
		if (phone == null || phone.isBlank()) { u.setPhone(null); return; }
		String digits = phone.replaceAll("[^0-9]", "");
		if (digits.length() < 9 || digits.length() > 11) {
			throw new ApiException(400, "올바른 휴대폰 번호가 아닙니다.");
		}
		u.setPhone(digits);
	}

	/** id 목록 → id별 User 맵 (목록 화면 조인용) */
	public Map<Long, User> mapByIds(List<Long> ids) {
		if (ids == null || ids.isEmpty()) return Map.of();
		return userRepo.findByIdIn(ids).stream()
				.collect(Collectors.toMap(User::getId, u -> u));
	}
}
