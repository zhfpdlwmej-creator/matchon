# matchon API 명세서

- Base URL: `/`
- 인증: 카카오 로그인 후 발급되는 **JWT(쿠키 `ACCESS_TOKEN`)**. REST 호출은 쿠키 자동 첨부 또는 `Authorization: Bearer <token>`.
- 요청/응답: `application/json; charset=UTF-8`
- 공통 응답: `{ "ok": true, ... }` / 실패 `{ "ok": false, "message": "..." }`
- 공통 에러코드: 400 잘못된 요청 · 401 미로그인 · 403 권한없음 · 404 없음 · 409 충돌

---

## 1. 인증 (브라우저 리다이렉트)
| Method | Path | 설명 |
|--------|------|------|
| GET | `/auth/kakao` | 카카오 로그인 시작(인가 코드 요청). 키 미설정 시 mock 로그인 |
| GET | `/auth/kakao/callback` | 콜백 → JWT 쿠키 발급 → `/`(또는 `/welcome`) |
| GET | `/auth/logout` | 쿠키 만료 → `/login` |

## 2. 사용자
### GET `/api/me`
현재 로그인 사용자.
```json
{ "ok": true, "loggedIn": true,
  "user": { "id": 1, "nickname": "손흥민", "position": "FW", "setupDone": true } }
```
### POST `/api/user/setup`
최초 닉네임/포지션 설정. Body: `{ "nickname":"손흥민", "position":"FW" }`
### POST `/api/user/profile`
프로필 수정. Body: `{ "nickname":"...", "position":"MF" }`

## 3. 팀
| Method | Path | 권한 | 설명 |
|--------|------|------|------|
| GET | `/api/team/list` | 회원 | 내가 속한 팀 목록 |
| POST | `/api/team` | 로그인 | 팀 생성 → 생성자 LEADER |
| POST | `/api/team/join` | 로그인 | 초대코드로 가입 |
| POST | `/api/team/{teamId}/invite-code` | 운영진+ | 초대코드 재발급 |
| GET | `/api/team/{teamId}/members` | 회원 | 팀원 목록 |
| POST | `/api/team/{teamId}/role` | 팀장 | 권한 변경 |
| POST | `/api/team/{teamId}/min-attendees` | 운영진+ | 인원부족 알림 기준 |

**POST /api/team** Body `{ "name":"FC 챔피언스", "description":"일요 풋살" }`
```json
{ "ok": true, "team": { "id":1, "name":"FC 챔피언스", "inviteCode":"AB3K9X",
  "memberCount":1, "myRole":"LEADER", "minAttendees":0 } }
```
**POST /api/team/join** `{ "inviteCode":"AB3K9X" }`
**POST /api/team/{id}/role** `{ "userId":5, "role":"MANAGER" }`
**POST /api/team/{id}/min-attendees** `{ "minAttendees":10 }`

**GET /api/team/{id}/members**
```json
{ "ok": true, "members": [
  { "userId":1, "nickname":"손흥민", "position":"FW", "role":"LEADER", "backNumber":7 } ] }
```

## 4. 경기 일정
| Method | Path | 권한 | 설명 |
|--------|------|------|------|
| GET | `/api/schedule/list?teamId=&year=&month=` | 회원 | 일정 목록(연·월 옵션 → 달력) |
| GET | `/api/schedule/{id}` | 회원 | 일정 상세 |
| GET | `/api/schedule/nearest?teamId=` | 회원 | 다가오는 가장 가까운 1건 |
| POST | `/api/schedule?teamId=` | 운영진+ | 일정 등록(+등록 알림) |
| PUT | `/api/schedule/{id}` | 운영진+ | 일정 수정 |
| DELETE | `/api/schedule/{id}` | 운영진+ | 일정 삭제 |

**POST /api/schedule?teamId=1** Body
```json
{ "title":"FC 챔피언스 vs FC 드림", "matchDate":"2026-06-20",
  "startTime":"20:00", "endTime":"22:00", "place":"잠실 풋살장 A",
  "fee":5000, "memo":"주차 가능" }
```
응답 `schedule` 객체: `{ id, teamId, title, matchDate, startTime, endTime, place, fee, memo, isPast }`

## 5. 참석
| Method | Path | 권한 | 설명 |
|--------|------|------|------|
| POST | `/api/attendance` | 회원 | 내 참석 상태 변경 |
| GET | `/api/attendance/list?scheduleId=` | 회원 | 참석 현황 집계+명단 |
| POST | `/api/attendance/paid` | 운영진+ | 회비 납부 토글 |

**POST /api/attendance** `{ "scheduleId":3, "status":"ATTEND" }` (ATTEND/ABSENT/PENDING)
**GET /api/attendance/list**
```json
{ "ok": true, "myStatus": "ATTEND",
  "summary": {
    "attend":12, "absent":3, "pending":5,
    "byPosition": { "GK":1, "DF":4, "MF":4, "FW":3 },
    "attendList":[{ "userId":1,"nickname":"손흥민","position":"FW","paid":true }],
    "absentList":[...], "pendingList":[...] } }
```
**POST /api/attendance/paid** `{ "scheduleId":3, "userId":5, "paid":true }`

## 6. 댓글
| Method | Path | 권한 | 설명 |
|--------|------|------|------|
| GET | `/api/comment/list?scheduleId=` | 회원 | 댓글 목록 |
| POST | `/api/comment` | 회원 | 댓글 작성 |
| DELETE | `/api/comment/{id}` | 작성자/운영진 | 삭제 |

**POST /api/comment** `{ "scheduleId":3, "content":"10분 늦습니다" }`

## 7. 통계 / 알림
| Method | Path | 권한 | 설명 |
|--------|------|------|------|
| GET | `/api/stats?teamId=` | 회원 | 회원별 출석률(이번달/3개월/전체) |
| GET | `/api/notification/list?teamId=` | 운영진+ | 알림 발송 이력 |

**GET /api/stats**
```json
{ "ok": true, "stats": [
  { "userId":1, "nickname":"손흥민", "position":"FW",
    "monthRate":100, "recent3Rate":83, "totalRate":78,
    "totalAttended":21, "totalMatches":27 } ] }
```

---

## 알림 발송 시점 (서버 자동, API 아님)
| 시점 | 트리거 | type |
|------|--------|------|
| 일정 등록 시 | `POST /api/schedule` | SCHEDULE_CREATED |
| 경기 하루 전 | 스케줄러(10분 주기) | D_1 |
| 경기 3시간 전 | 스케줄러 | H_3 |
| 경기 30분 전 | 스케줄러 | M_30 |
| 인원 부족 | 참석 변경 시 기준 미달 | LOW_ATTENDANCE |
> 동일 (schedule, type) 1회만 발송(중복 방지). 발송 채널은 `app.notify.mode` = `log`(개발) / `kakao`(알림톡).
