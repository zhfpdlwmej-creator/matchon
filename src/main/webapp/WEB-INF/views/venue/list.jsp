<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="venue" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 구장 정보</title>
	<%@ include file="../layout/head.jsp" %>
	<c:if test="${not empty kakaoJsKey}">
		<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoJsKey}&libraries=services&autoload=false"></script>
	</c:if>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="section-title">자주 가는 구장</div>
	<div class="muted small" style="padding:0 4px 8px;">팀이 자주 쓰는 구장을 저장해두면, 일정 등록 시 빠르게 선택할 수 있어요.</div>
	<div id="vViewMap" style="width:100%;height:220px;border-radius:12px;margin-bottom:12px;display:none;"></div>
	<div id="venueList"><div class="empty">불러오는 중...</div></div>

	<c:if test="${canManage}">
		<div class="card" style="margin-top:14px;">
			<h3>구장 추가</h3>
			<div style="display:flex;gap:8px;margin:8px 0;">
				<input type="text" id="vName" maxlength="120" placeholder="구장 이름/주소 검색 (예: 잠실 풋살장)" style="flex:1;min-width:0;">
				<button type="button" class="btn-ghost btn-sm" id="vSearch">검색</button>
			</div>
			<div id="vMap" style="width:100%;height:200px;border-radius:12px;background:#eef1f0;"></div>
			<div class="muted small" id="vHint" style="margin:6px 0;">검색하거나 지도를 탭해 위치를 지정하세요.</div>
			<input type="text" id="vMemo" maxlength="300" placeholder="메모 (가격·주차·구장번호 등)" style="width:100%;padding:10px;border:1px solid var(--line);border-radius:10px;margin-bottom:8px;">
			<input type="hidden" id="vLat"><input type="hidden" id="vLng"><input type="hidden" id="vAddr">
			<button class="btn-primary btn-block" id="vAdd">구장 저장</button>
		</div>
	</c:if>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const CAN_MANAGE = ${canManage};
let vmap, vmarker, vgeo, vready = false;

async function load() {
	const r = await api.get('/api/team/' + TEAM_ID + '/venues');
	const box = $('#venueList').empty();
	if (!r.ok) return;
	if (!r.venues.length) { box.html('<div class="empty"><div class="big">📍</div>저장된 구장이 없어요.</div>'); return; }
	r.venues.forEach(function (v) {
		const del = CAN_MANAGE ? '<a href="javascript:void(0)" class="delV muted small" data-id="' + v.id + '">삭제</a>' : '';
		const mapLink = (v.lat != null) ? '<a href="javascript:void(0)" class="vView small" style="color:var(--green);" data-lat="' + v.lat + '" data-lng="' + v.lng + '" data-name="' + esc(v.name) + '">📍 지도</a>' : '';
		box.append(
			'<div class="card" style="margin-bottom:10px;">' +
			'<div style="display:flex;align-items:center;gap:6px;">' +
			'<span class="title" style="font-weight:800;">📍 ' + esc(v.name) + '</span>' +
			'<span class="right" style="gap:8px;">' + mapLink + ' ' + del + '</span></div>' +
			(v.address ? '<div class="meta muted small" style="margin-top:4px;">' + esc(v.address) + '</div>' : '') +
			(v.memo ? '<div class="meta small" style="margin-top:4px;">📝 ' + esc(v.memo) + '</div>' : '') +
			'</div>');
	});
}

function ensureMap() {
	if (!window.kakao || !kakao.maps) { $('#vHint').text('카카오맵 키 미설정 — 이름만 저장해도 됩니다.'); $('#vMap').hide(); return; }
	kakao.maps.load(function () {
		if (!vready) {
			const c = new kakao.maps.LatLng(37.5145, 127.1066);
			vmap = new kakao.maps.Map(document.getElementById('vMap'), { center: c, level: 4 });
			vmarker = new kakao.maps.Marker({ position: c }); vmarker.setMap(vmap);
			vgeo = new kakao.maps.services.Geocoder();
			kakao.maps.event.addListener(vmap, 'click', function (me) { setPoint(me.latLng, true); });
			vready = true;
		}
		vmap.relayout();
	});
}
function setPoint(ll, fill) {
	vmarker.setPosition(ll);
	$('#vLat').val(ll.getLat()); $('#vLng').val(ll.getLng());
	if (fill && vgeo) vgeo.coord2Address(ll.getLng(), ll.getLat(), function (res, st) {
		if (st === kakao.maps.services.Status.OK && res[0]) {
			const a = res[0].road_address ? res[0].road_address.address_name : res[0].address.address_name;
			$('#vAddr').val(a || '');
			if (!$('#vName').val().trim()) $('#vName').val(a || '');
		}
	});
}

let viewMap, viewMarker, viewReady = false;
function showVenue(lat, lng) {
	$('#vViewMap').show();
	if (!window.kakao || !kakao.maps) { alert('지도를 불러올 수 없습니다.'); return; }
	kakao.maps.load(function () {
		if (!viewReady) {
			viewMap = new kakao.maps.Map(document.getElementById('vViewMap'), { center: new kakao.maps.LatLng(lat, lng), level: 4 });
			viewMarker = new kakao.maps.Marker(); viewMarker.setMap(viewMap);
			viewReady = true;
		}
		const ll = new kakao.maps.LatLng(lat, lng);
		viewMap.relayout(); viewMap.setCenter(ll); viewMarker.setPosition(ll);
	});
}

$(function () {
	load();
	if (CAN_MANAGE) setTimeout(ensureMap, 200);

	$('#venueList').on('click', '.vView', function () {
		showVenue(parseFloat($(this).data('lat')), parseFloat($(this).data('lng')));
		$('html,body').animate({ scrollTop: Math.max(0, $('#vViewMap').offset().top - 60) }, 200);
	});

	$('#vSearch').on('click', function () {
		const kw = $('#vName').val().trim();
		if (!kw || !vready || !kakao.maps.services) { alert('지도를 불러오는 중이거나 검색어가 없습니다.'); return; }
		const ps = new kakao.maps.services.Places();
		ps.keywordSearch(kw, function (data, st) {
			if (st === kakao.maps.services.Status.OK && data.length) {
				const f = data[0], ll = new kakao.maps.LatLng(f.y, f.x);
				vmap.setCenter(ll); vmarker.setPosition(ll);
				$('#vLat').val(f.y); $('#vLng').val(f.x); $('#vAddr').val(f.road_address_name || f.address_name || '');
				$('#vName').val(f.place_name);
			} else alert('검색 결과가 없습니다.');
		});
	});

	$('#vAdd').on('click', async function () {
		const name = $('#vName').val().trim();
		if (!name) { alert('구장 이름을 입력하세요.'); return; }
		const body = { name: name, address: $('#vAddr').val() || null, memo: $('#vMemo').val().trim() || null,
			lat: $('#vLat').val() ? parseFloat($('#vLat').val()) : null, lng: $('#vLng').val() ? parseFloat($('#vLng').val()) : null };
		const r = await api.post('/api/team/' + TEAM_ID + '/venues', body);
		if (r.ok) { $('#vName,#vMemo,#vLat,#vLng,#vAddr').val(''); load(); } else alert(r.message || '저장 실패');
	});

	$('#venueList').on('click', '.delV', async function () {
		if (!confirm('이 구장을 삭제할까요?')) return;
		const r = await api.del('/api/team/' + TEAM_ID + '/venues/' + $(this).data('id'));
		if (r.ok) load(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
