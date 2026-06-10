-- 팀 자주 가는 구장 즐겨찾기
CREATE TABLE venue (
    id         BIGSERIAL PRIMARY KEY,
    team_id    BIGINT NOT NULL,
    name       VARCHAR(120) NOT NULL,
    address    VARCHAR(200),
    lat        DOUBLE PRECISION,
    lng        DOUBLE PRECISION,
    memo       VARCHAR(300),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_venue_team ON venue(team_id);
