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
			초대 링크를 <b>카카오톡 단톡방</b>에 붙여넣으세요. 받은 사람이 링크를 누르면
			카카오 로그인 후 <b>자동으로 이 팀에 가입</b>됩니다.
		</div>
	</div>

	<div class="section-title">팀원 <span id="memCount"></span></div>
	<div class="card" id="memberList"><div class="empty">불러오는 중...</div></div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const CAN_MANAGE = ${canManage};
const MY_ROLE = '${myRole}';

function roleLabel(r) { return r === 'LEADER' ? '팀장' : (r === 'MANAGER' ? '운영진' : '회원'); }

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
		box.append('<div class="member-row"><span>' + posBadge(m.position) + '</span>' +
			'<span class="name">' + esc(m.nickname) + '</span>' +
			'<span class="right">' + right + '</span></div>');
	});
}

$(function () {
	load();
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
});
</script>
</body>
</html>
