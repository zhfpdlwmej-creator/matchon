<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="theme-color" content="#1a7f37">
<link rel="stylesheet" href="/css/app.css">
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<c:if test="${not empty kakaoJsKey}">
<script src="https://t1.kakaocdn.net/kakao_js_sdk/2.7.2/kakao.min.js"></script>
<script>
	if (window.Kakao && !Kakao.isInitialized()) { Kakao.init('${kakaoJsKey}'); }
</script>
</c:if>
<script src="/js/app.js" defer></script>
