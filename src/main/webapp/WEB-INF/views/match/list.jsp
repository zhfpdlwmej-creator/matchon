<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 팀 매칭</title>
	<%@ include file="../layout/head.jsp" %>
	<script src="/js/regions.js" defer></script>
	<c:if test="${not empty kakaoJsKey}">
		<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoJsKey}&libraries=services&autoload=false"></script>
	</c:if>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<a href="/" class="team-switch"><span class="emblem">⚔️</span><strong>팀 매칭</strong></a>
		<a href="/" class="role-badge">홈</a>
	</div>
</header>

<div class="app-wrap">
	<div class="muted small" style="padding:2px 4px 8px;">지역별 친선경기 모집·신청 (팀장·운영진만 등록/신청)</div>

	<div class="card">
		<div class="small" style="font-weight:700;margin-bottom:8px;">지역으로 보기</div>
		<div id="filterRegion"></div>
	</div>

	<div class="section-title">모집중인 매칭</div>
	<div id="matchList"><div class="empty">불러오는 중...</div></div>
</div>

<a class="fab" id="addBtn" href="javascript:void(0)">＋</a>

<!-- 매칭 등록 모달 -->
<div class="modal-back" id="matchModal">
	<div class="modal">
		<h3>매칭 올리기</h3>
		<form id="matchForm" class="card-form" style="padding:0;box-shadow:none;">
			<label>우리 팀 (호스트)</label>
			<select id="hostTeam"></select>

			<label>팀 수준</label>
			<div class="lvl-picker" id="lvlPicker">
				<button type="button" class="lvl" data-lv="HIGH">상</button>
				<button type="button" class="lvl" data-lv="MID">중</button>
				<button type="button" class="lvl" data-lv="LOW">하</button>
			</div>
			<input type="hidden" id="level">

			<div class="row-2">
				<div><label>인원</label><input type="number" id="headcount" min="1" value="6"></div>
				<div><label>날짜</label><input type="date" id="matchDate"></div>
			</div>
			<label>시작시간</label>
			<input type="time" id="startTime">

			<label>지역 (도 → 시/군/구)</label>
			<div id="createRegion"></div>
			<input type="hidden" id="region">

			<label>장소 (지도에서 위치 선택)</label>
			<div style="display:flex;gap:8px;margin-bottom:8px;">
				<input type="text" id="placeName" placeholder="장소명 또는 검색어" style="flex:1;min-width:0;">
				<button type="button" class="btn-ghost btn-sm" id="placeSearch">검색</button>
			</div>
			<div id="map" style="width:100%;height:190px;border-radius:12px;background:#eef1f0;"></div>
			<div class="muted small" id="mapHint" style="margin-top:6px;">지도를 탭하면 그 위치로 장소가 지정됩니다.</div>
			<input type="hidden" id="lat"><input type="hidden" id="lng">

			<label>메모 (선택)</label>
			<textarea id="memo" maxlength="500" placeholder="구장 정보, 회비, 룰 등"></textarea>

			<div class="row-2" style="margin-top:14px;">
				<button type="button" class="btn-ghost" id="cancelBtn">취소</button>
				<button type="submit" class="btn-primary">등록</button>
			</div>
		</form>
	</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const LEVEL_CLASS = { HIGH: 'lv-high', MID: 'lv-mid', LOW: 'lv-low' };
let map, marker, geocoder, places, mapReady = false;
let currentRegion = '';

function lvBadge(lv, label) { return '<span class="lvl-badge ' + (LEVEL_CLASS[lv]||'') + '">' + label + '</span>'; }

async function loadList() {
	const r = await api.get('/api/match/list' + (currentRegion ? ('?region=' + encodeURIComponent(currentRegion)) : ''));
	const box = $('#matchList').empty();
	if (!r.ok) return;
	if (!r.matches.length) { box.html('<div class="empty"><span class="big">⚽</span>' + (currentRegion ? esc(currentRegion) + ' 지역에 ' : '') + '모집중인 매칭이 없습니다.<br>우하단 ＋ 로 매칭을 올려보세요.</div>'); return; }
	r.matches.forEach(m => {
		const when = m.matchDate ? (m.matchDate.replaceAll('-', '.') + (m.startTime ? ' ' + m.startTime.slice(0,5) : '')) : '일정 협의';
		box.append(
			'<a class="schedule-item" href="/matches/' + m.id + '">' +
			'<div style="display:flex;align-items:center;gap:8px;">' + lvBadge(m.level, '수준 ' + m.levelLabel) +
			'<span class="date">' + esc(m.region || '지역 미정') + '</span>' +
			(m.mine ? '<span class="muted small" style="margin-left:auto;">내 팀</span>' : '') + '</div>' +
			'<div class="title">' + esc(m.hostTeamName) + '</div>' +
			'<div class="meta">👥 ' + m.headcount + '명 · 📅 ' + when + (m.placeName ? ' · 📍 ' + esc(m.placeName) : '') + '</div>' +
			'<div class="meta muted small">신청 ' + m.applications + '팀</div>' +
			'</a>');
	});
}

function ensureMap() {
	if (!window.kakao || !kakao.maps) { $('#mapHint').text('지도 키 미설정 — 장소명/지역만 입력해도 됩니다.'); $('#map').hide(); return; }
	kakao.maps.load(function () {
		if (mapReady) { map.relayout(); return; }
		const center = new kakao.maps.LatLng(37.5145, 127.1066);
		map = new kakao.maps.Map(document.getElementById('map'), { center: center, level: 5 });
		marker = new kakao.maps.Marker({ position: center });
		geocoder = new kakao.maps.services.Geocoder();
		places = new kakao.maps.services.Places();
		mapReady = true;
		kakao.maps.event.addListener(map, 'click', e => setPoint(e.latLng));
		setTimeout(() => map.relayout(), 100);
	});
}
function setPoint(latlng) {
	marker.setPosition(latlng); marker.setMap(map);
	$('#lat').val(latlng.getLat()); $('#lng').val(latlng.getLng());
	if (geocoder) geocoder.coord2Address(latlng.getLng(), latlng.getLat(), function (res, st) {
		if (st === kakao.maps.services.Status.OK && res[0] && !$('#placeName').val()) $('#placeName').val(res[0].address.address_name);
	});
}

function openModal() { $('#matchModal').addClass('open'); ensureMap(); setTimeout(() => { if (mapReady) map.relayout(); }, 250); }
function closeModal() { $('#matchModal').removeClass('open'); }

$(function () {
	// 지역 필터
	buildRegionPicker('#filterRegion', { includeAll: true, onChange: function (region) { currentRegion = region; loadList(); } });
	// 등록용 지역
	buildRegionPicker('#createRegion', { onChange: function (region) { $('#region').val(region); } });
	loadList();

	api.get('/api/match/my-teams').then(r => {
		const sel = $('#hostTeam').empty();
		if (r.ok && r.teams.length) r.teams.forEach(t => sel.append('<option value="' + t.id + '">' + esc(t.name) + '</option>'));
		else sel.append('<option value="">팀장/운영진인 팀이 없습니다</option>');
	});

	$('#addBtn').on('click', openModal);
	$('#cancelBtn').on('click', closeModal);
	$('#matchModal').on('click', e => { if (e.target.id === 'matchModal') closeModal(); });

	$('#lvlPicker .lvl').on('click', function () {
		$('#lvlPicker .lvl').removeClass('on'); $(this).addClass('on'); $('#level').val($(this).data('lv'));
	});

	$('#placeSearch').on('click', function () {
		const kw = $('#placeName').val().trim();
		if (!kw || !mapReady || !places) return;
		places.keywordSearch(kw, function (data, status) {
			if (status === kakao.maps.services.Status.OK && data[0]) {
				const ll = new kakao.maps.LatLng(data[0].y, data[0].x);
				map.setCenter(ll); setPoint(ll); $('#placeName').val(data[0].place_name);
			} else alert('검색 결과가 없습니다.');
		});
	});

	$('#matchForm').on('submit', async function (e) {
		e.preventDefault();
		const teamId = $('#hostTeam').val();
		if (!teamId) { alert('호스트로 등록할 팀이 없습니다. 팀장 권한이 필요합니다.'); return; }
		if (!$('#level').val()) { alert('팀 수준(상/중/하)을 선택해주세요.'); return; }
		const body = {
			level: $('#level').val(),
			headcount: parseInt($('#headcount').val() || '0', 10),
			region: $('#region').val().trim(),
			placeName: $('#placeName').val().trim(),
			lat: $('#lat').val() ? parseFloat($('#lat').val()) : null,
			lng: $('#lng').val() ? parseFloat($('#lng').val()) : null,
			matchDate: $('#matchDate').val() || null,
			startTime: $('#startTime').val() || null,
			memo: $('#memo').val().trim()
		};
		const r = await api.post('/api/match?teamId=' + teamId, body);
		if (r.ok) { closeModal(); location.href = '/matches/' + r.id; } else alert(r.message || '등록 실패');
	});
});
</script>
</body>
</html>
