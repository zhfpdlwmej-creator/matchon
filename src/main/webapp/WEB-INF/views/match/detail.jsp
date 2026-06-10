<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 매칭 상세</title>
	<%@ include file="../layout/head.jsp" %>
	<c:if test="${not empty naverMapsClientId}">
		<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=${naverMapsClientId}&submodules=geocoder"></script>
	</c:if>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<a href="/matches" class="team-switch"><span class="emblem">⚔️</span><strong>매칭 상세</strong></a>
		<a href="/matches" class="role-badge">목록</a>
	</div>
</header>

<div class="app-wrap">
	<div class="card" id="infoCard">
		<div style="display:flex;align-items:center;gap:8px;">
			<span id="dLevel"></span>
			<span class="date" id="dRegion" style="color:var(--green);font-weight:700;"></span>
			<span class="muted small" id="dStatus" style="margin-left:auto;"></span>
		</div>
		<div class="title" id="dTeam" style="font-size:20px;font-weight:800;margin:6px 0;"></div>
		<div class="meta muted small" id="dMeta"></div>
		<div class="meta small" id="dMemo" style="margin-top:8px;white-space:pre-wrap;"></div>
		<div id="map" style="width:100%;height:200px;border-radius:12px;background:#eef1f0;margin-top:12px;display:none;"></div>
	</div>

	<!-- 신청자(다른 팀) 영역 -->
	<div class="card" id="applyCard" style="display:none;">
		<h3>이 매칭에 신청하기</h3>
		<div class="card-form" style="padding:0;box-shadow:none;">
			<label>신청할 우리 팀</label>
			<select id="applyTeam"></select>
			<label>상대 팀장에게 한마디 (선택)</label>
			<input type="text" id="applyMsg" maxlength="300" placeholder="예: 일요일 오전 가능합니다!">
			<button class="btn-primary btn-block" id="applyBtn" style="margin-top:14px;">신청하기</button>
		</div>
	</div>

	<!-- 용병(개인) 지원 영역 -->
	<div class="card" id="guestApplyCard" style="display:none;">
		<h3>이 경기에 용병으로 지원</h3>
		<div class="card-form" style="padding:0;box-shadow:none;">
			<label>팀장에게 한마디 (선택)</label>
			<input type="text" id="guestMsg" maxlength="300" placeholder="예: 윙어 가능 / 8시까지 도착합니다">
			<button class="btn-primary btn-block" id="guestApplyBtn" style="margin-top:14px;">🙋 용병 지원하기</button>
		</div>
	</div>

	<!-- 호스트 영역: 신청 목록 -->
	<div id="hostArea" style="display:none;">
		<div class="section-title" id="appListTitle">신청한 팀</div>
		<div class="card" id="appList"></div>
		<button class="btn-ghost btn-block" id="closeBtn" style="margin-bottom:14px;color:var(--red);">매칭 마감하기</button>
	</div>

	<!-- 상대팀 평가 (성사된 경기) -->
	<div class="card" id="rateCard" style="display:none;">
		<h3>상대팀 매너 평가 · <span id="rateTarget"></span></h3>
		<div class="muted small">경기 종료 후 상대팀의 매너를 별점으로 남겨주세요.</div>
		<div id="starPick" style="font-size:42px;text-align:center;margin:12px 0;letter-spacing:8px;color:#f5b301;cursor:pointer;user-select:none;">
			<span data-v="1">☆</span><span data-v="2">☆</span><span data-v="3">☆</span><span data-v="4">☆</span><span data-v="5">☆</span>
		</div>
		<input type="hidden" id="mannerVal">
		<button class="btn-primary btn-block" id="rateBtn">평가 저장</button>
	</div>
	<div class="card muted small" id="ratedNote" style="display:none;text-align:center;">상대팀 평가를 완료했습니다. 감사합니다! 🙏</div>

	<!-- 신청 댓글(소통) -->
	<div id="commentSection" style="margin-top:8px;"></div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const MATCH_ID = ${matchId};
const TEAM_ID = ${empty team ? 'null' : team.id};   // 현재(활동) 팀
const LEVEL_CLASS = { HIGH: 'lv-high', MID: 'lv-mid', LOW: 'lv-low' };
const STATUS_LABEL = { OPEN: '모집중', MATCHED: '성사', CLOSED: '마감' };
const APP_STATUS = { PENDING: '대기', ACCEPTED: '수락됨', REJECTED: '거절됨' };
let mp = null, isHost = false, isGuestRecruit = false;

function lvBadge(lv, label) { return '<span class="lvl-badge ' + (LEVEL_CLASS[lv]||'') + '">' + label + '</span>'; }

async function load() {
	const r = await api.get('/api/match/' + MATCH_ID + (TEAM_ID ? '?teamId=' + TEAM_ID : ''));
	if (!r.ok) { alert('매칭을 불러올 수 없습니다.'); location.href = '/matches'; return; }
	mp = r.match; isHost = r.isHost; isGuestRecruit = !!r.isGuestRecruit;

	if (isGuestRecruit) $('#dLevel').html('<span class="lvl-badge" style="background:#e0454f;">🆘 용병 ' + mp.headcount + '명 모집</span>');
	else $('#dLevel').html(lvBadge(mp.level, '수준 ' + mp.levelLabel) +
		(mp.mannerAvg != null ? ' <span class="lvl-badge" style="background:#f5b301;color:#3a2e00;">' + mp.mannerAvg + '★ <span style="opacity:.7;">(' + mp.mannerCount + ')</span></span>' : ''));
	$('#dRegion').text(mp.region || mp.placeName || '지역 미정');
	$('#dStatus').text(STATUS_LABEL[mp.status] || mp.status);
	$('#dTeam').text(mp.hostTeamName);
	let when = mp.matchDate ? (mp.matchDate.replaceAll('-', '.') + (mp.startTime ? ' ' + mp.startTime.slice(0,5) : '')) : '일정 협의';
	$('#dMeta').html('👥 ' + mp.headcount + '명 · 📅 ' + when + (mp.placeName ? ' · 📍 ' + esc(mp.placeName) : ''));
	$('#dMemo').text(mp.memo || '');

	showMap();

	// 팀 매칭 호스트: 신청팀 목록 관리. (용병 모집은 아래 댓글 스레드로 처리)
	if (isHost && !isGuestRecruit) {
		$('#hostArea').show();
		$('#closeBtn').text('매칭 마감하기');
		renderApps(r.applications || []);
	}
	// 용병 모집 호스트(팀장): 마감 버튼만 (지원자 소통은 댓글 스레드)
	if (isHost && isGuestRecruit) {
		$('#hostArea').show();
		$('#appListTitle').hide(); $('#appList').hide();
		$('#closeBtn').text('용병 모집 마감하기');
	}

	// 상대팀 평가 (성사된 경기)
	if (r.canRate) { $('#rateCard').show(); $('#rateTarget').text(r.targetTeamName || '상대팀'); }
	else if (r.alreadyRated) { $('#ratedNote').show(); }

	// 팀 매칭: 내 팀으로 신청 (용병 모집은 댓글로 신청)
	if (!isGuestRecruit) {
		const applicable = r.applicableTeams || [];
		if (mp.status === 'OPEN' && applicable.length) {
			$('#applyCard').show();
			const sel = $('#applyTeam').empty();
			applicable.forEach(t => sel.append('<option value="' + t.id + '">' + esc(t.name) + '</option>'));
		}
	}
}

function renderApps(apps) {
	const box = $('#appList').empty();
	const emptyMsg = isGuestRecruit ? '아직 지원한 용병이 없습니다.' : '아직 신청한 팀이 없습니다.';
	if (!apps.length) { box.html('<div class="muted small" style="padding:8px 0;">' + emptyMsg + '</div>'); return; }
	apps.forEach(a => {
		const accepted = a.status === 'ACCEPTED';
		// 용병 지원은 여러 명 수락 가능(모집글 OPEN 유지), 팀 매칭은 1팀 수락 시 성사
		const canAccept = a.status === 'PENDING' && (isGuestRecruit ? mp.status === 'OPEN' : mp.status === 'OPEN');
		const cls = isGuestRecruit ? 'acceptGuestBtn' : 'acceptBtn';
		const btn = canAccept
			? '<button class="btn-primary btn-sm ' + cls + '" data-id="' + a.id + '">수락</button>'
			: '<span class="muted small">' + (APP_STATUS[a.status] || a.status) + '</span>';
		const title = isGuestRecruit ? ('🧤 ' + esc(a.applicant)) : esc(a.teamName);
		const sub = isGuestRecruit ? (a.message ? esc(a.message) : '한마디 없음') : (esc(a.applicant) + (a.message ? ' · ' + esc(a.message) : ''));
		box.append(
			'<div class="member-row"><div style="flex:1;min-width:0;">' +
			'<div class="name">' + title + (accepted ? ' ✅' : '') + '</div>' +
			'<div class="muted small">' + sub + '</div>' +
			'</div><span class="right">' + btn + '</span></div>');
	});
}

function showMap() {
	if (mp.lat == null || mp.lng == null) return;
	if (!window.naver || !naver.maps) return;
	$('#map').show();
	const ll = new naver.maps.LatLng(mp.lat, mp.lng);
	const map = new naver.maps.Map('map', { center: ll, zoom: 15 });
	new naver.maps.Marker({ position: ll, map: map });
	setTimeout(() => naver.maps.Event.trigger(map, 'resize'), 150);
}

async function loadComments() {
	const q = TEAM_ID ? ('?teamId=' + TEAM_ID) : '';
	const r = await api.get('/api/match/' + MATCH_ID + '/comments' + q);
	const box = $('#commentSection').empty();
	if (!r.ok || r.side === 'none') return;
	const isHost = r.side === 'host';
	const guest = !!r.guestRecruit;
	const canManage = !!r.canManage;
	const title = guest
		? (isHost ? '🆘 용병 지원 · 소통 (전체)' : '🆘 용병 지원 · 모집팀과 소통')
		: (isHost ? '💬 신청팀 메시지 (전체)' : '💬 모집팀과 메시지');
	box.append('<div class="section-title">' + title + '</div>');
	if (!r.threads.length) {
		box.append('<div class="card muted small">' + (guest && !isHost ? '아래에 메시지를 남기면 용병 지원이 접수됩니다.' : (isHost ? '아직 들어온 지원/신청이 없습니다.' : '신청 후 메시지를 주고받을 수 있어요.')) + '</div>');
		if (guest && !isHost) box.append(threadCard({ comments: [] }, guest, isHost, canManage));   // 빈 스레드(입력창)
		return;
	}
	r.threads.forEach(function (th) { box.append(threadCard(th, guest, isHost, canManage)); });
}
function threadCard(th, guest, isHost, canManage) {
	const card = $('<div class="card thread" data-team="' + (th.applicantTeamId || '') + '" data-user="' + (th.applicantUserId || '') + '"></div>');
	if (isHost) {
		const mb = (guest && th.mannerAvg != null) ? ' <span class="lvl-badge" style="background:#f5b301;color:#3a2e00;">' + th.mannerAvg + '★ <span style="opacity:.7;">(' + th.mannerCount + ')</span></span>' : '';
		let head = '<h3 style="margin-bottom:4px;">' + esc(th.name || '지원자') + mb + '</h3>';
		if (guest && th.accepted) {
			head += '<div class="small" style="color:var(--green);font-weight:700;margin-bottom:6px;">✅ 용병 확정됨</div>';
			if (canManage && !th.ratedByMe) head += guestRateWidget(th.applicantUserId);
			else if (canManage && th.ratedByMe) head += '<div class="small muted" style="margin-bottom:6px;">매너 평가 완료 🙏</div>';
		} else if (guest && canManage && th.applicationId) {
			head += '<button class="btn-primary btn-sm cmt-accept" data-app-id="' + th.applicationId + '" style="margin-bottom:8px;">🧤 용병으로 확정</button>';
		}
		card.append(head);
	}
	const list = $('<div class="cmt-list"></div>');
	renderThread(list, th.comments || [], guest);
	card.append(list);
	const ph = guest && !isHost ? '메시지를 남기면 지원 접수돼요 (포지션·도착시간 등)' : '메시지 (시간·장소 협의 등)';
	card.append('<div class="reply-hint muted small" style="display:none;margin-top:8px;"></div>' +
		'<div class="comment-input" style="margin-top:8px;">' +
		'<input type="text" class="cmt-text" maxlength="500" placeholder="' + ph + '">' +
		'<button class="btn-primary btn-sm cmt-send">전송</button></div>' +
		'<input type="hidden" class="cmt-parent">');
	return card;
}
function guestRateWidget(uid) {
	return '<div class="guest-rate" data-uid="' + uid + '" style="border:1px solid var(--line);border-radius:10px;padding:8px 10px;margin-bottom:8px;">' +
		'<div class="small" style="font-weight:700;">이 용병 매너 평가</div>' +
		'<div class="grstars" style="font-size:26px;color:#f5b301;cursor:pointer;letter-spacing:5px;user-select:none;"><span data-v="1">☆</span><span data-v="2">☆</span><span data-v="3">☆</span><span data-v="4">☆</span><span data-v="5">☆</span></div>' +
		'<input type="hidden" class="grval">' +
		'<div style="display:flex;gap:6px;margin-top:4px;"><input type="text" class="grcomment" maxlength="300" placeholder="한줄 후기 (선택)" style="flex:1;min-width:0;padding:8px;border:1px solid var(--line);border-radius:8px;"><button class="btn-primary btn-sm grsubmit">평가</button></div>' +
		'</div>';
}
function renderThread(list, comments, guest) {
	list.empty();
	if (!comments.length) { list.html('<div class="muted small" style="padding:6px 0;">첫 메시지를 남겨보세요.</div>'); return; }
	const byParent = {};
	comments.forEach(function (c) { const k = c.parentId || 0; (byParent[k] = byParent[k] || []).push(c); });
	(byParent[0] || []).forEach(function (c) {
		list.append(commentRow(c, false, guest));
		(byParent[c.id] || []).forEach(function (rep) { list.append(commentRow(rep, true, guest)); });
	});
}
function commentRow(c, isReply, guest) {
	const who = c.isHost ? '모집팀' : (guest ? '신청자' : '신청팀');
	const color = c.isHost ? 'var(--green)' : '#2f6df0';
	return '<div class="cmt-row" style="padding:7px 0;border-top:1px solid var(--line);' + (isReply ? 'margin-left:22px;' : '') + '">' +
		'<div class="small muted"><b style="color:var(--text);">' + esc(c.name) + '</b> <span style="color:' + color + ';">' + who + '</span> · ' + esc(c.createdAt) + '</div>' +
		'<div style="margin:2px 0;">' + (isReply ? '↳ ' : '') + esc(c.content) + '</div>' +
		'<div class="small">' + (!isReply ? '<a href="javascript:void(0)" class="cmt-reply" data-pid="' + c.id + '">답글</a>' : '') +
		(c.mine ? ' <a href="javascript:void(0)" class="cmt-del muted" data-id="' + c.id + '">삭제</a>' : '') + '</div></div>';
}

$(function () {
	load();
	loadComments();

	$('#commentSection').on('click', '.cmt-reply', function () {
		const card = $(this).closest('.thread');
		card.find('.cmt-parent').val($(this).data('pid'));
		card.find('.reply-hint').html('↳ 답글 작성 중 <a href="javascript:void(0)" class="reply-cancel">취소</a>').show();
		card.find('.cmt-text').focus();
	});
	$('#commentSection').on('click', '.reply-cancel', function () {
		const card = $(this).closest('.thread');
		card.find('.cmt-parent').val(''); card.find('.reply-hint').hide();
	});
	async function sendComment(card) {
		const text = card.find('.cmt-text').val().trim();
		if (!text) return;
		const body = { applicantTeamId: card.data('team') || null, applicantUserId: card.data('user') || null, parentId: card.find('.cmt-parent').val() || null, content: text };
		const r = await api.post('/api/match/' + MATCH_ID + '/comments' + (TEAM_ID ? ('?teamId=' + TEAM_ID) : ''), body);
		if (r.ok) loadComments(); else alert(r.message || '실패');
	}
	$('#commentSection').on('click', '.cmt-send', function () { sendComment($(this).closest('.thread')); });
	$('#commentSection').on('keypress', '.cmt-text', function (e) { if (e.which === 13) sendComment($(this).closest('.thread')); });
		$('#commentSection').on('click', '.cmt-accept', async function () {
			if (!confirm('이 지원자를 용병으로 확정할까요? 우리 일정에 자동 추가됩니다.')) return;
			const r = await api.post('/api/match/application/' + $(this).data('app-id') + '/accept-guest', {});
			if (r.ok) { alert('용병으로 확정했어요!'); loadComments(); } else alert(r.message || '실패');
		});
		$('#commentSection').on('click', '.grstars span', function () {
			const wrap = $(this).closest('.guest-rate'), n = $(this).data('v');
			wrap.find('.grval').val(n);
			wrap.find('.grstars span').each(function () { $(this).text($(this).data('v') <= n ? '★' : '☆'); });
		});
		$('#commentSection').on('click', '.grsubmit', async function () {
			const wrap = $(this).closest('.guest-rate'), manner = wrap.find('.grval').val();
			if (!manner) { alert('별점을 선택해주세요.'); return; }
			const r = await api.post('/api/match/' + MATCH_ID + '/rate-guest', { targetUserId: wrap.data('uid'), manner: parseInt(manner, 10), comment: wrap.find('.grcomment').val().trim() });
			if (r.ok) { alert('평가 완료! 감사합니다.'); loadComments(); } else alert(r.message || '실패');
		});
	$('#commentSection').on('click', '.cmt-del', async function () {
		if (!confirm('이 메시지를 삭제할까요?')) return;
		const r = await api.del('/api/match/comment/' + $(this).data('id') + (TEAM_ID ? ('?teamId=' + TEAM_ID) : ''));
		if (r.ok) loadComments(); else alert(r.message || '실패');
	});

	$('#applyBtn').on('click', async function () {
		const teamId = $('#applyTeam').val();
		if (!teamId) { alert('신청할 팀이 없습니다.'); return; }
		const r = await api.post('/api/match/' + MATCH_ID + '/apply', { teamId: teamId, message: $('#applyMsg').val().trim() });
		if (r.ok) { alert('신청 완료! 상대 팀장이 수락하면 성사됩니다.'); load(); loadComments(); }
		else alert(r.message || '신청 실패');
	});

	$('#appList').on('click', '.acceptBtn', async function () {
		if (!confirm('이 팀의 신청을 수락할까요? (매칭이 성사되고 나머지 신청은 거절됩니다)')) return;
		const r = await api.post('/api/match/application/' + $(this).data('id') + '/accept', {});
		if (r.ok) load(); else alert(r.message || '실패');
	});

	$('#appList').on('click', '.acceptGuestBtn', async function () {
		if (!confirm('이 용병을 수락할까요? 우리 일정에 용병으로 자동 추가됩니다.')) return;
		const r = await api.post('/api/match/application/' + $(this).data('id') + '/accept-guest', {});
		if (r.ok) load(); else alert(r.message || '실패');
	});

	$('#guestApplyBtn').on('click', async function () {
		const r = await api.post('/api/match/' + MATCH_ID + '/apply-guest', { message: $('#guestMsg').val().trim() });
		if (r.ok) { alert('지원 완료! 상대 팀장이 수락하면 확정됩니다.'); load(); }
		else alert(r.message || '지원 실패');
	});

	// 상대팀 매너 평가 (별점만)
	function renderStars(n) { $('#starPick span').each(function () { $(this).text($(this).data('v') <= n ? '★' : '☆'); }); }
	$('#starPick span').on('click', function () { const n = $(this).data('v'); $('#mannerVal').val(n); renderStars(n); });
	$('#rateBtn').on('click', async function () {
		const manner = $('#mannerVal').val();
		if (!manner) { alert('별점을 선택해주세요.'); return; }
		const r = await api.post('/api/match/' + MATCH_ID + '/rate', { manner: parseInt(manner, 10) });
		if (r.ok) { alert('평가 완료! 감사합니다.'); load(); } else alert(r.message || '평가 실패');
	});

	$('#closeBtn').on('click', async function () {
		if (!confirm('이 매칭을 마감할까요?')) return;
		const r = await api.post('/api/match/' + MATCH_ID + '/close', {});
		if (r.ok) load(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
