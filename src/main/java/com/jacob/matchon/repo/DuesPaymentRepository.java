package com.jacob.matchon.repo;

import com.jacob.matchon.model.DuesPayment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DuesPaymentRepository extends JpaRepository<DuesPayment, Long> {
	List<DuesPayment> findByTeamIdAndPeriod(Long teamId, String period);
	Optional<DuesPayment> findByTeamIdAndUserIdAndPeriod(Long teamId, Long userId, String period);
	boolean existsByTeamIdAndUserIdAndPeriod(Long teamId, Long userId, String period);
}
