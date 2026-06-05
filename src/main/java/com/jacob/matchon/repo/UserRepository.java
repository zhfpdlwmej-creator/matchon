package com.jacob.matchon.repo;

import com.jacob.matchon.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
	Optional<User> findByKakaoId(String kakaoId);
	List<User> findByIdIn(List<Long> ids);
}
