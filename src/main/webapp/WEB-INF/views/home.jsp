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

	<div style="padding:2px 4px 6px;">
		<div class="muted small">반가워요 👋</div>
		<div style="font-size:21px;font-weight:800;letter-spacing:-.3px;">${user.nickname}님</div>
	</div>

	<div class="section-title">가장 가까운 경기</div>

	<c:choose>
		<c:when test="${nearest != null}">
			<div class="card" id="nearestCard" data-id="${nearest.id}" style="padding:20px;">
				<div class="dday-row">
					<span class="dday-badge" id="dday">⚽ -</span>
					<span class="muted small" id="nearestDate"></span>
				</div>
				<div class="title" style="font-size:21px;font-weight:800;margin:12px 0;line-height:1.3;">${nearest.title}</div>

				<div class="info-grid">
					<div class="info-cell"><span class="ic">⏰</span><span>${nearest.startTime}<c:if test="${nearest.endTime != null}"> ~ ${nearest.endTime}</c:if></span></div>
					<c:if test="${nearest.place != null}"><div class="info-cell"><span class="ic">📍</span><span>${nearest.place}</span></div></c:if>
					<div class="info-cell"><span class="ic">👥</span><span id="iAttend">-</span></div>
					<div class="info-cell" id="iShortCell" style="display:none;color:var(--red);font-weight:700;"><span class="ic">⚠️</span><span id="iShort"></span></div>
				</div>

				<div id="progressWrap" style="display:none;margin-top:16px;">
					<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
						<span class="small" style="font-weight:700;">참석 진행률</span>
						<span class="small muted" id="progressText"></span>
					</div>
					<div class="stat-bar"><i id="progressBar" style="width:0;"></i></div>
					<div id="shortMsg" class="prog-msg"></div>
				</div>

				<div class="att-summary" id="homeSummary" style="margin-top:18px;">
					<div class="box attend" data-acc="attend"><div class="num" id="hsAttend">-</div><div class="lbl">참석 ▾</div></div>
					<div class="box absent" data-acc="absent"><div class="num" id="hsAbsent">-</div><div class="lbl">불참 ▾</div></div>
					<div class="box pending" data-acc="pending"><div class="num" id="hsPending">-</div><div class="lbl">미정 ▾</div></div>
				</div>
				<div class="acc-list" id="accList" style="display:none;"></div>

				<div class="attend-buttons" id="homeAttendBtns" style="margin-top:16px;">
					<button class="att-btn attend" data-s="ATTEND">✅ 참석</button>
					<button class="att-btn absent" data-s="ABSENT">❌ 불참</button>
					<button class="att-btn pending" data-s="PENDING">❓ 미정</button>
				</div>

				<a href="/team/${team.id}/schedule/${nearest.id}" class="btn-ghost btn-block" style="margin-top:16px;text-align:center;">자세히 보기 →</a>
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
	<a href="/matches" class="card" style="display:flex;align-items:center;gap:12px;background:linear-gradient(135deg,#1a9d52,#0f5e31);color:#fff;">
		<span style="font-size:28px;">⚔️</span>
		<span style="flex:1;"><strong>팀 매칭 찾기</strong><div class="small" style="opacity:.9;">지역별 친선경기 모집 · 신청</div></span>
		<span style="font-size:20px;opacity:.8;">›</span>
	</a>
</div>

<%@ include file="layout/bottomnav.jsp" %>

<c:if test="${nearest != null}">
<script>
const SCHEDULE_ID = ${nearest.id};
const TARGET = ${nearest.targetHeadcount};
const MATCH_DATE = '${nearest.matchDate}';
let summaryData = null, accOpen = null;

function fmtDate(iso) {
	const d = new Date(iso + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 (' + dow + ')';
}
function ddayInfo(iso) {
	const today = new Date(); today.setHours(0,0,0,0);
	const d = new Date(iso + 'T00:00:00');
	const diff = Math.round((d - today) / 86400000);
	if (diff === 0) return { t: '오늘 경기', cls: 'dday-today' };
	if (diff < 0) return { t: '경기 종료', cls: 'dday-past' };
	return { t: 'D-' + diff, cls: diff <= 1 ? 'dday-soon' : '' };
}

async function loadHome() {
	const r = await api.get('/api/attendance/list?scheduleId=' + SCHEDULE_ID);
	if (!r.ok) return;
	const sm = r.summary; summaryData = sm;
	const att = sm.attend;
	const guests = sm.guestCount || 0;
	const total = att + guests;       // 실제 모인 인원(참석 + 용병)
	$('#hsAttend').text(sm.attend); $('#hsAbsent').text(sm.absent); $('#hsPending').text(sm.pending);
	$('#iAttend').text('참석 ' + att + '명' + (guests > 0 ? ' + 용병 ' + guests : '') + (TARGET > 0 ? ' / 최소 ' + TARGET : ''));
	$('#homeAttendBtns .att-btn').removeClass('on');
	$('#homeAttendBtns .att-btn[data-s="' + r.myStatus + '"]').addClass('on');

	// 진행률(참석+용병 vs 최소 필요 인원) + 부족/성원완료
	if (TARGET > 0) {
		const pct = Math.min(100, Math.round(total / TARGET * 100));
		$('#progressWrap').show();
		$('#progressBar').css('width', pct + '%');
		$('#progressText').text(total + ' / ' + TARGET + '명' + (guests > 0 ? ' (용병 ' + guests + ' 포함)' : '') + ' · ' + pct + '%');
		if (total < TARGET) {
			const short = TARGET - total;
			$('#shortMsg').text('⚠️ 현재 ' + short + '명 부족').removeClass('ok').addClass('short');
			$('#progressBar').css('background', 'linear-gradient(90deg,#e08a16,#e0454f)');
			$('#iShortCell').show(); $('#iShort').text(short + '명 부족');
		} else {
			$('#shortMsg').text('✅ 성원 완료').removeClass('short').addClass('ok');
			$('#progressBar').css('background', '');
			$('#iShortCell').hide();
		}
	} else { $('#progressWrap').hide(); $('#iShortCell').hide(); }

	if (accOpen) renderAcc(accOpen);
}

function renderAcc(type) {
	const list = type === 'attend' ? summaryData.attendList : type === 'absent' ? summaryData.absentList : summaryData.pendingList;
	const label = type === 'attend' ? '참석' : type === 'absent' ? '불참' : '미정';
	const box = $('#accList');
	if (!list || !list.length) { box.html('<div class="muted small" style="padding:10px;">' + label + ' 인원이 없습니다.</div>').show(); return; }
	let html = '';
	list.forEach(m => html += '<div class="acc-row"><span class="name">' + esc(m.nickname) + '</span></div>');
	box.html(html).show();
}

$(function () {
	$('#nearestDate').text(fmtDate(MATCH_DATE));
	const dd = ddayInfo(MATCH_DATE);
	$('#dday').text('⚽ ' + dd.t).addClass(dd.cls);
	loadHome();

	$('#homeSummary .box').on('click', function () {
		const type = $(this).data('acc');
		$('#homeSummary .box').removeClass('sel');
		if (accOpen === type) { accOpen = null; $('#accList').hide(); return; }
		accOpen = type; $(this).addClass('sel'); renderAcc(type);
	});

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
