<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="navActive" value="board" />
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 게시판</title>
	<%@ include file="../layout/head.jsp" %>
</head>
<body>
<%@ include file="../layout/header.jsp" %>
<div class="app-wrap">
	<div class="section-title">팀 게시판</div>
	<div id="postList"><div class="empty">불러오는 중...</div></div>
</div>

<a class="fab" id="writeBtn" href="javascript:void(0)">＋</a>

<div class="modal-back" id="writeModal">
	<div class="modal">
		<h3>글쓰기</h3>
		<form id="writeForm" class="card-form" style="padding:0;box-shadow:none;">
			<c:if test="${canManage}">
				<label style="display:flex;align-items:center;gap:8px;cursor:pointer;">
					<input type="checkbox" id="wNotice" style="width:auto;transform:scale(1.2);"> 📢 공지로 등록
				</label>
			</c:if>
			<label>제목</label>
			<input type="text" id="wTitle" maxlength="120" required>
			<label>내용</label>
			<textarea id="wContent" maxlength="2000" rows="6" placeholder="내용을 입력하세요"></textarea>
			<div class="row-2" style="margin-top:14px;">
				<button type="button" class="btn-ghost" id="wCancel">취소</button>
				<button type="submit" class="btn-primary">등록</button>
			</div>
		</form>
	</div>
</div>

<%@ include file="../layout/bottomnav.jsp" %>

<script>
const TEAM_ID = ${team.id};
const MY_ROLE = '${myRole}';

async function load() {
	const r = await api.get('/api/team/' + TEAM_ID + '/board');
	const box = $('#postList').empty();
	if (!r.ok) return;
	if (!r.posts.length) { box.html('<div class="empty"><div class="big">📝</div>첫 글을 남겨보세요.</div>'); return; }
	r.posts.forEach(function (p) {
		const del = p.mine || MY_ROLE === 'LEADER' || MY_ROLE === 'MANAGER'
			? '<a href="javascript:void(0)" class="delPost muted small" data-id="' + p.id + '">삭제</a>' : '';
		box.append(
			'<div class="card" style="margin-bottom:10px;">' +
			'<div style="display:flex;align-items:center;gap:6px;">' +
			(p.notice ? '<span class="lvl-badge" style="background:var(--red);">📢 공지</span>' : '') +
			'<span class="title" style="font-weight:800;">' + esc(p.title) + '</span>' +
			'<span class="right">' + del + '</span></div>' +
			(p.content ? '<div class="meta small" style="margin-top:6px;white-space:pre-wrap;">' + esc(p.content) + '</div>' : '') +
			'<div class="muted small" style="margin-top:8px;">👤 ' + esc(p.author) + ' · ' + esc(p.createdAt) + '</div>' +
			'</div>');
	});
}

$(function () {
	load();
	$('#writeBtn').on('click', function () { $('#writeModal').addClass('open'); });
	$('#wCancel').on('click', function () { $('#writeModal').removeClass('open'); });
	$('#writeModal').on('click', function (e) { if (e.target.id === 'writeModal') $(this).removeClass('open'); });
	$('#writeForm').on('submit', async function (e) {
		e.preventDefault();
		const title = $('#wTitle').val().trim();
		if (!title) { alert('제목을 입력하세요.'); return; }
		const body = { notice: $('#wNotice').is(':checked'), title: title, content: $('#wContent').val().trim() };
		const r = await api.post('/api/team/' + TEAM_ID + '/board', body);
		if (r.ok) { $('#writeModal').removeClass('open'); $('#wTitle').val(''); $('#wContent').val(''); $('#wNotice').prop('checked', false); load(); }
		else alert(r.message || '등록 실패');
	});
	$('#postList').on('click', '.delPost', async function () {
		if (!confirm('이 글을 삭제할까요?')) return;
		const r = await api.del('/api/team/' + TEAM_ID + '/board/' + $(this).data('id'));
		if (r.ok) load(); else alert(r.message || '실패');
	});
});
</script>
</body>
</html>
