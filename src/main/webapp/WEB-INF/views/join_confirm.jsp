<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 가입 확인</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body class="page-login">
<div class="login-wrap">
	<div class="login-logo">
		<div class="logo-emblem">⚽</div>
		<h1>가입 확인</h1>
	</div>

	<div class="card" style="text-align:center;">
		<p style="margin:0 0 6px;">현재 <b style="color:var(--green);font-size:18px;">${fn:escapeXml(user.nickname)}</b> 님으로<br>로그인되어 있어요.</p>
		<p style="margin:10px 0 0;"><b>${fn:escapeXml(teamName)}</b> 팀에<br><u>이 계정</u>으로 가입 신청할까요?</p>

		<a href="/join/accept" class="btn-primary btn-block" style="margin-top:18px;">네, ${fn:escapeXml(user.nickname)}(으)로 가입 신청</a>
	</div>

	<p class="login-help">위 이름이 본인이 맞는지 확인 후 가입 신청해주세요.</p>
</div>
</body>
</html>
