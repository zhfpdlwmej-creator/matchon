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

	public User get(Long id) {
		return userRepo.findById(id)
				.orElseThrow(() -> new ApiException(404, "사용자를 찾을 수 없습니다."));
	}

	@Transactional
	public User createFromKakao(String kakaoId, String nickname) {
		User u = User.builder()
				.kakaoId(kakaoId)
				.nickname(nickname == null || nickname.isBlank() ? "축구인" : nickname)
				.setupDone(false)
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

	/** id 목록 → id별 User 맵 (목록 화면 조인용) */
	public Map<Long, User> mapByIds(List<Long> ids) {
		if (ids == null || ids.isEmpty()) return Map.of();
		return userRepo.findByIdIn(ids).stream()
				.collect(Collectors.toMap(User::getId, u -> u));
	}
}
