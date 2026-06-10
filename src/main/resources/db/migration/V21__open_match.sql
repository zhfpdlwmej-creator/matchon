-- 개인 오픈매치(픽업): 팀 없이 개인이 주최하는 모집글 → host_team_id NULL 허용
ALTER TABLE match_post ALTER COLUMN host_team_id DROP NOT NULL;
