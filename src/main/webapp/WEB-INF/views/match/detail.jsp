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
		<div class="section-title">신청한 팀</div>
		<div class="card" id="appList"></div>
		<button class="btn-ghost btn-block" id="closeBtn" style="margin-bottom:14px;color:var(--red);">매칭 마감하기</button>
	</div>

	<!-- 상대팀 평가 (성사된 경기) -->
	<div class="card" id="rateCard" style="display:none;">
		<h3>상대팀 평가 · <span id="rateTarget"></span></h3>
		<div class="card-form" style="padding:0;box-shadow:none;">
			<label>매너 점수 (1~5)</label>
			<div class="region-row" id="mannerPick">
				<button type="button" class="region-chip" data-v="1">1</button>
				<button type="button" class="region-chip" data-v="2">2</button>
				<button type="button" class="region-chip" data-v="3">3</button>
				<button type="button" class="region-chip" data-v="4">4</button>
				<button type="button" class="region-chip" data-v="5">5</button>
			</div>
			<input type="hidden" id="mannerVal">
			<label>실력</label>
			<div class="lvl-picker" id="skillPick">
				<button type="button" class="lvl" data-v="HIGH">상</button>
				<button type="button" class="lvl" data-v="MID">중</button>
				<button type="button" class="lvl" data-v="LOW">하</button>
			</div>
			<input type="hidden" id="skillVal">
			<label>한마디 (선택)</label>
			<input type="text" id="rateComment" maxlength="300" placeholder="예: 매너 좋고 즐겁게 했어요!">
			<button class="btn-primary btn-block" id="rateBtn" style="margin-top:14px;">평가 제출</button>
		</div>
	</div>
	<div class="card muted small" id="ratedNote" style="display:none;text-align:center;">상대팀 평가를 완료했습니다. 감사합니다! 🙏</div>
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
		(mp.mannerAvg != null ? ' <span class="lvl-badge" style="background:#1a9d52;">🤝 매너 ' + mp.mannerAvg + ' (' + mp.mannerCount + ')</span>' : ''));
	$('#dRegion').text(mp.region || mp.placeName || '지역 미정');
	$('#dStatus').text(STATUS_LABEL[mp.status] || mp.status);
	$('#dTeam').text(mp.hostTeamName);
	let when = mp.matchDate ? (mp.matchDate.replaceAll('-', '.') + (mp.startTime ? ' ' + mp.startTime.slice(0,5) : '')) : '일정 협의';
	$('#dMeta').html('👥 ' + mp.headcount + '명 · 📅 ' + when + (mp.placeName ? ' · 📍 ' + esc(mp.placeName) : ''));
	$('#dMemo').text(mp.memo || '');

	showMap();

	// 호스트면 신청/지원 관리 영역
	if (isHost) {
		$('#hostArea').show();
		$('#closeBtn').text(isGuestRecruit ? '용병 모집 마감하기' : '매칭 마감하기');
		renderApps(r.applications || []);
	}

	// 상대팀 평가 (성사된 경기)
	if (r.canRate) { $('#rateCard').show(); $('#rateTarget').text(r.targetTeamName || '상대팀'); }
	else if (r.alreadyRated) { $('#ratedNote').show(); }

	if (isGuestRecruit) {
		// 용병 모집글: 개인 지원
		if (r.canApplyGuest) $('#guestApplyCard').show();
	} else {
		// 팀 매칭: 내 팀으로 신청
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

	// 상대팀 평가
	$('#mannerPick .region-chip').on('click', function () { $('#mannerPick .region-chip').removeClass('on'); $(this).addClass('on'); $('#mannerVal').val($(this).data('v')); });
	$('#skillPick .lvl').on('click', function () { $('#skillPick .lvl').removeClass('on'); $(this).addClass('on'); $('#skillVal').val($(this).data('v')); });
	$('#rateBtn').on('click', async function () {
		const manner = $('#mannerVal').val();
		if (!manner) { alert('매너 점수를 선택해주세요.'); return; }
		const r = await api.post('/api/match/' + MATCH_ID + '/rate', { manner: parseInt(manner, 10), skill: $('#skillVal').val() || null, comment: $('#rateComment').val().trim() });
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
