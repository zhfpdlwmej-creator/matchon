-- 총무 지정: 팀장이 멤버 중 회비 관리자를 지정 (권한 role 과 별개 플래그)
ALTER TABLE team_member ADD COLUMN treasurer BOOLEAN NOT NULL DEFAULT FALSE;
