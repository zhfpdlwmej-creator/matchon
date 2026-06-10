package com.jacob.matchon.service;

import com.jacob.matchon.model.TeamPost;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.TeamPostRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.*;

/** 팀 게시판. */
@Service
@RequiredArgsConstructor
public class TeamPostService {

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM-dd HH:mm");

	private final TeamPostRepository postRepo;
	private final TeamService teamService;
	private final UserService userService;

	public List<Map<String, Object>> list(Long teamId, Long uid) {
		teamService.membership(teamId, uid);
		List<TeamPost> posts = postRepo.findByTeamIdOrderByNoticeDescIdDesc(teamId);
		Map<Long, User> users = userService.mapByIds(posts.stream().map(TeamPost::getAuthorUserId).toList());
		return posts.stream().map(p -> {
			Map<String, Object> m = new HashMap<>();
			User u = users.get(p.getAuthorUserId());
			m.put("id", p.getId());
			m.put("notice", p.isNotice());
			m.put("title", p.getTitle());
			m.put("content", p.getContent() == null ? "" : p.getContent());
			m.put("author", u == null ? "?" : u.getNickname());
			m.put("createdAt", p.getCreatedAt() == null ? "" : p.getCreatedAt().format(FMT));
			m.put("mine", uid.equals(p.getAuthorUserId()));
			return m;
		}).toList();
	}

	@Transactional
	public void create(Long teamId, Long uid, boolean notice, String title, String content) {
		teamService.membership(teamId, uid);
		if (notice) teamService.requireManager(teamId, uid);   // 공지는 팀장/운영진만
		if (title == null || title.isBlank()) throw new ApiException(400, "제목을 입력해주세요.");
		postRepo.save(TeamPost.builder()
				.teamId(teamId).authorUserId(uid).notice(notice)
				.title(title.trim().length() > 120 ? title.trim().substring(0, 120) : title.trim())
				.content(content == null || content.isBlank() ? null : content.trim())
				.build());
	}

	@Transactional
	public void delete(Long postId, Long uid) {
		TeamPost p = postRepo.findById(postId)
				.orElseThrow(() -> new ApiException(404, "글을 찾을 수 없습니다."));
		boolean manager = teamService.membership(p.getTeamId(), uid).getRole().canManage();
		if (!p.getAuthorUserId().equals(uid) && !manager) throw new ApiException(403, "삭제 권한이 없습니다.");
		postRepo.delete(p);
	}
}
