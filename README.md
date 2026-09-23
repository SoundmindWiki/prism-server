# Prism — 서버

**흩어진 프롬프트를 한 갈래로.**

팀이 잘 통한 프롬프트를 각자 메모장에 두지 않고 한곳에 모아 두는 사내 위키.
이 저장소는 그 **API 서버**다. 화면은 [prism-web](https://github.com/SoundmindWiki/prism-web) 에 있다.

- Ruby on Rails 8.1 (API 모드) · PostgreSQL 17 · 토큰 인증
- 응답은 전부 JSON. 화면 코드는 한 줄도 없다


## 분류는 팀을 따른다

카테고리가 곧 팀이다. 팀마다 자기 일에 쓰는 프롬프트가 다르기 때문에,
"개발 / 사무" 같은 성격별 분류보다 팀별 분류가 찾기 쉽다.

| 팀 | 주소 | 색 | 다루는 것 |
|---|---|---|---|
| WX | `wx` | 하늘 | 웹 서비스 — 프론트엔드 구현, 접근성, 웹 성능 |
| AX | `ax` | 보라 | AI 기능 — 프롬프트 설계, 응답 품질 평가, 검색 증강 |
| MX | `mx` | 초록 | 모바일 앱 — 앱 구현, 크래시 분석, 스토어 배포 |
| UX | `ux` | 자홍 | 사용자 경험 — 리서치, 화면 설계, 사용성 점검 |
| QC | `qc` | 주황 | 품질 — 테스트 설계, 결함 보고, 릴리스 검증 |
| MS | `ms` | 노랑 | 고객사 운영 — 장애 대응, 고객 문의, 운영 보고 |
| PMO | `pmo` | 분홍 | 프로젝트 — 일정과 범위, 리스크, 이해관계자 보고 |
| 경영지원팀 | `biz-support` | 청록 | 사람과 살림 — 채용, 사내 공지, 규정 안내 |
| 대표이사실 | `ceo-office` | 남색 | 경영 — 보고 요약, 대외 커뮤니케이션, 이사회 준비 |
| 기업부설연구소 | `rnd` | 청록빛 | 연구 — 기술 조사, 실험 설계, 과제 문서 |

팀이 늘거나 이름이 바뀌면 백오피스 → 카테고리에서 바꾸면 된다.
슬러그(주소)는 처음 만들 때 정해지고 이후 바뀌지 않는다. 공유된 링크가 깨지지 않게 하기 위해서다.

**분류 체계를 통째로 바꾼 뒤에는 `bin/rails db:reset` 으로 다시 만드는 편이 깔끔하다.**
`db:seed` 만 돌리면 예전 카테고리와 문서가 그대로 남는다.

## 도메인은 업계를 따른다

카테고리가 "어느 팀이 쓰는가" 라면 도메인은 "어느 업계 일에 쓰는가" 다.
제조 · 금융/보험 · 공공 · 헬스케어 · 국방 · 조선 · 교육 같은 산업 분야로 나눈다.

- **한 문서에 여러 도메인**을 달 수 있다. 아무것도 안 달면 업계를 가리지 않는 **범용** 문서다
- 도메인을 지우면 문서에서 떨어지기만 하고 문서는 남는다 (카테고리는 문서가 남아 있으면 못 지운다)
- 운영에는 맨 위 7개만 만들어 뒀다. 은행·보험·증권 같은 하위 분야는 백오피스 → 도메인에서 필요한 만큼 붙이면 된다

### 둘 다 트리다

카테고리와 도메인 모두 **3단계까지** 상위·하위를 둘 수 있다 (예: 금융/보험 › 보험 › 손해보험).

- **상위를 고르면 하위 문서까지 함께** 보인다. 사이드바 숫자도 하위까지 합친 수다
- 한 문서가 하위 두 곳에 같이 달려 있어도 상위 합계에서는 한 번만 센다
- 상위를 바꾸면 하위도 통째로 따라 옮겨지고, 새 자리의 맨 뒤에 붙는다. 옮긴 뒤 3단계를 넘게 되는 자리는 고를 수 없다
- 순서는 같은 상위 아래 형제끼리만 바꾼다
- 하위가 남아 있으면 지울 수 없다. 먼저 옮기거나 지운다

## MD 파일 형식

앞부분(`---` 사이)에 정보를 적고, 그 아래는 프롬프트 본문을 그대로 둔다.
**본문은 한 글자도 건드리지 않기 때문에, 내려받은 파일을 다시 올리면 똑같이 돌아온다.**

```markdown
---
title: 회귀 테스트 체크리스트 만들기
category: qc
domains:
- manufacturing
- 교육
tags:
- 테스트
- 릴리스
model: Claude Sonnet 5
summary: 변경 내역을 주면 이번 릴리스에서 꼭 다시 볼 곳을 뽑아 줍니다.
usage_notes: 변경 내역은 PR 목록을 그대로 붙여 넣으면 됩니다.
variables:
- name: 변경내역
  description: 이번 릴리스에 들어간 PR 목록
---

아래 변경 내역을 보고 회귀 테스트 체크리스트를 만들어 주세요.

{{변경내역}}
```

손으로 쓰는 파일도 너그럽게 받는다.

- **항목 이름은 한글로 써도 된다** — `제목` `카테고리` `도메인` `태그` `모델` `요약` `사용팁` `변수`
- **카테고리는 주소(`qc`)로도 이름(`QC`, `경영지원팀`)으로도** 찾는다. 못 찾으면 비워 두고 알려 준다
- **도메인도 주소(`finance`)로도 이름(`금융/보험`)으로도** 찾고, 여러 개를 적을 수 있다. 모르는 것만 빼고 알려 준다
- 태그는 목록으로 써도, `테스트, 릴리스` 처럼 쉼표로 써도 된다
- 변수는 목록으로 써도, `고객사: 회사 이름` 처럼 `이름: 설명` 으로 써도 된다
- **앞부분이 아예 없으면** 첫 번째 `# 제목` 을 제목으로 쓰고 그 줄은 본문에서 뺀다. 그것도 없으면 파일 이름을 쓴다
- **EUC-KR 로 저장된 옛날 메모장 파일**도 한글이 깨지지 않게 읽는다
- 앞부분이 깨져 있어도 본문은 살리고, 무엇을 못 읽었는지 알려 준다

올리면 **바로 저장하지 않고 폼에 채워만 둔다.** 훑어보고 카테고리 같은 걸 고친 뒤 저장하면 된다.
수정 화면에서 올리면 지금 내용을 덮어쓰기 전에 한 번 묻는다.

형식은 `server/app/models/prompt_markdown.rb` 한 곳에서 정한다.

## 실행

Ruby 는 시스템에 딸린 2.6 이 아니라 Homebrew 쪽 4.0 을 쓴다.

```bash
export PATH=/opt/homebrew/opt/postgresql@17/bin:/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH
```

### PostgreSQL

```bash
brew services start postgresql@17
pg_isready                          # accepting connections 가 나와야 한다
```

DB 이름은 `prism_development` · `prism_test` 다. 기본값은 OS 계정으로 `localhost:5432` 에 붙는다.
다르면 `DATABASE_HOST` `DATABASE_PORT` `DATABASE_USER` `DATABASE_PASSWORD` `DATABASE_NAME` 으로 바꾼다.

### 서버 (포트 3001)

```bash
cd server
bundle install          # gem 은 vendor/bundle 에 깔린다
bin/rails db:prepare     # 마이그레이션 + 시드
bin/rails server -p 3001
```

### 개발용 계정

시드가 만들어 주는 계정. **운영에 올리기 전에 반드시 지우거나 비밀번호를 바꿔야 한다.**

| 이메일 | 비밀번호 | 팀 | 권한 |
|---|---|---|---|
| `admin@example.com` | `1234` | WX | 관리자 |
| `jiwon.kim@soundmind.example` | `wiki1234!` | AX | 관리자 |
| `haneul.lee@soundmind.example` | `wiki1234!` | MX | 일반 |

관리자 주소는 `SEED_ADMIN_EMAIL`, 비밀번호는 `SEED_ADMIN_PASSWORD` 로 바꾼다.
운영에서는 `SEED_ADMIN_PASSWORD` 를 주지 않으면 무작위로 만들어 한 번만 찍어 준다.

나머지 팀(MS·PMO·경영지원팀·대표이사실·기업부설연구소)에도 문서 작성자용 계정이 하나씩 있다.
전부 `SEED_PASSWORD` 값을 쓴다.

나머지 계정의 비밀번호는 `SEED_PASSWORD` 로 바꿀 수 있다.
계정마다 다르게 주려면 `db/seeds.rb` 의 `MEMBERS` 에 `password:` 를 적으면 된다.
이미 있는 계정의 비밀번호는 시드를 다시 돌려도 덮어쓰지 않는다.

**비밀번호 `1234` 는 개발 편의를 위한 것이다.**
`User::MIN_PASSWORD_LENGTH` 는 개발·테스트에서 4자, 그 밖에서는 8자다
(`app/models/user.rb`). 운영에서는 4자짜리 비밀번호를 애초에 저장할 수 없다.

### 검사

```bash
bin/rails test      # 225개
```

## 구조

```
app/models/          Prompt, PromptVersion, Category, Domain, Tag, User, Session, AuditLog, Slug
app/models/concerns/ Treeable — 카테고리·도메인이 함께 쓰는 트리 규칙
app/controllers/api/v1/          위키 (로그인 필요)
app/controllers/api/v1/admin/    백오피스 (관리자만)
app/serializers/     응답 JSON 모양을 여기서만 정한다
db/seeds.rb          팀 10개 · 도메인 7개 · 문서 24개, 몇 번을 돌려도 같은 결과
test/                모델·컨트롤러 테스트
```

## 알아 둘 것

### 인증은 토큰 방식이다

로그인하면 `sessions` 테이블에 한 줄이 생기고 토큰을 돌려준다.
프론트는 그 토큰을 `Authorization: Bearer …` 헤더로 보낸다.
쿠키를 쓰지 않는 이유는 프론트(3000)와 API(3001)가 다른 오리진에서 돌기 때문이다.

세션은 **14일** 이면 만료되고, **12시간** 동안 아무 요청이 없어도 만료로 친다.
비밀번호를 바꾸거나 계정을 중지하면 그 사람의 세션이 전부 끊긴다.

**토큰을 localStorage 에 두는 건 XSS 에 약하다는 걸 알고 내린 선택이다.**
프론트와 API 의 오리진이 달라서 쿠키를 그대로 태우기 어려웠기 때문인데,
같은 도메인으로 합치게 되면 HttpOnly 쿠키로 바꾸는 편이 낫다.
바꿀 곳은 `app/composables/useAuth.ts` 와 `ApplicationController#current_session` 두 군데다.

### 권한은 둘뿐이다

`member` 는 위키를 읽고 쓸 수 있고, `admin` 은 백오피스까지 들어온다.
문서 단위 권한은 없다 — 위키니까 누구나 누구 문서든 고칠 수 있고, 대신 전부 히스토리에 남는다.

마지막 관리자는 스스로를 잠글 수 없게 막아 뒀다 (중지도, 권한 강등도).
아무도 백오피스에 못 들어가는 상태를 만들지 않기 위해서다.

### 활동 기록은 두 가지로 나뉜다

`AuditLog.record!` 는 **관리 기록**이다. 남기지 못하면 요청을 오류로 끝내 관리자가 알아채게 한다.
`AuditLog.track` 은 **구성원 활동**이다. 복사처럼 자주 일어나는 일이라, 기록에 실패해도 복사는 그대로 된다.

갈래와 이름표는 `AuditLog::GROUPS` 한 곳에서 정한다. 새 활동을 남기려면
여기에 한 줄 넣고 컨트롤러에서 `track_activity("종류", target: ...)` 를 부르면 된다.
비밀번호는 어떤 기록에도 남기지 않는다.

**활동 기록은 이 기능을 넣은 2026-09-22 부터 쌓인다.** 그 전 활동은 없다.
현황 표에서 그 전에 들어온 적 있는 사람은 "어제 로그인" 처럼 예전 로그인 시각으로 대신 보여 준다.

### 퇴사자는 지우지 않고 중지한다

계정을 지우면 그 사람이 쓴 문서와 히스토리가 함께 사라진다.
그래서 `DELETE /admin/users/:id` 는 실제로는 `active: false` 로 돌리고 세션만 끊는다.

### json gem 을 2.x 로 고정해 뒀다

Ruby 4.0 에 기본 포함된 json 3.x 는 `JSON.parse` 가 키워드 인자만 받는데
ActiveSupport 8.1 은 아직 위치 인자로 넘긴다. 그대로 두면 JSON 요청 본문 파싱이 통째로 깨진다.
ActiveSupport 가 고쳐지면 `Gemfile` 의 핀을 걷어내면 된다.

### 슬러그는 한글을 살린다

`회의록-정리와-액션-아이템-추출` 처럼 제목을 그대로 주소로 쓴다.
제목을 고쳐도 슬러그는 그대로 둔다 — 공유된 링크가 깨지면 안 되니까.
카테고리·태그도 마찬가지로, 이름을 고쳐도 카테고리 슬러그는 바뀌지 않는다.
(태그만은 이름과 주소가 어긋나면 헷갈려서 함께 바꾼다.)

### 검색은 ILIKE 다

제목·요약·본문·태그를 `ILIKE` 로 훑는다. 수천 건까지는 충분하고,
느려지면 Postgres 전문검색(`tsvector` + GIN 색인)으로 갈아타면 된다.
고칠 곳은 `app/models/prompt.rb` 의 `Prompt.search` 하나다.

## API

모두 `/api/v1` 아래. 로그인(`POST /session`)을 빼면 전부 `Authorization: Bearer <token>` 이 필요하다.

### 인증

| 메서드 | 경로 | 하는 일 |
|---|---|---|
| `POST` | `/session` | 로그인 — 토큰 발급 |
| `GET` | `/session` | 내 정보 |
| `DELETE` | `/session` | 로그아웃 — 이 세션만 삭제 |

### 위키

| 메서드 | 경로 | 하는 일 |
|---|---|---|
| `GET` | `/prompts` | 목록. `q` `category` `domain` `tag` `sort` `status` `page` `per_page`. `category`·`domain` 은 하위까지 포함 |
| `POST` | `/prompts` | 등록 (v1 이 함께 생성됨) |
| `GET` | `/prompts/:slug` | 상세 (조회수 +1, 수정 시각은 그대로) |
| `PATCH` | `/prompts/:slug` | 수정 (내용이 실제로 바뀌었을 때만 새 버전) |
| `POST` | `/prompts/:slug/copy` | 복사 횟수 +1 |
| `POST` | `/prompts/:slug/move` | 폴더(카테고리) 바꾸기. 내용이 그대로라 새 버전은 안 생김 |
| `POST` | `/prompts/:slug/archive` | 보관 — 목록에서 내려가지만 주소·히스토리는 유지 |
| `GET` | `/prompts/:slug/markdown` | `.md` 파일로 내려받기 |
| `POST` | `/prompts/parse_markdown` | `.md` 내용(`markdown`, `filename`)을 폼에 채울 값으로 읽기. 저장은 안 함, 256KB 까지 |
| `GET` | `/prompts/:slug/versions` | 히스토리 |
| `POST` | `/prompts/:slug/versions/:n/restore` | 되돌리기 (새 버전으로 쌓임) |
| `POST` | `/categories` | 폴더 만들기. `parent_slug` 필수 — 맨 위 팀 폴더는 백오피스에서만 |
| `GET` | `/categories` · `/domains` · `/tags` · `/stats` | 목록과 통계. 분류는 트리 순서로 편 목록에 `depth` `path` `parent_slug` `prompts_count`(바로 달린 수) `total_count`(하위 포함) |

### 마이페이지

| 메서드 | 경로 | 하는 일 |
|---|---|---|
| `GET` | `/profile` | 내 정보 · 활동 요약 · 내 문서 · 로그인 중인 기기 |
| `PATCH` | `/profile` | 이름·소속·직급·직함 수정 (이메일·권한은 못 바꿈) |
| `PATCH` | `/profile/password` | 비밀번호 변경 (다른 기기 로그아웃) |
| `DELETE` | `/profile/sessions/:id` · `/profile/sessions` | 기기 하나 · 지금 창 빼고 전부 내보내기 |

### 백오피스 (관리자만, `/admin` 아래)

| 메서드 | 경로 | 하는 일 |
|---|---|---|
| `GET` | `/admin/dashboard` | 현황 한 벌 |
| `GET` `POST` | `/admin/users` | 구성원 목록(`q` `role` `active`) · 추가 |
| `PATCH` `DELETE` | `/admin/users/:id` | 정보·권한 수정 · 계정 중지 |
| `POST` | `/admin/users/:id/reactivate` · `/reset_password` | 재개 · 비밀번호 재발급 |
| `GET` `POST` | `/admin/categories` · `/admin/domains` | 목록 · 추가 (`parent_slug` 로 상위 지정) |
| `PATCH` `DELETE` | `/admin/categories/:slug` · `/admin/domains/:slug` | 수정·상위 옮기기 · 삭제(하위 없을 때만. 카테고리는 문서도 없을 때만) |
| `POST` | `/admin/categories/reorder` · `/admin/domains/reorder` | 같은 상위 아래 형제 순서 변경 |
| `GET` `PATCH` `DELETE` | `/admin/tags[/:slug]` | 목록 · 이름 변경 · 삭제 |
| `POST` | `/admin/tags/:slug/merge` | 다른 태그로 병합 |
| `GET` | `/admin/prompts` | 초안·보관 포함 전체 |
| `PATCH` `DELETE` | `/admin/prompts/:slug` | 상태 변경 · 완전 삭제 |
| `GET` | `/admin/audit_logs` | 활동 기록. `group` `action_type` `user_id` `days(1·7·30)` `page` |
| `GET` | `/admin/audit_logs/summary` | 구성원별 현황. `days(1·7·30)` |

## 배포

| | |
|---|---|
| 서버 | AWS EC2 `t3.micro` · Ubuntu 26.04 · 2코어 / RAM 908MB / 디스크 28GB |
| 앱 | `/srv/prism/server` (Rails) · `/srv/prism/web` (정적 프론트) |
| 환경 변수 | `/srv/prism/shared/prism.env` (권한 600) |
| 서비스 | `prism.service` (Puma, 127.0.0.1:3001) · `nginx` · `postgresql` |
| 인증서 | Let's Encrypt, certbot 타이머로 자동 갱신 |

운영에서 읽는 환경 변수:

```bash
DATABASE_URL="postgres://user:pass@host:5432/prism"
PRISM_ALLOWED_ORIGINS="https://prism.example.com"
SECRET_KEY_BASE="…"
WEB_CONCURRENCY=0
PORT=3001
```

### 다시 배포하기

```bash
bin/deploy      # 코드 업로드 → bundle install → db:migrate → 재시작
```

배포 대상은 저장소에 적어 두지 않는다. 맨 위에 `.deploy.env` 를 만들어 두면 알아서 읽는다
(`.gitignore` 에 들어 있다).

```bash
PRISM_HOST=ubuntu@203.0.113.10
PRISM_KEY=~/keys/prism.pem
PRISM_DOMAIN=prism.example.com
```

### 자주 쓰는 명령

```bash
ssh -i $PRISM_KEY $PRISM_HOST

sudo journalctl -u prism -f                    # 앱 로그
sudo systemctl restart prism                   # 앱 재시작
sudo tail -f /var/log/nginx/access.log         # 접속 로그
cd /srv/prism/server && bundle exec rails c    # 콘솔 (환경 변수 먼저 읽어야 함)
```

### 서버에서 알아 둘 것

**nginx 의 `try_files` 순서가 중요하다.**
`try_files $uri ...` 를 먼저 두면 `/login` 이 디렉터리와 맞아떨어져 `/login/` 으로 301 이 난다.
그러면 SPA 라우터가 보는 경로와 주소창이 어긋나 로그인이 자기 자신으로 돌아가는 순환에 빠진다.
그래서 `try_files $uri.html $uri/index.html $uri /index.html;` 순서로 파일을 먼저 찾게 해 뒀다.

**램이 1GB 라 swap 2GB 를 붙여 뒀고**, Puma 는 단일 모드(`WEB_CONCURRENCY=0`)로 돈다.
`prism.service` 에 `MemoryMax=600M` 을 걸어 두어 새면 systemd 가 다시 띄운다.

**서버가 us-east-1 에 있다.** 한국에서 API 왕복이 600ms 쯤 걸린다.
체감이 거슬리면 ap-northeast-2(서울) 로 옮기는 게 가장 효과가 크다.

**AWS 보안 그룹(`launch-wizard-1`)이 방화벽이다.** 서버의 ufw 는 꺼져 있다.
포트를 열고 닫으려면 AWS 콘솔에서 해야 한다.

## 남은 일

- [ ] **DB 백업** — 지금은 백업이 없다. `pg_dump` 를 cron 에 걸어 두는 것부터
- [ ] 로그인 시도 제한 (Rails 8 의 `rate_limit`) — 지금은 실패가 기록에만 남는다
- [ ] 첫 로그인 때 비밀번호 바꾸기 강제
- [ ] 사내 SSO(SAML/OIDC) 연동 — 위 "인증은 토큰 방식이다" 참고
- [ ] 비밀번호 찾기 (지금은 관리자가 재발급해 주는 방식뿐)
- [ ] 만료된 세션 청소 — `Session.sweep_expired` 를 주기 작업으로
- [ ] 서버를 서울 리전으로 이전 (지금은 us-east-1 이라 왕복 600ms)
- [ ] CI — 테스트·배포 자동화
