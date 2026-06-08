<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 로그인</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body class="page-login">
<div class="login-wrap">
	<div class="login-logo">
		<img src="/img/logo.png" alt="matchon" style="width:230px;max-width:82%;border-radius:20px;display:block;margin:0 auto;box-shadow:0 6px 20px rgba(0,0,0,.18);">
		<p class="tagline" style="margin-top:16px;">⚽ 축구·풋살 팀<br>매칭 · 출석 · 포메이션 올인원</p>
	</div>

	<c:if test="${param.err != null}">
		<div class="alert">로그인에 실패했습니다. 다시 시도해주세요.</div>
	</c:if>

	<a href="/auth/kakao" class="btn-kakao">
		<span class="kakao-ic">💬</span> 카카오로 시작하기
	</a>

	<p class="login-help">최초 로그인 시 닉네임만 설정하면 바로 사용할 수 있어요.</p>
</div>
</body>
</html>
