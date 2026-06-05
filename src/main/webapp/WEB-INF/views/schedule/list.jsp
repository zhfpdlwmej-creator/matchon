<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="schedule" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 일정</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="card">
		<div class="cal-head">
			<button id="prevMonth">‹</button>
			<strong id="calLabel">-</strong>
			<button id="nextMonth">›</button>
		</div>
		<div class="cal-grid" id="calGrid"></div>
	</div>

	<div class="section-title">이번 달 일정</div>
	<div id="scheduleList"><div class="empty">불러오는 중...</div></div>
</div>

<c:if test="${canManage}">
	<a class="fab" id="addBtn" href="javascript:void(0)">＋</a>
</c:if>

<%@ include file="../layout/bottomnav.jsp" %>

<!-- 일정 등록/수정 모달 -->
<div class="modal-back" id="schModal">
	<div class="modal">
		<h3 id="schModalTitle">경기 일정 등록</h3>
		<form id="schForm" class="card-form" style="padding:0;">
			<input type="hidden" id="schId">
			<label>경기명</label>
			<input type="text" id="schTitle" maxlength="60" placeholder="예: FC 챔피언스 vs FC 드림" required>
			<div class="row-2">
				<div><label>날짜</label><input type="date" id="schDate" required></div>
			</div>
			<div class="row-2">
				<div><label>시작시간</label><input type="time" id="schStart" required></div>
				<div><label>종료시간</label><input type="time" id="schEnd"></div>
			</div>
			<label>장소</label>
			<input type="text" id="schPlace" maxlength="120" placeholder="예: 잠실 풋살장 A구장">
			<label>구장비용 총액 (원)</label>
			<input type="number" id="schFee" min="0" step="1000" value="0" placeholder="예: 60000 (참석 인원으로 자동 분배)">
			<div class="muted small" style="margin-top:4px;">구장 대여비 총액을 입력하면, 참석 인원으로 나눠 <b>인당 금액</b>이 자동 계산됩니다.</div>
			<label>메모</label>
			<textarea id="schMemo" maxlength="500" placeholder="준비물, 주차 안내 등"></textarea>
			<div class="row-2" style="margin-top:14px;">
				<button type="button" class="btn-ghost" id="schCancel">취소</button>
				<button type="submit" class="btn-primary">저장</button>
			</div>
			<button type="button" class="btn-ghost btn-block" id="schDelete" style="margin-top:8px;display:none;color:var(--red);">일정 삭제</button>
		</form>
	</div>
</div>

<script>
const TEAM_ID = ${team.id};
const CAN_MANAGE = ${canManage};
let cur = new Date();
cur.setDate(1);

function pad(n) { return n < 10 ? '0' + n : '' + n; }
function fmtMonthLabel(d) { return d.getFullYear() + '년 ' + (d.getMonth() + 1) + '월'; }

async function loadMonth() {
	const y = cur.getFullYear(), m = cur.getMonth() + 1;
	$('#calLabel').text(fmtMonthLabel(cur));
	const r = await api.get('/api/schedule/list?teamId=' + TEAM_ID + '&year=' + y + '&month=' + m);
	const schedules = r.ok ? r.schedules : [];
	renderCalendar(y, m, schedules);
	renderList(schedules);
}

function renderCalendar(y, m, schedules) {
	const grid = $('#calGrid').empty();
	['일','월','화','수','목','금','토'].forEach(d => grid.append('<div class="dow">' + d + '</div>'));
	const first = new Date(y, m - 1, 1);
	const startDow = first.getDay();
	const days = new Date(y, m, 0).getDate();
	const byDay = {};
	schedules.forEach(s => { const d = parseInt(s.matchDate.split('-')[2], 10); (byDay[d] = byDay[d] || []).push(s); });
	const todayStr = new Date().toISOString().slice(0, 10);
	for (let i = 0; i < startDow; i++) grid.append('<div class="cal-cell muted-day"></div>');
	for (let d = 1; d <= days; d++) {
		const ds = y + '-' + pad(m) + '-' + pad(d);
		const has = byDay[d];
		let cls = 'cal-cell' + (has ? ' has' : '') + (ds === todayStr ? ' today' : '');
		const cell = $('<div class="' + cls + '">' + d + (has ? '<span class="dot"></span>' : '') + '</div>');
		if (has) cell.on('click', () => location.href = '/team/' + TEAM_ID + '/schedule/' + has[0].id);
		grid.append(cell);
	}
}

function renderList(schedules) {
	const box = $('#scheduleList').empty();
	if (!schedules.length) { box.html('<div class="empty">이번 달 일정이 없습니다.</div>'); return; }
	schedules.forEach(s => {
		const dow = ['일','월','화','수','목','금','토'][new Date(s.matchDate + 'T00:00:00').getDay()];
		const d = s.matchDate.split('-');
		box.append(
			'<a class="schedule-item ' + (s.isPast ? 'past' : '') + '" href="/team/' + TEAM_ID + '/schedule/' + s.id + '">' +
			'<div class="date">' + parseInt(d[1]) + '월 ' + parseInt(d[2]) + '일 (' + dow + ')</div>' +
			'<div class="title">' + esc(s.title) + '</div>' +
			'<div class="meta">⏰ ' + s.startTime.slice(0,5) + (s.place ? ' · 📍 ' + esc(s.place) : '') + '</div>' +
			'</a>');
	});
}

// 모달 제어
function openModal(s) {
	$('#schModalTitle').text(s ? '경기 일정 수정' : '경기 일정 등록');
	$('#schId').val(s ? s.id : '');
	$('#schTitle').val(s ? s.title : '');
	$('#schDate').val(s ? s.matchDate : '');
	$('#schStart').val(s ? s.startTime.slice(0,5) : '');
	$('#schEnd').val(s && s.endTime ? s.endTime.slice(0,5) : '');
	$('#schPlace').val(s ? (s.place || '') : '');
	$('#schFee').val(s ? s.fee : 0);
	$('#schMemo').val(s ? (s.memo || '') : '');
	$('#schDelete').toggle(!!s);
	$('#schModal').addClass('open');
}
function closeModal() { $('#schModal').removeClass('open'); }

$(function () {
	loadMonth();
	$('#prevMonth').on('click', () => { cur.setMonth(cur.getMonth() - 1); loadMonth(); });
	$('#nextMonth').on('click', () => { cur.setMonth(cur.getMonth() + 1); loadMonth(); });
	if (CAN_MANAGE) {
		$('#addBtn').on('click', () => openModal(null));
		$('#schCancel').on('click', closeModal);
		$('#schModal').on('click', e => { if (e.target.id === 'schModal') closeModal(); });
		$('#schForm').on('submit', async function (e) {
			e.preventDefault();
			const id = $('#schId').val();
			const body = {
				title: $('#schTitle').val().trim(),
				matchDate: $('#schDate').val(),
				startTime: $('#schStart').val(),
				endTime: $('#schEnd').val() || null,
				place: $('#schPlace').val().trim(),
				fee: parseInt($('#schFee').val() || '0', 10),
				memo: $('#schMemo').val().trim()
			};
			const r = id
				? await api.put('/api/schedule/' + id, body)
				: await api.post('/api/schedule?teamId=' + TEAM_ID, body);
			if (r.ok) { closeModal(); loadMonth(); } else alert(r.message || '저장 실패');
		});
		$('#schDelete').on('click', async function () {
			const id = $('#schId').val();
			if (!id || !confirm('이 일정을 삭제할까요?')) return;
			const r = await api.del('/api/schedule/' + id);
			if (r.ok) { closeModal(); loadMonth(); } else alert(r.message || '삭제 실패');
		});
	}
});
</script>
</body>
</html>
