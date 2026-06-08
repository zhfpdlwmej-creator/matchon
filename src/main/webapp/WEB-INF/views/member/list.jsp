<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="navActive" value="members" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 팀원</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="card">
		<h3>팀원 초대</h3>
		<div class="invite-row">
			<strong id="inviteCode">${team.inviteCode}</strong>
			<button class="btn-ghost btn-sm" id="copyCode">코드 복사</button>
			<c:if test="${canManage}"><button class="btn-ghost btn-sm" id="regenCode">재발급</button></c:if>
		</div>
		<button class="btn-primary btn-block" id="shareLink" style="margin-top:12px;">🔗 초대 링크 복사 / 공유</button>
		<div class="muted small" style="margin-top:8px;">
			초대 링크를 <b>카카오톡 단톡방</b>에 붙여넣으세요. 받은 사람이 누르면
			<b>가입 신청</b>이 들어오고, 팀장/운영진이 승인하면 가입됩니다.
		</div>
	</div>

	<c:if test="${canManage}">
		<div class="section-title">가입 신청 <span class="muted small" id="reqCount"></span></div>
		<div class="card" id="joinReqs"><div class="muted small">불러오는 중...</div></div>
	</c:if>

	<div class="section-title">팀원 <span id="memCount"></span></div>
	<div class="card" id="memberList"><div class="empty">불러오는 중...</div></div>

	<c:if test="${myRole != 'LEADER'}">
		<button class="btn-ghost btn-block" id="leaveBtn" style="margin-top:6px;color:var(--red);">이 팀 나가기</button>
	</c:if>
	<c:if test="${myRole == 'LEADER'}">
		<button class="btn-ghost btn-block" id="disbandBtn" style="margin-top:6px;color:var(--red);">팀 해체하기</button>
		<div class="muted small" style="text-align:center;padding:8px;">해체하면 팀원·일정·매칭이 모두 삭제됩니다.</div>
	</c:if>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const CAN_MANAGE = ${canManage};
const MY_ROLE = '${myRole}';

function roleLabel(r) { return r === 'LEADER' ? '팀장' : (r === 'MANAGER' ? '운영진' : '회원'); }

async function loadRequests() {
	if (!CAN_MANAGE) return;
	const r = await api.get('/api/team/' + TEAM_ID + '/requests');
	const box = $('#joinReqs').empty();
	if (!r.ok) return;
	$('#reqCount').text(r.requests.length ? '(' + r.requests.length + ')' : '');
	if (!r.requests.length) { box.html('<div class="muted small" style="padding:6px 0;">대기 중인 신청이 없습니다.</div>'); return; }
	r.requests.forEach(q => {
		box.append('<div class="member-row"><span class="name">' + esc(q.nickname) + '</span>' +
			'<span class="right" style="gap:6px;">' +
			'<button class="btn-primary btn-sm reqApprove" data-id="' + q.id + '">승인</button>' +
			'<button class="btn-ghost btn-sm reqReject" data-id="' + q.id + '" style="color:var(--red);">거절</button>' +
			'</span></div>');
	});
}

async function load() {
	const r = await api.get('/api/team/' + TEAM_ID + '/members');
	const box = $('#memberList').empty();
	if (!r.ok) return;
	$('#memCount').text(r.members.length + '명');
	r.members.forEach(m => {
		let right = '<span class="role-badge role-' + m.role + '" style="background:#eef0f3;color:#444;">' + roleLabel(m.role) + '</span>';
		// 팀장만 권한 변경 가능 (자기 자신 제외)
		if (MY_ROLE === 'LEADER') {
			right = '<select class="roleSel small" data-uid="' + m.userId + '">' +
				['LEADER','MANAGER','MEMBER'].map(r => '<option value="' + r + '"' + (r === m.role ? ' selected' : '') + '>' + roleLabel(r) + '</option>').join('') +
				'</select>';
		}
		box.append('<div class="member-row">' +
			'<span class="name">' + esc(m.nickname) + '</span>' +
			'<span class="right">' + right + '</span></div>');
	});
}

$(function () {
	load();
	loadRequests();
	$('#joinReqs').on('click', '.reqApprove', async function () {
		const r = await api.post('/api/team/request/' + $(this).data('id') + '/approve', {});
		if (r.ok) { loadRequests(); load(); } else alert(r.message || '실패');
	});
	$('#joinReqs').on('click', '.reqReject', async function () {
		if (!confirm('이 신청을 거절할까요?')) return;
		const r = await api.post('/api/team/request/' + $(this).data('id') + '/reject', {});
		if (r.ok) loadRequests(); else alert(r.message || '실패');
	});
	function inviteLink() {
		return location.origin + '/join?code=' + $('#inviteCode').text().trim();
	}
	async function copyText(text, okMsg) {
		try {
			await navigator.clipboard.writeText(text);
			alert(okMsg);
		} catch (e) {
			// clipboard 권한 없을 때 폴백
			const t = document.createElement('textarea');
			t.value = text; document.body.appendChild(t); t.select();
			try { document.execCommand('copy'); alert(okMsg); }
			catch (e2) { prompt('아래 내용을 복사하세요', text); }
			document.body.removeChild(t);
		}
	}
	$('#copyCode').on('click', function () {
		copyText($('#inviteCode').text().trim(), '초대코드를 복사했습니다.');
	});
	$('#shareLink').on('click', async function () {
		const link = inviteLink();
		const msg = '[${team.name}] 출석 관리에 초대합니다!\n아래 링크를 눌러 가입하세요 👇\n' + link;
		// 모바일이면 카카오톡 등 네이티브 공유, 아니면 클립보드 복사
		if (navigator.share) {
			try { await navigator.share({ title: '${team.name} 초대', text: msg }); return; }
			catch (e) { /* 취소 시 복사로 폴백 */ }
		}
		copyText(msg, '초대 링크를 복사했습니다.\n카카오톡에 붙여넣어 보내세요!');
	});
	$('#regenCode').on('click', async function () {
		if (!confirm('초대코드를 재발급하면 기존 코드는 사용할 수 없습니다. 계속할까요?')) return;
		const r = await api.post('/api/team/' + TEAM_ID + '/invite-code', {});
		if (r.ok) $('#inviteCode').text(r.inviteCode); else alert(r.message || '실패');
	});
	$('#memberList').on('change', '.roleSel', async function () {
		const r = await api.post('/api/team/' + TEAM_ID + '/role', { userId: $(this).data('uid'), role: $(this).val() });
		if (!r.ok) { alert(r.message || '실패'); load(); }
	});

	$('#leaveBtn').on('click', async function () {
		if (!confirm('이 팀에서 나가시겠어요?\n다시 들어오려면 초대코드가 필요합니다.')) return;
		const r = await api.post('/api/team/' + TEAM_ID + '/leave', {});
		if (r.ok) { alert('팀에서 나갔습니다.'); location.href = '/'; } else alert(r.message || '실패');
	});

	$('#disbandBtn').on('click', async function () {
		if (!confirm('정말 팀을 해체할까요?\n팀원·일정·매칭·기록이 모두 삭제되며 되돌릴 수 없습니다.')) return;
		if (!confirm('한 번 더 확인합니다. 해체하시겠어요?')) return;
		const r = await api.post('/api/team/' + TEAM_ID + '/disband', {});
		if (r.ok) { alert('팀이 해체되었습니다.'); location.href = '/'; } else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
