# M1 — SMS 인증 + 공고 조회 Design Spec

**날짜**: 2026-05-10
**범위**: Sharework 실서비스 전환 첫 마일스톤(M1) 시스템 설계
**선행 문서**: [`../../master-plan.md`](../../master-plan.md)
**다음 단계**: writing-plans 스킬 → 상세 구현 plan 작성 → SDD 구현

## Context

UI Demo MVP의 80화면·75라우트는 완비되어 있으나 모든 데이터가 `lib/data/dummy_data.dart`에서 온다(main `928e397`). 단계적 베타 트랙으로 전환하기 위해 첫 단계로 **인증과 공고 조회 흐름을 실 백엔드(Supabase + BFF)로 교체**한다. 나머지 흐름(Giver·채팅·결제·지도 등)은 M2~M8에서 단계적으로 교체하며 본 M1 범위 외에선 dummy_data를 유지한다.

## 결정사항 lock-in (brainstorming 합의, 2026-05-10)

| 결정 | 값 | 근거 |
|------|---|------|
| SMS 공급자 | Mock으로 시작, 실 SMS는 M1 후반 또는 M2에 통합 | 발신 번호 등록 1~3일 심사 병렬화, 의도·설계 검증 우선 |
| 인증 백엔드 | Supabase Phone Auth | refresh·세션·JWT 자동 관리, BFF 코드 절감 |
| Flutter ↔ Supabase 패턴 | 하이브리드 — auth는 SDK 직접, data는 BFF 경유 | easy-travel-korea-api 패턴 승계, M5 결제 PG 웹훅 처리 자연 확장 |
| M1 완료 기준 | 마스터 플랜 기준 — Mock OTP 인증 + jobs 목록·상세 + 검색 + 카테고리 필터 + GET /me | 첫 베타에서 "조회" 흐름이 완전 |

## 1. Architecture & Components

```
Flutter (sharework repo)
├── supabase_flutter SDK    → Supabase Auth (Phone)         [auth 직접]
└── dio + ApiClient         → BFF (sharework-api)            [data 경유]
                                 └── @supabase/supabase-js   → Supabase Postgres (RLS)
```

**컴포넌트**:

- **`sharework-api`** (신규 레포): Next.js 16 + TypeScript + zod, Vercel 배포. easy-travel-korea-api 아키텍처 승계
- **`sharework`** (현재): Flutter 앱. M1에서 `lib/data/api_client.dart` + `lib/data/repositories/` 추가
- **Supabase 프로젝트** (신규): Postgres + Phone Auth. M2부터 Storage·Realtime 추가

**신규 Flutter 의존성**:

- `supabase_flutter`: Phone Auth + JWT/refresh 자동 관리
- `dio`: BFF API HTTP 클라이언트
- `freezed` + `json_serializable`: 모델 직렬화

**BFF 스택**:

- Next.js 16 App Router (Route Handlers)
- `@supabase/supabase-js` with **service role key** (서버 환경 변수만)
- JWT 검증 미들웨어: `jose` 또는 Supabase REST(`/auth/v1/user`) 호출
- zod로 query/body/response 모두 검증

## 2. Data Model (M1 — 3 테이블)

### `profiles` (Supabase auth.users 1:1)

가입 시 trigger로 자동 생성.

| 컬럼 | 타입 | 비고 |
|------|------|------|
| id | uuid | PK, FK auth.users(id) |
| phone | text | unique, E.164 형식 (`+8210...`) |
| name | text | 가입 후 사용자가 입력 (M1엔 미입력 허용, default = phone 끝자리 4) |
| role | text | enum: `worker` \| `giver`, default `worker` |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

**RLS**: 본인 row만 read/write (`auth.uid() = id`).

### `jobs`

| 컬럼 | 타입 | 비고 |
|------|------|------|
| id | uuid | PK, default gen_random_uuid() |
| giver_id | uuid | FK profiles(id) ON DELETE CASCADE |
| title | text | not null, max 100자 |
| description | text | not null, max 2000자 |
| wage_won | int | not null, 시급 (원) |
| schedule_text | text | "매주 토요일 09:00~18:00" 같은 자유 텍스트 (M1엔 단순) |
| status | text | enum: `active` \| `paused` \| `closed`, default `active` |
| category_id | uuid | FK job_categories(id) |
| location_address | text | "서울시 강남구 ..." |
| location_lat | numeric(9,6) | 위도, M1엔 nullable |
| location_lng | numeric(9,6) | 경도, M1엔 nullable |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

**RLS**:
- 인증 사용자: `status = 'active'` row만 read
- giver 본인: 본인 `giver_id = auth.uid()` row read/write 모두

**M1엔 jobs 등록·수정 RLS는 정의하지만 클라이언트 흐름은 미구현(M2)**.

### `job_categories`

| 컬럼 | 타입 | 비고 |
|------|------|------|
| id | uuid | PK |
| name | text | "서빙", "물류", "청소" 등 |
| slug | text | unique, URL-safe (`serving`, `logistics`, `cleaning`) |
| sort_order | int | default 0 |

**RLS**: anyone read, no write (admin이 SQL seed로 직접 INSERT).

**M1 시드**: 10~15개 카테고리 (`lib/data/dummy_data.dart`의 카테고리 리스트 그대로 마이그레이션).

## 3. Auth Flow (Mock OTP)

M1에서 BFF에 send-otp / verify-otp 엔드포인트를 만들지 **않는다**. Flutter가 supabase_flutter SDK로 Supabase Phone Auth를 직접 호출한다.

```
[Flutter phone_auth_screen]
       │
       │  1. supabase.auth.signInWithOtp(phone)
       ▼
[Supabase Auth (Mock 모드)]   ── (Mock OTP 반환, 실 SMS 미발송)
       │
       │  2. 사용자가 화면에 OTP 입력
       │
       │  3. supabase.auth.verifyOtp(phone, token)
       ▼
[Supabase Auth] ──→ JWT + refresh 반환
       │
       │  4. supabase_flutter SDK가 secure storage에 자동 영속
       │
       ▼
[Flutter 라우터] ── 인증 OK → /worker 진입
```

**Mock 모드 활성화 방법**: Supabase Phone Auth는 `Auth > Providers > Phone > Test OTP`에서 phone ↔ 고정 OTP 매핑을 등록 가능(공식 docs 확인 후 plan 단계에서 확정 — R5 적용). 또는 Supabase 로컬 dev에서 콘솔 로깅. M1 plan 작성 시 정확한 Supabase docs 인용 + 설정 절차 lock-in.

**BFF에서 JWT 검증**:

```
[Flutter ApiClient] ── Authorization: Bearer <jwt> ─→ [BFF middleware]
                                                            │
                                                            │  jose.jwtVerify(token, supabaseJwtSecret)
                                                            ▼
                                                       user_id 추출
                                                            │
                                                            ▼
                                                       [BFF route handler]
                                                            │
                                                            │  service role로 Supabase 조회
                                                            ▼
                                                       응답
```

JWT 검증 실패 → 401. supabase_flutter는 401 시 자동 refresh 시도. refresh도 실패하면 Flutter dio 인터셉터가 401 catch → AuthRepository.signOut → `/auth/phone` 리디렉트.

## 4. BFF API Endpoints (M1)

모든 응답은 envelope:

- 성공: `{ data: <payload>, page?: { total, page, limit } }`
- 오류: `{ error: { code: <enum>, message: <string> } }`

| Method | Path | Auth | 응답 data |
|--------|------|------|----------|
| GET | `/api/me` | required | `{ id, phone, name, role, created_at }` |
| GET | `/api/jobs?category=&q=&page=&limit=` | required | `Job[]` + page meta |
| GET | `/api/jobs/:id` | required | `Job` (단일) |
| GET | `/api/categories` | required | `JobCategory[]`, `Cache-Control: public, max-age=3600` |

**오류 코드 enum**:

- `UNAUTHORIZED` (401) — JWT 미검증
- `NOT_FOUND` (404) — id로 조회 실패
- `VALIDATION_ERROR` (400) — zod 검증 실패
- `INTERNAL` (500) — 그 외

**zod schema 예시 (`/api/jobs` query)**:

```ts
const querySchema = z.object({
  category: z.string().optional(),
  q: z.string().max(100).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
```

**page·limit cap**: limit 최대 50으로 강제. 무한 스크롤 가능하나 한 번에 너무 많이 못 가져옴.

## 5. Flutter Repository Pattern

### 신규 파일

```
lib/data/
├── api_client.dart                     # dio 인스턴스 + JWT 인터셉터
├── auth_storage.dart                   # supabase_flutter session 노출 helper
├── repositories/
│   ├── auth_repository.dart            # Supabase SDK wrapper
│   ├── job_repository.dart             # BFF /api/jobs, /api/categories
│   └── me_repository.dart              # BFF /api/me
└── models/                             # freezed로 자동 생성
    ├── profile.dart
    ├── job.dart
    └── job_category.dart
```

### 화면 변경 (7개)

| 화면 | 변경 내용 |
|------|----------|
| `screens/auth/phone_auth_screen.dart` | dummy → `AuthRepository.sendOtp/verifyOtp` |
| `screens/worker/home/worker_home_screen.dart` | dummy `nearbyJobs` → `JobRepository.getJobs()` |
| `screens/common/job_info_screen.dart` | dummy → `JobRepository.getJobById(id)` |
| `screens/common/search_screen.dart` | dummy → `JobRepository.getJobs(q=...)` |
| `screens/categories/categories_screen.dart` | dummy → `JobRepository.getCategories()` |
| `screens/categories/category_jobs_screen.dart` | dummy → `JobRepository.getJobs(category=...)` |
| `screens/worker/mypage/mypage_screen.dart` | dummy → `MeRepository.getMe()` |

**다른 화면(Giver 흐름·채팅·결제·통계 등)은 dummy_data 그대로 유지**. M1에서 절대 건드리지 않음.

### 상태 관리

기존 코드 패턴(StatefulWidget + setState 또는 Provider/Riverpod)을 유지. 새 의존성 도입은 M1 범위 밖. plan 단계에서 현재 패턴 grep 후 일치시킴.

## 6. Error Handling & UX

### BFF 에러 매핑

| 상황 | HTTP | code |
|------|------|------|
| zod 검증 실패 | 400 | `VALIDATION_ERROR` |
| JWT 검증 실패/만료 | 401 | `UNAUTHORIZED` |
| 데이터 미발견 | 404 | `NOT_FOUND` |
| Supabase 오류 | 500 | `INTERNAL` (메시지에 sanitized 정보) |

### Flutter dio 인터셉터

- 401 catch → `AuthRepository.signOut()` → `context.go('/auth/phone')`
- 그 외 → `JobException` / `ApiException` 던지기

### UI 상태

- **로딩**: `CircularProgressIndicator` (기존 위젯 패턴 따름)
- **빈 상태**: 화면별 메시지 — `worker_home`은 "근처 공고가 없어요", `search`는 "검색 결과가 없어요", `categories_screen`은 "카테고리가 비어 있어요"
- **오류 상태**: "연결이 불안정합니다" + **다시 시도** 버튼

### 라우터 가드

`lib/router/app_router.dart`에 redirect 추가:

```dart
redirect: (context, state) {
  final session = supabase.auth.currentSession;
  final isAuthRoute = state.matchedLocation.startsWith('/auth/');
  final isOnboarding = state.matchedLocation.startsWith('/onboarding');
  if (session == null && !isAuthRoute && !isOnboarding) {
    return '/auth/phone';
  }
  return null;
},
```

## 7. Testing Strategy (TDD)

### BFF (`sharework-api` 신규 레포)

- **Unit**:
  - zod schema 6개 (각 엔드포인트의 query/path/response)
  - JWT 검증 미들웨어 (mock JWT 발급기로)
- **Integration** (실 Supabase test DB):
  - 각 엔드포인트별 1~2 케이스 (성공 + 주요 오류)
  - test DB는 Supabase 별도 프로젝트 또는 `pgtap`/`pg-mem`
- **E2E 1건**: 인증→jobs 목록→jobs 상세→/me 시나리오 (Playwright 또는 supertest)
- 도구: vitest 또는 jest

### Flutter (`sharework`)

- **Widget test 7개** (변경 화면 1대1):
  - mock repository 주입
  - 정상 / 빈 상태 / 오류 상태 3 케이스
- **Integration test 1건** (`test/integration/m1_smoke_test.dart`):
  - Mock OTP → jobs 표시까지 한 흐름
- **Golden test** (선택 — 빈 상태/오류 상태 UI 회귀 방지) — 도입 여부는 plan 단계 결정
- 기존 `flutter test 2/2`는 유지 (regression)

### TDD 강제

글로벌 룰("TDD 의무, 테스트 먼저"). 각 SDD 태스크는 RED→GREEN→REFACTOR 사이클로 진행. 구현 후 테스트 작성 시 lesson 로그.

## 8. Out of Scope (M1 명시 제외)

본 마일스톤 범위 밖으로 명시한다. 시도 시 즉시 다음 마일스톤으로 분기:

- 실 SMS 발송 → M1 후반 또는 M2 (NHN Cloud / Twilio 등 결정 후)
- Giver 화면 (jobs 등록·수정·지원자 관리) → M2
- 사진 업로드 (jobs 이미지) → M2
- 채팅·푸시 알림 → M3·M4
- 결제·에스크로 → M5
- 위치·지도 SDK + Info.plist 권한 호출 → M6
- 사업자 인증 + KYC → M7
- TestFlight 정식 트랙 → M8

## 외부 의존성 (M1 시작 전 사용자 작업)

| # | 작업 | 소요 | 시점 |
|---|------|------|------|
| 1 | Supabase 회원가입 + 신규 프로젝트 생성 | 5분 | M1 시작 직전 (필수) |
| 2 | URL · anon key · service role key 메모 | 1분 | M1 시작 직전 (필수) |
| 3 | sharework-api GitHub 신규 레포 생성 | 5분 | M1 시작 직전 또는 plan 단계 |
| 4 | Vercel 계정 + GitHub 연동 (BFF 배포용) | 5분 | M1 후반 |
| 5 | (선택) SMS 공급자 가입·발신 번호 등록 | 1~3일 | M1 후반 또는 M2 (병렬 가능) |

## 문제 영역 / 미정 (plan 단계에서 확정)

R5(training data 가정 금지) 적용 — 다음은 plan 단계에서 공식 docs 직접 확인 후 lock-in:

1. **Supabase Phone Auth Mock 모드 정확한 활성화 방법** — 대시보드 Test OTP 기능 정확한 위치·제약·요금
2. **Supabase Phone Auth 가격 정책** — Free tier 한도, Pro tier 가격
3. **JWT secret 노출 정책** — Supabase JWT secret을 BFF 환경 변수로 두는 게 권장 패턴인지 (또는 `/auth/v1/user` 호출이 더 안전한지)
4. **Vercel Hobby tier 한도** — sharework-api가 Hobby tier에 적합한지 (easy-travel-korea-api에서 검증된 결정 재확인)
5. **Next.js 16 + dio + supabase_flutter 호환성** — 일부 알려진 호환성 이슈

## 다음 단계

1. 사용자가 본 spec 검토
2. 사용자 승인 시 `writing-plans` 스킬 호출 → `docs/superpowers/plans/2026-05-10-m1-auth-job-list.md` 작성
3. plan 리뷰 루프 1~2회
4. plan 승인 + 외부 의존성(#1~#3) 완료 시 SDD 진입

## 참고

- 마스터 플랜: `../../master-plan.md`
- 사이드로드 가이드 (검증 환경): `../../sideload-guide.md`
- 메모리: `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/project_sharework.md`
