<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 내 팀</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<span class="team-switch"><span class="emblem">⚽</span><strong>내 팀</strong></span>
		<a href="/profile" class="role-badge">내정보</a>
	</div>
</header>
<div class="app-wrap">
	<div class="section-title">가입한 팀</div>
	<div id="teamList"><div class="empty">불러오는 중...</div></div>

	<div class="section-title">새 팀 만들기</div>
	<form id="createForm" class="card-form">
		<label>팀명</label>
		<input type="text" id="teamName" maxlength="40" placeholder="예: FC 챔피언스" required>
		<label>팀 소개 (선택)</label>
		<input type="text" id="teamDesc" maxlength="255" placeholder="예: 매주 일요일 아침 풋살">
		<button type="submit" class="btn-primary btn-block" style="margin-top:14px;">팀 생성</button>
	</form>

	<div class="section-title">초대코드로 가입</div>
	<form id="joinForm" class="card-form">
		<label>초대코드 (6자리)</label>
		<input type="text" id="inviteCode" maxlength="12" placeholder="예: AB3K9X" style="text-transform:uppercase;" required>
		<button type="submit" class="btn-ghost btn-block" style="margin-top:14px;">가입하기</button>
	</form>
</div>

<%@ include file="layout/bottomnav.jsp" %>

<script>
async function loadTeams() {
	const r = await api.get('/api/team/list');
	const box = $('#teamList').empty();
	if (!r.ok || !r.teams.length) {
		box.html('<div class="empty"><div class="big">⚽</div>아직 가입한 팀이 없어요.<br>팀을 만들거나 초대코드로 가입하세요.</div>');
		return;
	}
	r.teams.forEach(function (t) {
		const role = t.myRole === 'LEADER' ? '팀장' : (t.myRole === 'MANAGER' ? '운영진' : '회원');
		box.append(
			'<a class="schedule-item" href="/team/' + t.id + '">' +
			'<div class="title">' + esc(t.name) + '</div>' +
			'<div class="meta">' + esc(t.description || '') + '</div>' +
			'<div class="meta">멤버 ' + t.memberCount + '명 · 내 권한 ' + role + '</div>' +
			'</a>');
	});
}
$(function () {
	loadTeams();
	$('#createForm').on('submit', async function (e) {
		e.preventDefault();
		const r = await api.post('/api/team', { name: $('#teamName').val().trim(), description: $('#teamDesc').val().trim() });
		if (r.ok) location.href = '/team/' + r.team.id;
		else alert(r.message || '생성 실패');
	});
	$('#joinForm').on('submit', async function (e) {
		e.preventDefault();
		const r = await api.post('/api/team/join', { inviteCode: $('#inviteCode').val().trim().toUpperCase() });
		if (r.ok) location.href = '/team/' + r.team.id;
		else alert(r.message || '가입 실패');
	});
});
</script>
</body>
</html>
