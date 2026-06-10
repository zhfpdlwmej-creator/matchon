-- =============================================================
-- matchon · 경기 종료 후 입력 테스트용 강제 데이터 1건
-- =============================================================
-- 내가 'LEADER'인 팀을 호스트로 삼고, 더미 상대팀을 만들어
-- "어제(CURRENT_DATE - 1) 날짜의 성사된(MATCHED) 매칭 + 지난 일정"을 생성합니다.
-- → 일정 상세 화면에서 [경기 결과(득실/득점/MOM)] + [상대팀 매너 평가]가 모두 노출됩니다.
--
-- 전제: 현재 로그인한 계정이 어떤 팀의 LEADER 여야 합니다.
--       (여러 팀의 리더면 가장 최근 만든 팀이 선택됩니다)
-- =============================================================

WITH ldr AS (                       -- 리더인 (팀, 유저) 한 쌍
    SELECT tm.team_id, tm.user_id
    FROM team_member tm
    WHERE tm.role = 'LEADER'
    ORDER BY tm.team_id DESC
    LIMIT 1
),
opp AS (                            -- 더미 상대팀 생성
    INSERT INTO team (name, description, invite_code, owner_id)
    SELECT '[테스트] 상대 FC', '테스트용 더미 상대팀', left(md5(random()::text), 8), user_id
    FROM ldr
    RETURNING id
),
mp AS (                             -- 매칭글 (성사 상태)
    INSERT INTO match_post
        (host_team_id, host_user_id, level, headcount, region, place_name,
         match_date, start_time, status, recruit_guest)
    SELECT l.team_id, l.user_id, 'MID', 6, '서울 송파구', '잠실 풋살장',
           CURRENT_DATE - 1, TIME '20:00', 'MATCHED', false
    FROM ldr l
    RETURNING id
),
app AS (                            -- 상대팀 신청 (수락됨)
    INSERT INTO match_application
        (match_post_id, applicant_team_id, applicant_user_id, status)
    SELECT mp.id, opp.id, l.user_id, 'ACCEPTED'
    FROM mp, opp, ldr l
    RETURNING id
)
INSERT INTO match_schedule          -- 지난 일정 (어제) + 매칭/상대팀 연결
    (team_id, title, match_date, start_time, place, match_post_id, opponent_team_id, created_by)
SELECT l.team_id, 'vs [테스트] 상대 FC', CURRENT_DATE - 1, TIME '20:00',
       '잠실 풋살장', mp.id, opp.id, l.user_id
FROM mp, opp, ldr l
RETURNING id AS schedule_id, team_id, match_post_id, opponent_team_id;

-- 위 결과의 team_id, schedule_id 로 접속:
--   /team/{team_id}/schedule/{schedule_id}
-- (일정 목록 화면의 '지난 경기' 펼치기에서도 보입니다)


-- =============================================================
-- 테스트 데이터 정리 (확인 끝난 뒤 실행 — 순서대로)
-- =============================================================
-- DELETE FROM match_result WHERE schedule_id IN (SELECT id FROM match_schedule WHERE title = 'vs [테스트] 상대 FC');
-- DELETE FROM match_event  WHERE schedule_id IN (SELECT id FROM match_schedule WHERE title = 'vs [테스트] 상대 FC');
-- DELETE FROM mom_vote     WHERE schedule_id IN (SELECT id FROM match_schedule WHERE title = 'vs [테스트] 상대 FC');
-- DELETE FROM team_rating  WHERE target_team_id IN (SELECT id FROM team WHERE name = '[테스트] 상대 FC');
-- DELETE FROM match_post   WHERE id IN (SELECT match_post_id FROM match_schedule WHERE title = 'vs [테스트] 상대 FC');  -- match_application 자동삭제
-- DELETE FROM match_schedule WHERE title = 'vs [테스트] 상대 FC';   -- attendance/comment 자동삭제
-- DELETE FROM team WHERE name = '[테스트] 상대 FC';
