package com.jacob.matchon.web;

import com.jacob.matchon.model.Comment;
import com.jacob.matchon.model.TeamMember;
import com.jacob.matchon.model.User;
import com.jacob.matchon.security.CurrentUser;
import com.jacob.matchon.service.CommentService;
import com.jacob.matchon.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** 일정 댓글 REST API. */
@RestController
@RequestMapping("/api/comment")
@RequiredArgsConstructor
public class CommentApiController {

	private final CommentService commentService;
	private final UserService userService;

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM-dd HH:mm");

	@GetMapping("/list")
	public Map<String, Object> list(@RequestParam Long scheduleId) {
		CurrentUser.required();
		List<Comment> comments = commentService.list(scheduleId);
		Map<Long, User> users = userService.mapByIds(comments.stream().map(Comment::getUserId).toList());
		List<Map<String, Object>> rows = comments.stream().map(c -> {
			User u = users.get(c.getUserId());
			Map<String, Object> m = new HashMap<>();
			m.put("id", c.getId());
			m.put("userId", c.getUserId());
			m.put("nickname", u == null ? "?" : u.getNickname());
			m.put("content", c.getContent());
			m.put("createdAt", c.getCreatedAt() == null ? "" : c.getCreatedAt().format(FMT));
			return m;
		}).toList();
		return Map.of("ok", true, "comments", rows);
	}

	@PostMapping
	public Map<String, Object> add(@RequestBody Map<String, String> body) {
		Long uid = CurrentUser.required();
		Long scheduleId = Long.valueOf(body.get("scheduleId"));
		Comment c = commentService.add(scheduleId, uid, body.get("content"));
		return Map.of("ok", true, "id", c.getId());
	}

	@DeleteMapping("/{id}")
	public Map<String, Object> delete(@PathVariable Long id) {
		Long uid = CurrentUser.required();
		commentService.delete(id, uid);
		return Map.of("ok", true);
	}
}
