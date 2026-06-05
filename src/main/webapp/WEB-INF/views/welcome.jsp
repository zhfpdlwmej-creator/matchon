<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 환영합니다</title>
	<%@ include file="layout/head.jsp" %>
</head>
<body class="page-welcome">
<div class="welcome-wrap">
	<h2>환영합니다! 👋</h2>
	<p class="sub">동호회에서 사용할 닉네임과 포지션을 설정해주세요.</p>

	<form id="setupForm" class="card-form">
		<label>닉네임</label>
		<input type="text" id="nickname" maxlength="20" value="${user.nickname}" placeholder="예: 손흥민" required>

		<label>선호 포지션</label>
		<div class="pos-picker" id="posPicker">
			<button type="button" class="pos" data-pos="GK">GK</button>
			<button type="button" class="pos" data-pos="DF">DF</button>
			<button type="button" class="pos" data-pos="MF">MF</button>
			<button type="button" class="pos" data-pos="FW">FW</button>
		</div>
		<input type="hidden" id="position" value="">

		<button type="submit" class="btn-primary btn-block" style="margin-top:32px;padding:15px;">시작하기</button>
	</form>
</div>
<script>
$(function () {
	$('#posPicker .pos').on('click', function () {
		$('#posPicker .pos').removeClass('on');
		$(this).addClass('on');
		$('#position').val($(this).data('pos'));
	});
	$('#setupForm').on('submit', async function (e) {
		e.preventDefault();
		const nickname = $('#nickname').val().trim();
		if (!nickname) { alert('닉네임을 입력해주세요.'); return; }
		const r = await api.post('/api/user/setup', {
			nickname: nickname,
			position: $('#position').val()
		});
		if (r.ok) location.href = '/';
		else alert(r.message || '설정에 실패했습니다.');
	});
});
</script>
</body>
</html>
