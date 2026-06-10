package com.jacob.matchon.web;

import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.TeamPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 팀 게시판 REST API. */
@RestController
@RequestMapping("/api/team/{teamId}/board")
@RequiredArgsConstructor
public class TeamPostApiController {

	private final TeamPostService boardService;

	@GetMapping
	public Map<String, Object> list(@PathVariable Long teamId) {
		Long uid = CurrentUser.required();
		return Map.of("ok", true, "posts", boardService.list(teamId, uid));
	}

	@PostMapping
	public Map<String, Object> create(@PathVariable Long teamId, @RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		boolean notice = Boolean.parseBoolean(String.valueOf(body.getOrDefault("notice", "false")));
		boardService.create(teamId, uid, notice,
				String.valueOf(body.getOrDefault("title", "")),
				body.get("content") == null ? null : String.valueOf(body.get("content")));
		return Map.of("ok", true);
	}

	@DeleteMapping("/{postId}")
	public Map<String, Object> delete(@PathVariable Long teamId, @PathVariable Long postId) {
		Long uid = CurrentUser.required();
		boardService.delete(postId, uid);
		return Map.of("ok", true);
	}
}
