/* 웹 푸시 구독 — 내정보 화면의 #pushBtn 에서 사용 */
(function () {
	function urlB64ToUint8(base64) {
		const pad = '='.repeat((4 - base64.length % 4) % 4);
		const b64 = (base64 + pad).replace(/-/g, '+').replace(/_/g, '/');
		const raw = atob(b64);
		const out = new Uint8Array(raw.length);
		for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
		return out;
	}

	async function setup() {
		const btn = document.getElementById('pushBtn');
		const desc = document.getElementById('pushDesc');
		if (!btn) return;

		if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
			btn.textContent = '이 브라우저는 알림 미지원';
			btn.disabled = true;
			if (desc) desc.textContent = 'iOS는 Safari에서 "홈 화면에 추가" 후 사용할 수 있어요.';
			return;
		}

		let reg;
		try { reg = await navigator.serviceWorker.register('/sw.js'); }
		catch (e) { btn.textContent = '알림 사용 불가'; btn.disabled = true; return; }

		const existing = await reg.pushManager.getSubscription();
		if (existing && Notification.permission === 'granted') {
			btn.textContent = '✅ 알림 켜짐 (테스트 발송)';
			btn.onclick = function () { window.api && api.post('/api/push/test', {}).then(function () { alert('테스트 알림을 보냈어요!'); }); };
			return;
		}

		btn.textContent = '🔔 알림 켜기';
		btn.onclick = async function () {
			const perm = await Notification.requestPermission();
			if (perm !== 'granted') { alert('알림 권한을 허용해야 받을 수 있어요.'); return; }
			const keyRes = await api.get('/api/push/key');
			if (!keyRes.ok || !keyRes.key) { alert('알림 설정이 비활성화되어 있습니다.'); return; }
			let sub;
			try {
				sub = await reg.pushManager.subscribe({
					userVisibleOnly: true,
					applicationServerKey: urlB64ToUint8(keyRes.key)
				});
			} catch (e) { alert('구독 실패: ' + e.message); return; }
			const j = sub.toJSON();
			const r = await api.post('/api/push/subscribe', { endpoint: sub.endpoint, keys: j.keys });
			if (r.ok) { btn.textContent = '✅ 알림 켜짐'; alert('알림이 켜졌습니다! 경기 등록·리마인드를 폰으로 받아요.'); }
			else alert(r.message || '구독 저장 실패');
		};
	}

	if (document.readyState !== 'loading') setup();
	else document.addEventListener('DOMContentLoaded', setup);
})();
