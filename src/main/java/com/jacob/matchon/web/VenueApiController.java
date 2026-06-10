package com.jacob.matchon.web;

import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.VenueService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 팀 즐겨찾기 구장 REST API. */
@RestController
@RequestMapping("/api/team/{teamId}/venues")
@RequiredArgsConstructor
public class VenueApiController {

	private final VenueService venueService;

	@GetMapping
	public Map<String, Object> list(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		return Map.of("ok", true, "venues", venueService.list(teamId, uid));
	}

	@PostMapping
	public Map<String, Object> create(@PathVariable Long teamId, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		venueService.create(teamId, uid,
				String.valueOf(body.getOrDefault("name", "")),
				body.get("address") == null ? null : String.valueOf(body.get("address")),
				body.get("lat") == null ? null : Double.valueOf(String.valueOf(body.get("lat"))),
				body.get("lng") == null ? null : Double.valueOf(String.valueOf(body.get("lng"))),
				body.get("memo") == null ? null : String.valueOf(body.get("memo")));
		return Map.of("ok", true);
	}

	@DeleteMapping("/{venueId}")
	public Map<String, Object> delete(@PathVariable Long teamId, @PathVariable Long venueId) {
		Long uid = CurrentUser.required();
		venueService.delete(venueId, uid);
		return Map.of("ok", true);
	}
}
