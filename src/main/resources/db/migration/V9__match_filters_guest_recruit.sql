-- 매칭 필터(매치타입/연령대) + 용병 모집글 연동
ALTER TABLE match_post ADD COLUMN match_type VARCHAR(12);
ALTER TABLE match_post ADD COLUMN age_group  VARCHAR(8);
ALTER TABLE match_post ADD COLUMN recruit_guest BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE match_post ADD COLUMN source_schedule_id BIGINT;

-- 용병(개인) 지원은 팀 없이 신청 → applicant_team_id NULL 허용
ALTER TABLE match_application ALTER COLUMN applicant_team_id DROP NOT NULL;
