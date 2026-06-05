# matchon ⚽ — 축구·풋살 동호회 출석 관리 서비스

카카오톡 단톡방을 **대체하지 않고**, 카카오톡과 함께 쓰는 **출석 관리 보조 서비스**입니다.
경기 일정 등록 → 참석/불참 체크 → 카카오 알림, 이 세 가지에 집중합니다.

## 핵심 기능 (MVP)

- **카카오 로그인** (별도 회원가입 없음, 최초 로그인 시 닉네임 설정)
- **팀 관리** (생성 / 초대코드 가입 / 팀장·운영진·일반회원 권한)
- **경기 일정** (월별 달력, 팀장·운영진만 등록)
- **참석 체크** (참석/불참/미정 버튼, 실시간 집계)
- **참석 현황** (인원수 + 명단 + 포지션별 인원)
- **카카오 알림** (일정 등록 시 / 하루 전 / 3시간 전 / 30분 전)
- 부가: 포지션 관리, 출석률 통계, 인원부족 알림, 일정 댓글, 회비 납부 체크

## 기술 스택

- Java 21, Spring Boot 3.3.x, Gradle (war/JSP)
- Spring Security + **JWT**(jjwt) 무상태 인증
- JPA(Hibernate) + **QueryDSL** + **MariaDB** + Flyway 마이그레이션
- View: **JSP** + JSTL + HTML5/CSS3/ES6 + jQuery (모바일 우선 반응형)

## 로컬 실행

### 0) 사전 준비
- JDK 21 (없어도 됨 — Gradle toolchain 이 자동 다운로드)
- MariaDB 10.6+

### 1) DB 생성
```sql
CREATE DATABASE matchon DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'matchon'@'%' IDENTIFIED BY 'matchon1234';
GRANT ALL PRIVILEGES ON matchon.* TO 'matchon'@'%';
FLUSH PRIVILEGES;
```

### 2) 로컬 설정
`src/main/resources/application-local.yml` 을 환경에 맞게 수정합니다.
(`application-local.yml.example` 참고. 카카오 키를 비워두면 **mock 로그인**으로 자동 진행됩니다.)

### 3) 실행
```bat
gradlew.bat bootRun
```
→ http://localhost:8282

> JSP 는 `bootRun` / `bootWar` 에서 동작합니다. 배포는 `gradlew bootWar` 로 실행 가능한 WAR 를 만드세요.

## 카카오 로그인 설정 (실서비스)

1. [Kakao Developers](https://developers.kakao.com) 앱 생성
2. 카카오 로그인 활성화 + Redirect URI 등록: `http://localhost:8282/auth/kakao/callback`
3. REST API 키 / (선택)Client Secret 을 `application-local.yml` 에 입력

## 프로젝트 구조

```
matchon/
├─ build.gradle / settings.gradle
├─ src/main/java/com/jacob/matchon/
│  ├─ config/        SecurityConfig, QuerydslConfig
│  ├─ security/      JwtTokenProvider, JwtAuthFilter, CurrentUser
│  ├─ model/         엔티티 + enum
│  ├─ repo/          JPA Repository + QueryDSL StatsRepository
│  ├─ service/       비즈니스 로직
│  ├─ web/           REST API + JSP 라우팅 컨트롤러
│  ├─ notification/  알림 발송 추상화(log/kakao)
│  └─ scheduler/     리마인드 알림 스케줄러
├─ src/main/resources/
│  ├─ application.yml / application-local.yml
│  └─ db/migration/  Flyway SQL
└─ src/main/webapp/WEB-INF/views/  JSP

docs/  서비스 기획서·화면설계·ERD·DB설계·API명세·일정·운영전략
```

자세한 설계 문서는 [`docs/`](./docs) 폴더를 참고하세요.
