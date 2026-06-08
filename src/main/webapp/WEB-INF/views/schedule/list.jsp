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

	<div class="section-title">다가오는 일정</div>
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
				<div><label>시작시간</label><input type="text" id="schStart" required></div>
				<div><label>종료시간</label><input type="text" id="schEnd"></div>
			</div>
			<label>장소</label>
			<input type="text" id="schPlace" maxlength="120" placeholder="예: 잠실 풋살장 A구장">
			<label>목표 인원 (선택)</label>
			<input type="number" id="schTarget" min="0" value="0" placeholder="예: 12 (진행률·부족 인원 표시)">
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
const TEAM_NAME = "${team.name}";
const CAN_MANAGE = ${canManage};
let cur = new Date();
cur.setDate(1);

function fmtWhen(s) {
	const d = new Date(s.matchDate + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일(' + dow + ') ' + s.startTime.slice(0, 5);
}
function offerShare(s) {
	const url = location.origin + '/team/' + TEAM_ID + '/schedule/' + s.id;
	if (confirm('✅ 일정이 등록되었습니다.\n\n카카오톡 단톡방에 공유해서 팀원들이 참석 투표하게 할까요?')) {
		kakaoShareSchedule({ teamName: TEAM_NAME, title: s.title, when: fmtWhen(s), place: s.place, url: url });
	}
}

function pad(n) { return n < 10 ? '0' + n : '' + n; }
function fmtMonthLabel(d) { return d.getFullYear() + '년 ' + (d.getMonth() + 1) + '월'; }

async function loadMonth() {
	const y = cur.getFullYear(), m = cur.getMonth() + 1;
	$('#calLabel').text(fmtMonthLabel(cur));
	const r = await api.get('/api/schedule/list?teamId=' + TEAM_ID + '&year=' + y + '&month=' + m);
	const schedules = r.ok ? r.schedules : [];
	renderCalendar(y, m, schedules);
}

// 달력과 별개로, 다가오는 일정(오늘 이후)을 월에 상관없이 전부 표시
async function loadUpcoming() {
	const r = await api.get('/api/schedule/list?teamId=' + TEAM_ID);
	const all = r.ok ? r.schedules : [];
	renderList(all.filter(s => !s.isPast));
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
	if (!schedules.length) { box.html('<div class="empty">예정된 일정이 없습니다.</div>'); return; }
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
	$('#schTarget').val(s ? s.targetHeadcount : 0);
	$('#schMemo').val(s ? (s.memo || '') : '');
	$('#schDelete').toggle(!!s);
	$('#schModal').addClass('open');
}
function closeModal() { $('#schModal').removeClass('open'); }

$(function () {
	loadMonth();
	loadUpcoming();
	$('#prevMonth').on('click', () => { cur.setMonth(cur.getMonth() - 1); loadMonth(); });
	$('#nextMonth').on('click', () => { cur.setMonth(cur.getMonth() + 1); loadMonth(); });
	if (CAN_MANAGE) {
		bindTime('#schStart'); bindTime('#schEnd');
		$('#addBtn').on('click', () => openModal(null));
		$('#schCancel').on('click', closeModal);
		$('#schModal').on('click', e => { if (e.target.id === 'schModal') closeModal(); });
		$('#schForm').on('submit', async function (e) {
			e.preventDefault();
			const id = $('#schId').val();
			if (!validTime($('#schStart').val())) { alert('시작시간을 HH:MM 형식으로 입력해주세요. 예: 20:00'); return; }
			if ($('#schEnd').val() && !validTime($('#schEnd').val())) { alert('종료시간을 HH:MM 형식으로 입력해주세요.'); return; }
			const body = {
				title: $('#schTitle').val().trim(),
				matchDate: $('#schDate').val(),
				startTime: $('#schStart').val(),
				endTime: $('#schEnd').val() || null,
				place: $('#schPlace').val().trim(),
				targetHeadcount: parseInt($('#schTarget').val() || '0', 10),
				memo: $('#schMemo').val().trim()
			};
			const r = id
				? await api.put('/api/schedule/' + id, body)
				: await api.post('/api/schedule?teamId=' + TEAM_ID, body);
			if (r.ok) {
				closeModal();
				loadMonth(); loadUpcoming();
				if (!id && r.schedule) offerShare(r.schedule);  // 새 등록만 공유 제안
			} else alert(r.message || '저장 실패');
		});
		$('#schDelete').on('click', async function () {
			const id = $('#schId').val();
			if (!id || !confirm('이 일정을 삭제할까요?')) return;
			const r = await api.del('/api/schedule/' + id);
			if (r.ok) { closeModal(); loadMonth(); loadUpcoming(); } else alert(r.message || '삭제 실패');
		});
	}
});
</script>
</body>
</html>
