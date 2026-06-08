<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="schedule" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 포메이션</title>
	<%@ include file="../layout/head.jsp" %>
	<style>
		.pitch { position: relative; width: 100%; aspect-ratio: 3 / 4; border-radius: 14px; overflow: hidden;
			background: linear-gradient(180deg,#1f9d55,#15823f); box-shadow: var(--shadow); touch-action: none; }
		.pitch .line { position: absolute; border: 2px solid rgba(255,255,255,.55); }
		.pitch .halfway { top: 50%; left: 0; right: 0; border: none; border-top: 2px solid rgba(255,255,255,.55); }
		.pitch .circle { top: 50%; left: 50%; width: 26%; aspect-ratio: 1; transform: translate(-50%,-50%); border-radius: 50%; }
		.pitch .boxTop { top: 0; left: 22%; right: 22%; height: 16%; border-top: none; }
		.pitch .boxBot { bottom: 0; left: 22%; right: 22%; height: 16%; border-bottom: none; }
		.tok { position: absolute; transform: translate(-50%,-50%); min-width: 44px; max-width: 70px; padding: 6px 4px;
			background: #fff; border-radius: 10px; box-shadow: 0 2px 6px rgba(0,0,0,.3); text-align: center;
			font-size: 11px; font-weight: 700; cursor: grab; user-select: none; line-height: 1.15; }
		.tok.dragging { cursor: grabbing; z-index: 10; box-shadow: 0 6px 14px rgba(0,0,0,.4); }
		.tok .dot { display: block; width: 18px; height: 18px; margin: 0 auto 3px; border-radius: 50%; background: var(--green); color: #fff; font-size: 11px; line-height: 18px; }
		.bench { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
		.bench .btok { padding: 8px 12px; background: #fff; border: 1px solid var(--line); border-radius: 999px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; }
		.bench .btok .x { color: var(--red); font-weight: 700; }
	</style>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<a href="/team/${team.id}/schedule/${scheduleId}" class="small muted">‹ 경기 상세</a>
	<div class="section-title" style="margin-top:6px;">포메이션 <span class="muted small" id="fmTitle"></span></div>

	<div class="pitch" id="pitch">
		<div class="line halfway"></div>
		<div class="line circle"></div>
		<div class="line boxTop"></div>
		<div class="line boxBot"></div>
	</div>

	<div class="muted small" style="margin-top:8px;">벤치의 선수를 탭하면 필드에 올라가고, 필드에서 드래그로 위치 조정 · 탭하면 벤치로 내려갑니다.</div>

	<div id="presetWrap" style="display:none;margin-top:12px;">
		<div class="small" style="font-weight:700;margin-bottom:6px;">인원</div>
		<div class="region-row" id="countSel">
			<button class="region-chip on" data-c="11">11명</button>
			<button class="region-chip" data-c="8">8명</button>
			<button class="region-chip" data-c="6">6명</button>
			<button class="region-chip" data-c="5">5명</button>
		</div>
		<div class="small" style="font-weight:700;margin:12px 0 6px;">포메이션 프리셋</div>
		<div class="region-row" id="presets"></div>
	</div>

	<div class="section-title" style="margin-left:0;">벤치</div>
	<div class="bench" id="bench"></div>

	<div style="display:flex;gap:8px;margin-top:10px;">
		<input type="text" id="customName" placeholder="선수 직접 추가" style="flex:1;min-width:0;padding:10px 12px;border:1px solid var(--line);border-radius:10px;">
		<button class="btn-ghost btn-sm" id="addCustom">＋ 추가</button>
		<button class="btn-ghost btn-sm" id="reloadRoster">참석자 불러오기</button>
	</div>

	<c:if test="${canManage}">
		<button class="btn-primary btn-block" id="saveFm" style="margin-top:14px;">저장</button>
	</c:if>
	<c:if test="${!canManage}">
		<div class="muted small" style="text-align:center;margin-top:12px;">저장은 팀장/운영진만 가능합니다.</div>
	</c:if>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const SCHEDULE_ID = ${scheduleId};
const CAN_MANAGE = ${canManage};
let SPORT = 'SOCCER';
let tokens = [];   // { id, label, x, y }  (x/y null = 벤치)
let seq = 1;

// 인원수별 프리셋 (GK 1명 포함 좌표, 위쪽이 공격 방향)
const PRESETS = {
	'11': {
		'4-4-2': [[50,88],[15,70],[38,70],[62,70],[85,70],[15,46],[38,46],[62,46],[85,46],[38,22],[62,22]],
		'4-3-3': [[50,88],[15,70],[38,70],[62,70],[85,70],[30,50],[50,52],[70,50],[22,24],[50,18],[78,24]],
		'3-5-2': [[50,88],[25,72],[50,72],[75,72],[12,50],[34,48],[50,50],[66,48],[88,50],[40,22],[60,22]],
		'3-4-3': [[50,88],[25,72],[50,72],[75,72],[15,50],[38,50],[62,50],[85,50],[25,24],[50,20],[75,24]]
	},
	'8': {
		'3-3-1': [[50,90],[20,70],[50,70],[80,70],[20,46],[50,46],[80,46],[50,22]],
		'2-3-2': [[50,90],[35,72],[65,72],[20,48],[50,48],[80,48],[35,24],[65,24]],
		'3-1-3': [[50,90],[20,72],[50,72],[80,72],[50,50],[22,26],[50,22],[78,26]],
		'2-4-1': [[50,90],[35,72],[65,72],[15,48],[38,48],[62,48],[85,48],[50,24]]
	},
	'6': {
		'2-2-1': [[50,88],[35,68],[65,68],[35,46],[65,46],[50,24]],
		'1-3-1': [[50,88],[50,70],[25,48],[50,48],[75,48],[50,24]],
		'2-1-2': [[50,88],[35,70],[65,70],[50,48],[35,26],[65,26]]
	},
	'5': {
		'1-2-1': [[50,88],[50,70],[30,48],[70,48],[50,26]],
		'2-1-1': [[50,88],[35,70],[65,70],[50,48],[50,26]],
		'2-0-2': [[50,88],[35,66],[65,66],[35,40],[65,40]]
	}
};
let curCount = '11';

function render() {
	// 필드 토큰
	$('#pitch .tok').remove();
	const pitch = document.getElementById('pitch');
	tokens.filter(t => t.x != null).forEach(t => {
		const el = document.createElement('div');
		el.className = 'tok'; el.dataset.id = t.id;
		el.style.left = t.x + '%'; el.style.top = t.y + '%';
		el.innerHTML = '<span class="dot">' + (t.label[0] || '·') + '</span>' + esc(t.label);
		pitch.appendChild(el);
		makeDraggable(el, t);
	});
	// 벤치
	const bench = $('#bench').empty();
	const benched = tokens.filter(t => t.x == null);
	if (!benched.length) bench.html('<div class="muted small">벤치가 비었어요.</div>');
	benched.forEach(t => {
		const b = $('<div class="btok">' + esc(t.label) + ' <span class="x" data-del="' + t.id + '">✕</span></div>');
		b.on('click', function (e) {
			if ($(e.target).attr('data-del')) { tokens = tokens.filter(x => x.id !== t.id); render(); return; }
			t.x = 50; t.y = 50; render();   // 필드 중앙에 올림
		});
		bench.append(b);
	});
}

function makeDraggable(el, t) {
	let moved = false, startX, startY;
	el.addEventListener('pointerdown', function (e) {
		e.preventDefault(); moved = false; startX = e.clientX; startY = e.clientY;
		el.setPointerCapture(e.pointerId); el.classList.add('dragging');
	});
	el.addEventListener('pointermove', function (e) {
		if (!el.classList.contains('dragging')) return;
		if (Math.abs(e.clientX - startX) > 3 || Math.abs(e.clientY - startY) > 3) moved = true;
		const r = document.getElementById('pitch').getBoundingClientRect();
		let x = (e.clientX - r.left) / r.width * 100;
		let y = (e.clientY - r.top) / r.height * 100;
		t.x = Math.max(3, Math.min(97, x)); t.y = Math.max(3, Math.min(97, y));
		el.style.left = t.x + '%'; el.style.top = t.y + '%';
	});
	el.addEventListener('pointerup', function (e) {
		el.classList.remove('dragging');
		if (!moved) { t.x = null; t.y = null; render(); }   // 탭 → 벤치로
	});
}

function addToken(label) {
	if (!label || !label.trim()) return;
	tokens.push({ id: seq++, label: label.trim().slice(0, 8), x: null, y: null });
}

function renderPresets(count) {
	curCount = count;
	const box = $('#presets').empty();
	Object.keys(PRESETS[count]).forEach(name =>
		box.append('<button type="button" class="region-chip" data-name="' + name + '">' + name + '</button>'));
}
function applyPreset(pos) {
	if (!pos) return;
	let i = 0;
	// 이미 필드에 있는 선수 + 벤치 순으로 자리 채움
	const ordered = tokens.slice().sort((a, b) => (a.x == null) - (b.x == null));
	ordered.forEach(t => { if (i < pos.length) { t.x = pos[i][0]; t.y = pos[i][1]; i++; } else { t.x = null; t.y = null; } });
	render();
}

async function loadRoster(merge) {
	const r = await api.get('/api/attendance/list?scheduleId=' + SCHEDULE_ID);
	if (!r.ok) return;
	const names = [];
	(r.summary.attendList || []).forEach(m => names.push(m.nickname));
	(r.summary.guests || []).forEach(g => { for (let k = 0; k < g.headcount; k++) names.push(g.name + (g.headcount > 1 ? (k + 1) : '')); });
	if (!merge) tokens = [];
	const existing = new Set(tokens.map(t => t.label));
	names.forEach(n => { if (!existing.has(n)) addToken(n); });
	render();
}

async function load() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID + '/formation');
	if (r.ok) {
		$('#fmTitle').text(r.title ? '· ' + r.title : '');
		SPORT = r.sport || 'SOCCER';
		$('#presetWrap').toggle(SPORT === 'SOCCER');
		if (r.formation) {
			try {
				const data = JSON.parse(r.formation);
				tokens = (data.tokens || []).map(t => ({ id: seq++, label: t.label, x: t.x, y: t.y }));
			} catch (e) {}
		}
	}
	if (!tokens.length) await loadRoster(false);
	else render();
}

$(function () {
	load();
	renderPresets('11');
	$('#countSel .region-chip').on('click', function () {
		$('#countSel .region-chip').removeClass('on'); $(this).addClass('on');
		renderPresets($(this).data('c'));
	});
	$('#presets').on('click', '.region-chip', function () {
		$('#presets .region-chip').removeClass('on'); $(this).addClass('on');
		applyPreset(PRESETS[curCount][$(this).data('name')]);
	});
	$('#addCustom').on('click', function () { addToken($('#customName').val()); $('#customName').val(''); render(); });
	$('#customName').on('keypress', e => { if (e.which === 13) { addToken($('#customName').val()); $('#customName').val(''); render(); } });
	$('#reloadRoster').on('click', function () { if (confirm('현재 참석자/용병을 벤치로 다시 불러올까요?')) loadRoster(true); });
	$('#saveFm').on('click', async function () {
		const data = { tokens: tokens.map(t => ({ label: t.label, x: t.x, y: t.y })) };
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/formation', { data: JSON.stringify(data) });
		alert(r.ok ? '저장했습니다.' : (r.message || '실패'));
	});
});
</script>
</body>
</html>
