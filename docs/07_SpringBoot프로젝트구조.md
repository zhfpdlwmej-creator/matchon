# matchon Spring Boot 프로젝트 구조

## 패키지 트리
```
com.jacob.matchon
├─ MatchonApplication.java          # @SpringBootApplication, @EnableScheduling
│
├─ config/
│  ├─ SecurityConfig.java           # JWT 무상태 시큐리티 체인
│  └─ QuerydslConfig.java           # JPAQueryFactory 빈
│
├─ security/
│  ├─ JwtTokenProvider.java         # JWT 발급/검증(jjwt 0.12)
│  ├─ JwtAuthFilter.java            # 쿠키/헤더 토큰 → 인증 주입
│  └─ CurrentUser.java             # SecurityContext에서 userId 추출
│
├─ model/                           # JPA 엔티티 + enum
│  ├─ User, Team, TeamMember
│  ├─ MatchSchedule, Attendance, Comment, Notification
│  └─ Role, AttendanceStatus, Position, NotificationType
│
├─ repo/                            # 데이터 접근
│  ├─ UserRepository ... NotificationRepository  (Spring Data JPA)
│  └─ StatsRepository.java          # QueryDSL 출석률 집계
│
├─ dto/
│  ├─ ScheduleForm.java             # 일정 등록/수정 폼
│  ├─ AttendanceSummary.java        # 참석 현황 집계 결과
│  └─ StatRow.java                  # 통계 행
│
├─ service/                         # 비즈니스 로직(@Transactional)
│  ├─ UserService, TeamService, ScheduleService
│  ├─ AttendanceService, CommentService, StatsService
│  └─ NotificationService
│
├─ notification/                    # 알림 발송 추상화
│  ├─ NotificationSender (interface)
│  ├─ LogNotificationSender         # mode=log (개발)
│  └─ KakaoNotificationSender       # mode=kakao (알림톡, 확장지점)
│
├─ scheduler/
│  └─ ReminderScheduler.java        # D-1/3h/30m 리마인드(@Scheduled)
│
└─ web/                             # 컨트롤러
   ├─ MainController.java           # JSP 화면 라우팅
   ├─ AuthController.java           # 카카오 OAuth → JWT
   ├─ TeamApiController.java        # 사용자/팀 REST
   ├─ ScheduleApiController.java    # 일정 REST
   ├─ AttendanceApiController.java  # 참석 REST
   ├─ CommentApiController.java     # 댓글 REST
   ├─ StatsApiController.java       # 통계/알림이력 REST
   ├─ ApiException.java             # 비즈니스 예외
   └─ ApiExceptionHandler.java      # @RestControllerAdvice
```

## 레이어 아키텍처
```
[JSP + jQuery]  ──AJAX(/api)──▶  [Controller]
                                    │ (검증/권한: CurrentUser, TeamService.requireManager)
                                    ▼
                                 [Service] ──▶ [Repository(JPA/QueryDSL)] ──▶ MariaDB
                                    │
                                    └─▶ [NotificationService] ──▶ [NotificationSender]
[Scheduler] ──@Scheduled──▶ [NotificationService]
```

## 리소스
```
src/main/resources/
├─ application.yml                  # 공통(JSP뷰, JPA, Flyway, JWT, kakao)
├─ application-local.yml(.example)  # 로컬 DB/키 (gitignore)
└─ db/migration/V1__init.sql        # Flyway 초기 스키마
```

## 빌드 설정 (build.gradle 핵심)
- Java **toolchain 21** (미설치 시 foojay 로 자동 다운로드 — settings.gradle)
- 플러그인: `java`, `war`, `org.springframework.boot` 3.3.x, `io.spring.dependency-management`
- 의존성: web, data-jpa, security, validation, **tomcat-embed-jasper(JSP)**, JSTL,
  **jjwt**, **querydsl-jpa:jakarta**, mariadb-java-client, flyway-core/mysql, lombok, gson
- QueryDSL Q클래스 생성 경로: `build/generated/querydsl` (sourceSets 등록)

## 실행/배포
| 목적 | 명령 |
|------|------|
| 로컬 실행 | `gradlew bootRun` (→ :8282) |
| 배포 산출물 | `gradlew bootWar` (실행 가능한 WAR, JSP 포함) |
| 컨테이너 | `Dockerfile` (gradle:8.8-jdk21 빌드 → temurin:21-jre 실행) |

## 환경변수(운영)
`SPRING_PROFILES_ACTIVE=prod`, `SPRING_DATASOURCE_URL/USERNAME/PASSWORD`,
`JWT_SECRET`(32자+), `KAKAO_REST_API_KEY`, `KAKAO_REDIRECT_URI`, `KAKAO_CLIENT_SECRET`, `NOTIFY_MODE`
