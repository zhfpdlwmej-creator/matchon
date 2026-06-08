<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="schedule" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 경기 상세</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<a href="/team/${team.id}/schedules" class="small muted">‹ 일정 목록</a>

	<div class="card" id="infoCard" style="margin-top:8px;">
		<div class="date" id="dDate" style="color:var(--green);font-weight:700;"></div>
		<div class="title" id="dTitle" style="font-size:20px;font-weight:800;margin:4px 0;"></div>
		<div class="meta muted small" id="dMeta"></div>
		<div class="meta small" id="dMemo" style="margin-top:8px;white-space:pre-wrap;"></div>
		<button class="btn-primary btn-block" id="shareBtn" style="margin-top:14px;">📢 카카오톡으로 일정 공유</button>
		<a href="/team/${team.id}/schedule/${scheduleId}/formation" class="btn-ghost btn-block" style="margin-top:8px;text-align:center;"><c:choose><c:when test="${canManage}">📋 포메이션 짜기</c:when><c:otherwise>📋 포메이션 보기</c:otherwise></c:choose></a>
		<button class="btn-ghost btn-block" id="recruitBtn" style="margin-top:8px;display:none;color:var(--red);"></button>
	</div>

	<div class="card">
		<h3>내 참석 여부</h3>
		<div class="attend-buttons" id="attendBtns">
			<button class="att-btn attend" data-s="ATTEND">✅ 참석</button>
			<button class="att-btn absent" data-s="ABSENT">❌ 불참</button>
			<button class="att-btn pending" data-s="PENDING">❓ 미정</button>
		</div>
	</div>

	<div class="card">
		<h3>참석 현황</h3>
		<div class="att-summary">
			<div class="box attend"><div class="num" id="sAttend">-</div><div class="lbl">참석</div></div>
			<div class="box absent"><div class="num" id="sAbsent">-</div><div class="lbl">불참</div></div>
			<div class="box pending"><div class="num" id="sPending">-</div><div class="lbl">미정</div></div>
		</div>

		<div class="section-title" style="margin-left:0;">참석자</div>
		<div id="attendList"></div>
		<div class="section-title" style="margin-left:0;">불참 / 미정</div>
		<div id="otherList"></div>
	</div>

	<div class="card" id="resultCard">
		<h3>경기 결과</h3>
		<div id="resultBox"></div>
		<c:if test="${canManage}">
			<div class="row-2" style="margin-top:8px;">
				<div><label class="small">우리 득점</label><input type="number" id="ourScore" min="0" value="0" style="width:100%;padding:10px;border:1px solid var(--line);border-radius:10px;"></div>
				<div><label class="small">상대 득점</label><input type="number" id="oppScore" min="0" value="0" style="width:100%;padding:10px;border:1px solid var(--line);border-radius:10px;"></div>
			</div>
			<button class="btn-primary btn-sm btn-block" id="saveResult" style="margin-top:8px;">결과 저장</button>
		</c:if>

		<div class="section-title" style="margin-left:0;">⚽ 득점 / 도움</div>
		<div id="eventList"></div>
		<c:if test="${canManage}">
			<div style="display:flex;gap:6px;margin-top:8px;">
				<select id="scorerSel" style="flex:1;min-width:0;padding:9px;border:1px solid var(--line);border-radius:10px;"></select>
				<select id="assistSel" style="flex:1;min-width:0;padding:9px;border:1px solid var(--line);border-radius:10px;"></select>
				<button class="btn-primary btn-sm" id="addEvent">＋골</button>
			</div>
		</c:if>

		<div class="section-title" style="margin-left:0;">👑 MOM 투표</div>
		<div id="momBox"></div>
		<div style="display:flex;gap:6px;margin-top:8px;">
			<select id="momSel" style="flex:1;min-width:0;padding:9px;border:1px solid var(--line);border-radius:10px;"></select>
			<button class="btn-primary btn-sm" id="voteMomBtn">투표</button>
		</div>
	</div>

	<div class="card">
		<h3>용병 <span class="muted small" id="guestSum"></span></h3>
		<div class="muted small" style="margin-bottom:8px;">팀원이 아닌 외부 참석 인원을 추가해 정확히 집계해요.</div>
		<div id="guestList"></div>
		<div class="comment-input" style="margin-top:10px;">
			<input type="text" id="guestName" maxlength="40" placeholder="용병 이름 (예: 철수 지인)" style="flex:2;">
			<input type="number" id="guestCount" min="1" value="1" style="flex:1;min-width:0;" title="인원수">
			<button class="btn-primary btn-sm" id="guestAdd">＋ 추가</button>
		</div>
	</div>

	<div class="card">
		<h3>댓글 <span class="muted small" id="cmtCount"></span></h3>
		<div id="commentList"></div>
		<div class="comment-input">
			<input type="text" id="cmtInput" maxlength="300" placeholder="예: 10분 정도 늦습니다 / 주차 가능한가요?">
			<button class="btn-primary btn-sm" id="cmtSend">등록</button>
		</div>
	</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const SCHEDULE_ID = ${scheduleId};
const CAN_MANAGE = ${canManage};
const MY_ID = ${user.id};
const TEAM_NAME = "${team.name}";
let isPast = false; // 경기 종료 여부
let sched = null;   // 현재 일정 (공유용)
let attendees = [];   // 참석 멤버 [{userId,name}]
let scorerPool = [];  // 참석멤버 + 용병 [{userId,name}]

async function loadResult() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID + '/result');
	if (!r.ok) return;
	const res = r.result;
	if (res) $('#resultBox').html('<div style="font-size:24px;font-weight:800;text-align:center;color:var(--green);">우리 ' + res.ourScore + ' : ' + res.oppScore + ' <span style="color:var(--text);font-size:16px;">상대</span></div>');
	else $('#resultBox').html('<div class="muted small">아직 결과가 입력되지 않았습니다.</div>');
	if (CAN_MANAGE && res) { $('#ourScore').val(res.ourScore); $('#oppScore').val(res.oppScore); }

	const el = $('#eventList').empty();
	if (!r.events.length) el.html('<div class="muted small" style="padding:6px 0;">기록 없음</div>');
	r.events.forEach(e => {
		const del = CAN_MANAGE ? ' <a href="javascript:void(0)" class="evtDel muted small" data-id="' + e.id + '">삭제</a>' : '';
		el.append('<div class="member-row"><span class="name">⚽ ' + esc(e.scorerName) + (e.assistName ? ' <span class="muted small">(도움 ' + esc(e.assistName) + ')</span>' : '') + '</span><span class="right">' + del + '</span></div>');
	});

	// 득점/도움 드롭다운 (팀장)
	const s = $('#scorerSel').empty().append('<option value="">득점자</option>');
	const a = $('#assistSel').empty().append('<option value="">도움 없음</option>');
	scorerPool.forEach(p => { const v = (p.userId || '') + '|' + p.name; s.append('<option value="' + v + '">' + esc(p.name) + '</option>'); a.append('<option value="' + v + '">' + esc(p.name) + '</option>'); });

	// MOM
	const mb = $('#momBox').empty();
	if (!r.mom.length) mb.html('<div class="muted small" style="padding:6px 0;">아직 투표가 없습니다.</div>');
	r.mom.forEach((m, i) => mb.append('<div class="member-row"><span class="name">' + (i === 0 ? '👑 ' : '') + esc(m.name) + '</span><span class="right muted small">' + m.votes + '표' + (m.userId === r.myVote ? ' · 내 표' : '') + '</span></div>'));
	const ms = $('#momSel').empty().append('<option value="">MOM 선택</option>');
	attendees.forEach(p => ms.append('<option value="' + p.userId + '"' + (p.userId === r.myVote ? ' selected' : '') + '>' + esc(p.name) + '</option>'));
}

function fmtDate(iso) {
	const d = new Date(iso + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 (' + dow + ')';
}

async function loadInfo() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID);
	if (!r.ok) { alert('일정을 불러올 수 없습니다.'); return; }
	const s = r.schedule;
	sched = s;
	$('#dDate').text(fmtDate(s.matchDate));
	$('#dTitle').text(s.title);
	let meta = '⏰ ' + s.startTime.slice(0,5) + (s.endTime ? ' ~ ' + s.endTime.slice(0,5) : '');
	if (s.place) meta += ' · 📍 ' + s.place;
	$('#dMeta').text(meta);
	isPast = !!s.isPast;
	$('#dMemo').text(s.memo || '');
}

async function loadAttendance() {
	const r = await api.get('/api/attendance/list?scheduleId=' + SCHEDULE_ID);
	if (!r.ok) return;
	const sm = r.summary;
	$('#sAttend').text(sm.attend);
	$('#sAbsent').text(sm.absent);
	$('#sPending').text(sm.pending);
	$('#attendBtns .att-btn').removeClass('on');
	$('#attendBtns .att-btn[data-s="' + r.myStatus + '"]').addClass('on');

	// 인원 부족 → 용병 모집글 버튼 (팀장/운영진)
	const target = sched ? sched.targetHeadcount : 0;
	const shortage = target - (sm.attend + (sm.guestCount || 0));
	if (CAN_MANAGE && shortage > 0) $('#recruitBtn').show().text('🆘 용병 ' + shortage + '명 모집글 올리기');
	else $('#recruitBtn').hide();

	// 결과 카드용 명단 캐시
	attendees = (sm.attendList || []).map(m => ({ userId: m.userId, name: m.nickname }));
	scorerPool = attendees.slice();
	(sm.guests || []).forEach(g => { for (let k = 0; k < g.headcount; k++) scorerPool.push({ userId: null, name: g.name + (g.headcount > 1 ? (k + 1) : '') }); });

	// 참석자
	const al = $('#attendList').empty();
	if (!sm.attendList.length) al.html('<div class="muted small" style="padding:8px 0;">아직 참석자가 없습니다.</div>');
	sm.attendList.forEach(m => al.append(memberRow(m)));

	// 불참/미정
	const ol = $('#otherList').empty();
	const others = sm.absentList.map(m => ({...m, _t:'불참'})).concat(sm.pendingList.map(m => ({...m, _t:'미정'})));
	if (!others.length) ol.html('<div class="muted small" style="padding:8px 0;">없음</div>');
	others.forEach(m => {
		ol.append('<div class="member-row"><span class="name">' + esc(m.nickname) +
			'</span><span class="right small muted">' + m._t + '</span></div>');
	});

	// 용병
	const guests = sm.guests || [];
	const gc = sm.guestCount || 0;
	$('#guestSum').text(gc > 0 ? '(' + gc + '명)' : '');
	const gl = $('#guestList').empty();
	if (!guests.length) gl.html('<div class="muted small" style="padding:6px 0;">추가된 용병이 없습니다.</div>');
	guests.forEach(g => gl.append(
		'<div class="member-row"><span class="name">🧤 ' + esc(g.name) + (g.headcount > 1 ? ' (' + g.headcount + '명)' : '') + '</span>' +
		'<span class="right"><a href="javascript:void(0)" class="guestDel muted small" data-id="' + g.id + '">삭제</a></span></div>'));
}

function memberRow(m) {
	return '<div class="member-row"><span class="name">' + esc(m.nickname) + '</span></div>';
}

async function loadComments() {
	const r = await api.get('/api/comment/list?scheduleId=' + SCHEDULE_ID);
	const box = $('#commentList').empty();
	if (!r.ok) return;
	$('#cmtCount').text(r.comments.length);
	if (!r.comments.length) { box.html('<div class="muted small" style="padding:8px 0;">첫 댓글을 남겨보세요.</div>'); return; }
	r.comments.forEach(c => {
		const del = (c.userId === MY_ID || CAN_MANAGE)
			? ' <a href="javascript:void(0)" class="cmtDel muted small" data-id="' + c.id + '">삭제</a>' : '';
		box.append('<div class="comment"><span class="who">' + esc(c.nickname) + '</span>' +
			'<span class="when">' + esc(c.createdAt) + '</span>' + del +
			'<div>' + esc(c.content) + '</div></div>');
	});
}

$(function () {
	loadInfo().then(loadAttendance).then(loadResult);
	loadComments();

	$('#saveResult').on('click', async function () {
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/result', { our: parseInt($('#ourScore').val() || '0', 10), opp: parseInt($('#oppScore').val() || '0', 10) });
		if (r.ok) loadResult(); else alert(r.message || '실패');
	});
	$('#addEvent').on('click', async function () {
		const sv = $('#scorerSel').val(); if (!sv) { alert('득점자를 선택하세요.'); return; }
		const sp = sv.split('|');
		const av = $('#assistSel').val(); let auid = null, aname = null;
		if (av) { const ap = av.split('|'); auid = ap[0] || null; aname = ap[1]; }
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/event', { scorerUserId: sp[0] || null, scorerName: sp[1], assistUserId: auid, assistName: aname });
		if (r.ok) loadResult(); else alert(r.message || '실패');
	});
	$('#eventList').on('click', '.evtDel', async function () {
		if (!confirm('이 기록을 삭제할까요?')) return;
		const r = await api.del('/api/schedule/event/' + $(this).data('id'));
		if (r.ok) loadResult(); else alert(r.message || '실패');
	});
	$('#voteMomBtn').on('click', async function () {
		const t = $('#momSel').val(); if (!t) { alert('MOM 후보를 선택하세요.'); return; }
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/mom', { targetUserId: t });
		if (r.ok) { alert('투표 완료!'); loadResult(); } else alert(r.message || '실패');
	});

	$('#recruitBtn').on('click', async function () {
		if (!confirm('인원이 부족한 만큼 매칭 탭에 용병 모집글을 올릴까요?')) return;
		const r = await api.post('/api/match/recruit-guest?scheduleId=' + SCHEDULE_ID, {});
		if (r.ok) { alert('용병 모집글을 등록했어요! 매칭 탭에서 확인하세요.'); location.href = '/matches/' + r.id; }
		else alert(r.message || '실패');
	});

	$('#attendBtns .att-btn').on('click', async function () {
		const s = $(this).data('s');
		const r = await api.post('/api/attendance', { scheduleId: SCHEDULE_ID, status: s });
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});

	$('#shareBtn').on('click', function () {
		if (!sched) return;
		const url = location.origin + '/team/' + TEAM_ID + '/schedule/' + sched.id;
		const d = new Date(sched.matchDate + 'T00:00:00');
		const dow = ['일','월','화','수','목','금','토'][d.getDay()];
		const when = (d.getMonth() + 1) + '월 ' + d.getDate() + '일(' + dow + ') ' + sched.startTime.slice(0, 5);
		kakaoShareSchedule({ teamName: TEAM_NAME, title: sched.title, when: when, place: sched.place, url: url });
	});

	async function sendComment() {
		const v = $('#cmtInput').val().trim();
		if (!v) return;
		const r = await api.post('/api/comment', { scheduleId: SCHEDULE_ID, content: v });
		if (r.ok) { $('#cmtInput').val(''); loadComments(); } else alert(r.message || '실패');
	}
	$('#cmtSend').on('click', sendComment);
	$('#cmtInput').on('keypress', e => { if (e.which === 13) sendComment(); });

	$('#commentList').on('click', '.cmtDel', async function () {
		if (!confirm('댓글을 삭제할까요?')) return;
		const r = await api.del('/api/comment/' + $(this).data('id'));
		if (r.ok) loadComments(); else alert(r.message || '실패');
	});

	// 용병 추가/삭제
	async function addGuest() {
		const name = $('#guestName').val().trim();
		const cnt = parseInt($('#guestCount').val() || '1', 10);
		if (!name) { alert('용병 이름을 입력하세요.'); return; }
		const r = await api.post('/api/attendance/guest', { scheduleId: SCHEDULE_ID, name: name, headcount: cnt });
		if (r.ok) { $('#guestName').val(''); $('#guestCount').val(1); loadAttendance(); } else alert(r.message || '실패');
	}
	$('#guestAdd').on('click', addGuest);
	$('#guestName').on('keypress', e => { if (e.which === 13) addGuest(); });
	$('#guestList').on('click', '.guestDel', async function () {
		if (!confirm('이 용병을 삭제할까요?')) return;
		const r = await api.del('/api/attendance/guest/' + $(this).data('id'));
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
