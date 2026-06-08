-- 경기 결과 / 득점·도움 / MOM 투표 / 매너·실력 평점

-- 경기 결과 (일정당 1건)
CREATE TABLE match_result (
    id            BIGSERIAL PRIMARY KEY,
    schedule_id   BIGINT NOT NULL UNIQUE,
    our_score     INT NOT NULL DEFAULT 0,
    opp_score     INT NOT NULL DEFAULT 0,
    opponent_name VARCHAR(60),
    created_by    BIGINT NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);

-- 득점/도움 이벤트 (골 1개당 1행, 도움은 선택)
CREATE TABLE match_event (
    id              BIGSERIAL PRIMARY KEY,
    schedule_id     BIGINT NOT NULL,
    team_id         BIGINT NOT NULL,
    scorer_user_id  BIGINT,
    scorer_name     VARCHAR(60) NOT NULL,
    assist_user_id  BIGINT,
    assist_name     VARCHAR(60),
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_event_schedule ON match_event(schedule_id);
CREATE INDEX idx_event_team ON match_event(team_id);

-- MOM 투표 (일정당 1인 1표)
CREATE TABLE mom_vote (
    id             BIGSERIAL PRIMARY KEY,
    schedule_id    BIGINT NOT NULL,
    team_id        BIGINT NOT NULL,
    voter_user_id  BIGINT NOT NULL,
    target_user_id BIGINT NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_mom UNIQUE (schedule_id, voter_user_id)
);

-- 상대팀 매너/실력 평점 (매칭당 평가자-대상팀 1건)
CREATE TABLE team_rating (
    id             BIGSERIAL PRIMARY KEY,
    match_post_id  BIGINT,
    rater_user_id  BIGINT NOT NULL,
    rater_team_id  BIGINT NOT NULL,
    target_team_id BIGINT NOT NULL,
    manner         INT NOT NULL,
    skill          VARCHAR(8),
    comment        VARCHAR(300),
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_team_rating UNIQUE (match_post_id, rater_team_id, target_team_id)
);
CREATE INDEX idx_rating_target ON team_rating(target_team_id);
