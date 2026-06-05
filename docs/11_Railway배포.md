# matchon Railway 배포 가이드

Dockerfile 기반 배포. DB는 기존 **Supabase Postgres 공유**(로컬과 같은 DB).

## 0. 사전
- GitHub 계정, Railway 계정(railway.com, 신규는 체험 크레딧 제공)
- Supabase 접속정보(이미 보유)

## 1. GitHub에 푸시
이미 로컬 커밋(main)은 되어 있음. GitHub에 새 저장소 만들고 연결:

```bash
# github.com 에서 빈 저장소 'matchon' 생성(Public/Private 무관, README 추가 X) 후:
cd /d/eclipse/eclipse-workspace/matchon
git remote add origin https://github.com/<본인아이디>/matchon.git
git push -u origin main
```
> 푸시 시 GitHub 로그인 창이 뜨면 인증(브라우저/PAT).

## 2. Railway 프로젝트 생성
1. railway.com → **New Project** → **Deploy from GitHub repo**
2. `matchon` 저장소 선택 → Railway가 **Dockerfile 자동 감지**해서 빌드 시작
3. 첫 빌드는 3~6분(Gradle + 의존성 다운로드)

## 3. 환경변수 설정 (Variables 탭)
아래를 추가. **PORT는 Railway가 자동 주입하므로 넣지 말 것.**

| KEY | VALUE |
|-----|-------|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres?sslmode=require` |
| `SPRING_DATASOURCE_USERNAME` | `postgres.uctqayuitxfbszdggqeu` |
| `SPRING_DATASOURCE_PASSWORD` | (Supabase DB 비밀번호) |
| `JWT_SECRET` | (32자 이상 임의 문자열) |

> `prod` 프로필이면 `application-local.yml`을 안 읽고 위 환경변수로 접속한다.
> Flyway는 같은 Supabase DB에 이미 적용돼 있어 재실행해도 검증만 하고 넘어간다.

### (선택) 실제 카카오 로그인까지 쓰려면
| KEY | VALUE |
|-----|-------|
| `KAKAO_REST_API_KEY` | 카카오 REST API 키 |
| `KAKAO_REDIRECT_URI` | `https://<railway도메인>/auth/kakao/callback` |
| `KAKAO_CLIENT_SECRET` | (보안에서 사용 시) |

키를 안 넣으면 **mock 로그인**(누를 때마다 임의 유저 생성)으로 동작 → 빠른 화면 확인용.

## 4. 공개 도메인 생성
Settings → Networking → **Generate Domain** → `https://matchon-production-xxxx.up.railway.app` 발급.
환경변수 바꾸면 자동 재배포됨.

## 5. 카카오 콘솔 설정 (실로그인 시)
[Kakao Developers] → 내 앱 → 카카오 로그인:
- 활성화 ON
- **Redirect URI**에 `https://<railway도메인>/auth/kakao/callback` 추가
- 플랫폼 → Web 도메인에 `https://<railway도메인>` 추가
- (앱 키의 REST API 키를 `KAKAO_REST_API_KEY`로)

## 6. 지인 테스트
- 발급된 도메인을 단톡방에 공유
- 팀장이 팀 생성 → **팀원 탭 → 초대 링크 복사/공유** → 단톡방에 붙여넣기
- 지인이 링크 클릭 → 로그인 → 자동 가입 → 일정/참석 테스트

## 트러블슈팅
| 증상 | 원인/해결 |
|------|-----------|
| 빌드 실패: java.home | Dockerfile이 `org.gradle.java.home` 줄을 제거함(이미 반영). 다시 푸시 |
| DB connection refused | 환경변수 URL/비번 확인, Supabase가 살아있는지 |
| tenant not found | pooler host의 region(aws-1-ap-southeast-1) 확인 |
| 로그인 후 매번 새 유저 | mock 로그인 특성 → 실유저는 카카오 키 설정 |
| 502/시작 안됨 | 로그(Deployments→View Logs)에서 `Started MatchonApplication` 확인, PORT 변수 넣지 않았는지 확인 |
| Supabase 연결수 초과 | Hikari pool=5, 무료 pooler 한도 확인. 로컬 앱 동시 실행 줄이기 |
