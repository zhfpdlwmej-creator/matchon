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

	<div class="section-title">출석률 통계 (전체 참석률 순)</div>
	<div class="card" style="font-size:12px;color:var(--muted);">
		막대는 전체 참석률입니다. 이번 달 / 최근 3개월 / 전체 순으로 표시됩니다.
	</div>
	<div class="card" id="statList"><div class="empty">불러오는 중...</div></div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};

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
	$('#teamSummary').html(
		'<div style="display:flex;justify-content:space-around;text-align:center;">' +
		'<div><div style="font-size:20px;font-weight:800;">' + t.w + '<span class="muted small">승</span> ' + t.d + '<span class="muted small">무</span> ' + t.l + '<span class="muted small">패</span></div><div class="muted small">최근 5경기</div></div>' +
		'<div><div style="font-size:20px;font-weight:800;color:var(--green);">' + t.gf + '</div><div class="muted small">총 득점</div></div>' +
		'<div><div style="font-size:20px;font-weight:800;color:var(--red);">' + t.ga + '</div><div class="muted small">총 실점</div></div>' +
		'</div>' +
		(t.recent.length ? '<div style="margin-top:12px;">' + t.recent.map(recentRow).join('') + '</div>'
			: '<div class="muted small" style="margin-top:10px;text-align:center;">기록된 경기 결과가 없습니다.<br>경기 상세 → 경기 결과에서 입력해보세요.</div>')
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

$(function () { loadDashboard(); loadAttendance(); });
</script>
</body>
</html>
