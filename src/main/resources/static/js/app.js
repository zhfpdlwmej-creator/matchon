/* matchon 공통 스크립트 — fetch 래퍼 + 유틸 */
(function (global) {
	async function request(method, url, body) {
		const opts = {
			method: method,
			headers: { 'Content-Type': 'application/json' },
			credentials: 'same-origin'
		};
		if (body !== undefined) opts.body = JSON.stringify(body);
		try {
			const res = await fetch(url, opts);
			const text = await res.text();
			let data = {};
			try { data = text ? JSON.parse(text) : {}; } catch (e) { data = { ok: false, message: text }; }
			if (!res.ok && data.ok === undefined) data.ok = false;
			return data;
		} catch (e) {
			return { ok: false, message: '네트워크 오류' };
		}
	}

	global.api = {
		get: (url) => request('GET', url),
		post: (url, body) => request('POST', url, body),
		put: (url, body) => request('PUT', url, body),
		del: (url) => request('DELETE', url)
	};

	/* HTML escape — XSS 방어 */
	global.esc = function (s) {
		if (s == null) return '';
		return String(s).replace(/[&<>"']/g, function (c) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
		});
	};

	/* 숫자 → 1,000 콤마 */
	global.won = function (n) {
		return (n || 0).toLocaleString('ko-KR') + '원';
	};

	global.posBadge = function (pos) {
		if (!pos) return '';
		return '<span class="pos-badge pos-' + pos + '">' + pos + '</span>';
	};
})(window);
