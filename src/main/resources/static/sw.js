/* matchon 서비스워커 — 웹 푸시 */
self.addEventListener('install', function (e) { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });

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
