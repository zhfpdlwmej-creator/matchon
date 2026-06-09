<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<title>matchon · 개인정보처리방침</title>
	<%@ include file="../layout/head.jsp" %>
	<style>
		.legal { max-width: 760px; margin: 0 auto; padding: 18px 16px 60px; line-height: 1.7; font-size: 14px; color: var(--text); }
		.legal h1 { font-size: 20px; margin: 8px 0 4px; }
		.legal h2 { font-size: 15px; margin: 22px 0 6px; }
		.legal p, .legal li { color: #333; }
		.legal ul { padding-left: 18px; }
		.legal .muted { color: var(--muted); font-size: 12px; }
		.legal table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 13px; }
		.legal td, .legal th { border: 1px solid var(--line); padding: 7px 9px; text-align: left; vertical-align: top; }
	</style>
</head>
<body>
<div class="legal">
	<a href="javascript:history.back()" class="small muted">‹ 뒤로</a>
	<h1>개인정보처리방침</h1>
	<p class="muted">matchon(이하 "서비스")은 이용자의 개인정보를 중요하게 생각하며, 「개인정보 보호법」 등 관계 법령을 준수합니다.</p>

	<h2>1. 수집하는 개인정보 항목</h2>
	<table>
		<tr><th>구분</th><th>항목</th></tr>
		<tr><td>카카오 로그인</td><td>카카오 회원번호(고유 식별자), 이름 또는 닉네임, 프로필 이미지(선택)</td></tr>
		<tr><td>서비스 이용</td><td>소속 팀·역할, 일정/출석 정보, 경기 기록(스코어·득점·MOM), 포지션 신청, 매칭/용병 신청·평가·메시지, 장소(위치 좌표)</td></tr>
		<tr><td>자동 수집</td><td>접속 로그, 기기·브라우저 정보, 푸시 알림 구독 정보</td></tr>
	</table>

	<h2>2. 개인정보의 수집·이용 목적</h2>
	<ul>
		<li>회원 식별 및 카카오 간편 로그인</li>
		<li>팀 출석·일정·매칭·통계 등 서비스 기능 제공</li>
		<li>일정/매칭 관련 알림(웹 푸시) 발송</li>
		<li>부정 이용 방지 및 서비스 운영·개선</li>
	</ul>

	<h2>3. 보유 및 이용 기간</h2>
	<p>회원 탈퇴 또는 팀 탈퇴 시 지체 없이 파기합니다. 다만 관계 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관합니다.</p>

	<h2>4. 제3자 제공</h2>
	<p>서비스는 이용자의 개인정보를 외부에 제공하지 않습니다. 단, 법령에 근거가 있거나 수사기관의 적법한 요청이 있는 경우는 예외로 합니다.</p>

	<h2>5. 처리 위탁</h2>
	<ul>
		<li>카카오 — 소셜 로그인 인증</li>
		<li>클라우드 인프라(호스팅·데이터베이스) 사업자 — 서비스 운영을 위한 데이터 저장</li>
	</ul>

	<h2>6. 이용자의 권리</h2>
	<p>이용자는 언제든지 본인 개인정보의 열람·정정·삭제·처리정지를 요청할 수 있으며, 카카오 로그인 연결 해제 또는 회원 탈퇴로 동의를 철회할 수 있습니다.</p>

	<h2>7. 개인정보의 안전성 확보 조치</h2>
	<p>전송 구간 암호화(HTTPS), 인증 토큰의 안전한 저장(HttpOnly 쿠키), 접근 권한 통제 등의 조치를 시행합니다.</p>

	<h2>8. 개인정보 보호책임자 / 문의</h2>
	<p>※ 운영자 정보는 정식 출시 전 실제 값으로 교체해 주세요.<br>
		운영자: matchon 운영팀 · 문의: <span class="muted">admin@matchon.app</span></p>

	<p class="muted" style="margin-top:24px;">본 방침은 게시일로부터 적용됩니다. 내용 변경 시 서비스 내 공지합니다.</p>
	<p class="muted">시행일: 2026-06-09</p>

	<p style="margin-top:20px;"><a href="/terms" style="color:var(--green);">이용약관 보기 ›</a></p>
</div>
</body>
</html>
