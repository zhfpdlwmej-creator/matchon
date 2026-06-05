<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<nav class="bottom-nav">
	<a href="/team/${team.id}" class="nav-item ${navActive == 'home' ? 'active' : ''}">
		<span class="ic">🏠</span><span>홈</span>
	</a>
	<a href="/team/${team.id}/schedules" class="nav-item ${navActive == 'schedule' ? 'active' : ''}">
		<span class="ic">📅</span><span>일정</span>
	</a>
	<a href="/team/${team.id}/members" class="nav-item ${navActive == 'members' ? 'active' : ''}">
		<span class="ic">👥</span><span>팀원</span>
	</a>
	<a href="/team/${team.id}/stats" class="nav-item ${navActive == 'stats' ? 'active' : ''}">
		<span class="ic">📊</span><span>통계</span>
	</a>
	<a href="/profile" class="nav-item ${navActive == 'profile' ? 'active' : ''}">
		<span class="ic">⚙️</span><span>내정보</span>
	</a>
</nav>
