<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="theme-color" content="#ffffff">
<link rel="manifest" href="/manifest.webmanifest">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="matchon">
<link rel="apple-touch-icon" href="/icons/icon-192.png?v=3">
<link rel="icon" href="/favicon.ico?v=3" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32.png?v=3">
<link rel="icon" type="image/png" sizes="16x16" href="/icons/favicon-16.png?v=3">
<script>
	// 설치형 PWA: 모든 페이지에서 서비스워커 등록
	if ('serviceWorker' in navigator) {
		window.addEventListener('load', function () { navigator.serviceWorker.register('/sw.js').catch(function () {}); });
	}
	// 안드로이드/크롬: '앱 설치' 버튼 노출
	(function () {
		var deferred = null;
		window.addEventListener('beforeinstallprompt', function (e) {
			e.preventDefault(); deferred = e;
			if (document.getElementById('pwaInstall')) return;
			var b = document.createElement('button');
			b.id = 'pwaInstall'; b.textContent = '📲 앱 설치';
			b.style.cssText = 'position:fixed;left:50%;transform:translateX(-50%);bottom:74px;z-index:9999;background:#16a34a;color:#fff;border:none;border-radius:999px;padding:10px 18px;font-weight:700;box-shadow:0 4px 14px rgba(0,0,0,.22);cursor:pointer;';
			b.onclick = function () { b.remove(); if (deferred) { deferred.prompt(); deferred.userChoice.finally(function () { deferred = null; }); } };
			(document.body || document.documentElement).appendChild(b);
		});
		window.addEventListener('appinstalled', function () { var b = document.getElementById('pwaInstall'); if (b) b.remove(); });
	})();
</script>
<link rel="dns-prefetch" href="https://t1.kakaocdn.net">
<link rel="dns-prefetch" href="https://oapi.map.naver.com">
<link rel="dns-prefetch" href="https://cdnjs.cloudflare.com">
<link rel="stylesheet" href="/css/app.css">
<script src="/js/jquery-3.7.1.min.js"></script>
<c:if test="${not empty kakaoJsKey}">
<script defer src="https://t1.kakaocdn.net/kakao_js_sdk/2.7.2/kakao.min.js"></script>
<script>
	window.addEventListener('load', function () { if (window.Kakao && !Kakao.isInitialized()) Kakao.init('${kakaoJsKey}'); });
</script>
</c:if>
<script src="/js/app.js" defer></script>
