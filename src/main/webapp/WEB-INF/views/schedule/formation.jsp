<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="schedule" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 포메이션</title>
	<%@ include file="../layout/head.jsp" %>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
	<style>
		.pitch { position: relative; width: 100%; aspect-ratio: 3 / 4; border-radius: 14px; overflow: hidden;
			background: linear-gradient(180deg,#1f9d55,#15823f); box-shadow: var(--shadow); touch-action: pan-y; }
		.pitch .line { position: absolute; border: 2px solid rgba(255,255,255,.55); }
		.pitch .halfway { top: 50%; left: 0; right: 0; border: none; border-top: 2px solid rgba(255,255,255,.55); }
		.pitch .circle { top: 50%; left: 50%; width: 26%; aspect-ratio: 1; transform: translate(-50%,-50%); border-radius: 50%; }
		.pitch .boxTop { top: 0; left: 22%; right: 22%; height: 16%; border-top: none; }
		.pitch .boxBot { bottom: 0; left: 22%; right: 22%; height: 16%; border-bottom: none; }
		.tok { position: absolute; transform: translate(-50%,-50%); min-width: 44px; max-width: 70px; padding: 6px 4px;
			background: #fff; border-radius: 10px; box-shadow: 0 2px 6px rgba(0,0,0,.3); text-align: center;
			font-size: 11px; font-weight: 700; cursor: grab; user-select: none; line-height: 1.15; touch-action: none; }
		.tok.dragging { cursor: grabbing; z-index: 10; box-shadow: 0 6px 14px rgba(0,0,0,.4); }
		.tok .dot { display: block; width: 18px; height: 18px; margin: 0 auto 3px; border-radius: 50%; background: var(--green); color: #fff; font-size: 11px; line-height: 18px; }
		.bench { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
		.bench .btok { padding: 8px 12px; background: #fff; border: 1px solid var(--line); border-radius: 999px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; }
		.bench .btok .x { color: var(--red); font-weight: 700; }
		#qTabs { display: flex; gap: 5px; overflow-x: auto; margin-bottom: 10px; }
		#qTabs .qtab { flex: 0 0 auto; padding: 9px 14px; border: 1.5px solid var(--line); background: #fff; border-radius: 10px; font-weight: 700; cursor: pointer; }
		#qTabs .qtab.on { background: var(--green); color: #fff; border-color: var(--green); }
	</style>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<a href="/team/${team.id}/schedule/${scheduleId}" class="small muted">‹ 경기 상세</a>
	<div class="section-title" style="margin-top:6px;">포메이션 <span class="muted small" id="fmTitle"></span></div>

	<div id="qTabs"></div>
	<div style="display:flex;gap:8px;margin-bottom:10px;" id="qControls">
		<button class="btn-ghost btn-sm" id="addQ">＋ 쿼터 추가</button>
		<button class="btn-ghost btn-sm" id="copyPrev">이전 쿼터 복사</button>
		<button class="btn-ghost btn-sm" id="delQ" style="color:var(--red);">쿼터 삭제</button>
	</div>

	<div class="pitch" id="pitch">
		<div class="line halfway"></div>
		<div class="line circle"></div>
		<div class="line boxTop"></div>
		<div class="line boxBot"></div>
	</div>

	<div class="muted small" style="margin-top:8px;" id="pitchHint">벤치 선수를 탭하면 필드에 올라가고, 드래그로 위치 조정 · 탭하면 벤치로. (빈 공간은 스크롤)</div>

	<div class="section-title" style="margin-left:0;">선호 포지션 신청</div>
	<div class="card">
		<div class="muted small">원하는 포지션을 신청하면 팀장이 라인업 짤 때 참고해요.</div>
		<div class="region-row" id="posPick" style="margin-top:8px;">
			<button type="button" class="region-chip" data-v="GK">🧤 GK</button>
			<button type="button" class="region-chip" data-v="DF">🛡 DF</button>
			<button type="button" class="region-chip" data-v="MF">⚙️ MF</button>
			<button type="button" class="region-chip" data-v="FW">⚔️ FW</button>
		</div>
		<div style="display:flex;gap:6px;margin-top:8px;">
			<input type="text" id="posNote" maxlength="200" placeholder="한마디 (선택: 예-왼쪽 윙 선호)" style="flex:1;min-width:0;padding:10px;border:1px solid var(--line);border-radius:10px;">
			<button class="btn-primary btn-sm" id="posApply">신청</button>
			<button class="btn-ghost btn-sm" id="posCancel">취소</button>
		</div>
		<div id="posList" style="margin-top:10px;"></div>
	</div>

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

	<div style="display:flex;gap:8px;margin-top:10px;" id="rosterControls">
		<input type="text" id="customName" placeholder="선수 직접 추가" style="flex:1;min-width:0;padding:10px 12px;border:1px solid var(--line);border-radius:10px;">
		<button class="btn-ghost btn-sm" id="addCustom">＋ 추가</button>
		<button class="btn-ghost btn-sm" id="reloadRoster">참석자 불러오기</button>
	</div>
	<button class="btn-ghost btn-block" id="clearAll" style="margin-top:8px;color:var(--red);">이 쿼터 전체 비우기</button>

	<div class="row-2" style="margin-top:12px;">
		<button class="btn-ghost" id="saveImg">📷 이미지 저장</button>
		<button class="btn-ghost" id="shareFm">🔗 카카오 공유</button>
	</div>
	<c:if test="${canManage}">
		<button class="btn-primary btn-block" id="saveFm" style="margin-top:8px;">저장</button>
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
const VIEW_ONLY = !CAN_MANAGE;   // 일반 회원 = 조회 전용 뷰어
const TEAM_NAME = "${fn:escapeXml(team.name)}";
let SPORT = 'SOCCER';
let fm = { quarters: { '1': [] } };   // 쿼터별 토큰
let curQ = '1';
let tokens = fm.quarters['1'];        // 현재 쿼터 토큰(참조)
let seq = 1;
let roster = [];                      // 참석자+용병 이름 명단
let selectedPos = '';                 // 신청할 선호 포지션
const POS_LABEL = { GK: '🧤 GK', DF: '🛡 DF', MF: '⚙️ MF', FW: '⚔️ FW' };

async function loadPositions() {
	const r = await api.get('/api/schedule/' + SCHEDULE_ID + '/positions');
	if (!r.ok) return;
	$('#posPick .region-chip').removeClass('on');
	if (r.myPosition) { $('#posPick .region-chip[data-v="' + r.myPosition + '"]').addClass('on'); selectedPos = r.myPosition; }
	const box = $('#posList').empty();
	if (!r.requests.length) { box.html('<div class="muted small">아직 신청한 사람이 없어요.</div>'); return; }
	r.requests.forEach(p => box.append('<div class="member-row"><span class="name">' + esc(p.name) + '</span>' +
		'<span class="right small">' + (POS_LABEL[p.position] || p.position) + (p.note ? ' <span class="muted">· ' + esc(p.note) + '</span>' : '') + '</span></div>'));
}

const PRESETS = {
	'11': { '4-4-2': [[50,88],[15,70],[38,70],[62,70],[85,70],[15,46],[38,46],[62,46],[85,46],[38,22],[62,22]],
		'4-3-3': [[50,88],[15,70],[38,70],[62,70],[85,70],[30,50],[50,52],[70,50],[22,24],[50,18],[78,24]],
		'3-5-2': [[50,88],[25,72],[50,72],[75,72],[12,50],[34,48],[50,50],[66,48],[88,50],[40,22],[60,22]],
		'3-4-3': [[50,88],[25,72],[50,72],[75,72],[15,50],[38,50],[62,50],[85,50],[25,24],[50,20],[75,24]] },
	'8': { '3-3-1': [[50,90],[20,70],[50,70],[80,70],[20,46],[50,46],[80,46],[50,22]],
		'2-3-2': [[50,90],[35,72],[65,72],[20,48],[50,48],[80,48],[35,24],[65,24]],
		'3-1-3': [[50,90],[20,72],[50,72],[80,72],[50,50],[22,26],[50,22],[78,26]],
		'2-4-1': [[50,90],[35,72],[65,72],[15,48],[38,48],[62,48],[85,48],[50,24]] },
	'6': { '2-2-1': [[50,88],[35,68],[65,68],[35,46],[65,46],[50,24]],
		'1-3-1': [[50,88],[50,70],[25,48],[50,48],[75,48],[50,24]],
		'2-1-2': [[50,88],[35,70],[65,70],[50,48],[35,26],[65,26]] },
	'5': { '1-2-1': [[50,88],[50,70],[30,48],[70,48],[50,26]],
		'2-1-1': [[50,88],[35,70],[65,70],[50,48],[50,26]],
		'2-0-2': [[50,88],[35,66],[65,66],[35,40],[65,40]] }
};
let curCount = '11';

function renderQTabs() {
	const box = $('#qTabs').empty();
	Object.keys(fm.quarters).sort((a, b) => a - b).forEach(q => {
		box.append('<button type="button" class="qtab ' + (q === curQ ? 'on' : '') + '" data-q="' + q + '">' + q + '쿼터</button>');
	});
}

function renderPresets(count) {
	curCount = count;
	const box = $('#presets').empty();
	Object.keys(PRESETS[count]).forEach(name => box.append('<button type="button" class="region-chip" data-name="' + name + '">' + name + '</button>'));
}

function render() {
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
	const bench = $('#bench').empty();
	const benched = tokens.filter(t => t.x == null);
	if (!benched.length) bench.html('<div class="muted small">' + (VIEW_ONLY ? '벤치 인원이 없습니다.' : '벤치가 비었어요.') + '</div>');
	benched.forEach(t => {
		if (VIEW_ONLY) { bench.append('<div class="btok">' + esc(t.label) + '</div>'); return; }
		const b = $('<div class="btok">' + esc(t.label) + ' <span class="x" data-del="' + t.id + '">✕</span></div>');
		b.on('click', function (e) {
			if ($(e.target).attr('data-del')) { const i = tokens.indexOf(t); if (i >= 0) tokens.splice(i, 1); render(); return; }
			t.x = 50; t.y = 50; render();
		});
		bench.append(b);
	});
}

function makeDraggable(el, t) {
	if (VIEW_ONLY) { el.style.cursor = 'default'; return; }   // 뷰어는 드래그 불가
	let moved = false, sx, sy;
	el.addEventListener('pointerdown', function (e) { e.preventDefault(); moved = false; sx = e.clientX; sy = e.clientY; el.setPointerCapture(e.pointerId); el.classList.add('dragging'); });
	el.addEventListener('pointermove', function (e) {
		if (!el.classList.contains('dragging')) return;
		if (Math.abs(e.clientX - sx) > 3 || Math.abs(e.clientY - sy) > 3) moved = true;
		const r = document.getElementById('pitch').getBoundingClientRect();
		t.x = Math.max(3, Math.min(97, (e.clientX - r.left) / r.width * 100));
		t.y = Math.max(3, Math.min(97, (e.clientY - r.top) / r.height * 100));
		el.style.left = t.x + '%'; el.style.top = t.y + '%';
	});
	el.addEventListener('pointerup', function (e) { el.classList.remove('dragging'); if (!moved) { t.x = null; t.y = null; render(); } });
}

function addToken(label) { if (!label || !label.trim()) return; tokens.push({ id: seq++, label: label.trim().slice(0, 8), x: null, y: null }); }

function applyPreset(pos) {
	if (!pos) return;
	let i = 0;
	tokens.slice().sort((a, b) => (a.x == null) - (b.x == null)).forEach(t => { if (i < pos.length) { t.x = pos[i][0]; t.y = pos[i][1]; i++; } else { t.x = null; t.y = null; } });
	render();
}

function switchQ(q) {
	if (!fm.quarters[q]) fm.quarters[q] = [];
	curQ = q; tokens = fm.quarters[q];
	renderQTabs(); render();
}

// 참석자/용병 명단을 한 번 가져와 roster 에 보관 (쿼터마다 벤치 채울 때 재사용)
async function fetchRoster() {
	const r = await api.get('/api/attendance/list?scheduleId=' + SCHEDULE_ID);
	if (!r.ok) return;
	roster = [];
	(r.summary.attendList || []).forEach(m => roster.push(m.nickname));
	(r.summary.guests || []).forEach(g => { for (let k = 0; k < g.headcount; k++) roster.push(g.name + (g.headcount > 1 ? (k + 1) : '')); });
}

// 해당 쿼터에 명단 중 빠진 사람을 벤치(미배치)로 보충
function fillBench(q) {
	const arr = fm.quarters[q];
	const existing = new Set(arr.map(t => t.label));
	roster.forEach(n => { if (!existing.has(n)) arr.push({ id: seq++, label: n, x: null, y: null }); });
}

async function loadRoster(merge) {
	await fetchRoster();
	if (!merge) { fm.quarters[curQ] = []; tokens = fm.quarters[curQ]; }
	fillBench(curQ);
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
				if (data.quarters) fm = data;
				else if (data.tokens) fm = { quarters: { '1': data.tokens } };   // 구버전 마이그레이션
			} catch (e) {}
		}
	}
	// id 부여
	Object.keys(fm.quarters).forEach(q => fm.quarters[q].forEach(t => { if (!t.id) t.id = seq++; }));
	curQ = Object.keys(fm.quarters).sort((a, b) => a - b)[0] || '1';
	tokens = fm.quarters[curQ];
	renderQTabs();
	await fetchRoster();                       // 명단 미리 확보 → 새 쿼터/복사 시 벤치 자동 보충
	if (!tokens.length && !VIEW_ONLY) fillBench(curQ);
	render();
}

async function saveImage() {
	try {
		const canvas = await html2canvas(document.getElementById('pitch'), { backgroundColor: null, scale: 2, useCORS: true });
		const a = document.createElement('a');
		a.href = canvas.toDataURL('image/png');
		a.download = 'matchon_' + curQ + '쿼터_포메이션.png';
		document.body.appendChild(a); a.click(); a.remove();
	} catch (e) { alert('이미지 저장 실패: ' + e.message); }
}

$(function () {
	if (VIEW_ONLY) {
		// 조회 전용: 편집 컨트롤 숨김 (이미지 저장/공유는 가능)
		$('#qControls, #presetWrap, #rosterControls, #clearAll').hide();
		$('#pitchHint').text('팀장이 짠 라인업입니다. 쿼터 탭으로 확인하고 📷 저장 · 🔗 공유만 가능해요. (보기 전용)');
	}
	load();
	renderPresets('11');
	loadPositions();

	$('#posPick .region-chip').on('click', function () { $('#posPick .region-chip').removeClass('on'); $(this).addClass('on'); selectedPos = $(this).data('v'); });
	$('#posApply').on('click', async function () {
		if (!selectedPos) { alert('포지션을 선택해주세요.'); return; }
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/position', { position: selectedPos, note: $('#posNote').val().trim() });
		if (r.ok) { alert('신청 완료!'); loadPositions(); } else alert(r.message || '실패');
	});
	$('#posCancel').on('click', async function () {
		const r = await api.del('/api/schedule/' + SCHEDULE_ID + '/position');
		if (r.ok) { selectedPos = ''; $('#posPick .region-chip').removeClass('on'); $('#posNote').val(''); loadPositions(); } else alert(r.message || '실패');
	});

	$('#qTabs').on('click', '.qtab', function () { switchQ($(this).data('q') + ''); });
	$('#addQ').on('click', function () {
		const keys = Object.keys(fm.quarters).map(Number);
		const next = (Math.max.apply(null, keys.concat(0)) + 1);
		if (next > 6) { alert('최대 6쿼터까지 가능합니다.'); return; }
		fm.quarters[next] = []; fillBench(next + ''); switchQ(next + '');   // 새 쿼터에 참석자 벤치 자동 채움
	});
	$('#copyPrev').on('click', function () {
		const prev = (Number(curQ) - 1);
		if (prev < 1 || !fm.quarters[prev]) { alert('복사할 이전 쿼터가 없습니다.'); return; }
		fm.quarters[curQ] = fm.quarters[prev].map(t => ({ id: seq++, label: t.label, x: t.x, y: t.y }));
		tokens = fm.quarters[curQ];
		fillBench(curQ);   // 복사 후 빠진 참석자도 벤치로 보충
		render();
	});
	$('#delQ').on('click', function () {
		if (Object.keys(fm.quarters).length <= 1) { alert('최소 1쿼터는 필요합니다.'); return; }
		if (!confirm(curQ + '쿼터를 삭제할까요?')) return;
		delete fm.quarters[curQ];
		curQ = Object.keys(fm.quarters).sort((a, b) => a - b)[0];
		tokens = fm.quarters[curQ]; renderQTabs(); render();
	});

	$('#countSel .region-chip').on('click', function () { $('#countSel .region-chip').removeClass('on'); $(this).addClass('on'); renderPresets($(this).data('c')); });
	$('#presets').on('click', '.region-chip', function () { $('#presets .region-chip').removeClass('on'); $(this).addClass('on'); applyPreset(PRESETS[curCount][$(this).data('name')]); });
	$('#addCustom').on('click', function () { addToken($('#customName').val()); $('#customName').val(''); render(); });
	$('#customName').on('keypress', e => { if (e.which === 13) { addToken($('#customName').val()); $('#customName').val(''); render(); } });
	$('#reloadRoster').on('click', function () { if (confirm('현재 참석자/용병을 이 쿼터 벤치로 불러올까요?')) loadRoster(true); });
	$('#clearAll').on('click', function () { if (!confirm(curQ + '쿼터 선수를 모두 벤치로 내릴까요?')) return; tokens.forEach(t => { t.x = null; t.y = null; }); $('#presets .region-chip').removeClass('on'); render(); });

	$('#saveImg').on('click', saveImage);
	$('#shareFm').on('click', function () {
		const url = location.origin + '/team/' + TEAM_ID + '/schedule/' + SCHEDULE_ID + '/formation';
		const msg = '⚽ [' + TEAM_NAME + '] 포메이션\n' + url + '\n(이미지는 "이미지 저장" 후 첨부해 보내세요)';
		if (window.Kakao && Kakao.isInitialized && Kakao.isInitialized()) {
			try { Kakao.Share.sendDefault({ objectType: 'text', text: msg, link: { mobileWebUrl: url, webUrl: url }, buttonTitle: '포메이션 보기' }); return; } catch (e) {}
		}
		if (navigator.clipboard) navigator.clipboard.writeText(msg).then(() => alert('공유 링크를 복사했어요. 카카오톡에 붙여넣으세요.'));
		else prompt('복사하세요', msg);
	});

	$('#saveFm').on('click', async function () {
		const r = await api.post('/api/schedule/' + SCHEDULE_ID + '/formation', { data: JSON.stringify(fm) });
		alert(r.ok ? '저장했습니다.' : (r.message || '실패'));
	});
});
</script>
</body>
</html>
