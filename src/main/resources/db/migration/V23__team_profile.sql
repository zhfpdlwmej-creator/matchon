-- 팀 프로필: 연령대 / 실력 / 활동지역
ALTER TABLE team ADD COLUMN age_group VARCHAR(8);
ALTER TABLE team ADD COLUMN level VARCHAR(8);
ALTER TABLE team ADD COLUMN region VARCHAR(60);
