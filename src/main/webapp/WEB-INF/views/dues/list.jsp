<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 회비 관리</title>
	<%@ include file="../layout/head.jsp" %>
	<style>
		.dues-monthbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
		.dues-monthbar button { background: #f5f6f8; border: 1px solid var(--line); width: 38px; height: 38px; border-radius: 10px; font-size: 18px; cursor: pointer; color: var(--text); }
		.dues-monthbar strong { font-size: 18px; }
		.dues-sum { display: flex; gap: 8px; text-align: center; margin-bottom: 14px; }
		.dues-sum .box { flex: 1; padding: 14px 0; border-radius: 12px; background: #f5f6f8; border: 1px solid var(--line); }
		.dues-sum .box .num { font-size: 23px; font-weight: 800; line-height: 1.1; }
		.dues-sum .box.paid { background: var(--green-soft); border-color: #d8efe0; }
		.dues-sum .box.paid .num { color: var(--green); }
		.dues-sum .box .lbl { font-size: 12px; color: var(--muted); margin-top: 2px; }
		.pay-btn { flex: 0 0 auto; padding: 8px 15px; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; border: 1px solid var(--line-strong); background: #fff; color: var(--muted); transition: all .12s; }
		.pay-btn.on { background: var(--green); border-color: var(--green); color: #fff; }
		.mem-sub { font-size: 12px; color: var(--muted); margin-left: 7px; font-weight: 500; }
	</style>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div style="display:flex;align-items:center;margin-bottom:4px;">
		<a href="/team/${team.id}" class="small muted">‹ 팀 홈</a>
	</div>

	<div class="section-title" style="margin-top:14px;">💰 회비 관리</div>
	<div class="muted small" style="margin:-4px 4px 12px;">총무가 계좌 입금을 확인하고 납부 버튼으로 체크합니다.</div>

	<div class="card">
		<div class="dues-monthbar">
			<button id="prevM" aria-label="이전 달">‹</button>
			<strong id="monthLabel">—</strong>
			<button id="nextM" aria-label="다음 달">›</button>
		</div>
		<div class="dues-sum">
			<div class="box paid"><div class="num" id="paidNum">0</div><div class="lbl">납부 완료</div></div>
			<div class="box"><div class="num" id="unpaidNum">0</div><div class="lbl">미납</div></div>
			<div class="box"><div class="num" id="totalNum">0</div><div class="lbl">전체</div></div>
		</div>
		<div id="memberList"><div class="empty">불러오는 중...</div></div>
	</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
let curPeriod = null; // 'YYYY-MM'

function fmtMonth(p) {
	const [y, m] = p.split('-');
	return y + '년 ' + parseInt(m, 10) + '월';
}
function shiftMonth(p, delta) {
	let [y, m] = p.split('-').map(n => parseInt(n, 10));
	m += delta;
	while (m < 1) { m += 12; y--; }
	while (m > 12) { m -= 12; y++; }
	return y + '-' + String(m).padStart(2, '0');
}

async function load() {
	const q = curPeriod ? ('?period=' + curPeriod) : '';
	const r = await api.get('/api/team/' + TEAM_ID + '/dues' + q);
	if (!r.ok) { alert(r.message || '불러오기 실패'); return; }
	curPeriod = r.period;
	$('#monthLabel').text(fmtMonth(curPeriod));

	const paid = r.members.filter(m => m.paid).length;
	$('#paidNum').text(paid);
	$('#unpaidNum').text(r.total - paid);
	$('#totalNum').text(r.total);

	const box = $('#memberList').empty();
	if (!r.members.length) { box.html('<div class="empty">팀원이 없습니다.</div>'); return; }
	r.members.forEach(m => {
		const btn = m.paid
			? '<button class="pay-btn on" data-uid="' + m.userId + '">납부완료 ✓</button>'
			: '<button class="pay-btn" data-uid="' + m.userId + '">납부</button>';
		box.append('<div class="member-row">' +
			'<span class="name">' + esc(m.nickname) + '<span class="mem-sub">' + esc(m.membershipLabel) + '</span></span>' +
			'<span class="right">' + btn + '</span></div>');
	});
}

$(function () {
	load();
	$('#prevM').on('click', function () { curPeriod = shiftMonth(curPeriod, -1); load(); });
	$('#nextM').on('click', function () { curPeriod = shiftMonth(curPeriod, 1); load(); });
	$('#memberList').on('click', '.pay-btn', async function () {
		const uid = $(this).data('uid');
		const willPay = !$(this).hasClass('on');
		const r = await api.post('/api/team/' + TEAM_ID + '/dues',
			{ userId: uid, period: curPeriod, paid: willPay });
		if (r.ok) load(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
