-- 용병 모집 댓글: 개인(user) 스레드 지원
-- 팀 매칭 = applicant_team_id 기준 스레드, 용병 모집 = applicant_user_id 기준 스레드
ALTER TABLE match_comment ADD COLUMN applicant_user_id BIGINT;
ALTER TABLE match_comment ALTER COLUMN applicant_team_id DROP NOT NULL;
