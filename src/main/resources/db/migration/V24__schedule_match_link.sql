-- 매칭 성사로 생성된 일정 ↔ 매칭글/상대팀 연결 (상대팀 평가용)
ALTER TABLE match_schedule ADD COLUMN match_post_id BIGINT;
ALTER TABLE match_schedule ADD COLUMN opponent_team_id BIGINT;
