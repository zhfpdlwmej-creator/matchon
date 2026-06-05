<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="profile" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 관리</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<c:if test="${!canManage}">
		<div class="card empty">관리자(팀장/운영진)만 접근할 수 있습니다.</div>
	</c:if>

	<c:if test="${canManage}">
		<div class="section-title">팀 운영 설정</div>
		<div class="card">
			<h3>인원 부족 알림</h3>
			<div class="muted small" style="margin-bottom:8px;">참석 인원이 기준 미만이면 자동으로 알림을 보냅니다. (0 = 사용 안 함)</div>
			<div style="display:flex;gap:8px;align-items:center;">
				<input type="number" id="minAtt" min="0" value="${team.minAttendees}" style="width:100px;padding:10px;border:1px solid var(--line);border-radius:9px;">
				<span>명 미만</span>
				<button class="btn-primary btn-sm" id="saveMin" style="margin-left:auto;">저장</button>
			</div>
		</div>

		<div class="section-title">알림 발송 이력</div>
		<div class="card" id="notiList"><div class="empty">불러오는 중...</div></div>
	</c:if>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<c:if test="${canManage}">
<script>
const TEAM_ID = ${team.id};
const TYPE_LABEL = {
	SCHEDULE_CREATED: '일정등록', D_1: '하루전', H_3: '3시간전', M_30: '30분전', LOW_ATTENDANCE: '인원부족'
};
async function loadNoti() {
	const r = await api.get('/api/notification/list?teamId=' + TEAM_ID);
	const box = $('#notiList').empty();
	if (!r.ok) { box.html('<div class="empty">불러올 수 없습니다.</div>'); return; }
	if (!r.notifications.length) { box.html('<div class="empty">발송된 알림이 없습니다.</div>'); return; }
	r.notifications.forEach(n => {
		box.append('<div class="member-row" style="align-items:flex-start;">' +
			'<span class="role-badge" style="background:#eef0f3;color:#444;">' + (TYPE_LABEL[n.type] || n.type) + '</span>' +
			'<div style="flex:1;"><div class="small" style="white-space:pre-wrap;">' + esc(n.message) + '</div>' +
			'<div class="muted small">' + esc(n.createdAt) + (n.sent ? ' · 발송완료' : ' · 대기') + '</div></div>' +
			'</div>');
	});
}
$(function () {
	loadNoti();
	$('#saveMin').on('click', async function () {
		const v = parseInt($('#minAtt').val() || '0', 10);
		const r = await api.post('/api/team/' + TEAM_ID + '/min-attendees', { minAttendees: v });
		alert(r.ok ? '저장했습니다.' : (r.message || '실패'));
	});
});
</script>
</c:if>
</body>
</html>
