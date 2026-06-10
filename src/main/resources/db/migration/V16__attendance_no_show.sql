-- 노쇼 관리: 참석 확정 후 안 온 사람 표시
ALTER TABLE attendance ADD COLUMN no_show BOOLEAN NOT NULL DEFAULT FALSE;
