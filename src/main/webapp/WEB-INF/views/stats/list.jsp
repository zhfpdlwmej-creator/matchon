<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="stats" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 통계</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="section-title">출석률 통계 (전체 참석률 순)</div>
	<div class="card" style="font-size:12px;color:var(--muted);">
		막대는 전체 참석률입니다. 이번 달 / 최근 3개월 / 전체 순으로 표시됩니다.
	</div>
	<div class="card" id="statList"><div class="empty">불러오는 중...</div></div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
async function load() {
	const r = await api.get('/api/stats?teamId=' + TEAM_ID);
	const box = $('#statList').empty();
	if (!r.ok) return;
	if (!r.stats.length) { box.html('<div class="empty">통계 데이터가 없습니다.</div>'); return; }
	r.stats.forEach((s, i) => {
		box.append(
			'<div class="stat-row">' +
			'<div class="top">' +
			'<span class="muted small">' + (i + 1) + '</span> ' +
			posBadge(s.position) +
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
$(load);
</script>
</body>
</html>
