package com.jacob.matchon.service;

import com.jacob.matchon.model.MatchApplication;
import com.jacob.matchon.model.MatchComment;
import com.jacob.matchon.model.MatchPost;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.MatchApplicationRepository;
import com.jacob.matchon.repo.MatchCommentRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 매칭 신청 댓글(소통).
 * - 모집팀(호스트): 모든 신청팀 스레드 열람/답글
 * - 신청팀: 본인 스레드만 열람/작성
 */
@Service
@RequiredArgsConstructor
public class MatchCommentService {

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM-dd HH:mm");

	private final MatchCommentRepository commentRepo;
	private final MatchApplicationRepository appRepo;
	private final MatchService matchService;
	private final TeamService teamService;
	private final UserService userService;

	/** 현재 팀 기준 가시 스레드 조회 */
	public Map<String, Object> list(Long postId, Long uid, Long currentTeamId) {
		MatchPost post = matchService.get(postId);
		boolean isHost = isHostSide(post, uid, currentTeamId);
		Long myAppTeam = isHost ? null : applicantTeam(post, uid, currentTeamId);

		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		if (!isHost && myAppTeam == null) { res.put("side", "none"); res.put("threads", List.of()); return res; }
		res.put("side", isHost ? "host" : "applicant");

		// 스레드 대상 신청팀 목록
		List<Long> teamIds = isHost
				? appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
						.map(MatchApplication::getApplicantTeamId).distinct().toList()
				: List.of(myAppTeam);

		List<MatchComment> all = isHost
				? commentRepo.findByMatchPostIdOrderByIdAsc(postId)
				: commentRepo.findByMatchPostIdAndApplicantTeamIdOrderByIdAsc(postId, myAppTeam);
		Map<Long, User> users = userService.mapByIds(all.stream().map(MatchComment::getAuthorUserId).toList());

		List<Map<String, Object>> threads = new ArrayList<>();
		for (Long t : teamIds) {
			Map<String, Object> th = new HashMap<>();
			th.put("applicantTeamId", t);
			th.put("teamName", teamService.get(t).getName());
			List<Map<String, Object>> rows = new ArrayList<>();
			for (MatchComment c : all) {
				if (!c.getApplicantTeamId().equals(t)) continue;
				Map<String, Object> m = new HashMap<>();
				User u = users.get(c.getAuthorUserId());
				m.put("id", c.getId());
				m.put("name", u == null ? "?" : u.getNickname());
				m.put("isHost", c.isHost());
				m.put("parentId", c.getParentId());
				m.put("content", c.getContent());
				m.put("createdAt", c.getCreatedAt() == null ? "" : c.getCreatedAt().format(FMT));
				m.put("mine", uid.equals(c.getAuthorUserId()));
				rows.add(m);
			}
			th.put("comments", rows);
			threads.add(th);
		}
		res.put("threads", threads);
		return res;
	}

	/** 댓글/대댓글 작성 */
	@Transactional
	public void add(Long postId, Long uid, Long currentTeamId, Long applicantTeamId, Long parentId, String content) {
		if (content == null || content.isBlank()) throw new ApiException(400, "내용을 입력해주세요.");
		MatchPost post = matchService.get(postId);
		boolean isHost = isHostSide(post, uid, currentTeamId);
		Long threadTeam;
		if (isHost) {
			threadTeam = applicantTeamId;
			if (threadTeam == null || !appRepo.existsByMatchPostIdAndApplicantTeamId(postId, threadTeam)) {
				throw new ApiException(400, "대상 신청팀이 올바르지 않습니다.");
			}
		} else {
			threadTeam = applicantTeam(post, uid, currentTeamId);
			if (threadTeam == null) throw new ApiException(403, "이 매칭에 신청한 팀만 메시지를 남길 수 있습니다.");
		}
		// 대댓글이면 같은 스레드의 부모인지 확인
		if (parentId != null) {
			MatchComment parent = commentRepo.findById(parentId).orElse(null);
			if (parent == null || !parent.getMatchPostId().equals(postId) || !parent.getApplicantTeamId().equals(threadTeam)) {
				throw new ApiException(400, "잘못된 답글 대상입니다.");
			}
		}
		commentRepo.save(MatchComment.builder()
				.matchPostId(postId)
				.applicantTeamId(threadTeam)
				.authorUserId(uid)
				.authorTeamId(currentTeamId)
				.host(isHost)
				.parentId(parentId)
				.content(content.trim().length() > 500 ? content.trim().substring(0, 500) : content.trim())
				.build());
	}

	/** 삭제 (작성자 또는 모집팀) */
	@Transactional
	public void delete(Long commentId, Long uid, Long currentTeamId) {
		MatchComment c = commentRepo.findById(commentId)
				.orElseThrow(() -> new ApiException(404, "댓글을 찾을 수 없습니다."));
		MatchPost post = matchService.get(c.getMatchPostId());
		boolean isHost = isHostSide(post, uid, currentTeamId);
		if (!c.getAuthorUserId().equals(uid) && !isHost) {
			throw new ApiException(403, "삭제 권한이 없습니다.");
		}
		commentRepo.delete(c);
	}

	private boolean isHostSide(MatchPost post, Long uid, Long currentTeamId) {
		return currentTeamId != null && currentTeamId.equals(post.getHostTeamId())
				&& teamService.isMember(post.getHostTeamId(), uid);
	}

	private Long applicantTeam(MatchPost post, Long uid, Long currentTeamId) {
		if (currentTeamId == null || !teamService.isMember(currentTeamId, uid)) return null;
		return appRepo.existsByMatchPostIdAndApplicantTeamId(post.getId(), currentTeamId) ? currentTeamId : null;
	}
}
