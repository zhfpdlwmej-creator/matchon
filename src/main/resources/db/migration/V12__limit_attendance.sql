-- 선착순 참석 마감 옵션 (체크 시 인원 다 차면 참석 투표 불가)
ALTER TABLE match_schedule ADD COLUMN limit_attendance BOOLEAN NOT NULL DEFAULT FALSE;
