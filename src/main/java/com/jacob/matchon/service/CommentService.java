package com.jacob.matchon.service;

import com.jacob.matchon.model.Comment;
import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.repo.CommentRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {

	private final CommentRepository commentRepo;
	private final ScheduleService scheduleService;
	private final TeamService teamService;

	public List<Comment> list(Long scheduleId) {
		return commentRepo.findByScheduleIdOrderByCreatedAtAsc(scheduleId);
	}

	@Transactional
	public Comment add(Long scheduleId, Long userId, String content) {
		if (content == null || content.isBlank()) {
			throw new ApiException(400, "댓글 내용을 입력해주세요.");
		}
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), userId); // 멤버만
		String c = content.trim();
		if (c.length() > 300) c = c.substring(0, 300);
		return commentRepo.save(Comment.builder()
				.scheduleId(scheduleId)
				.userId(userId)
				.content(c)
				.build());
	}

	@Transactional
	public void delete(Long commentId, Long userId) {
		Comment c = commentRepo.findById(commentId)
				.orElseThrow(() -> new ApiException(404, "댓글을 찾을 수 없습니다."));
		MatchSchedule s = scheduleService.get(c.getScheduleId());
		// 작성자 본인 또는 팀장/운영진
		boolean isManager = teamService.membership(s.getTeamId(), userId).getRole().canManage();
		if (!c.getUserId().equals(userId) && !isManager) {
			throw new ApiException(403, "삭제 권한이 없습니다.");
		}
		commentRepo.delete(c);
	}
}
