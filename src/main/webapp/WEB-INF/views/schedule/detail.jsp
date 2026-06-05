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
		<div class="meta muted small" id="dFee"></div>
		<div class="meta small" id="dMemo" style="margin-top:8px;white-space:pre-wrap;"></div>
	</div>

	<div class="card">
		<h3>내 참석 여부</h3>
		<div class="attend-buttons" id="attendBtns">
			<button class="att-btn attend" data-s="ATTEND">참석</button>
			<button class="att-btn absent" data-s="ABSENT">불참</button>
			<button class="att-btn pending" data-s="PENDING">미정</button>
		</div>
	</div>

	<div class="card">
		<h3>참석 현황</h3>
		<div class="att-summary">
			<div class="box attend"><div class="num" id="sAttend">-</div><div class="lbl">참석</div></div>
			<div class="box absent"><div class="num" id="sAbsent">-</div><div class="lbl">불참</div></div>
			<div class="box pending"><div class="num" id="sPending">-</div><div class="lbl">미정</div></div>
		</div>
		<div class="pos-by" id="posBy"></div>

		<div class="section-title" style="margin-left:0;">참석자</div>
		<div id="attendList"></div>
		<div class="section-title" style="margin-left:0;">불참 / 미정</div>
		<div id="otherList"></div>
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

function fmtDate(iso) {
	const d = new Date(iso + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 (' + dow + ')';
}

async function loadInfo() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID);
	if (!r.ok) { alert('일정을 불러올 수 없습니다.'); return; }
	const s = r.schedule;
	$('#dDate').text(fmtDate(s.matchDate));
	$('#dTitle').text(s.title);
	let meta = '⏰ ' + s.startTime.slice(0,5) + (s.endTime ? ' ~ ' + s.endTime.slice(0,5) : '');
	if (s.place) meta += ' · 📍 ' + s.place;
	$('#dMeta').text(meta);
	$('#dFee').text(s.fee > 0 ? '💰 참가비 ' + won(s.fee) : '');
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

	// 포지션별
	const pb = $('#posBy').empty();
	['GK','DF','MF','FW'].forEach(p => {
		pb.append('<span class="chip">' + posBadge(p) + ' ' + (sm.byPosition[p] || 0) + '명</span>');
	});

	// 참석자
	const al = $('#attendList').empty();
	if (!sm.attendList.length) al.html('<div class="muted small" style="padding:8px 0;">아직 참석자가 없습니다.</div>');
	sm.attendList.forEach(m => al.append(memberRow(m, true)));

	// 불참/미정
	const ol = $('#otherList').empty();
	const others = sm.absentList.map(m => ({...m, _t:'불참'})).concat(sm.pendingList.map(m => ({...m, _t:'미정'})));
	if (!others.length) ol.html('<div class="muted small" style="padding:8px 0;">없음</div>');
	others.forEach(m => {
		ol.append('<div class="member-row"><span>' + posBadge(m.position) + '</span><span class="name">' + esc(m.nickname) +
			'</span><span class="right small muted">' + m._t + '</span></div>');
	});
}

function memberRow(m, withPaid) {
	let right = '';
	if (withPaid) {
		const tag = m.paid ? '<span class="paid-tag paid-yes">납부</span>' : '<span class="paid-tag paid-no">미납</span>';
		if (CAN_MANAGE) {
			right = '<button class="btn-ghost btn-sm paidToggle" data-uid="' + m.userId + '" data-paid="' + m.paid + '">' +
				(m.paid ? '납부취소' : '납부확인') + '</button>';
		} else {
			right = tag;
		}
	}
	return '<div class="member-row"><span>' + posBadge(m.position) + '</span><span class="name">' + esc(m.nickname) +
		'</span><span class="right">' + right + '</span></div>';
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
	loadInfo();
	loadAttendance();
	loadComments();

	$('#attendBtns .att-btn').on('click', async function () {
		const s = $(this).data('s');
		const r = await api.post('/api/attendance', { scheduleId: SCHEDULE_ID, status: s });
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});

	$('#attendList').on('click', '.paidToggle', async function () {
		const uid = $(this).data('uid');
		const paid = !($(this).data('paid') === true || $(this).data('paid') === 'true');
		const r = await api.post('/api/attendance/paid', { scheduleId: SCHEDULE_ID, userId: uid, paid: paid });
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
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
});
</script>
</body>
</html>
