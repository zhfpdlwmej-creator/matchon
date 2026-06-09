/* matchon 서비스워커 — 웹 푸시 + 설치형 PWA */
self.addEventListener('install', function (e) { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });

/* 정적 자원 캐싱(stale-while-revalidate) — 화면 전환 속도 개선 */
var STATIC_CACHE = 'matchon-static-v1';
var STATIC_RE = /\.(css|js|png|jpg|jpeg|svg|webp|ico|woff2?)$/i;
var CDN_HOSTS = ['code.jquery.com', 'cdnjs.cloudflare.com', 't1.kakaocdn.net'];

self.addEventListener('fetch', function (e) {
	var req = e.request;
	if (req.method !== 'GET') return;
	var url = new URL(req.url);
	var isStatic = (url.origin === location.origin && STATIC_RE.test(url.pathname))
		|| CDN_HOSTS.indexOf(url.hostname) !== -1;
	if (!isStatic) return; // HTML/네비게이션/API/지도 등은 그대로 네트워크
	e.respondWith(
		caches.open(STATIC_CACHE).then(function (cache) {
			return cache.match(req).then(function (cached) {
				var net = fetch(req).then(function (res) {
					if (res && (res.status === 200 || res.type === 'opaque')) cache.put(req, res.clone());
					return res;
				}).catch(function () { return cached; });
				return cached || net;   // 캐시 있으면 즉시 반환 + 백그라운드 갱신
			});
		})
	);
});

self.addEventListener('push', function (e) {
	let d = { title: 'matchon', body: '', url: '/' };
	try { if (e.data) d = Object.assign(d, e.data.json()); }
	catch (_) { if (e.data) d.body = e.data.text(); }
	e.waitUntil(self.registration.showNotification(d.title, {
		body: d.body,
		data: { url: d.url || '/' },
		tag: d.url || 'matchon',
		renotify: true
	}));
});

self.addEventListener('notificationclick', function (e) {
	e.notification.close();
	const url = (e.notification.data && e.notification.data.url) || '/';
	e.waitUntil(
		self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
			for (const c of list) { if ('focus' in c) { c.navigate(url); return c.focus(); } }
			return self.clients.openWindow(url);
		})
	);
});
