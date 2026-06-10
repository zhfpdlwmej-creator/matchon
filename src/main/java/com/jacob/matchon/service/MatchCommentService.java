package com.jacob.matchon.service;

import com.jacob.matchon.model.ApplicationStatus;
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
import java.util.stream.Collectors;

/**
 * 매칭/용병 신청 댓글(소통).
 * - 팀 매칭: 신청팀별 스레드. 모집팀=전체, 신청팀=본인 스레드.
 * - 용병 모집: 신청 '개인'별 스레드. 모집팀=전체, 신청 개인=본인 스레드. (댓글 작성=지원)
 * - 다른 신청자는 서로의 스레드를 볼 수 없음.
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

	/** 가시 스레드 조회 */
	public Map<String, Object> list(Long postId, Long uid, Long currentTeamId) {
		MatchPost post = matchService.get(postId);
		return post.isRecruitGuest() ? listGuest(post, uid) : listTeam(post, uid, currentTeamId);
	}

	// ---------- 용병 모집(개인 스레드) ----------

	private Map<String, Object> listGuest(MatchPost post, Long uid) {
		Long postId = post.getId();
		boolean isHost = teamService.isMember(post.getHostTeamId(), uid);
		boolean canManage = isHost && teamService.membership(post.getHostTeamId(), uid).getRole().canManage();
		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("guestRecruit", true);
		res.put("side", isHost ? "host" : "applicant");
		res.put("canManage", canManage);

		// 지원 개인 → 지원서 매핑
		Map<Long, MatchApplication> appByUser = appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
				.filter(a -> a.getApplicantUserId() != null)
				.collect(Collectors.toMap(MatchApplication::getApplicantUserId, a -> a, (a, b) -> a, LinkedHashMap::new));

		List<Long> userIds = isHost ? new ArrayList<>(appByUser.keySet()) : List.of(uid);
		List<MatchComment> all = isHost
				? commentRepo.findByMatchPostIdOrderByIdAsc(postId)
				: commentRepo.findByMatchPostIdAndApplicantUserIdOrderByIdAsc(postId, uid);
		Map<Long, User> users = userService.mapByIds(
				new HashSet<>(concat(userIds, all.stream().map(MatchComment::getAuthorUserId).toList())).stream().toList());

		List<Map<String, Object>> threads = new ArrayList<>();
		for (Long u : userIds) {
			Map<String, Object> th = new HashMap<>();
			th.put("applicantUserId", u);
			th.put("name", nameOf(users, u));
			MatchApplication app = appByUser.get(u);
			th.put("applicationId", app == null ? null : app.getId());
			th.put("accepted", app != null && app.getStatus() == ApplicationStatus.ACCEPTED);
			double[] mn = matchService.userMannerSummary(u);
			th.put("mannerAvg", mn[1] > 0 ? mn[0] : null);
			th.put("mannerCount", (int) mn[1]);
			if (canManage) th.put("ratedByMe", matchService.ratedGuest(postId, uid, u));
			th.put("comments", rows(all.stream().filter(c -> u.equals(c.getApplicantUserId())).toList(), users, uid));
			threads.add(th);
		}
		res.put("threads", threads);
		return res;
	}

	// ---------- 팀 매칭(팀 스레드) ----------

	private Map<String, Object> listTeam(MatchPost post, Long uid, Long currentTeamId) {
		Long postId = post.getId();
		boolean isHost = isHostTeamSide(post, uid, currentTeamId);
		Long myAppTeam = isHost ? null : applicantTeam(post, uid, currentTeamId);

		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("guestRecruit", false);
		if (!isHost && myAppTeam == null) { res.put("side", "none"); res.put("threads", List.of()); return res; }
		res.put("side", isHost ? "host" : "applicant");

		List<Long> teamIds = isHost
				? appRepo.findByMatchPostIdOrderByCreatedAtAsc(postId).stream()
						.map(MatchApplication::getApplicantTeamId).filter(Objects::nonNull).distinct().toList()
				: List.of(myAppTeam);
		List<MatchComment> all = isHost
				? commentRepo.findByMatchPostIdOrderByIdAsc(postId)
				: commentRepo.findByMatchPostIdAndApplicantTeamIdOrderByIdAsc(postId, myAppTeam);
		Map<Long, User> users = userService.mapByIds(all.stream().map(MatchComment::getAuthorUserId).toList());

		List<Map<String, Object>> threads = new ArrayList<>();
		for (Long t : teamIds) {
			Map<String, Object> th = new HashMap<>();
			th.put("applicantTeamId", t);
			th.put("name", teamService.get(t).getName());
			th.put("comments", rows(all.stream().filter(c -> t.equals(c.getApplicantTeamId())).toList(), users, uid));
			threads.add(th);
		}
		res.put("threads", threads);
		return res;
	}

	/** 댓글/대댓글 작성 */
	@Transactional
	public void add(Long postId, Long uid, Long currentTeamId, Long applicantTeamId, Long applicantUserId,
					Long parentId, String content) {
		if (content == null || content.isBlank()) throw new ApiException(400, "내용을 입력해주세요.");
		String body = content.trim();
		if (body.length() > 500) body = body.substring(0, 500);
		MatchPost post = matchService.get(postId);

		Long threadTeam = null, threadUser = null;
		boolean isHost;
		if (post.isRecruitGuest()) {
			isHost = teamService.isMember(post.getHostTeamId(), uid);
			if (isHost) {
				threadUser = applicantUserId;
				if (threadUser == null || !appRepo.existsByMatchPostIdAndApplicantUserId(postId, threadUser)) {
					throw new ApiException(400, "대상 지원자가 올바르지 않습니다.");
				}
			} else {
				threadUser = uid;
				matchService.ensureGuestApplication(uid, postId, body);   // 댓글 작성 = 지원
			}
		} else {
			isHost = isHostTeamSide(post, uid, currentTeamId);
			if (isHost) {
				threadTeam = applicantTeamId;
				if (threadTeam == null || !appRepo.existsByMatchPostIdAndApplicantTeamId(postId, threadTeam)) {
					throw new ApiException(400, "대상 신청팀이 올바르지 않습니다.");
				}
			} else {
				threadTeam = applicantTeam(post, uid, currentTeamId);
				if (threadTeam == null) throw new ApiException(403, "이 매칭에 신청한 팀만 메시지를 남길 수 있습니다.");
			}
		}

		if (parentId != null) {
			MatchComment parent = commentRepo.findById(parentId).orElse(null);
			boolean sameThread = parent != null && parent.getMatchPostId().equals(postId)
					&& (threadTeam != null ? threadTeam.equals(parent.getApplicantTeamId())
											: threadUser.equals(parent.getApplicantUserId()));
			if (!sameThread) throw new ApiException(400, "잘못된 답글 대상입니다.");
		}

		commentRepo.save(MatchComment.builder()
				.matchPostId(postId)
				.applicantTeamId(threadTeam)
				.applicantUserId(threadUser)
				.authorUserId(uid)
				.authorTeamId(currentTeamId)
				.host(isHost)
				.parentId(parentId)
				.content(body)
				.build());
	}

	/** 삭제 (작성자 또는 모집팀) */
	@Transactional
	public void delete(Long commentId, Long uid, Long currentTeamId) {
		MatchComment c = commentRepo.findById(commentId)
				.orElseThrow(() -> new ApiException(404, "댓글을 찾을 수 없습니다."));
		MatchPost post = matchService.get(c.getMatchPostId());
		boolean isHost = post.isRecruitGuest()
				? teamService.isMember(post.getHostTeamId(), uid)
				: isHostTeamSide(post, uid, currentTeamId);
		if (!c.getAuthorUserId().equals(uid) && !isHost) {
			throw new ApiException(403, "삭제 권한이 없습니다.");
		}
		commentRepo.delete(c);
	}

	// ---------- helpers ----------

	private List<Map<String, Object>> rows(List<MatchComment> comments, Map<Long, User> users, Long uid) {
		List<Map<String, Object>> rows = new ArrayList<>();
		for (MatchComment c : comments) {
			Map<String, Object> m = new HashMap<>();
			m.put("id", c.getId());
			m.put("name", nameOf(users, c.getAuthorUserId()));
			m.put("isHost", c.isHost());
			m.put("parentId", c.getParentId());
			m.put("content", c.getContent());
			m.put("createdAt", c.getCreatedAt() == null ? "" : c.getCreatedAt().format(FMT));
			m.put("mine", uid.equals(c.getAuthorUserId()));
			rows.add(m);
		}
		return rows;
	}

	private String nameOf(Map<Long, User> users, Long uid) {
		User u = users.get(uid);
		return u == null ? "?" : u.getNickname();
	}

	private List<Long> concat(List<Long> a, List<Long> b) {
		List<Long> l = new ArrayList<>(a);
		l.addAll(b);
		return l;
	}

	private boolean isHostTeamSide(MatchPost post, Long uid, Long currentTeamId) {
		return currentTeamId != null && currentTeamId.equals(post.getHostTeamId())
				&& teamService.isMember(post.getHostTeamId(), uid);
	}

	private Long applicantTeam(MatchPost post, Long uid, Long currentTeamId) {
		if (currentTeamId == null || !teamService.isMember(currentTeamId, uid)) return null;
		return appRepo.existsByMatchPostIdAndApplicantTeamId(post.getId(), currentTeamId) ? currentTeamId : null;
	}
}
