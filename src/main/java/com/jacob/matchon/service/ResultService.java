package com.jacob.matchon.service;

import com.jacob.matchon.model.*;
import com.jacob.matchon.repo.*;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/** 경기 결과 / 득점·도움 / MOM 투표. */
@Service
@RequiredArgsConstructor
public class ResultService {

	private final MatchResultRepository resultRepo;
	private final MatchEventRepository eventRepo;
	private final MomVoteRepository momRepo;
	private final ScheduleService scheduleService;
	private final TeamService teamService;
	private final UserService userService;

	/** 결과 + 득점/도움 + MOM 집계 조회 (팀 멤버) */
	public Map<String, Object> view(Long scheduleId, Long uid) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), uid);

		Map<String, Object> res = new HashMap<>();
		MatchResult r = resultRepo.findByScheduleId(scheduleId).orElse(null);
		if (r != null) {
			res.put("result", Map.of(
					"ourScore", r.getOurScore(),
					"oppScore", r.getOppScore(),
					"opponentName", r.getOpponentName() == null ? "" : r.getOpponentName()));
		} else {
			res.put("result", null);
		}

		List<MatchEvent> events = eventRepo.findByScheduleIdOrderByIdAsc(scheduleId);
		res.put("events", events.stream().map(e -> {
			Map<String, Object> m = new HashMap<>();
			m.put("id", e.getId());
			m.put("scorerName", e.getScorerName());
			m.put("assistName", e.getAssistName());
			return m;
		}).toList());

		// MOM 투표 집계
		List<MomVote> votes = momRepo.findByScheduleId(scheduleId);
		Map<Long, Long> counts = votes.stream()
				.collect(Collectors.groupingBy(MomVote::getTargetUserId, Collectors.counting()));
		Map<Long, User> users = userService.mapByIds(new ArrayList<>(counts.keySet()));
		List<Map<String, Object>> mom = counts.entrySet().stream()
				.sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
				.map(en -> {
					Map<String, Object> m = new HashMap<>();
					User u = users.get(en.getKey());
					m.put("userId", en.getKey());
					m.put("name", u == null ? "?" : u.getNickname());
					m.put("votes", en.getValue());
					return m;
				}).toList();
		res.put("mom", mom);
		res.put("myVote", momRepo.findByScheduleIdAndVoterUserId(scheduleId, uid)
				.map(MomVote::getTargetUserId).orElse(null));
		res.put("ok", true);
		return res;
	}

	/** 결과 저장/수정 (팀장/운영진) */
	@Transactional
	public void saveResult(Long scheduleId, Long uid, int our, int opp, String opponentName) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.requireManager(s.getTeamId(), uid);
		MatchResult r = resultRepo.findByScheduleId(scheduleId).orElseGet(() ->
				MatchResult.builder().scheduleId(scheduleId).createdBy(uid).build());
		r.setOurScore(Math.max(0, our));
		r.setOppScore(Math.max(0, opp));
		r.setOpponentName(opponentName == null || opponentName.isBlank() ? null : opponentName.trim());
		if (r.getCreatedBy() == null) r.setCreatedBy(uid);
		resultRepo.save(r);
	}

	/** 득점/도움 추가 (팀장/운영진) */
	@Transactional
	public void addEvent(Long scheduleId, Long uid, Long scorerUserId, String scorerName,
						 Long assistUserId, String assistName) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.requireManager(s.getTeamId(), uid);
		String sn = resolveName(scorerUserId, scorerName);
		if (sn == null) throw new ApiException(400, "득점자를 선택하거나 입력해주세요.");
		eventRepo.save(MatchEvent.builder()
				.scheduleId(scheduleId)
				.teamId(s.getTeamId())
				.scorerUserId(scorerUserId)
				.scorerName(sn)
				.assistUserId(assistUserId)
				.assistName(resolveName(assistUserId, assistName))
				.build());
	}

	/** 득점/도움 삭제 (팀장/운영진) */
	@Transactional
	public void deleteEvent(Long eventId, Long uid) {
		MatchEvent e = eventRepo.findById(eventId)
				.orElseThrow(() -> new ApiException(404, "기록을 찾을 수 없습니다."));
		MatchSchedule s = scheduleService.get(e.getScheduleId());
		teamService.requireManager(s.getTeamId(), uid);
		eventRepo.delete(e);
	}

	/** MOM 투표 (팀 멤버, 1인 1표) */
	@Transactional
	public void voteMom(Long scheduleId, Long uid, Long targetUserId) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), uid);
		MomVote v = momRepo.findByScheduleIdAndVoterUserId(scheduleId, uid).orElseGet(() ->
				MomVote.builder().scheduleId(scheduleId).teamId(s.getTeamId()).voterUserId(uid).build());
		v.setTargetUserId(targetUserId);
		v.setTeamId(s.getTeamId());
		momRepo.save(v);
	}

	private String resolveName(Long userId, String fallback) {
		if (userId != null) {
			return userService.findById(userId).map(User::getNickname).orElse(fallback);
		}
		return (fallback == null || fallback.isBlank()) ? null : fallback.trim();
	}
}
