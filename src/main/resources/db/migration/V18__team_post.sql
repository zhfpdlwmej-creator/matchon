-- 팀 게시판 (공지 / 자유글)
CREATE TABLE team_post (
    id             BIGSERIAL PRIMARY KEY,
    team_id        BIGINT NOT NULL,
    author_user_id BIGINT NOT NULL,
    notice         BOOLEAN NOT NULL DEFAULT FALSE,
    title          VARCHAR(120) NOT NULL,
    content        VARCHAR(2000),
    created_at     TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_team_post_team ON team_post(team_id);
