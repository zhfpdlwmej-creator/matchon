<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<header class="app-header">
	<div class="app-header-inner">
		<a href="/teams" class="team-switch">
			<span class="emblem">${empty team.sportEmoji ? '🏟️' : team.sportEmoji}</span>
			<strong>${fn:escapeXml(team.name)}</strong>
			<span class="caret">▾</span>
		</a>
		<a href="/profile" class="role-badge role-${myRole}" title="내 계정 / 로그아웃">
			<c:if test="${not empty user}"><b>${fn:escapeXml(user.nickname)}</b> · </c:if><c:choose>
				<c:when test="${myRole == 'LEADER'}">팀장</c:when>
				<c:when test="${myRole == 'MANAGER'}">운영진</c:when>
				<c:otherwise>회원</c:otherwise>
			</c:choose>
		</a>
	</div>
</header>
