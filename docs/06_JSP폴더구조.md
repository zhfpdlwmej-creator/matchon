# matchon JSP 폴더 구조

JSP 는 `src/main/webapp/WEB-INF/views/` 아래. ViewResolver: prefix `/WEB-INF/views/`, suffix `.jsp`
(`application.yml`의 `spring.mvc.view`). 직접 URL 접근 차단(WEB-INF) → 컨트롤러 경유만.

```
src/main/webapp/
└─ WEB-INF/
   └─ views/
      ├─ login.jsp                 # 로그인 (/login)
      ├─ welcome.jsp               # 최초 닉네임/포지션 설정 (/welcome)
      ├─ home.jsp                  # 홈-가장 가까운 경기 (/team/{id})
      ├─ profile.jsp               # 내 정보 (/profile)
      │
      ├─ layout/                   # 공통 include 조각
      │  ├─ head.jsp               #  <meta>/css/jquery/app.js
      │  ├─ header.jsp             #  상단 그린 헤더(팀명/권한)
      │  └─ bottomnav.jsp          #  하단 5탭 네비
      │
      ├─ team/
      │  └─ teams.jsp              # 내 팀 목록/생성/가입 (/teams)
      │
      ├─ schedule/
      │  ├─ list.jsp               # 월별 달력 + 일정 리스트 (/team/{id}/schedules)
      │  └─ detail.jsp             # 일정 상세·참석관리·댓글 (/team/{id}/schedule/{sid})
      │
      ├─ member/
      │  └─ list.jsp               # 팀원/초대코드/권한 (/team/{id}/members)
      │
      ├─ stats/
      │  └─ list.jsp               # 출석률 통계 (/team/{id}/stats)
      │
      └─ admin/
         └─ index.jsp             # 운영설정/알림이력 (/team/{id}/admin)
```

## 정적 리소스 (`src/main/resources/static/`)
```
static/
├─ css/app.css        # 모바일 우선 전체 스타일(컬러 토큰, 컴포넌트)
├─ js/app.js          # 공통: api(fetch 래퍼), esc(XSS), won, posBadge
└─ img/               # 아이콘/엠블럼(추후)
```
> 페이지별 로직은 각 JSP 하단 `<script>` 에 인라인. 공통 함수만 app.js.

## 화면 ↔ 컨트롤러 매핑 (MainController)
| URL | View | 비고 |
|-----|------|------|
| `/login` | login.jsp | 로그인됨이면 `/` |
| `/welcome` | welcome.jsp | 설정 전 사용자 |
| `/` | (redirect) | 팀 없으면 `/teams`, 있으면 첫 팀 홈 |
| `/teams` | team/teams.jsp | |
| `/team/{id}` | home.jsp | `nearest` 모델 |
| `/team/{id}/schedules` | schedule/list.jsp | |
| `/team/{id}/schedule/{sid}` | schedule/detail.jsp | `scheduleId` 모델 |
| `/team/{id}/members` | member/list.jsp | |
| `/team/{id}/stats` | stats/list.jsp | |
| `/team/{id}/admin` | admin/index.jsp | `canManage` |
| `/profile` | profile.jsp | |

## JSP 작성 규칙
- 상단 `<%@ page contentType="text/html;charset=UTF-8" %>` + JSTL core(`jakarta.tags.core`)
- 모델 노출 값은 EL `${...}`(자동 escape는 JSTL `<c:out>`/JS `esc()`로 보강)
- 데이터는 JS가 `/api`로 비동기 로드 → JSP는 뼈대만(서버 렌더 최소화)
- 공통 조각은 `<%@ include file="layout/xxx.jsp" %>` 정적 include
- 빌드/실행: JSP 는 `bootRun`/`bootWar`에서 동작(`bootJar` 는 JSP 미지원 → war 패키징)
