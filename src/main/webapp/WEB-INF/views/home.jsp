<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="home" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · ${team.name}</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body>
<%@ include file="layout/header.jsp" %>
<div class="app-wrap">

	<div class="section-title">가장 가까운 경기</div>

	<c:choose>
		<c:when test="${nearest != null}">
			<div class="card" id="nearestCard" data-id="${nearest.id}">
				<div class="date" id="nearestDate" style="color:var(--green);font-weight:700;">${nearest.matchDate}</div>
				<div class="title" style="font-size:20px;font-weight:800;margin:4px 0;">${nearest.title}</div>
				<div class="meta muted small">
					⏰ ${nearest.startTime}
					<c:if test="${nearest.endTime != null}"> ~ ${nearest.endTime}</c:if>
					<c:if test="${nearest.place != null}"> · 📍 ${nearest.place}</c:if>
				</div>
				<c:if test="${nearest.fee > 0}">
					<div class="meta muted small">🏟️ 구장비용(총) ${nearest.fee}원</div>
				</c:if>

				<div class="att-summary" id="homeSummary" style="margin:14px 0;">
					<div class="box attend"><div class="num" id="hsAttend">-</div><div class="lbl">참석</div></div>
					<div class="box absent"><div class="num" id="hsAbsent">-</div><div class="lbl">불참</div></div>
					<div class="box pending"><div class="num" id="hsPending">-</div><div class="lbl">미정</div></div>
				</div>
				<div id="homeSettle" class="settle-box" style="display:none;"></div>

				<div class="attend-buttons" id="homeAttendBtns">
					<button class="att-btn attend" data-s="ATTEND">참석</button>
					<button class="att-btn absent" data-s="ABSENT">불참</button>
					<button class="att-btn pending" data-s="PENDING">미정</button>
				</div>

				<a href="/team/${team.id}/schedule/${nearest.id}" class="btn-ghost btn-block" style="margin-top:12px;text-align:center;">자세히 보기 →</a>
			</div>
		</c:when>
		<c:otherwise>
			<div class="card empty">
				<div class="big">📅</div>
				예정된 경기가 없습니다.
				<c:if test="${canManage}"><br><a href="/team/${team.id}/schedules" style="color:var(--green);">일정 등록하러 가기</a></c:if>
			</div>
		</c:otherwise>
	</c:choose>

	<div class="row-2" style="margin-top:6px;">
		<a href="/team/${team.id}/schedules" class="card" style="text-align:center;">📅<div class="small">전체 일정</div></a>
		<a href="/team/${team.id}/members" class="card" style="text-align:center;">👥<div class="small">팀원 보기</div></a>
	</div>
</div>

<%@ include file="layout/bottomnav.jsp" %>

<c:if test="${nearest != null}">
<script>
const SCHEDULE_ID = ${nearest.id};
const FEE = ${nearest.fee};
async function loadHome() {
	const r = await api.get('/api/attendance/list?scheduleId=' + SCHEDULE_ID);
	if (!r.ok) return;
	const att = r.summary.attend;
	$('#hsAttend').text(att);
	$('#hsAbsent').text(r.summary.absent);
	$('#hsPending').text(r.summary.pending);
	$('#homeAttendBtns .att-btn').removeClass('on');
	$('#homeAttendBtns .att-btn[data-s="' + r.myStatus + '"]').addClass('on');

	// 인당 금액 = 구장비용 ÷ 참석 인원
	if (FEE > 0 && att > 0) {
		const per = Math.ceil(FEE / att);
		$('#homeSettle').show().html(
			'<div class="settle-amt">인당 ' + won(per) + '</div>' +
			'<div class="settle-sub">구장비용 ' + won(FEE) + ' ÷ 참석 ' + att + '명</div>');
	} else {
		$('#homeSettle').hide();
	}
}
function fmtDate(iso) {
	const d = new Date(iso + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 (' + dow + ')';
}
$(function () {
	$('#nearestDate').text(fmtDate('${nearest.matchDate}'));
	loadHome();
	$('#homeAttendBtns .att-btn').on('click', async function () {
		const s = $(this).data('s');
		const r = await api.post('/api/attendance', { scheduleId: SCHEDULE_ID, status: s });
		if (r.ok) loadHome(); else alert(r.message || '실패');
	});
});
</script>
</c:if>
</body>
</html>
