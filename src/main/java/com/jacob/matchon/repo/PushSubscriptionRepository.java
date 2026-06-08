package com.jacob.matchon.repo;

import com.jacob.matchon.model.PushSubscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PushSubscriptionRepository extends JpaRepository<PushSubscription, Long> {
	List<PushSubscription> findByUserId(Long userId);
	List<PushSubscription> findByUserIdIn(List<Long> userIds);
	Optional<PushSubscription> findByEndpoint(String endpoint);
	void deleteByEndpoint(String endpoint);
}
