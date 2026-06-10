<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="matches" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 팀 매칭</title>
	<%@ include file="../layout/head.jsp" %>
	<script src="/js/regions.js" defer></script>
	<c:if test="${not empty naverMapsClientId}">
		<script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpClientId=${naverMapsClientId}&submodules=geocoder"></script>
	</c:if>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<a href="/" class="team-switch"><span class="emblem">⚔️</span><strong>매칭 / 용병</strong></a>
		<a href="/" class="role-badge">홈</a>
	</div>
</header>

<div class="app-wrap">
	<div class="muted small" style="padding:2px 4px 8px;">
		<c:if test="${not empty team}">현재 팀: <b style="color:var(--green);">${fn:escapeXml(team.name)}</b> 기준 · </c:if>지역별 친선경기 · 용병 모집
	</div>

	<div class="tabs" id="mainTabs">
		<button class="tab on" data-pane="match">⚔️ 팀 매칭</button>
		<button class="tab" data-pane="guest">🆘 용병 모집</button>
	</div>

	<!-- ===== 팀 매칭 ===== -->
	<div id="matchPane">
		<div class="section-title">내 매칭</div>
		<div class="tabs" id="mineTabs">
			<button class="tab on" data-tab="hosting">등록한 매칭 <span class="cnt" id="cntHosting"></span></button>
			<button class="tab" data-tab="applied">신청한 매칭 <span class="cnt" id="cntApplied"></span></button>
		</div>
		<div id="tabHosting"></div>
		<div id="tabApplied" style="display:none;"></div>

		<div class="card">
			<div class="small" style="font-weight:700;margin-bottom:8px;">종목</div>
			<div class="region-row" id="fType">
				<button class="region-chip on" data-v="">전체</button>
				<button class="region-chip" data-v="SOCCER_11">⚽ 축구</button>
				<button class="region-chip" data-v="FUTSAL_5">🥅 풋살</button>
			</div>
			<div class="small" style="font-weight:700;margin:12px 0 8px;">실력대</div>
			<div class="region-row" id="fLevel">
				<button class="region-chip on" data-v="">전체</button>
				<button class="region-chip" data-v="HIGH">상</button>
				<button class="region-chip" data-v="MID">중</button>
				<button class="region-chip" data-v="LOW">하</button>
			</div>
			<div class="small" style="font-weight:700;margin:12px 0 8px;">매너</div>
			<div class="region-row" id="fManner">
				<button class="region-chip on" data-v="">전체</button>
				<button class="region-chip" data-v="hidebad">😡 비매너(2.5★미만) 숨기기</button>
			</div>
			<div class="small" style="font-weight:700;margin:12px 0 8px;">지역으로 보기</div>
			<div id="filterRegion"></div>
		</div>

		<div class="section-title">모집중인 경기</div>
		<div id="matchList"><div class="empty">불러오는 중...</div></div>
	</div>

	<!-- ===== 용병 모집 ===== -->
	<div id="guestPane" style="display:none;">
		<div class="card muted small">
			인원이 부족한 팀이 올린 <b>용병 모집글</b>입니다. 누구나 지원할 수 있고, 팀장이 수락하면 해당 경기에 참여합니다.<br>
			모집글은 <b>경기 상세 → 🆘 용병 모집글 올리기</b>에서 등록돼요.
		</div>
		<div class="section-title">모집중인 용병</div>
		<div id="guestList"><div class="empty">불러오는 중...</div></div>
	</div>
</div>

<a class="fab" id="addBtn" href="javascript:void(0)">＋</a>

<!-- 매칭 등록 모달 -->
<div class="modal-back" id="matchModal">
	<div class="modal">
		<h3>경기(팀 매칭) 올리기</h3>
		<form id="matchForm" class="card-form" style="padding:0;box-shadow:none;">
			<label>우리 팀 (호스트)</label>
			<input type="text" id="hostTeamName" readonly style="background:#f4f6f5;font-weight:700;">

			<label>종목</label>
			<div class="lvl-picker" id="typePicker">
				<button type="button" class="lvl on" data-v="SOCCER_11">⚽ 축구</button>
				<button type="button" class="lvl" data-v="FUTSAL_5">🥅 풋살</button>
			</div>
			<input type="hidden" id="matchType" value="SOCCER_11">

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
			<input type="text" id="startTime">

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

			<label>소개글 (선택)</label>
			<textarea id="memo" maxlength="500" placeholder="연령대, 구장 정보, 회비, 룰 등 자유롭게 작성하세요"></textarea>

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
const TEAM_ID = ${empty team ? 'null' : team.id};
const TEAM_NAME = "${fn:escapeXml(team.name)}";
const IS_LEADER = ${isLeader};
let map, marker, mapReady = false;
let currentRegion = '';
let currentType = '', currentLevel = '', currentManner = '';
let allMatches = [];
let canCreate = false;
let curPane = 'match';

const TYPE_LABEL = { FUTSAL_5: '풋살', SOCCER_11: '축구' };
const POST_STATUS = { OPEN: '모집중', MATCHED: '성사', CLOSED: '마감' };
const MY_STATUS = { PENDING: '⏳ 대기중', ACCEPTED: '✅ 수락됨(성사)', REJECTED: '거절됨' };

function lvBadge(lv, label) { return '<span class="lvl-badge ' + (LEVEL_CLASS[lv] || '') + '">' + label + '</span>'; }

function hostingCard(m) {
	const badge = m.pending > 0
		? '<span class="lvl-badge" style="background:#e0454f;margin-left:auto;">🔔 새 신청 ' + m.pending + '</span>'
		: '<span class="muted small" style="margin-left:auto;">' + (POST_STATUS[m.status] || m.status) + '</span>';
	return '<a class="schedule-item" href="/matches/' + m.id + '">' +
		'<div style="display:flex;align-items:center;gap:8px;">' + lvBadge(m.level, '수준 ' + m.levelLabel) +
		'<span class="date">' + esc(m.region || '지역 미정') + '</span>' + badge + '</div>' +
		'<div class="title">' + esc(m.hostTeamName) + '</div>' +
		'<div class="meta muted small">신청 ' + m.applications + '팀' + (m.pending > 0 ? ' · 수락 대기 ' + m.pending : '') + ' · 탭하여 관리</div>' +
		'</a>';
}
function appliedCard(a) {
	return '<a class="schedule-item" href="/matches/' + a.matchId + '">' +
		'<div style="display:flex;align-items:center;gap:8px;">' + lvBadge(a.level, '수준 ' + a.levelLabel) +
		'<span class="date">' + esc(a.region || '지역 미정') + '</span>' +
		'<span class="muted small" style="margin-left:auto;">' + (MY_STATUS[a.myStatus] || a.myStatus) + '</span></div>' +
		'<div class="title">' + esc(a.myTeamName) + ' → ' + esc(a.hostTeamName) + '</div>' +
		'</a>';
}
async function loadMine() {
	const h = $('#tabHosting').empty(), ap = $('#tabApplied').empty();
	const noTeam = '<div class="card muted small" style="text-align:center;">팀을 선택하면 표시됩니다.</div>';
	if (!TEAM_ID) { h.html(noTeam); ap.html(noTeam); $('#cntHosting,#cntApplied').text(''); return; }
	const r = await api.get('/api/match/mine?teamId=' + TEAM_ID);
	if (!r.ok) return;
	$('#cntHosting').text(r.hosting.length ? '(' + r.hosting.length + ')' : '');
	$('#cntApplied').text(r.applied.length ? '(' + r.applied.length + ')' : '');
	if (!r.hosting.length) h.html('<div class="card muted small" style="text-align:center;">등록한 경기가 없어요.</div>');
	else r.hosting.forEach(m => h.append(hostingCard(m)));
	if (!r.applied.length) ap.html('<div class="card muted small" style="text-align:center;">신청한 경기가 없어요.</div>');
	else r.applied.forEach(a => ap.append(appliedCard(a)));
}

async function loadList() {
	const q = [];
	if (currentRegion) q.push('region=' + encodeURIComponent(currentRegion));
	if (TEAM_ID) q.push('teamId=' + TEAM_ID);
	const r = await api.get('/api/match/list' + (q.length ? '?' + q.join('&') : ''));
	allMatches = r.ok ? r.matches : [];
	renderList();
}

function passFilter(m) {
	if (currentType && m.matchType !== currentType) return false;
	if (currentLevel && m.level !== currentLevel) return false;
	if (currentManner === 'hidebad' && m.mannerAvg != null && m.mannerAvg < 2.5) return false;
	return true;
}

function renderList() {
	const box = $('#matchList').empty();
	const list = allMatches.filter(passFilter);
	if (!list.length) { box.html('<div class="empty"><span class="big">⚽</span>' + (currentRegion ? esc(currentRegion) + ' 지역에 ' : '') + '조건에 맞는 경기가 없습니다.<br>우하단 ＋ 로 경기를 올려보세요.</div>'); return; }
	list.forEach(m => {
		const when = m.matchDate ? (m.matchDate.replaceAll('-', '.') + (m.startTime ? ' ' + m.startTime.slice(0, 5) : '')) : '일정 협의';
		const tags = lvBadge(m.level, '수준 ' + m.levelLabel) +
			(m.matchType ? '<span class="lvl-badge" style="background:#2f6df0;">' + (TYPE_LABEL[m.matchType] || m.matchType) + '</span>' : '') +
			(m.mannerAvg != null ? '<span class="lvl-badge" style="background:#f5b301;color:#3a2e00;">' + m.mannerAvg + '★</span>' : '');
		box.append(
			'<a class="schedule-item" href="/matches/' + m.id + '">' +
			'<div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">' + tags +
			(m.mine ? '<span class="muted small" style="margin-left:auto;">내 팀</span>' : '') + '</div>' +
			'<div class="title">' + esc(m.hostTeamName) + '</div>' +
			'<div class="meta">📍 ' + esc(m.region || '지역 미정') + ' · 👥 ' + m.headcount + '명 · 📅 ' + when + (m.placeName ? ' · ' + esc(m.placeName) : '') + '</div>' +
			'<div class="meta muted small">👤 등록자 ' + esc(m.hostName) + ' · 신청 ' + m.applications + '팀</div>' +
			'</a>');
	});
}

async function loadGuestList() {
	const q = ['guest=true'];
	if (currentRegion) q.push('region=' + encodeURIComponent(currentRegion));
	if (TEAM_ID) q.push('teamId=' + TEAM_ID);
	const r = await api.get('/api/match/list?' + q.join('&'));
	const box = $('#guestList').empty();
	const list = r.ok ? r.matches : [];
	if (!list.length) { box.html('<div class="empty"><span class="big">🆘</span>모집중인 용병 공고가 없습니다.</div>'); return; }
	list.forEach(m => {
		const when = m.matchDate ? (m.matchDate.replaceAll('-', '.') + (m.startTime ? ' ' + m.startTime.slice(0, 5) : '')) : '일정 협의';
		box.append(
			'<a class="schedule-item" href="/matches/' + m.id + '">' +
			'<div style="display:flex;align-items:center;gap:8px;">' +
			'<span class="lvl-badge" style="background:#e0454f;">🆘 용병 ' + m.headcount + '명</span>' +
			(m.placeName ? '<span class="date">' + esc(m.placeName) + '</span>' : '') + '</div>' +
			'<div class="title">' + esc(m.hostTeamName) + '</div>' +
			'<div class="meta">📅 ' + when + '</div>' +
			'<div class="meta muted small">' + esc(m.memo || '') + ' · 지원 ' + m.applications + '명</div>' +
			'</a>');
	});
}

function switchPane(pane) {
	curPane = pane;
	$('#mainTabs .tab').removeClass('on');
	$('#mainTabs .tab[data-pane="' + pane + '"]').addClass('on');
	$('#matchPane').toggle(pane === 'match');
	$('#guestPane').toggle(pane === 'guest');
	$('#addBtn').toggle(pane === 'match' && canCreate);
	if (pane === 'guest') loadGuestList();
}

function ensureMap() {
	if (!window.naver || !naver.maps) { $('#mapHint').text('네이버 지도 키 미설정 — 장소명/지역만 입력해도 됩니다.'); $('#map').hide(); return; }
	if (mapReady) { naver.maps.Event.trigger(map, 'resize'); return; }
	const center = new naver.maps.LatLng(37.5145, 127.1066);
	map = new naver.maps.Map('map', { center: center, zoom: 13 });
	marker = new naver.maps.Marker({ position: center, map: map });
	mapReady = true;
	naver.maps.Event.addListener(map, 'click', e => setPoint(e.coord));
}
function setPoint(latlng) {
	marker.setPosition(latlng);
	$('#lat').val(latlng.lat()); $('#lng').val(latlng.lng());
	if (naver.maps.Service) naver.maps.Service.reverseGeocode({ coords: latlng, orders: 'roadaddr,addr' }, function (status, res) {
		if (status === naver.maps.Service.Status.OK) {
			const a = res.v2 && res.v2.address;
			const addr = a ? (a.roadAddress || a.jibunAddress) : '';
			if (addr && !$('#placeName').val()) $('#placeName').val(addr);
		}
	});
}

function openModal() { $('#matchModal').addClass('open'); ensureMap(); setTimeout(() => { if (mapReady) naver.maps.Event.trigger(map, 'resize'); }, 250); }
function closeModal() { $('#matchModal').removeClass('open'); }

$(function () {
	buildRegionPicker('#filterRegion', { includeAll: true, onChange: function (region) { currentRegion = region; loadList(); } });
	buildRegionPicker('#createRegion', { onChange: function (region) { $('#region').val(region); } });
	bindTime('#startTime');
	loadMine();
	loadList();
	if (!TEAM_ID) switchPane('guest');   // 팀 없는 개인은 용병 탭부터

	$('#mainTabs .tab').on('click', function () { switchPane($(this).data('pane')); });

	$('#mineTabs .tab').on('click', function () {
		$('#mineTabs .tab').removeClass('on'); $(this).addClass('on');
		const t = $(this).data('tab');
		$('#tabHosting').toggle(t === 'hosting');
		$('#tabApplied').toggle(t === 'applied');
	});

	$('#hostTeamName').val(TEAM_NAME || '');
	$('#addBtn').hide();
	if (TEAM_ID) {
		api.get('/api/match/my-teams').then(function (r) {
			canCreate = (r.ok && (r.teams || []).some(t => String(t.id) === String(TEAM_ID))) || IS_LEADER;
			$('#addBtn').toggle(curPane === 'match' && canCreate);
		});
	}

	$('#addBtn').on('click', openModal);
	$('#cancelBtn').on('click', closeModal);
	$('#matchModal').on('click', e => { if (e.target.id === 'matchModal') closeModal(); });

	$('#lvlPicker .lvl').on('click', function () { $('#lvlPicker .lvl').removeClass('on'); $(this).addClass('on'); $('#level').val($(this).data('lv')); });
	$('#typePicker .lvl').on('click', function () { $('#typePicker .lvl').removeClass('on'); $(this).addClass('on'); $('#matchType').val($(this).data('v')); });
	$('#fType .region-chip').on('click', function () { $('#fType .region-chip').removeClass('on'); $(this).addClass('on'); currentType = $(this).data('v') || ''; renderList(); });
	$('#fLevel .region-chip').on('click', function () { $('#fLevel .region-chip').removeClass('on'); $(this).addClass('on'); currentLevel = $(this).data('v') || ''; renderList(); });
	$('#fManner .region-chip').on('click', function () { $('#fManner .region-chip').removeClass('on'); $(this).addClass('on'); currentManner = $(this).data('v') || ''; renderList(); });

	$('#placeSearch').on('click', function () {
		const kw = $('#placeName').val().trim();
		if (!kw || !mapReady || !naver.maps.Service) return;
		naver.maps.Service.geocode({ query: kw }, function (status, res) {
			if (status === naver.maps.Service.Status.OK && res.v2.addresses.length) {
				const a = res.v2.addresses[0];
				const ll = new naver.maps.LatLng(parseFloat(a.y), parseFloat(a.x));
				map.setCenter(ll); setPoint(ll); $('#placeName').val(a.roadAddress || a.jibunAddress || kw);
			} else alert('검색 결과가 없습니다. 도로명/지번 주소로 검색해보세요.');
		});
	});

	$('#matchForm').on('submit', async function (e) {
		e.preventDefault();
		if (!TEAM_ID || !IS_LEADER) { alert('현재 팀의 팀장만 경기를 등록할 수 있습니다.'); return; }
		if (!$('#level').val()) { alert('팀 수준(상/중/하)을 선택해주세요.'); return; }
		if ($('#startTime').val() && !validTime($('#startTime').val())) { alert('시작시간을 HH:MM 형식으로 입력해주세요. 예: 14:00'); return; }
		const body = {
			level: $('#level').val(),
			matchType: $('#matchType').val(),
			headcount: parseInt($('#headcount').val() || '0', 10),
			region: $('#region').val().trim(),
			placeName: $('#placeName').val().trim(),
			lat: $('#lat').val() ? parseFloat($('#lat').val()) : null,
			lng: $('#lng').val() ? parseFloat($('#lng').val()) : null,
			matchDate: $('#matchDate').val() || null,
			startTime: $('#startTime').val() || null,
			memo: $('#memo').val().trim()
		};
		const r = await api.post('/api/match?teamId=' + TEAM_ID, body);
		if (r.ok) { closeModal(); location.href = '/matches/' + r.id; } else alert(r.message || '등록 실패');
	});
});
</script>
</body>
</html>
