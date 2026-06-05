-- 경기 목표 인원 (진행률·부족인원 표시용)
ALTER TABLE match_schedule ADD COLUMN target_headcount INT NOT NULL DEFAULT 0;
