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
		.ts-metrics { display: grid; grid-template-columns: repeat(4, 1fr); gap: 7px; }
		.ts-metric { background: #f6f8f7; border: 1px solid var(--line); border-radius: 10px; padding: 7px 4px; text-align: center; }
		.ts-metric .v { font-size: 17px; font-weight: 800; line-height: 1.2; }
		.ts-metric .l { font-size: 11px; color: var(--muted); margin-top: 1px; }
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
	<div class="card muted small">지난 경기를 탭하면 스코어·득점/도움·MOM을 확인할 수 있어요. 입력은 <b>일정 상세 화면(경기 종료 후)</b>에서 합니다.</div>
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

async function loadDashboard() {
	const r = await api.get('/api/stats/dashboard?teamId=' + TEAM_ID);
	if (!r.ok) return;
	const t = r.team;
	$('#teamSummary').html(
		'<div class="ts-metrics">' +
		'<div class="ts-metric"><div class="v" style="color:var(--green);">' + t.w + '</div><div class="l">승</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:#9aa3a0;">' + t.d + '</div><div class="l">무</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:var(--red);">' + t.l + '</div><div class="l">패</div></div>' +
		'<div class="ts-metric"><div class="v" style="color:#b8860b;">' + (t.mannerAvg != null ? t.mannerAvg + '★' : '–') + '</div><div class="l">매너' + (t.mannerCount ? ' (' + t.mannerCount + ')' : '') + '</div></div>' +
		'</div>'
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

// ===== 경기 결과 · 기록 (읽기 전용 · 입력은 일정 상세에서) =====
async function loadGames() {
	const r = await api.get('/api/schedule/list?teamId=' + TEAM_ID);
	const box = $('#gameList').empty();
	if (!r.ok) return;
	const games = (r.schedules || []).filter(g => g.isPast).slice().sort((a, b) => (a.matchDate < b.matchDate ? 1 : -1));
	if (!games.length) { box.html('<div class="empty">지난 경기가 없습니다.</div>'); return; }
	games.forEach(g => {
		box.append(
			'<div class="game-row" data-id="' + g.id + '">' +
			'<div class="game-head" data-id="' + g.id + '"><span class="name">' + g.matchDate.slice(5).replace('-', '.') + ' ' + esc(g.title) + '</span>' +
			'<span class="score" id="score' + g.id + '">▾</span></div>' +
			'<div class="game-panel" id="panel' + g.id + '" style="display:none;"></div>' +
			'</div>');
	});
}

async function loadGame(id) {
	const rr = await api.get('/api/schedule/' + id + '/result');
	const res = rr.ok ? rr.result : null;
	$('#score' + id).text(res ? (res.ourScore + ':' + res.oppScore) : '미입력');

	let html = res
		? '<div style="text-align:center;font-size:20px;font-weight:800;margin:4px 0;">우리 <span style="color:var(--green);">' + res.ourScore + '</span> : <span style="color:var(--red);">' + res.oppScore + '</span> <span class="muted small">상대</span></div>'
		: '<div class="muted small" style="text-align:center;padding:4px 0;">스코어 미입력</div>';

	html += '<div class="section-title" style="margin-left:0;">⚽ 득점 / 도움</div>';
	const events = rr.ok ? rr.events : [];
	if (!events.length) html += '<div class="muted small" style="padding:4px 0;">기록 없음</div>';
	else events.forEach(e => html += '<div class="member-row"><span class="name">⚽ ' + esc(e.scorerName) + (e.assistName ? ' <span class="muted small">(도움 ' + esc(e.assistName) + ')</span>' : '') + '</span></div>');

	html += '<div class="section-title" style="margin-left:0;">👑 MOM</div>';
	const mom = rr.ok ? rr.mom : [];
	if (!mom.length) html += '<div class="muted small" style="padding:4px 0;">투표 없음</div>';
	else mom.forEach((m, i) => html += '<div class="member-row"><span class="name">' + (i === 0 ? '👑 ' : '') + esc(m.name) + '</span><span class="right muted small">' + m.votes + '표</span></div>');

	$('#panel' + id).html(html);
}

$(function () {
	loadDashboard();
	loadAttendance();
	loadGames();

	$('#gameList').on('click', '.game-head', function () {
		const id = $(this).data('id');
		const panel = $('#panel' + id);
		if (panel.is(':visible')) { panel.hide(); return; }
		if (!panel.data('loaded')) { panel.data('loaded', true); loadGame(id); }
		panel.show();
	});
});
</script>
</body>
</html>
