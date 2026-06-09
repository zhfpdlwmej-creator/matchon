<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="profile" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 내 정보</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body>
<header class="app-header">
	<div class="app-header-inner">
		<span class="team-switch"><span class="emblem">⚙️</span><strong>내 정보</strong></span>
		<a href="/auth/logout" class="role-badge">로그아웃</a>
	</div>
</header>
<div class="app-wrap" style="padding-top:20px;">
	<div class="card-form" style="margin-bottom:22px;">
		<label>이름 (카카오 계정)</label>
		<div style="padding:13px 14px;border:1px solid var(--line);border-radius:11px;background:#f4f6f5;font-weight:700;">${fn:escapeXml(user.nickname)}</div>
		<div class="muted small" style="margin-top:6px;">이름은 카카오 계정 이름으로 자동 설정됩니다.</div>
	</div>

	<!-- 알림 설정 -->
	<div class="card" style="margin-bottom:24px;">
		<h3>🔔 알림</h3>
		<div class="muted small" id="pushDesc" style="margin-bottom:12px;">경기 등록·리마인드 알림을 폰으로 받습니다.</div>
		<button class="btn-primary btn-block" id="pushBtn">알림 켜기</button>
	</div>

	<div class="section-title" style="margin-top:8px;">내 팀</div>
	<div class="card" style="margin-bottom:22px;">
		<c:forEach var="t" items="${teams}">
			<a class="member-row" href="/team/${t.id}">
				<span class="emblem">${t.sportEmoji}</span>
				<span class="name">${fn:escapeXml(t.name)}</span>
				<span class="right muted small">이동 ›</span>
			</a>
		</c:forEach>
		<c:if test="${empty teams}"><div class="empty">가입한 팀이 없습니다.</div></c:if>
		<a href="/teams" class="btn-ghost btn-block" style="margin-top:10px;text-align:center;">+ 팀 추가 / 가입</a>
	</div>

	<div class="card" style="text-align:center;">
		<a href="/auth/logout" class="muted small">로그아웃</a>
		<div class="muted small" style="margin-top:10px;">
			<a href="/terms" class="muted">이용약관</a> · <a href="/privacy" class="muted">개인정보처리방침</a>
		</div>
	</div>

	<div class="muted" style="font-size:11px;line-height:1.6;text-align:center;padding:14px 12px 4px;">
		📱 <b>홈 화면에 앱으로 추가</b> (테스트 버전)<br>
		<b>아이폰</b>: 사파리에서 열기 → 하단 <b>공유(⬆️)</b> → <b>"홈 화면에 추가"</b><br>
		<b>안드로이드</b>: 크롬에서 하단 <b>"📲 앱 설치"</b> 버튼 → 설치 (또는 ⋮ 메뉴 → 앱 설치)<br>
		<span style="opacity:.8;">※ 카카오톡 내부 브라우저는 설치가 안 돼요 → ⋮ → "다른 브라우저로 열기"</span>
	</div>
</div>

<%@ include file="layout/bottomnav.jsp" %>
<script src="/js/push.js" defer></script>
</body>
</html>
