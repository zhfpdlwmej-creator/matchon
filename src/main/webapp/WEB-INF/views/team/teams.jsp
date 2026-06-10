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
		<span class="team-switch"><span class="emblem">🏟️</span><strong>내 팀</strong></span>
		<a href="/profile" class="role-badge">내정보</a>
	</div>
</header>
<div class="app-wrap">
	<div class="section-title">가입한 팀</div>
	<div id="teamList"><div class="empty">불러오는 중...</div></div>

	<div id="reqWrap" style="display:none;">
		<div class="section-title">승인 대기 중</div>
		<div class="card" id="myRequests"></div>
	</div>

	<div class="section-title">팀 추가</div>
	<div class="tabs" id="teamModeTabs">
		<button class="tab on" data-mode="create">새 팀 만들기</button>
		<button class="tab" data-mode="join">초대코드 가입</button>
	</div>

	<form id="createForm" class="card-form">
		<label>팀명</label>
		<input type="text" id="teamName" maxlength="40" placeholder="예: FC 챔피언스" required>
		<label>팀 소개 (선택)</label>
		<input type="text" id="teamDesc" maxlength="255" placeholder="예: 매주 일요일 아침 풋살">
		<label>회비 관리 방식 (선택)</label>
		<div class="opt-list" id="feePicker">
			<button type="button" class="opt-item on" data-v="NONE">
				<b>구분 안 함</b><span>회비를 따로 관리하지 않아요 (나중에 바꿀 수 있어요)</span>
			</button>
			<button type="button" class="opt-item" data-v="MONTHLY">
				<b>회비회원제</b><span>매월 정기 회비를 걷어요 · 월별 납부 관리</span>
			</button>
			<button type="button" class="opt-item" data-v="PER_GAME">
				<b>참가회원제</b><span>경기마다 일정 금액을 납부해요</span>
			</button>
			<button type="button" class="opt-item" data-v="MIXED">
				<b>회비회원 + 참가회원 혼합</b><span>두 유형이 함께 있어요 · 팀원별로 구분해서 관리</span>
			</button>
		</div>
		<button type="submit" class="btn-primary btn-block" style="margin-top:14px;">팀 생성</button>
	</form>

	<form id="joinForm" class="card-form" style="display:none;">
		<label>초대코드 (6자리)</label>
		<input type="text" id="inviteCode" maxlength="12" placeholder="예: AB3K9X" style="text-transform:uppercase;" required>
		<button type="submit" class="btn-primary btn-block" style="margin-top:14px;">가입 신청</button>
	</form>

	<div class="section-title">팀 없이 참여</div>
	<a href="/matches" class="card" style="display:flex;align-items:center;gap:12px;text-decoration:none;">
		<span style="font-size:26px;">🧤</span>
		<span style="flex:1;"><strong>개인(용병)으로 둘러보기</strong><div class="muted small">팀에 가입하지 않아도, 용병 모집글에 지원해 경기에 참여할 수 있어요.</div></span>
		<span style="font-size:20px;opacity:.6;">›</span>
	</a>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
async function loadTeams() {
	const r = await api.get('/api/team/list');
	const box = $('#teamList').empty();
	if (!r.ok || !r.teams.length) {
		box.html('<div class="empty"><div class="big">🏟️</div>아직 가입한 팀이 없어요.<br>팀을 만들거나 초대코드로 가입하세요.</div>');
		return;
	}
	r.teams.forEach(function (t) {
		const role = t.myRole === 'LEADER' ? '팀장' : (t.myRole === 'MANAGER' ? '운영진' : '회원');
		box.append(
			'<a class="schedule-item" href="/team/' + t.id + '">' +
			'<div class="title">⚽ ' + esc(t.name) + '</div>' +
			'<div class="meta">' + esc(t.description || '') + '</div>' +
			'<div class="meta">멤버 ' + t.memberCount + '명 · 내 권한 ' + role + '</div>' +
			'</a>');
	});
}
async function loadMyRequests() {
	const r = await api.get('/api/team/my-requests');
	if (!r.ok) return;
	if (!r.requests.length) { $('#reqWrap').hide(); return; }
	$('#reqWrap').show();
	const box = $('#myRequests').empty();
	r.requests.forEach(function (q) {
		box.append('<div class="member-row"><span class="name">' + (q.sportEmoji || '') + ' ' + esc(q.teamName) + '</span>' +
			'<span class="right muted small">⏳ 승인 대기</span></div>');
	});
}
$(function () {
	loadTeams();
	loadMyRequests();
	if (location.search.indexOf('req=sent') >= 0) {
		setTimeout(function () { alert('가입 신청이 접수되었습니다.\n팀장이 승인하면 가입됩니다.'); }, 200);
	}
	$('#teamModeTabs .tab').on('click', function () {
		$('#teamModeTabs .tab').removeClass('on'); $(this).addClass('on');
		const m = $(this).data('mode');
		$('#createForm').toggle(m === 'create');
		$('#joinForm').toggle(m === 'join');
	});
	let feeMode = 'NONE';
	$('#feePicker .opt-item').on('click', function () {
		$('#feePicker .opt-item').removeClass('on');
		$(this).addClass('on');
		feeMode = $(this).data('v');
	});
	$('#createForm').on('submit', async function (e) {
		e.preventDefault();
		const r = await api.post('/api/team', {
			name: $('#teamName').val().trim(),
			description: $('#teamDesc').val().trim(),
			feeMode: feeMode
		});
		if (r.ok) location.href = '/team/' + r.team.id;
		else alert(r.message || '생성 실패');
	});
	$('#joinForm').on('submit', async function (e) {
		e.preventDefault();
		const r = await api.post('/api/team/join', { inviteCode: $('#inviteCode').val().trim().toUpperCase() });
		if (r.ok) { alert((r.teamName || '팀') + ' 가입 신청 완료!\n팀장이 승인하면 가입됩니다.'); $('#inviteCode').val(''); loadMyRequests(); }
		else alert(r.message || '신청 실패');
	});
});
</script>
</body>
</html>
