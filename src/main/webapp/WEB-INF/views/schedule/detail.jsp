<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="schedule" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 경기 상세</title>
	<%@ include file="../layout/head.jsp" %>
	<c:if test="${not empty kakaoJsKey}">
		<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoJsKey}&libraries=services&autoload=false"></script>
	</c:if>
	<style>
		.wdl-btns { display: flex; gap: 8px; }
		.wdl-btn { flex: 1; padding: 15px 0; border: 1px solid var(--line); border-radius: 12px; background: #fff; font-size: 17px; font-weight: 800; color: var(--muted); cursor: pointer; transition: all .12s; }
		.wdl-btn.on.win { background: var(--green); color: #fff; border-color: var(--green); }
		.wdl-btn.on.draw { background: #9aa3a0; color: #fff; border-color: #9aa3a0; }
		.wdl-btn.on.loss { background: var(--red); color: #fff; border-color: var(--red); }
	</style>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div style="display:flex;align-items:center;">
		<a href="/team/${team.id}/schedules" class="small muted">‹ 일정 목록</a>
		<c:if test="${canManage}">
			<a href="javascript:void(0)" id="delSchedBtn" class="small" style="margin-left:auto;color:var(--red);">🗑 삭제</a>
		</c:if>
	</div>

	<div class="card" id="infoCard" style="margin-top:8px;">
		<div class="date" id="dDate" style="color:var(--green);font-weight:700;"></div>
		<div class="title" id="dTitle" style="font-size:20px;font-weight:800;margin:4px 0;"></div>
		<div class="meta muted small" id="dMeta"></div>
		<div class="meta small" id="dMemo" style="margin-top:8px;white-space:pre-wrap;"></div>
		<button class="btn-primary btn-block" id="shareBtn" style="margin-top:14px;">📢 카카오톡으로 일정 공유</button>
		<button class="btn-ghost btn-block" id="locBtn" style="margin-top:8px;display:none;">📍 위치 확인</button>
		<div id="schMap" style="width:100%;height:220px;border-radius:12px;margin-top:8px;display:none;"></div>
		<a href="/team/${team.id}/schedule/${scheduleId}/formation" id="formationBtn" class="btn-ghost btn-block" style="margin-top:8px;text-align:center;"><c:choose><c:when test="${canManage}">📋 포메이션 짜기</c:when><c:otherwise>📋 포메이션 보기</c:otherwise></c:choose></a>
		<button class="btn-ghost btn-block" id="recruitBtn" style="margin-top:8px;display:none;color:var(--red);"></button>
	</div>

	<c:if test="${canManage}">
		<div class="card" id="rateCard" style="display:none;">
			<h3>상대팀 매너 평가 · <span id="rateOpp"></span></h3>
			<div class="muted small" id="rateOppManner" style="margin-bottom:4px;"></div>
			<div id="starPick" style="font-size:40px;text-align:center;margin:8px 0;letter-spacing:8px;color:#f5b301;cursor:pointer;user-select:none;">
				<span data-v="1">☆</span><span data-v="2">☆</span><span data-v="3">☆</span><span data-v="4">☆</span><span data-v="5">☆</span>
			</div>
			<input type="hidden" id="mannerVal">
			<button class="btn-primary btn-block" id="rateBtn">평가 저장</button>
		</div>
		<div class="card muted small" id="ratedNote" style="display:none;text-align:center;">상대팀 평가를 완료했습니다. 🙏</div>
	</c:if>

	<!-- 경기 종료 후: 결과 입력/확인 (접기/펼치기) -->
	<div class="card" id="resultCard" style="display:none;">
		<h3 id="resultHead" style="cursor:pointer;display:flex;align-items:center;margin:0;">📊 경기 결과 <span class="muted small" style="font-weight:400;margin-left:6px;">경기 종료 후 입력</span><span id="resultCaret" style="margin-left:auto;color:var(--muted);">▾</span></h3>
		<div id="resultBody" style="display:none;margin-top:12px;">
			<div id="outcomeView" style="text-align:center;font-size:26px;font-weight:900;margin:0 0 12px;"></div>
			<c:if test="${canManage}">
				<div class="wdl-btns">
					<button type="button" class="wdl-btn win" data-o="W">승</button>
					<button type="button" class="wdl-btn draw" data-o="D">무</button>
					<button type="button" class="wdl-btn loss" data-o="L">패</button>
				</div>
				<div class="muted small" style="text-align:center;margin-top:6px;">버튼을 누르면 바로 저장됩니다.</div>
			</c:if>

			<div class="section-title" style="margin-left:0;">👑 MOM 투표</div>
			<div id="momList"></div>
			<div style="display:flex;gap:6px;margin-top:8px;">
				<select id="msSel" style="flex:1;min-width:0;padding:9px;border:1px solid var(--line);border-radius:10px;"></select>
				<button class="btn-primary btn-sm" id="voteMom" style="white-space:nowrap;flex-shrink:0;">투표</button>
			</div>
		</div>
	</div>

	<div class="card" id="attendCard">
		<h3>내 참석 여부</h3>
		<div class="attend-buttons" id="attendBtns">
			<button class="att-btn attend" data-s="ATTEND">✅ 참석</button>
			<button class="att-btn absent" data-s="ABSENT">❌ 불참</button>
			<button class="att-btn pending" data-s="PENDING">❓ 미정</button>
		</div>
		<div id="limitStatus" class="small" style="margin-top:10px;text-align:center;"></div>
	</div>

	<div class="card" id="attendStatusCard">
		<h3>참석 현황</h3>
		<div class="att-summary">
			<div class="box attend"><div class="num" id="sAttend">-</div><div class="lbl">참석</div></div>
			<div class="box absent"><div class="num" id="sAbsent">-</div><div class="lbl">불참</div></div>
			<div class="box pending"><div class="num" id="sPending">-</div><div class="lbl">미정</div></div>
		</div>

		<div class="section-title" style="margin-left:0;">참석자</div>
		<div id="attendList"></div>
		<div class="section-title" id="waitTitle" style="margin-left:0;display:none;">🕒 예비 (대기)</div>
		<div id="waitList"></div>
		<div class="section-title" style="margin-left:0;">불참 / 미정</div>
		<div id="otherList"></div>
	</div>

	<div class="card" id="feeCard" style="display:none;">
		<h3>💰 회비 정산</h3>
		<div id="feeSummary" class="small" style="margin-bottom:8px;"></div>
		<div id="feeList"></div>
	</div>

	<div class="card" id="guestCard">
		<h3>용병 <span class="muted small" id="guestSum"></span></h3>
		<div class="muted small" style="margin-bottom:8px;">팀원이 아닌 외부 참석 인원을 추가해 정확히 집계해요.</div>
		<div id="guestList"></div>
		<div class="comment-input" style="margin-top:10px;">
			<input type="text" id="guestName" maxlength="40" placeholder="용병 이름 (예: 철수 지인)" style="flex:2;">
			<input type="number" id="guestCount" min="1" value="1" style="flex:1;min-width:0;" title="인원수">
			<button class="btn-primary btn-sm" id="guestAdd">＋ 추가</button>
		</div>
	</div>

	<div class="card" id="commentCard">
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
const TEAM_NAME = "${fn:escapeXml(team.name)}";
let isPast = false; // 경기 종료 여부
let sched = null;   // 현재 일정 (공유용)
let attendeePool = []; // MOM 투표 후보(참석자)
let myAtt = 'PENDING'; // 내 현재 참석 상태
let curLimit = false;  // 선착순 마감 사용 여부
let lastFull = false;  // 현재 정원 마감 여부

function fmtDate(iso) {
	const d = new Date(iso + 'T00:00:00');
	const dow = ['일','월','화','수','목','금','토'][d.getDay()];
	return (d.getMonth() + 1) + '월 ' + d.getDate() + '일 (' + dow + ')';
}

async function loadInfo() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID);
	if (!r.ok) { alert('일정을 불러올 수 없습니다.'); return; }
	const s = r.schedule;
	sched = s;
	$('#dDate').text(fmtDate(s.matchDate));
	$('#dTitle').text(s.title);
	let meta = '⏰ ' + s.startTime.slice(0,5) + (s.endTime ? ' ~ ' + s.endTime.slice(0,5) : '');
	if (s.place) meta += ' · 📍 ' + s.place;
	$('#dMeta').text(meta);
	isPast = !!s.isPast;
	$('#shareBtn').toggle(!isPast);   // 지난 경기엔 일정 공유 숨김
	$('#formationBtn').toggle(!isPast);   // 지난 경기엔 포메이션 버튼 숨김
	// 지난 경기: 참석/현황/용병/댓글 숨기고 결과·평가에 집중
	$('#attendCard, #attendStatusCard, #guestCard, #commentCard').toggle(!isPast);
	$('#dMemo').text(s.memo || '');
	$('#locBtn').toggle(s.lat != null || !!s.place);
	loadRating();
}

async function loadRating() {
	if (!isPast || !CAN_MANAGE || !sched || !sched.matchPostId) return; // 경기 종료 후에만
	const r = await api.get('/api/match/' + sched.matchPostId + '/rate-info');
	if (!r.ok) return;
	$('#rateOpp').text(sched.opponentName || r.targetTeamName || '상대팀');
	if (r.targetMannerAvg != null) $('#rateOppManner').html('상대팀 현재 매너: <b style="color:#b8860b;">' + r.targetMannerAvg + '★</b> (' + r.targetMannerCount + '회)');
	if (r.canRate) $('#rateCard').show();
	else if (r.alreadyRated) $('#ratedNote').show();
}

let mapReady2 = false, kmap2, kmarker2;
function showSchMap() {
	if (!window.kakao || !kakao.maps) { alert('지도를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'); return; }
	kakao.maps.load(function () {
		if (!mapReady2) {
			kmap2 = new kakao.maps.Map(document.getElementById('schMap'), { center: new kakao.maps.LatLng(37.5145, 127.1066), level: 4 });
			kmarker2 = new kakao.maps.Marker(); kmarker2.setMap(kmap2);
			mapReady2 = true;
		}
		kmap2.relayout();
		if (sched && sched.lat != null) {
			const ll = new kakao.maps.LatLng(sched.lat, sched.lng);
			kmap2.setCenter(ll); kmarker2.setPosition(ll);
		} else if (sched && sched.place && kakao.maps.services) {
			const ps = new kakao.maps.services.Places();
			ps.keywordSearch(sched.place, function (data, status) {
				if (status === kakao.maps.services.Status.OK && data.length) {
					const f = data[0], ll = new kakao.maps.LatLng(f.y, f.x);
					kmap2.setCenter(ll); kmarker2.setPosition(ll);
				}
			});
		}
	});
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

	// 인원 부족 → 용병 모집글 버튼 (팀장/운영진)
	const target = sched ? sched.targetHeadcount : 0;
	const filled = sm.attend + (sm.guestCount || 0);
	const shortage = target - filled;
	if (CAN_MANAGE && shortage > 0 && !isPast) $('#recruitBtn').show().text('🆘 용병 ' + shortage + '명 모집글 올리기');
	else $('#recruitBtn').hide();

	// 선착순 마감 / 예비(대기) 상태
	myAtt = r.myStatus;
	curLimit = !!(sched && sched.limitAttendance && target > 0);
	lastFull = curLimit && (filled >= target);
	const wl = sm.waitlistList || [];
	if (curLimit) {
		const left = target - filled;
		let html = left > 0
			? '🔒 선착순 · <b>' + filled + ' / ' + target + '</b>명 (남은 자리 ' + left + ')'
			: '🔒 <b style="color:var(--red);">정원 마감</b> (' + filled + ' / ' + target + '명)';
		if (wl.length) html += ' · 예비 ' + wl.length + '명';
		if (myAtt === 'WAITLIST') {
			const pos = wl.findIndex(m => m.userId === MY_ID) + 1;
			html += '<br><b style="color:var(--amber);">🕒 예비 ' + (pos || '') + '번 대기 중 — 자리가 나면 자동 참석됩니다.</b>';
		}
		$('#limitStatus').html(html);
		$('#attendBtns .att-btn.attend').css('opacity', (left > 0 || myAtt === 'WAITLIST') ? '1' : '.5');
	} else $('#limitStatus').empty();

	// 회비 정산 (구장비 / 참여 인원)
	const fee = sched ? sched.fee : 0;
	const partTotal = sm.attend + (sm.guestCount || 0);
	if (fee > 0 && partTotal > 0) {
		$('#feeCard').show();
		const per = Math.ceil(fee / partTotal / 100) * 100;
		let paidCnt = 0;
		const fl = $('#feeList').empty();
		(sm.attendList || []).forEach(function (m) {
			if (m.paid) paidCnt++;
			const tog = CAN_MANAGE ? '<a href="javascript:void(0)" class="paidBtn muted small" data-uid="' + m.userId + '" data-on="' + (m.paid ? 1 : 0) + '">' + (m.paid ? '납부취소' : '납부확인') + '</a>' : '';
			fl.append('<div class="member-row"><span class="name">' + (m.paid ? '✅ ' : '') + esc(m.nickname) + '</span><span class="right">' + (m.paid ? '<span class="muted small">납부</span>' : '<span class="small" style="color:var(--red);">미납</span>') + ' ' + tog + '</span></div>');
		});
		$('#feeSummary').html('총 <b>' + fee.toLocaleString() + '원</b> · ' + partTotal + '명 → 인당 <b style="color:var(--green);">' + per.toLocaleString() + '원</b> · 납부 ' + paidCnt + '/' + (sm.attendList || []).length + '명');
	} else $('#feeCard').hide();

	// 참석자
	const al = $('#attendList').empty();
	if (!sm.attendList.length) al.html('<div class="muted small" style="padding:8px 0;">아직 참석자가 없습니다.</div>');
	sm.attendList.forEach(m => al.append(memberRow(m, true)));

	// 예비(대기) — 등록 순으로 '예비 N번'
	const wlBox = $('#waitList').empty();
	$('#waitTitle').toggle(wl.length > 0);
	wl.forEach((m, i) => wlBox.append('<div class="member-row"><span class="name">예비 ' + (i + 1) + '번 · ' + esc(m.nickname) + '</span></div>'));

	// 불참/미정
	const ol = $('#otherList').empty();
	const others = sm.absentList.map(m => ({...m, _t:'불참'})).concat(sm.pendingList.map(m => ({...m, _t:'미정'})));
	if (!others.length) ol.html('<div class="muted small" style="padding:8px 0;">없음</div>');
	others.forEach(m => {
		ol.append('<div class="member-row"><span class="name">' + esc(m.nickname) +
			'</span><span class="right small muted">' + m._t + '</span></div>');
	});

	// 용병
	const guests = sm.guests || [];
	const gc = sm.guestCount || 0;
	$('#guestSum').text(gc > 0 ? '(' + gc + '명)' : '');
	const gl = $('#guestList').empty();
	if (!guests.length) gl.html('<div class="muted small" style="padding:6px 0;">추가된 용병이 없습니다.</div>');
	guests.forEach(g => gl.append(
		'<div class="member-row"><span class="name">🧤 ' + esc(g.name) + (g.headcount > 1 ? ' (' + g.headcount + '명)' : '') + '</span>' +
		'<span class="right"><a href="javascript:void(0)" class="guestDel muted small" data-id="' + g.id + '">삭제</a></span></div>'));

	// MOM 투표 후보 (참석자)
	attendeePool = (sm.attendList || []).map(m => ({ userId: m.userId, name: m.nickname }));
	if (isPast) loadResult();
}

// ===== 경기 결과 (경기 종료 후) =====
function outcomeLabel(o) {
	if (o === 'W') return '<span style="color:var(--green);">승리 🎉</span>';
	if (o === 'L') return '<span style="color:var(--red);">패배</span>';
	if (o === 'D') return '<span style="color:#9aa3a0;">무승부</span>';
	return '<span class="muted" style="font-size:14px;font-weight:400;">결과 미입력</span>';
}
async function loadResult() {
	$('#resultCard').show();
	const rr = await api.get('/api/schedule/' + SCHEDULE_ID + '/result');
	const res = rr.ok ? rr.result : null;
	const outcome = res ? (res.ourScore > res.oppScore ? 'W' : res.ourScore < res.oppScore ? 'L' : 'D') : null;
	$('#outcomeView').html(outcomeLabel(outcome));
	$('.wdl-btn').removeClass('on');
	if (outcome) $('.wdl-btn[data-o="' + outcome + '"]').addClass('on');

	const mb = $('#momList').empty();
	const mom = rr.ok ? rr.mom : [];
	const myVote = rr.ok ? rr.myVote : null;
	if (!mom.length) mb.html('<div class="muted small" style="padding:4px 0;">아직 투표가 없습니다.</div>');
	mom.forEach((m, i) => mb.append('<div class="member-row"><span class="name">' + (i === 0 ? '👑 ' : '') + esc(m.name) + '</span><span class="right muted small">' + m.votes + '표' + (m.userId === myVote ? ' · 내 표' : '') + '</span></div>'));
	const ms = $('#msSel').empty().append('<option value="">MOM 선택</option>');
	attendeePool.forEach(p => ms.append('<option value="' + p.userId + '"' + (p.userId === myVote ? ' selected' : '') + '>' + esc(p.name) + '</option>'));
}

function memberRow(m, allowNoShow) {
	const badge = m.noShow ? ' <span class="lvl-badge" style="background:var(--red);">🚫 노쇼</span>' : '';
	const toggle = (CAN_MANAGE && allowNoShow) ? '<a href="javascript:void(0)" class="noShowBtn muted small" data-uid="' + m.userId + '" data-on="' + (m.noShow ? 1 : 0) + '">' + (m.noShow ? '노쇼 해제' : '노쇼 표시') + '</a>' : '';
	return '<div class="member-row"><span class="name">' + esc(m.nickname) + badge + '</span><span class="right">' + toggle + '</span></div>';
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
	loadInfo().then(loadAttendance);
	loadComments();

	function renderStars(n) { $('#starPick span').each(function () { $(this).text($(this).data('v') <= n ? '★' : '☆'); }); }
	$('#starPick span').on('click', function () { const n = $(this).data('v'); $('#mannerVal').val(n); renderStars(n); });
	$('#rateBtn').on('click', async function () {
		const m = $('#mannerVal').val();
		if (!m) { alert('별점을 선택해주세요.'); return; }
		const r = await api.post('/api/match/' + sched.matchPostId + '/rate', { manner: parseInt(m, 10) });
		if (r.ok) { alert('평가 완료! 감사합니다.'); $('#rateCard').hide(); $('#ratedNote').show(); } else alert(r.message || '실패');
	});

	// 경기 결과 카드 접기/펼치기
	$('#resultHead').on('click', function () {
		const body = $('#resultBody');
		const willOpen = !body.is(':visible');
		body.slideToggle(150);
		$('#resultCaret').text(willOpen ? '▴' : '▾');
	});

	// 경기 결과: 승/무/패 버튼 (클릭 즉시 저장)
	$('#resultBody').on('click', '.wdl-btn', async function () {
		const map = { W: { our: 1, opp: 0 }, D: { our: 0, opp: 0 }, L: { our: 0, opp: 1 } };
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/result', map[$(this).data('o')]);
		if (r.ok) loadResult(); else alert(r.message || '실패');
	});
	$('#voteMom').on('click', async function () {
		const t = $('#msSel').val(); if (!t) { alert('MOM 후보를 선택하세요.'); return; }
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/mom', { targetUserId: t });
		if (r.ok) { alert('투표 완료!'); loadResult(); } else alert(r.message || '실패');
	});

	$('#delSchedBtn').on('click', async function () {
		if (!confirm('이 일정을 삭제할까요?\n참석·댓글·기록도 함께 삭제되며 되돌릴 수 없습니다.')) return;
		const r = await api.del('/api/schedule/' + SCHEDULE_ID);
		if (r.ok) { alert('일정을 삭제했습니다.'); location.href = '/team/' + TEAM_ID + '/schedules'; }
		else alert(r.message || '삭제 실패');
	});

	$('#locBtn').on('click', function () {
		const box = $('#schMap');
		if (box.is(':visible')) { box.hide(); $(this).text('📍 위치 확인'); return; }
		box.show(); $(this).text('📍 위치 닫기'); showSchMap();
	});

	$('#recruitBtn').on('click', async function () {
		if (!confirm('인원이 부족한 만큼 매칭 탭에 용병 모집글을 올릴까요?')) return;
		const r = await api.post('/api/match/recruit-guest?scheduleId=' + SCHEDULE_ID, {});
		if (r.ok) { alert('용병 모집글을 등록했어요! 매칭 탭에서 확인하세요.'); location.href = '/matches/' + r.id; }
		else alert(r.message || '실패');
	});

	$('#attendBtns .att-btn').on('click', async function () {
		const s = $(this).data('s');
		// 정원이 찬 상태에서 참석자가 빠질 때 — 예비 자동 승급 안내 확인창
		if ((s === 'ABSENT' || s === 'PENDING') && myAtt === 'ATTEND' && curLimit && lastFull) {
			if (!confirm('지금 빠지면 예비 인원이 참석으로 올라갑니다.\n추후 다시 참석하면 예비(대기) 인원으로 등록됩니다.\n\n계속할까요?')) return;
		}
		const r = await api.post('/api/attendance', { scheduleId: SCHEDULE_ID, status: s });
		if (r.ok) {
			if (s === 'ATTEND' && r.status === 'WAITLIST') {
				alert('정원이 마감되어 예비(대기) 인원으로 등록되었습니다.\n자리가 나면 등록 순서대로 자동 참석 처리됩니다.');
			}
			loadAttendance();
		} else alert(r.message || '실패');
	});

	$('#attendList').on('click', '.noShowBtn', async function () {
		const on = String($(this).data('on')) === '1';
		const r = await api.post('/api/attendance/no-show', { scheduleId: SCHEDULE_ID, userId: $(this).data('uid'), noShow: !on });
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});

	$('#feeList').on('click', '.paidBtn', async function () {
		const on = String($(this).data('on')) === '1';
		const r = await api.post('/api/attendance/paid', { scheduleId: SCHEDULE_ID, userId: $(this).data('uid'), paid: !on });
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});

	$('#shareBtn').on('click', function () {
		if (!sched) return;
		const url = location.origin + '/team/' + TEAM_ID + '/schedule/' + sched.id;
		const d = new Date(sched.matchDate + 'T00:00:00');
		const dow = ['일','월','화','수','목','금','토'][d.getDay()];
		const when = (d.getMonth() + 1) + '월 ' + d.getDate() + '일(' + dow + ') ' + sched.startTime.slice(0, 5);
		kakaoShareSchedule({ teamName: TEAM_NAME, title: sched.title, when: when, place: sched.place, url: url });
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

	// 용병 추가/삭제
	async function addGuest() {
		const name = $('#guestName').val().trim();
		const cnt = parseInt($('#guestCount').val() || '1', 10);
		if (!name) { alert('용병 이름을 입력하세요.'); return; }
		const r = await api.post('/api/attendance/guest', { scheduleId: SCHEDULE_ID, name: name, headcount: cnt });
		if (r.ok) { $('#guestName').val(''); $('#guestCount').val(1); loadAttendance(); } else alert(r.message || '실패');
	}
	$('#guestAdd').on('click', addGuest);
	$('#guestName').on('keypress', e => { if (e.which === 13) addGuest(); });
	$('#guestList').on('click', '.guestDel', async function () {
		if (!confirm('이 용병을 삭제할까요?')) return;
		const r = await api.del('/api/attendance/guest/' + $(this).data('id'));
		if (r.ok) loadAttendance(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
