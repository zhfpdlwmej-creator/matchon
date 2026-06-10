<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="settings" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 팀 관리</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="section-title">팀 관리</div>

	<div class="card-form">
		<label>팀명</label>
		<input type="text" id="tName" maxlength="40" value="${fn:escapeXml(team.name)}">

		<label>팀 소개</label>
		<textarea id="tDesc" maxlength="255" rows="2" placeholder="예: 매주 일요일 아침 풋살">${fn:escapeXml(team.description)}</textarea>

		<label>연령대</label>
		<div class="lvl-picker" id="tAge">
			<button type="button" class="lvl" data-v="AGE_20">20대</button>
			<button type="button" class="lvl" data-v="AGE_30">30대</button>
			<button type="button" class="lvl" data-v="AGE_40">40대+</button>
			<button type="button" class="lvl" data-v="MIX">혼합</button>
		</div>
		<input type="hidden" id="tAgeV" value="${team.ageGroup}">

		<label>팀 실력</label>
		<div class="lvl-picker" id="tLevel">
			<button type="button" class="lvl" data-v="HIGH">상</button>
			<button type="button" class="lvl" data-v="MID">중</button>
			<button type="button" class="lvl" data-v="LOW">하</button>
		</div>
		<input type="hidden" id="tLevelV" value="${team.level}">

		<label>활동 지역 (도 → 시/군/구)</label>
		<div id="tRegion"></div>
		<input type="hidden" id="tRegionV" value="${fn:escapeXml(team.region)}">
		<div class="muted small" style="margin:2px 0 8px;">현재: <b id="tRegionCur">${empty team.region ? '미설정' : fn:escapeXml(team.region)}</b></div>

		<label>인원부족 알림 기준 (명)</label>
		<input type="number" id="tMin" min="0" value="${team.minAttendees}">
		<div class="muted small" style="margin-top:2px;">참석 인원이 이 수보다 적으면 인원부족 알림이 갑니다. (0 = 미사용)</div>

		<button class="btn-primary btn-block" id="saveBtn" style="margin-top:16px;">저장</button>
	</div>

	<div class="muted small" style="text-align:center;margin-top:14px;">팀명·연령대·실력은 매칭/팀 프로필에 활용됩니다.</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script src="/js/regions.js" defer></script>
<script>
const TEAM_ID = ${team.id};

$(function () {
	$('#tAge .lvl[data-v="' + $('#tAgeV').val() + '"]').addClass('on');
	$('#tLevel .lvl[data-v="' + $('#tLevelV').val() + '"]').addClass('on');
	$('#tAge .lvl').on('click', function () { $('#tAge .lvl').removeClass('on'); $(this).addClass('on'); $('#tAgeV').val($(this).data('v')); });
	$('#tLevel .lvl').on('click', function () { $('#tLevel .lvl').removeClass('on'); $(this).addClass('on'); $('#tLevelV').val($(this).data('v')); });

	buildRegionPicker('#tRegion', { onChange: function (region) { $('#tRegionV').val(region); $('#tRegionCur').text(region || '미설정'); } });

	$('#saveBtn').on('click', async function () {
		const body = {
			name: $('#tName').val().trim(),
			description: $('#tDesc').val().trim(),
			ageGroup: $('#tAgeV').val(),
			level: $('#tLevelV').val(),
			region: $('#tRegionV').val().trim(),
			minAttendees: parseInt($('#tMin').val() || '0', 10)
		};
		const r = await api.post('/api/team/' + TEAM_ID + '/settings', body);
		if (r.ok) { alert('저장했습니다.'); location.reload(); } else alert(r.message || '저장 실패');
	});
});
</script>
</body>
</html>
