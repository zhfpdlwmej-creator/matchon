<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:choose>
	<%-- 팀 컨텍스트가 있을 때: 메인 메뉴 --%>
	<c:when test="${not empty team}">
		<nav class="bottom-nav">
			<a href="/team/${team.id}" class="nav-item ${navActive == 'home' ? 'active' : ''}">
				<span class="ic">🏠</span><span>홈</span>
			</a>
			<a href="/team/${team.id}/schedules" class="nav-item ${navActive == 'schedule' ? 'active' : ''}">
				<span class="ic">📅</span><span>일정</span>
			</a>
			<a href="/matches" class="nav-item ${navActive == 'matches' ? 'active' : ''}">
				<span class="ic">⚔️</span><span>매칭</span>
			</a>
			<a href="/team/${team.id}/stats" class="nav-item ${navActive == 'stats' ? 'active' : ''}">
				<span class="ic">📊</span><span>통계</span>
			</a>
			<a href="javascript:void(0)" class="nav-item" onclick="openDrawer()">
				<span class="ic">☰</span><span>더보기</span>
			</a>
		</nav>
	</c:when>
	<%-- 팀이 없을 때(개인): 홈/매칭/팀/더보기 --%>
	<c:otherwise>
		<nav class="bottom-nav">
			<a href="/" class="nav-item"><span class="ic">🏠</span><span>홈</span></a>
			<a href="/matches" class="nav-item ${navActive == 'matches' ? 'active' : ''}"><span class="ic">⚔️</span><span>매칭</span></a>
			<a href="/teams" class="nav-item"><span class="ic">👥</span><span>팀</span></a>
			<a href="javascript:void(0)" class="nav-item" onclick="openDrawer()"><span class="ic">☰</span><span>더보기</span></a>
		</nav>
	</c:otherwise>
</c:choose>

<%-- 더보기 드로어: 메인 외 메뉴 --%>
<div class="drawer-back" id="appDrawer" onclick="if(event.target===this) closeDrawer()">
	<div class="drawer">
		<div class="d-head">
			<strong><c:out value="${empty user ? '내 계정' : user.nickname}" /></strong>
			<span class="d-close" onclick="closeDrawer()">✕</span>
		</div>

		<div class="d-sec">내 팀</div>
		<c:forEach var="t" items="${teams}">
			<a href="/team/${t.id}" class="d-item ${not empty team and team.id == t.id ? 'on' : ''}"><span class="ic">⚽</span>${fn:escapeXml(t.name)}</a>
		</c:forEach>
		<a href="/teams" class="d-item"><span class="ic">＋</span>팀 추가 / 가입</a>

		<div class="d-sec">메뉴</div>
		<c:if test="${not empty team}">
			<a href="/team/${team.id}/board" class="d-item"><span class="ic">📝</span>팀 게시판</a>
			<a href="/team/${team.id}/members" class="d-item"><span class="ic">👥</span>팀원 관리</a>
		</c:if>
		<a href="/profile" class="d-item"><span class="ic">⚙️</span>내정보 · 설정</a>

		<div class="d-sec">기타</div>
		<a href="/terms" class="d-item"><span class="ic">📄</span>이용약관 · 개인정보</a>
		<a href="/auth/logout" class="d-item" style="color:var(--red);"><span class="ic">↩</span>로그아웃</a>
	</div>
</div>
<script>
	function openDrawer() { document.getElementById('appDrawer').classList.add('open'); }
	function closeDrawer() { document.getElementById('appDrawer').classList.remove('open'); }
</script>
