-- 개인(용병) 매너 평가 + 후기 한줄평
CREATE TABLE user_rating (
    id             BIGSERIAL PRIMARY KEY,
    target_user_id BIGINT NOT NULL,
    rater_user_id  BIGINT NOT NULL,
    rater_team_id  BIGINT,
    match_post_id  BIGINT,
    manner         INT NOT NULL,
    comment        VARCHAR(300),
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_rating UNIQUE (match_post_id, rater_user_id, target_user_id)
);
CREATE INDEX idx_user_rating_target ON user_rating(target_user_id);
