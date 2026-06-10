-- 팀 회원 유형: 회비회원(DUES) / 참가회원(GUEST)
-- 기존 팀원은 모두 회비회원(정회원)으로 간주
ALTER TABLE team_member
    ADD COLUMN membership_type VARCHAR(8) NOT NULL DEFAULT 'DUES';
