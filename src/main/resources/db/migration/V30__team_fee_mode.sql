-- 팀 회비 관리 방식: NONE(구분 안 함) / MONTHLY(회비회원제) / PER_GAME(참가회원제)
ALTER TABLE team ADD COLUMN fee_mode VARCHAR(10) NOT NULL DEFAULT 'NONE';
