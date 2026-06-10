package com.jacob.matchon.repo;

import com.jacob.matchon.model.UserRating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRatingRepository extends JpaRepository<UserRating, Long> {
	List<UserRating> findByTargetUserIdOrderByIdDesc(Long targetUserId);
	boolean existsByMatchPostIdAndRaterUserIdAndTargetUserId(Long matchPostId, Long raterUserId, Long targetUserId);
}
