-- 일정 위치(카카오맵) 좌표
ALTER TABLE match_schedule ADD COLUMN lat DOUBLE PRECISION;
ALTER TABLE match_schedule ADD COLUMN lng DOUBLE PRECISION;
