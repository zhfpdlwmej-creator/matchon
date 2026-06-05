<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="profile" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 내 정보</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<span class="team-switch"><span class="emblem">⚙️</span><strong>내 정보</strong></span>
		<a href="/auth/logout" class="role-badge">로그아웃</a>
	</div>
</header>
<div class="app-wrap">
	<div class="card-form">
		<label>이름 (카카오 계정)</label>
		<div style="padding:13px 14px;border:1px solid var(--line);border-radius:11px;background:#f4f6f5;font-weight:700;">${user.nickname}</div>
		<div class="muted small" style="margin-top:6px;">이름은 카카오 계정 이름으로 자동 설정됩니다.</div>
		<label>선호 포지션</label>
		<div class="pos-picker" id="posPicker">
			<button type="button" class="pos" data-pos="GK">GK</button>
			<button type="button" class="pos" data-pos="DF">DF</button>
			<button type="button" class="pos" data-pos="MF">MF</button>
			<button type="button" class="pos" data-pos="FW">FW</button>
		</div>
		<input type="hidden" id="position" value="${user.position}">
		<button class="btn-primary btn-block" id="saveBtn" style="margin-top:16px;">저장</button>
	</div>

	<div class="section-title">내 팀</div>
	<div class="card">
		<c:forEach var="t" items="${teams}">
			<a class="member-row" href="/team/${t.id}">
				<span class="emblem">⚽</span>
				<span class="name">${t.name}</span>
				<span class="right muted small">이동 ›</span>
			</a>
		</c:forEach>
		<c:if test="${empty teams}"><div class="empty">가입한 팀이 없습니다.</div></c:if>
		<a href="/teams" class="btn-ghost btn-block" style="margin-top:10px;text-align:center;">+ 팀 추가 / 가입</a>
	</div>

	<div class="card" style="text-align:center;">
		<a href="/auth/logout" class="muted small">로그아웃</a>
	</div>
</div>

<%@ include file="layout/bottomnav.jsp" %>

<script>
$(function () {
	const cur = '${user.position}';
	if (cur) $('#posPicker .pos[data-pos="' + cur + '"]').addClass('on');
	$('#posPicker .pos').on('click', function () {
		$('#posPicker .pos').removeClass('on');
		$(this).addClass('on');
		$('#position').val($(this).data('pos'));
	});
	$('#saveBtn').on('click', async function () {
		const r = await api.post('/api/user/profile', { position: $('#position').val() });
		alert(r.ok ? '저장했습니다.' : (r.message || '실패'));
	});
});
</script>
</body>
</html>
