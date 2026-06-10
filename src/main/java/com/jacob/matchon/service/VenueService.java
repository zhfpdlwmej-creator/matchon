package com.jacob.matchon.service;

import com.jacob.matchon.model.Venue;
import com.jacob.matchon.repo.VenueRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/** 팀 즐겨찾기 구장. */
@Service
@RequiredArgsConstructor
public class VenueService {

	private final VenueRepository venueRepo;
	private final TeamService teamService;

	public List<Map<String, Object>> list(Long teamId, Long uid) {
		teamService.membership(teamId, uid);
		return venueRepo.findByTeamIdOrderByIdDesc(teamId).stream().map(v -> {
			Map<String, Object> m = new HashMap<>();
			m.put("id", v.getId());
			m.put("name", v.getName());
			m.put("address", v.getAddress());
			m.put("lat", v.getLat());
			m.put("lng", v.getLng());
			m.put("memo", v.getMemo());
			return m;
		}).toList();
	}

	@Transactional
	public void create(Long teamId, Long uid, String name, String address, Double lat, Double lng, String memo) {
		teamService.requireManager(teamId, uid);
		if (name == null || name.isBlank()) throw new ApiException(400, "구장 이름을 입력해주세요.");
		venueRepo.save(Venue.builder()
				.teamId(teamId).name(name.trim()).address(address)
				.lat(lat).lng(lng)
				.memo(memo == null || memo.isBlank() ? null : memo.trim())
				.build());
	}

	@Transactional
	public void delete(Long venueId, Long uid) {
		Venue v = venueRepo.findById(venueId)
				.orElseThrow(() -> new ApiException(404, "구장을 찾을 수 없습니다."));
		teamService.requireManager(v.getTeamId(), uid);
		venueRepo.delete(v);
	}
}
