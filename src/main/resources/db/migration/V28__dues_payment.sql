-- 월별 회비 납부 체크 (총무가 계좌 확인 후 수동 체크). 행이 존재하면 = 해당 월 납부 완료
CREATE TABLE dues_payment (
    id         BIGSERIAL PRIMARY KEY,
    team_id    BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    period     VARCHAR(7) NOT NULL,           -- 납부 대상 월 (YYYY-MM)
    marked_by  BIGINT NOT NULL,               -- 체크한 총무
    paid_at    TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_dues UNIQUE (team_id, user_id, period)
);
CREATE INDEX idx_dues_team_period ON dues_payment(team_id, period);
