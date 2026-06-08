package com.jacob.matchon.service;

import com.jacob.matchon.model.MatchSchedule;
import com.jacob.matchon.model.Position;
import com.jacob.matchon.model.PositionRequest;
import com.jacob.matchon.model.User;
import com.jacob.matchon.repo.PositionRequestRepository;
import com.jacob.matchon.web.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** 포메이션 선호 포지션 신청. */
@Service
@RequiredArgsConstructor
public class PositionRequestService {

	private final PositionRequestRepository repo;
	private final ScheduleService scheduleService;
	private final TeamService teamService;
	private final UserService userService;

	/** 내 선호 포지션 신청/변경 (팀 멤버) */
	@Transactional
	public void apply(Long scheduleId, Long uid, String position, String note) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), uid);
		String pos = parse(position);
		if (pos == null) throw new ApiException(400, "포지션을 선택해주세요. (GK/DF/MF/FW)");
		PositionRequest r = repo.findByScheduleIdAndUserId(scheduleId, uid)
				.orElseGet(() -> PositionRequest.builder().scheduleId(scheduleId).userId(uid).build());
		r.setPosition(pos);
		r.setNote(note == null || note.isBlank() ? null : note.trim());
		repo.save(r);
	}

	/** 내 신청 취소 */
	@Transactional
	public void cancel(Long scheduleId, Long uid) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), uid);
		repo.deleteByScheduleIdAndUserId(scheduleId, uid);
	}

	/** 신청 현황 + 내 신청 */
	public Map<String, Object> list(Long scheduleId, Long uid) {
		MatchSchedule s = scheduleService.get(scheduleId);
		teamService.membership(s.getTeamId(), uid);
		List<PositionRequest> all = repo.findByScheduleIdOrderByIdAsc(scheduleId);
		Map<Long, User> users = userService.mapByIds(all.stream().map(PositionRequest::getUserId).toList());
		List<Map<String, Object>> rows = all.stream().map(r -> {
			Map<String, Object> m = new HashMap<>();
			User u = users.get(r.getUserId());
			m.put("userId", r.getUserId());
			m.put("name", u == null ? "?" : u.getNickname());
			m.put("position", r.getPosition());
			m.put("note", r.getNote());
			return m;
		}).toList();
		Map<String, Object> res = new HashMap<>();
		res.put("ok", true);
		res.put("requests", rows);
		res.put("myPosition", repo.findByScheduleIdAndUserId(scheduleId, uid)
				.map(PositionRequest::getPosition).orElse(null));
		return res;
	}

	private String parse(String v) {
		try {
			return v == null ? null : Position.valueOf(v.trim().toUpperCase()).name();
		} catch (Exception e) {
			return null;
		}
	}
}
