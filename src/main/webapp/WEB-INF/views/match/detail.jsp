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

	<!-- 호스트 영역: 신청 목록 -->
	<div id="hostArea" style="display:none;">
		<div class="section-title">신청한 팀</div>
		<div class="card" id="appList"></div>
		<button class="btn-ghost btn-block" id="closeBtn" style="margin-bottom:14px;color:var(--red);">매칭 마감하기</button>
	</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const MATCH_ID = ${matchId};
const LEVEL_CLASS = { HIGH: 'lv-high', MID: 'lv-mid', LOW: 'lv-low' };
const STATUS_LABEL = { OPEN: '모집중', MATCHED: '성사', CLOSED: '마감' };
const APP_STATUS = { PENDING: '대기', ACCEPTED: '수락됨', REJECTED: '거절됨' };
let mp = null, isHost = false;

function lvBadge(lv, label) { return '<span class="lvl-badge ' + (LEVEL_CLASS[lv]||'') + '">' + label + '</span>'; }

async function load() {
	const r = await api.get('/api/match/' + MATCH_ID);
	if (!r.ok) { alert('매칭을 불러올 수 없습니다.'); location.href = '/matches'; return; }
	mp = r.match; isHost = r.isHost;

	$('#dLevel').html(lvBadge(mp.level, '수준 ' + mp.levelLabel));
	$('#dRegion').text(mp.region || '지역 미정');
	$('#dStatus').text(STATUS_LABEL[mp.status] || mp.status);
	$('#dTeam').text(mp.hostTeamName);
	let when = mp.matchDate ? (mp.matchDate.replaceAll('-', '.') + (mp.startTime ? ' ' + mp.startTime.slice(0,5) : '')) : '일정 협의';
	$('#dMeta').html('👥 ' + mp.headcount + '명 · 📅 ' + when + (mp.placeName ? ' · 📍 ' + esc(mp.placeName) : ''));
	$('#dMemo').text(mp.memo || '');

	showMap();

	// 호스트면 신청 관리 영역
	if (isHost) {
		$('#hostArea').show();
		renderApps(r.applications || []);
	}
	// 신청 가능한 내 팀이 있으면(호스트라도 다른 팀으로) 신청 폼 노출
	const applicable = r.applicableTeams || [];
	if (mp.status === 'OPEN' && applicable.length) {
		$('#applyCard').show();
		const sel = $('#applyTeam').empty();
		applicable.forEach(t => sel.append('<option value="' + t.id + '">' + esc(t.name) + '</option>'));
	}
}

function renderApps(apps) {
	const box = $('#appList').empty();
	if (!apps.length) { box.html('<div class="muted small" style="padding:8px 0;">아직 신청한 팀이 없습니다.</div>'); return; }
	apps.forEach(a => {
		const accepted = a.status === 'ACCEPTED';
		const btn = (mp.status === 'OPEN' && a.status === 'PENDING')
			? '<button class="btn-primary btn-sm acceptBtn" data-id="' + a.id + '">수락</button>'
			: '<span class="muted small">' + (APP_STATUS[a.status] || a.status) + '</span>';
		box.append(
			'<div class="member-row"><div style="flex:1;min-width:0;">' +
			'<div class="name">' + esc(a.teamName) + (accepted ? ' ✅' : '') + '</div>' +
			'<div class="muted small">' + esc(a.applicant) + (a.message ? ' · ' + esc(a.message) : '') + '</div>' +
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

$(function () {
	load();

	$('#applyBtn').on('click', async function () {
		const teamId = $('#applyTeam').val();
		if (!teamId) { alert('신청할 팀이 없습니다.'); return; }
		const r = await api.post('/api/match/' + MATCH_ID + '/apply', { teamId: teamId, message: $('#applyMsg').val().trim() });
		if (r.ok) { alert('신청 완료! 상대 팀장이 수락하면 성사됩니다.'); load(); }
		else alert(r.message || '신청 실패');
	});

	$('#appList').on('click', '.acceptBtn', async function () {
		if (!confirm('이 팀의 신청을 수락할까요? (매칭이 성사되고 나머지 신청은 거절됩니다)')) return;
		const r = await api.post('/api/match/application/' + $(this).data('id') + '/accept', {});
		if (r.ok) load(); else alert(r.message || '실패');
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
