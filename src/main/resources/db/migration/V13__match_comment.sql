-- 매칭 신청 댓글(소통) — 신청팀별 스레드, 대댓글 지원
-- 가시성: 모집팀(호스트)=모든 스레드, 신청팀=본인 스레드만
CREATE TABLE match_comment (
    id                BIGSERIAL PRIMARY KEY,
    match_post_id     BIGINT NOT NULL,
    applicant_team_id BIGINT NOT NULL,   -- 어느 신청팀 스레드인지
    author_user_id    BIGINT NOT NULL,
    author_team_id    BIGINT NOT NULL,
    is_host           BOOLEAN NOT NULL DEFAULT FALSE,
    parent_id         BIGINT,            -- 대댓글이면 부모 댓글 id
    content           VARCHAR(500) NOT NULL,
    created_at        TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_mcomment_post ON match_comment(match_post_id);
CREATE INDEX idx_mcomment_thread ON match_comment(match_post_id, applicant_team_id);
