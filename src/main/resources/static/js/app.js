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

	/* 숫자 입력 천단위 콤마 */
	global.commaNumber = function (v) {
		var n = String(v == null ? '' : v).replace(/[^\d]/g, '');
		return n ? Number(n).toLocaleString('ko-KR') : '';
	};
	global.unComma = function (v) {
		return parseInt(String(v == null ? '' : v).replace(/[^\d]/g, ''), 10) || 0;
	};
	global.bindComma = function (sel) {
		$(sel).attr('inputmode', 'numeric').on('input', function () { this.value = commaNumber(this.value); });
	};

	/* 시간 직접 입력 — 숫자만 치면 HH:MM 자동 포맷 (예: 2000 → 20:00) */
	global.formatTimeInput = function (v) {
		var d = String(v == null ? '' : v).replace(/[^\d]/g, '').slice(0, 4);
		if (d.length >= 3) return d.slice(0, 2) + ':' + d.slice(2);
		return d;
	};
	global.bindTime = function (sel) {
		$(sel).attr({ inputmode: 'numeric', maxlength: 5, placeholder: '예: 20:00' })
			.on('input', function () { this.value = formatTimeInput(this.value); });
	};
	global.validTime = function (v) { return /^([01]\d|2[0-3]):([0-5]\d)$/.test(v); };

	/* 경기 일정을 카카오톡 단톡방에 공유 (투표 버튼 포함).
	   o = { teamName, title, when, place, url } */
	global.kakaoShareSchedule = function (o) {
		var text = '⚽ [' + o.teamName + '] 새 경기 일정\n\n'
			+ o.title + '\n' + o.when
			+ (o.place ? '\n📍 ' + o.place : '')
			+ '\n\n참석 여부를 투표해주세요!';
		if (global.Kakao && Kakao.isInitialized && Kakao.isInitialized()) {
			try {
				Kakao.Share.sendDefault({
					objectType: 'text',
					text: text,
					link: { mobileWebUrl: o.url, webUrl: o.url },
					buttonTitle: '참석 투표하기'
				});
				return;
			} catch (e) { /* 폴백으로 진행 */ }
		}
		// SDK 미초기화(키 없음/도메인 미등록) 시 메시지 복사 폴백
		var msg = text + '\n\n▶ 참석 투표: ' + o.url;
		if (navigator.clipboard) {
			navigator.clipboard.writeText(msg).then(
				function () { alert('공유 메시지를 복사했어요.\n카카오톡 단톡방에 붙여넣어 보내세요!'); },
				function () { prompt('아래 내용을 복사해 단톡방에 붙여넣으세요', msg); });
		} else {
			prompt('아래 내용을 복사해 단톡방에 붙여넣으세요', msg);
		}
	};
})(window);
