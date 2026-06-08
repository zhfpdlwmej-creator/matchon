<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<header class="app-header">
	<div class="app-header-inner">
		<a href="/teams" class="team-switch">
			<span class="emblem">${empty team.sportEmoji ? '🏟️' : team.sportEmoji}</span>
			<strong>${team.name}</strong>
			<span class="caret">▾</span>
		</a>
		<span class="role-badge role-${myRole}">
			<c:choose>
				<c:when test="${myRole == 'LEADER'}">팀장</c:when>
				<c:when test="${myRole == 'MANAGER'}">운영진</c:when>
				<c:otherwise>회원</c:otherwise>
			</c:choose>
		</span>
	</div>
</header>
