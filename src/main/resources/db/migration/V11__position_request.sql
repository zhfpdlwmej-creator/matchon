-- 포메이션 선호 포지션 신청 (일정당 1인 1건)
CREATE TABLE position_request (
    id          BIGSERIAL PRIMARY KEY,
    schedule_id BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    position    VARCHAR(8) NOT NULL,
    note        VARCHAR(200),
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_position_request UNIQUE (schedule_id, user_id)
);
CREATE INDEX idx_posreq_schedule ON position_request(schedule_id);
