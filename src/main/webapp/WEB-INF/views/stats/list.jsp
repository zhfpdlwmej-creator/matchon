<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="stats" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 통계</title>
	<%@ include file="../layout/head.jsp" %>
	<style>
		.rank-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
		.rank-box { border: 1px solid var(--line); border-radius: 12px; padding: 10px; }
		.rank-box h4 { margin: 0 0 6px; font-size: 13px; }
		.rank-box .ri { display: flex; justify-content: space-between; font-size: 13px; padding: 3px 0; }
		.rank-box .ri .n { color: var(--muted); width: 18px; }
		.game-row { border-bottom: 1px solid var(--line); }
		.game-row:last-child { border-bottom: none; }
		.game-head { display: flex; align-items: center; padding: 11px 2px; cursor: pointer; }
		.game-head .name { font-weight: 600; font-size: 14px; }
		.game-head .score { margin-left: auto; font-weight: 700; }
		.game-panel { padding: 4px 2px 12px; }
		.game-panel input, .game-panel select { padding: 9px; border: 1px solid var(--line); border-radius: 10px; width: 100%; }
		.ts-record { display: flex; align-items: baseline; gap: 10px; flex-wrap: wrap; }
		.ts-wdl { font-size: 30px; font-weight: 900; letter-spacing: 1px; }
		.ts-wdl .w { color: var(--green); } .ts-wdl .d { color: #9aa3a0; } .ts-wdl .l { color: var(--red); }
		.ts-form { display: flex; gap: 5px; margin: 10px 0 14px; }
		.ts-form .pill { width: 26px; height: 26px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #fff; }
		.ts-form .pill.W { background: var(--green); } .ts-form .pill.D { background: #9aa3a0; } .ts-form .pill.L { background: var(--red); }
		.ts-metrics { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
		.ts-metric { background: #f6f8f7; border: 1px solid var(--line); border-radius: 12px; padding: 11px 4px; text-align: center; }
		.ts-metric .v { font-size: 18px; font-weight: 800; }
		.ts-metric .l { font-size: 11px; color: var(--muted); margin-top: 3px; }
		.ts-recent { margin-top: 14px; }
	</style>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="section-title">팀 최근 성적</div>
	<div class="card" id="teamSummary"><div class="empty">불러오는 중...</div></div>

	<div class="section-title">개인 랭킹 (TOP 5)</div>
	<div class="card"><div class="rank-grid">
		<div class="rank-box"><h4>⚽ 득점왕</h4><div id="rkScorers"></div></div>
		<div class="rank-box"><h4>🅰️ 도움왕</h4><div id="rkAssists"></div></div>
		<div class="rank-box"><h4>🙌 출석왕</h4><div id="rkAttend"></div></div>
		<div class="rank-box"><h4>👑 MOM</h4><div id="rkMom"></div></div>
	</div></div>

	<div class="section-title">경기 결과 · 기록</div>
	<div class="card muted small">경기를 탭하면 스코어·득점/도움·MOM을 입력/확인할 수 있어요.<c:if test="${not canManage}"><br>스코어·득점 입력은 팀장/운영진만 가능합니다.</c:if></div>
	<div class="card" id="gameList"><div class="empty">불러오는 중...</div></div>

	<div class="section-title">출석률 통계 (전체 참석률 순)</div>
	<div class="card" style="font-size:12px;color:var(--muted);">
		막대는 전체 참석률입니다. 이번 달 / 최근 3개월 / 전체 순으로 표시됩니다.
	</div>
	<div class="card" id="statList"><div class="empty">불러오는 중...</div></div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const CAN_MANAGE = ${canManage};
const MY_ID = ${user.id};

function rankList(box, rows, unit) {
	const el = $(box).empty();
	if (!rows.length) { el.html('<div class="muted small">없음</div>'); return; }
	rows.forEach((r, i) => el.append('<div class="ri"><span><span class="n">' + (i + 1) + '</span>' + esc(r.name) + '</span><b>' + r.count + unit + '</b></div>'));
}

function recentRow(m) {
	const o = m.outcome === 'W' ? '<span style="color:var(--green);font-weight:700;">승</span>'
		: m.outcome === 'L' ? '<span style="color:var(--red);font-weight:700;">패</span>'
		: '<span class="muted" style="font-weight:700;">무</span>';
	return '<div class="member-row"><span class="name small">' + m.date.slice(5).replace('-', '.') + ' ' + esc(m.title) + (m.opponent ? ' <span class="muted">vs ' + esc(m.opponent) + '</span>' : '') + '</span>' +
		'<span class="right small"><b>' + m.our + ':' + m.opp + '</b> ' + o + '</span></div>';
}

async function loadDashboard() {
	const r = await api.get('/api/stats/dashboard?teamId=' + TEAM_ID);
	if (!r.ok) return;
	const t = r.team;
	const played = t.w + t.d + t.l;
	const diff = t.gf - t.ga;
	const diffStr = (diff > 0 ? '+' : '') + diff;
	const pills = (t.recent || []).slice(0, 5)
		.map(m => '<span class="pill ' + m.outcome + '">' + (m.outcome === 'W' ? '승' : m.outcome === 'L' ? '패' : '무') + '</span>').join('');
	$('#teamSummary').html(
		'<div class="ts-record"><div class="ts-wdl"><span class="w">' + t.w + '</span> <span class="d">' + t.d + '</span> <span class="l">' + t.l + '</span></div>' +
		'<span class="muted small">최근 ' + played + '경기 · 승무패</span></div>' +
		(pills ? '<div class="ts-form">' + pills + '</div>' : '<div style="height:6px;"></div>') +
		'<div class="ts-metrics">' +
		'<div class="ts-metric"><div class="v" style="color:var(--green);">' + t.gf + '</div><div class="l">득점</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:var(--red);">' + t.ga + '</div><div class="l">실점</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:' + (diff >= 0 ? 'var(--green)' : 'var(--red)') + ';">' + diffStr + '</div><div class="l">득실차</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:#b8860b;">' + (t.mannerAvg != null ? t.mannerAvg + '★' : '–') + '</div><div class="l">매너' + (t.mannerCount ? ' (' + t.mannerCount + ')' : '') + '</div></div>' +
		'</div>' +
		(t.recent.length ? '<div class="ts-recent">' + t.recent.map(recentRow).join('') + '</div>'
			: '<div class="muted small" style="margin-top:12px;text-align:center;">기록된 경기 결과가 없습니다.<br>아래 경기 결과에서 스코어를 입력해보세요.</div>')
	);
	rankList('#rkScorers', r.scorers, '골');
	rankList('#rkAssists', r.assisters, '');
	rankList('#rkAttend', r.attendance, '회');
	rankList('#rkMom', r.mom, '표');
}

async function loadAttendance() {
	const r = await api.get('/api/stats?teamId=' + TEAM_ID);
	const box = $('#statList').empty();
	if (!r.ok) return;
	if (!r.stats.length) { box.html('<div class="empty">통계 데이터가 없습니다.</div>'); return; }
	r.stats.forEach((s, i) => {
		box.append(
			'<div class="stat-row">' +
			'<div class="top">' +
			'<span class="muted small">' + (i + 1) + '</span> ' +
			'<span class="name">' + esc(s.nickname) + '</span>' +
			'<span class="right muted small" style="margin-left:auto;">' + s.totalAttended + '/' + s.totalMatches + '경기</span>' +
			'</div>' +
			'<div class="stat-bar"><i style="width:' + s.totalRate + '%;"></i></div>' +
			'<div class="stat-pcts">' +
			'<span>이번달 <b>' + s.monthRate + '%</b></span>' +
			'<span>최근3개월 <b>' + s.recent3Rate + '%</b></span>' +
			'<span>전체 <b>' + s.totalRate + '%</b></span>' +
			'</div></div>');
	});
}

// ===== 경기 결과 · 기록 =====
async function loadGames() {
	const r = await api.get('/api/schedule/list?teamId=' + TEAM_ID);
	const box = $('#gameList').empty();
	if (!r.ok) return;
	const games = (r.schedules || []).slice().sort((a, b) => (a.matchDate < b.matchDate ? 1 : -1));
	if (!games.length) { box.html('<div class="empty">등록된 경기 일정이 없습니다.</div>'); return; }
	games.forEach(g => {
		box.append(
			'<div class="game-row" data-id="' + g.id + '">' +
			'<div class="game-head" data-id="' + g.id + '"><span class="name">' + g.matchDate.slice(5).replace('-', '.') + ' ' + esc(g.title) + '</span>' +
			'<span class="score" id="score' + g.id + '">▾</span></div>' +
			'<div class="game-panel" id="panel' + g.id + '" style="display:none;"></div>' +
			'</div>');
	});
}

function gameEditorHtml(id) {
	return '<div id="rbox' + id + '"></div>' +
		(CAN_MANAGE ? '<div class="row-2" style="margin-top:8px;">' +
			'<div><label class="small">우리 득점</label><input type="number" id="our' + id + '" min="0" value="0"></div>' +
			'<div><label class="small">상대 득점</label><input type="number" id="opp' + id + '" min="0" value="0"></div></div>' +
			'<button class="btn-primary btn-sm btn-block save-result" data-id="' + id + '" style="margin-top:6px;">스코어 저장</button>' : '') +
		'<div class="section-title" style="margin-left:0;">⚽ 득점 / 도움</div>' +
		'<div id="evt' + id + '"></div>' +
		(CAN_MANAGE ? '<div style="display:flex;gap:6px;margin-top:6px;"><select id="sc' + id + '"></select><select id="as' + id + '"></select><button class="btn-primary btn-sm add-evt" data-id="' + id + '">＋골</button></div>' : '') +
		'<div class="section-title" style="margin-left:0;">👑 MOM 투표</div>' +
		'<div id="mom' + id + '"></div>' +
		'<div style="display:flex;gap:6px;margin-top:6px;"><select id="ms' + id + '"></select><button class="btn-primary btn-sm vote-mom" data-id="' + id + '">투표</button></div>';
}

async function loadGame(id) {
	const rr = await api.get('/api/schedule/' + id + '/result');
	const ar = await api.get('/api/attendance/list?scheduleId=' + id);
	const sm = ar.ok ? ar.summary : { attendList: [], guests: [] };
	const attendees = (sm.attendList || []).map(m => ({ userId: m.userId, name: m.nickname }));
	const pool = attendees.slice();
	(sm.guests || []).forEach(g => { for (let k = 0; k < g.headcount; k++) pool.push({ userId: null, name: g.name + (g.headcount > 1 ? (k + 1) : '') }); });

	const res = rr.ok ? rr.result : null;
	$('#rbox' + id).html(res ? '<div style="font-size:20px;font-weight:800;text-align:center;color:var(--green);">우리 ' + res.ourScore + ' : ' + res.oppScore + ' <span style="color:var(--text);font-size:14px;">상대</span></div>' : '<div class="muted small">스코어 미입력</div>');
	if (CAN_MANAGE && res) { $('#our' + id).val(res.ourScore); $('#opp' + id).val(res.oppScore); }
	$('#score' + id).text(res ? (res.ourScore + ':' + res.oppScore) : '미입력');

	const el = $('#evt' + id).empty();
	const events = rr.ok ? rr.events : [];
	if (!events.length) el.html('<div class="muted small" style="padding:4px 0;">기록 없음</div>');
	events.forEach(e => el.append('<div class="member-row"><span class="name">⚽ ' + esc(e.scorerName) + (e.assistName ? ' <span class="muted small">(도움 ' + esc(e.assistName) + ')</span>' : '') + '</span>' + (CAN_MANAGE ? '<span class="right"><a href="javascript:void(0)" class="evt-del muted small" data-eid="' + e.id + '" data-id="' + id + '">삭제</a></span>' : '') + '</div>'));

	const sc = $('#sc' + id).empty().append('<option value="">득점자</option>');
	const as = $('#as' + id).empty().append('<option value="">도움</option>');
	pool.forEach(p => { const v = (p.userId || '') + '|' + p.name; sc.append('<option value="' + v + '">' + esc(p.name) + '</option>'); as.append('<option value="' + v + '">' + esc(p.name) + '</option>'); });

	const mb = $('#mom' + id).empty();
	const mom = rr.ok ? rr.mom : [];
	const myVote = rr.ok ? rr.myVote : null;
	if (!mom.length) mb.html('<div class="muted small" style="padding:4px 0;">아직 투표가 없습니다.</div>');
	mom.forEach((m, i) => mb.append('<div class="member-row"><span class="name">' + (i === 0 ? '👑 ' : '') + esc(m.name) + '</span><span class="right muted small">' + m.votes + '표' + (m.userId === myVote ? ' · 내 표' : '') + '</span></div>'));
	const ms = $('#ms' + id).empty().append('<option value="">MOM 선택</option>');
	attendees.forEach(p => ms.append('<option value="' + p.userId + '"' + (p.userId === myVote ? ' selected' : '') + '>' + esc(p.name) + '</option>'));
}

$(function () {
	loadDashboard();
	loadAttendance();
	loadGames();

	$('#gameList').on('click', '.game-head', function () {
		const id = $(this).data('id');
		const panel = $('#panel' + id);
		if (panel.is(':visible')) { panel.hide(); $('#score' + id).text($('#score' + id).text() === '▾' ? '▾' : $('#score' + id).text()); return; }
		if (!panel.data('loaded')) { panel.html(gameEditorHtml(id)).data('loaded', true); loadGame(id); }
		panel.show();
	});
	$('#gameList').on('click', '.save-result', async function () {
		const id = $(this).data('id');
		const r = await api.post('/api/schedule/' + id + '/result', { our: parseInt($('#our' + id).val() || '0', 10), opp: parseInt($('#opp' + id).val() || '0', 10) });
		if (r.ok) { loadGame(id); loadDashboard(); } else alert(r.message || '실패');
	});
	$('#gameList').on('click', '.add-evt', async function () {
		const id = $(this).data('id');
		const sv = $('#sc' + id).val(); if (!sv) { alert('득점자를 선택하세요.'); return; }
		const sp = sv.split('|');
		const av = $('#as' + id).val(); let auid = null, aname = null;
		if (av) { const ap = av.split('|'); auid = ap[0] || null; aname = ap[1]; }
		const r = await api.post('/api/schedule/' + id + '/event', { scorerUserId: sp[0] || null, scorerName: sp[1], assistUserId: auid, assistName: aname });
		if (r.ok) { loadGame(id); loadDashboard(); } else alert(r.message || '실패');
	});
	$('#gameList').on('click', '.evt-del', async function () {
		if (!confirm('이 기록을 삭제할까요?')) return;
		const id = $(this).data('id');
		const r = await api.del('/api/schedule/event/' + $(this).data('eid'));
		if (r.ok) { loadGame(id); loadDashboard(); } else alert(r.message || '실패');
	});
	$('#gameList').on('click', '.vote-mom', async function () {
		const id = $(this).data('id');
		const t = $('#ms' + id).val(); if (!t) { alert('MOM 후보를 선택하세요.'); return; }
		const r = await api.post('/api/schedule/' + id + '/mom', { targetUserId: t });
		if (r.ok) { alert('투표 완료!'); loadGame(id); loadDashboard(); } else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
