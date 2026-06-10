-- 알림톡 수신용 휴대폰 번호 (숫자만 저장)
ALTER TABLE users
    ADD COLUMN phone VARCHAR(20);
