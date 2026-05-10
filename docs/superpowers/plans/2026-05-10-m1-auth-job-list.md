# M1 — Mock OTP 인증 + 공고 조회 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sharework UI Demo에서 인증 + 공고 조회 흐름(7개 화면)을 dummy_data → 실 백엔드(Supabase Phone Auth + Next.js 16 BFF)로 교체한다. 나머지 흐름(Giver·채팅·결제·통계 등)은 dummy_data 유지.

**Architecture:** Flutter 앱은 Supabase Phone Auth(Mock OTP)를 SDK로 직접 호출해 JWT를 받고, 데이터 조회는 dio HTTP 클라이언트로 신규 레포 `sharework-api`(Next.js 16 Route Handlers)에 호출한다. BFF는 Supabase JWKS 엔드포인트로 JWT를 검증한 뒤 service role로 Supabase Postgres를 조회해 envelope 응답을 반환한다.

**Tech Stack:**
- BFF: Next.js 16 (App Router) + TypeScript + zod + jose + @supabase/supabase-js, Vitest, Vercel Hobby tier
- Mobile: Flutter 3.27 + supabase_flutter 2.12.4 + dio 5.9.2 + freezed + json_serializable + go_router 14.2
- Data: Supabase Postgres (RLS) + Phone Auth (Test phone numbers Mock 모드)

**선행 문서**:
- spec: `../specs/2026-05-10-m1-auth-job-list-design.md`
- master-plan: `../../master-plan.md`
- 메모리: `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/project_sharework.md`

---

## R5 결정 lock-in (공식 docs 직접 확인 후)

| # | 결정 | 값 | 근거 (docs URL · 확인일) |
|---|------|---|------------------------|
| R5-1 | Phone Auth Mock 모드 활성화 | Supabase 호스트 dashboard `Authentication > Sign In/Up > Phone provider`의 **Test phone numbers** 등록 — phone ↔ 고정 6자리 OTP 매핑, SMS 미발송 | 사용자 dashboard 직접 확인 결정 (2026-05-10), Supabase Auth GitHub Discussion #5358 / #1252 / #1293 검토 |
| R5-2 | Phone Auth 가격 | Free tier에 **Phone login 자체는 포함**. Twilio/MessageBird SMS 비용은 공급자에게 직접 청구. (Supabase MFA-as-2nd-factor의 $75/월은 무관). Mock 모드 동안 SMS 비용 0원 | https://supabase.com/pricing (확인 2026-05-10) |
| R5-3 | JWT 검증 패턴 | Supabase **JWKS endpoint(`https://{project-id}.supabase.co/auth/v1/.well-known/jwks.json`)** + `jose.createRemoteJWKSet` + `jose.jwtVerify`. **ES256 (P-256 EC) 비대칭 키** — JWKS 응답 실측 확인 (alg=ES256, crv=P-256, kty=EC, use=sig). jose `jwtVerify`가 JWKS 키 알고리즘 자동 선택하므로 `algorithms` 옵션 명시 불요. JWT secret 노출 불필요. anon/service_role 키(HS256)와 user JWT(ES256) 서명 키 분리. | https://supabase.com/docs/guides/auth/jwts (확인 2026-05-10), JWKS endpoint 실측 (확인 2026-05-10) |
| R5-4 | Vercel Hobby 한도 | Functions: 10s default / 60s max (pre-Apr 23 2025) · Concurrent Builds 1 · Build 45min · 1M invocations · 100GB Fast Data · 100 deploys/day · 32 builds/hour. **Hobby tier는 Git 조직 레포 연결 불가 — 개인 GitHub 계정만 허용** | https://vercel.com/docs/limits last_updated 2026-03-02 (확인 2026-05-10) |
| R5-5 | 의존성 버전 | supabase_flutter **2.12.4** (publish 2026-04-16), dio **5.9.2** (verified publisher), Flutter SDK >=3.27 (현재 pubspec과 일치), Next.js 16 (easy-travel-korea-api 검증된 스택) | https://pub.dev/packages/supabase_flutter, https://pub.dev/packages/dio (확인 2026-05-10) |

---

## 사용자 결정 lock-in (2026-05-10)

| # | 결정 | 값 | 영향 |
|---|------|---|------|
| Q1 | Mock 모드 전략 | **E 단독** (Supabase 호스트 dashboard Test phone numbers) — Task 0 분기 없음 | Task 0/Task 9에서 dashboard 설정만, BFF mock-otp endpoint 미생성 |
| Q2 | worker_home applied/hired pill | **M1 0/0 하드코딩** (applications 테이블 M2) | Task 19에서 pill 카운트 0으로 고정 + UI 코멘트 `// M1: applications API 미존재, M2 연결` |
| Q3 | sharework-api 레포 위치 | **개인 GitHub** (Vercel Hobby tier 무료) | Task 1에서 사용자 개인 계정에 sharework-api 신규 레포 생성, 정식 베타 시 Pro+조직 이전 |

---

## 외부 의존성 (사용자 작업) — Task 0 단계

| # | 작업 | 상세 | 소요 |
|---|------|------|------|
| 0.1 | Supabase 회원가입 + 신규 프로젝트 | Region: ap-northeast-2 (Seoul) 선택. 프로젝트명: `sharework-prod` (M1엔 prod 단일 환경, 추후 dev 분리는 M2+) | 5분 |
| 0.2 | Supabase 키 3개 메모 | 대시보드 `Settings > API`에서 (a) Project URL (b) anon (public) key (c) service_role (secret) key 메모 | 1분 |
| 0.3 | Supabase Phone provider 활성화 | `Authentication > Sign In/Up > Phone` 토글 ON. SMS provider는 일단 Twilio 선택 후 fake credentials 입력 (실 발송 안 됨) 또는 Mock 모드 dashboard 옵션 활용 | 2분 |
| 0.4 | Supabase Test phone numbers 등록 | `Authentication > Sign In/Up > Phone > Test phone numbers`에서 최소 2개 등록 — 예: `+821012345678 / 123456`, `+821087654321 / 654321` | 2분 |
| 0.5 | sharework-api GitHub 레포 생성 | 개인 계정에 빈 레포(README only). visibility=Private | 5분 |
| 0.6 | Vercel 계정 + GitHub 연동 | personal team (Hobby) 사용. sharework-api 레포 import 준비 | 5분 |

**Task 1 진입 전 0.1~0.5 완료 필수, Task 9 진입 전 0.6 완료 필수.**

---

## File Structure

### sharework-api (신규 레포)

```
sharework-api/
├── package.json              # next 16, typescript, zod, jose, @supabase/supabase-js, vitest
├── tsconfig.json
├── next.config.ts
├── vitest.config.ts
├── .env.example              # SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_ISSUER
├── .env.local                # gitignored
├── src/
│   ├── lib/
│   │   ├── supabase.ts       # service role client 싱글톤
│   │   ├── jwt.ts            # JWKS verify (jose)
│   │   ├── envelope.ts       # success/error response helpers
│   │   └── errors.ts         # ErrorCode enum + AppError class
│   ├── middleware.ts         # JWT 검증 미들웨어 (Next.js middleware)
│   └── app/
│       └── api/
│           ├── me/route.ts
│           ├── jobs/route.ts
│           ├── jobs/[id]/route.ts
│           └── categories/route.ts
├── supabase/
│   ├── migrations/
│   │   ├── 20260510_001_profiles.sql
│   │   ├── 20260510_002_job_categories.sql
│   │   ├── 20260510_003_jobs.sql
│   │   ├── 20260510_004_seed_categories.sql
│   │   └── 20260510_005_profile_trigger.sql
│   └── seed.sql              # 개발용 추가 jobs seed (dummy_data 일부 이전)
├── tests/
│   ├── unit/
│   │   ├── envelope.test.ts
│   │   ├── jwt.test.ts
│   │   └── schemas.test.ts
│   ├── integration/
│   │   ├── me.test.ts
│   │   ├── categories.test.ts
│   │   ├── jobs-list.test.ts
│   │   └── jobs-detail.test.ts
│   └── e2e/
│       └── m1-flow.test.ts
└── README.md
```

### sharework (기존 레포)

```
sharework/
├── pubspec.yaml              # +supabase_flutter, +dio, +freezed_annotation, +json_annotation
├── pubspec.lock
├── lib/
│   ├── main.dart                          # MODIFY: Supabase.initialize
│   ├── data/
│   │   ├── api_client.dart                # NEW
│   │   ├── auth_storage.dart              # NEW
│   │   ├── repositories/                  # NEW
│   │   │   ├── auth_repository.dart
│   │   │   ├── job_repository.dart
│   │   │   └── me_repository.dart
│   │   ├── api_models/                    # NEW (freezed-generated)
│   │   │   ├── profile.dart
│   │   │   ├── profile.freezed.dart
│   │   │   ├── profile.g.dart
│   │   │   ├── job.dart
│   │   │   ├── job.freezed.dart
│   │   │   ├── job.g.dart
│   │   │   ├── job_category.dart
│   │   │   ├── job_category.freezed.dart
│   │   │   └── job_category.g.dart
│   │   └── exceptions.dart                # NEW (ApiException, AuthException)
│   ├── router/
│   │   └── app_router.dart                # MODIFY: redirect 가드
│   └── screens/
│       ├── auth/
│       │   └── phone_auth_screen.dart     # MODIFY: AuthRepository 사용
│       ├── worker/
│       │   ├── home/worker_home_screen.dart   # MODIFY: JobRepository + applied/hired 0/0
│       │   └── mypage/mypage_screen.dart      # MODIFY: MeRepository
│       ├── common/
│       │   ├── job_info_screen.dart       # MODIFY: JobRepository.getJobById
│       │   └── search_screen.dart         # MODIFY: JobRepository.getJobs(q)
│       └── categories/
│           ├── categories_screen.dart     # MODIFY: JobRepository.getCategories
│           └── category_jobs_screen.dart  # MODIFY: JobRepository.getJobs(category)
├── test/
│   ├── widget_test.dart                   # 기존 유지 (회귀)
│   ├── repositories/                      # NEW
│   │   ├── auth_repository_test.dart
│   │   ├── job_repository_test.dart
│   │   └── me_repository_test.dart
│   ├── screens/                           # NEW
│   │   ├── phone_auth_screen_test.dart
│   │   ├── worker_home_screen_test.dart
│   │   ├── mypage_screen_test.dart
│   │   ├── job_info_screen_test.dart
│   │   ├── search_screen_test.dart
│   │   ├── categories_screen_test.dart
│   │   └── category_jobs_screen_test.dart
│   └── integration/
│       └── m1_smoke_test.dart             # NEW
└── ios/
    └── Runner.xcodeproj/project.pbxproj   # 사이드로드용 DEVELOPMENT_TEAM (별도 cleanup, M1 범위 X)
```

---

## Tasks

### Task 0: 외부 의존성 점검 (사용자 작업 + 확인)

**Files:**
- Read: 사용자 메모 (Supabase URL, anon key, service role key, test phone+OTP 2쌍, GitHub 레포 URL)

- [ ] **Step 1: 외부 의존성 0.1~0.5 완료 확인**

사용자에게 확인:
1. Supabase URL (예: `https://abcdefghij.supabase.co`)
2. anon key (eyJ로 시작, 길이 ~200자)
3. service_role key (eyJ로 시작, 길이 ~200자)
4. Test phone 2쌍 (예: `+821012345678 / 123456`)
5. GitHub 레포 URL (예: `https://github.com/{user}/sharework-api`)

받은 값을 임시 노트로 보관(절대 commit 안 함).

- [ ] **Step 2: dashboard Test phone 등록 검증**

사용자가 `Authentication > Sign In/Up > Phone > Test phone numbers`에서 등록 완료했는지 스크린샷 또는 다음 정보 확인:
- 등록된 phone 2개 (E.164 format `+82...`)
- 각 phone의 6자리 OTP

dashboard에 Test phone numbers 기능이 **없거나 다른 위치에 있는 경우** → 즉시 사용자 surface, plan 재검토 (R5-1 fallback C 옵션 발동).

---

### Task 1: sharework-api 레포 부트스트랩

**Files:**
- Create: `sharework-api/package.json`
- Create: `sharework-api/tsconfig.json`
- Create: `sharework-api/next.config.ts`
- Create: `sharework-api/vitest.config.ts`
- Create: `sharework-api/.env.example`
- Create: `sharework-api/.gitignore`
- Create: `sharework-api/README.md`
- Create: `sharework-api/src/app/layout.tsx` (minimal)

- [ ] **Step 1: 레포 clone + Next.js 16 부트스트랩**

```bash
cd /Users/sengmindavidhyun/Documents/David/projects
git clone https://github.com/{user}/sharework-api.git
cd sharework-api
npx create-next-app@16 . --ts --no-tailwind --app --no-src-dir --import-alias "@/*" --no-eslint --use-npm
```

CRA 프롬프트가 뜨면: "Would you like your code inside a `src/` directory?" → Yes.

- [ ] **Step 2: 의존성 추가**

```bash
npm install zod jose @supabase/supabase-js
npm install -D vitest @vitest/coverage-v8 @types/node typescript
```

생성된 `package.json` scripts에 추가:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

- [ ] **Step 3: vitest.config.ts 작성**

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    include: ['tests/**/*.test.ts'],
    coverage: { reporter: ['text', 'html'], reportsDirectory: './coverage' },
    // Bug 1 fix: jwt.ts의 getJWKS()가 module-level env 검사하므로 테스트용 dummy 값 주입
    env: {
      SUPABASE_JWKS_URL: 'https://test-project.supabase.co/auth/v1/.well-known/jwks.json',
      SUPABASE_JWT_ISSUER: 'https://test-project.supabase.co/auth/v1',
      SUPABASE_URL: 'https://test-project.supabase.co',
      SUPABASE_SERVICE_ROLE_KEY: 'test-service-role-dummy',
    },
  },
  resolve: {
    alias: { '@': new URL('./src', import.meta.url).pathname },
  },
});
```

- [ ] **Step 4: .env.example + .gitignore**

`.env.example`:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_JWT_ISSUER=https://your-project-id.supabase.co/auth/v1
SUPABASE_JWKS_URL=https://your-project-id.supabase.co/auth/v1/.well-known/jwks.json
```

`.gitignore`에 다음이 포함되어 있는지 확인 (Next.js가 자동 생성):
```
.env*.local
.env
node_modules
.next
coverage
```

- [ ] **Step 5: 빌드 + 첫 commit**

```bash
npm run build
```

기대: `✓ Compiled successfully`.

```bash
git add package.json package-lock.json tsconfig.json next.config.ts vitest.config.ts .env.example .gitignore src/app/layout.tsx src/app/page.tsx README.md
git commit -m "chore: bootstrap sharework-api with Next.js 16 + zod + jose + vitest"
```

---

### Task 2: Supabase 마이그레이션 — `profiles` 테이블

**Files:**
- Create: `sharework-api/supabase/migrations/20260510_001_profiles.sql`

- [ ] **Step 1: profiles 마이그레이션 작성**

```sql
-- 20260510_001_profiles.sql
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text not null unique,
  name text,
  role text not null default 'worker' check (role in ('worker', 'giver')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_phone_idx on public.profiles(phone);

alter table public.profiles enable row level security;

create policy "profiles_self_read"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_self_write"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

- [ ] **Step 2: dashboard SQL Editor에서 실행**

사용자에게 다음 안내:
1. Supabase dashboard `SQL Editor` 열기
2. 위 SQL 붙여넣기 → Run
3. 결과 `Success. No rows returned` 확인

또는 supabase CLI:
```bash
npx supabase db push
```

(CLI 사용 시 `supabase init` + 프로젝트 link 선행 필요. M1엔 dashboard 직접 실행이 더 단순.)

- [ ] **Step 3: 검증**

dashboard `Database > Tables`에서 `profiles` 테이블 확인. 컬럼 6개 + RLS enabled.

- [ ] **Step 4: commit**

```bash
git add supabase/migrations/20260510_001_profiles.sql
git commit -m "feat(db): add profiles table with RLS"
```

---

### Task 3: Supabase 마이그레이션 — `job_categories` + 시드

**Files:**
- Create: `sharework-api/supabase/migrations/20260510_002_job_categories.sql`
- Create: `sharework-api/supabase/migrations/20260510_004_seed_categories.sql`

- [ ] **Step 1: job_categories 테이블 마이그레이션**

```sql
-- 20260510_002_job_categories.sql
create table if not exists public.job_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.job_categories enable row level security;

create policy "categories_public_read"
  on public.job_categories for select
  to authenticated
  using (true);
```

- [ ] **Step 2: 카테고리 시드 (Flutter `JobCategory` enum 9개와 매핑)**

```sql
-- 20260510_004_seed_categories.sql
insert into public.job_categories (name, slug, sort_order) values
  ('카페', 'cafe', 1),
  ('식당', 'restaurant', 2),
  ('마트', 'mart', 3),
  ('물류', 'logistics', 4),
  ('배달', 'delivery', 5),
  ('행사', 'event', 6),
  ('청소', 'cleaning', 7),
  ('사무보조', 'office', 8),
  ('기타', 'etc', 99)
on conflict (slug) do nothing;
```

- [ ] **Step 3: dashboard에서 실행 + 검증**

`SQL Editor`에서 두 마이그레이션 순차 실행. 검증:
```sql
select count(*) from public.job_categories;
-- 9
```

- [ ] **Step 4: commit**

```bash
git add supabase/migrations/20260510_002_job_categories.sql supabase/migrations/20260510_004_seed_categories.sql
git commit -m "feat(db): add job_categories table + 9 seed rows"
```

---

### Task 4: Supabase 마이그레이션 — `jobs` 테이블

**Files:**
- Create: `sharework-api/supabase/migrations/20260510_003_jobs.sql`

- [ ] **Step 1: jobs 마이그레이션**

```sql
-- 20260510_003_jobs.sql
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  giver_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (length(title) <= 100),
  description text not null check (length(description) <= 2000),
  wage_won int not null check (wage_won >= 0),
  schedule_text text,
  status text not null default 'active' check (status in ('active', 'paused', 'closed')),
  category_id uuid not null references public.job_categories(id),
  location_address text not null,
  location_lat numeric(9,6),
  location_lng numeric(9,6),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists jobs_status_created_idx on public.jobs(status, created_at desc);
create index if not exists jobs_category_status_idx on public.jobs(category_id, status);

alter table public.jobs enable row level security;

create policy "jobs_active_read"
  on public.jobs for select
  to authenticated
  using (status = 'active');

create policy "jobs_giver_owner_full"
  on public.jobs for all
  to authenticated
  using (giver_id = auth.uid())
  with check (giver_id = auth.uid());
```

- [ ] **Step 2: dashboard 실행 + 검증**

```sql
select count(*) from public.jobs;
-- 0
```

- [ ] **Step 3: commit**

```bash
git add supabase/migrations/20260510_003_jobs.sql
git commit -m "feat(db): add jobs table with RLS for active read + giver-owner write"
```

---

### Task 5: Supabase 마이그레이션 — profile auto-create trigger

**Files:**
- Create: `sharework-api/supabase/migrations/20260510_005_profile_trigger.sql`

- [ ] **Step 1: trigger 마이그레이션**

```sql
-- 20260510_005_profile_trigger.sql
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, phone, name, role)
  values (
    new.id,
    coalesce(new.phone, ''),
    coalesce(right(new.phone, 4), 'user'),
    'worker'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

- [ ] **Step 2: dashboard 실행**

`SQL Editor` 실행 후 검증:
```sql
select tgname from pg_trigger where tgname = 'on_auth_user_created';
-- 1 row
```

- [ ] **Step 3: commit**

(dev seed jobs INSERT는 Task 14 Step 1.5로 이동 — auth.users에 첫 사용자 row가 생긴 후 실행해야 FK 충돌 없음.)

```bash
git add supabase/migrations/20260510_005_profile_trigger.sql
git commit -m "feat(db): auto-create profile on auth.users insert"
```

---

### Task 6: BFF — envelope helpers (TDD)

**Files:**
- Create: `sharework-api/src/lib/errors.ts`
- Create: `sharework-api/src/lib/envelope.ts`
- Test: `sharework-api/tests/unit/envelope.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
// tests/unit/envelope.test.ts
import { describe, it, expect } from 'vitest';
import { ok, fail, ErrorCode } from '@/lib/envelope';

describe('envelope', () => {
  it('ok wraps payload as { data }', async () => {
    const res = ok({ id: '1', name: 'A' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toEqual({ data: { id: '1', name: 'A' } });
  });

  it('ok includes page meta when provided', async () => {
    const res = ok([{ id: '1' }], { page: { total: 5, page: 1, limit: 20 } });
    const body = await res.json();
    expect(body).toEqual({ data: [{ id: '1' }], page: { total: 5, page: 1, limit: 20 } });
  });

  it('fail returns { error: { code, message } } with right HTTP status', async () => {
    const res = fail(ErrorCode.NOT_FOUND, 'job not found');
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body).toEqual({ error: { code: 'NOT_FOUND', message: 'job not found' } });
  });

  it('fail maps each error code to its HTTP status', async () => {
    expect((await fail(ErrorCode.UNAUTHORIZED, 'x')).status).toBe(401);
    expect((await fail(ErrorCode.VALIDATION_ERROR, 'x')).status).toBe(400);
    expect((await fail(ErrorCode.INTERNAL, 'x')).status).toBe(500);
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
cd sharework-api && npm test -- tests/unit/envelope.test.ts
```

기대: `Cannot find module '@/lib/envelope'` 또는 비슷한 import 에러.

- [ ] **Step 3: 최소 구현**

```ts
// src/lib/errors.ts
export enum ErrorCode {
  UNAUTHORIZED = 'UNAUTHORIZED',
  NOT_FOUND = 'NOT_FOUND',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INTERNAL = 'INTERNAL',
}

export const ERROR_HTTP_STATUS: Record<ErrorCode, number> = {
  [ErrorCode.UNAUTHORIZED]: 401,
  [ErrorCode.NOT_FOUND]: 404,
  [ErrorCode.VALIDATION_ERROR]: 400,
  [ErrorCode.INTERNAL]: 500,
};

export class AppError extends Error {
  constructor(public code: ErrorCode, message: string) {
    super(message);
    this.name = 'AppError';
  }
}
```

```ts
// src/lib/envelope.ts
import { NextResponse } from 'next/server';
import { ErrorCode, ERROR_HTTP_STATUS } from './errors';

export { ErrorCode };

export type PageMeta = { total: number; page: number; limit: number };

export function ok<T>(data: T, opts?: { page?: PageMeta }): NextResponse {
  const body = opts?.page ? { data, page: opts.page } : { data };
  return NextResponse.json(body, { status: 200 });
}

export function fail(code: ErrorCode, message: string): NextResponse {
  return NextResponse.json(
    { error: { code, message } },
    { status: ERROR_HTTP_STATUS[code] }
  );
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/unit/envelope.test.ts
```

기대: `4 passed`.

- [ ] **Step 5: commit**

```bash
git add src/lib/errors.ts src/lib/envelope.ts tests/unit/envelope.test.ts
git commit -m "feat(bff): add envelope ok/fail helpers + ErrorCode enum"
```

---

### Task 7: BFF — JWT 검증 (jose + JWKS) (TDD)

**Files:**
- Create: `sharework-api/src/lib/jwt.ts`
- Test: `sharework-api/tests/unit/jwt.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
// tests/unit/jwt.test.ts
import { describe, it, expect, vi } from 'vitest';
import { verifyAccessToken } from '@/lib/jwt';

vi.mock('jose', () => ({
  createRemoteJWKSet: vi.fn(() => 'fake-jwks-fn'),
  jwtVerify: vi.fn(async (token: string) => {
    if (token === 'valid-jwt') {
      return { payload: { sub: 'user-123', aud: 'authenticated', iss: 'https://x.supabase.co/auth/v1' } };
    }
    throw new Error('JWTExpired or invalid signature');
  }),
}));

describe('verifyAccessToken', () => {
  it('returns userId from valid JWT', async () => {
    const result = await verifyAccessToken('valid-jwt');
    expect(result.userId).toBe('user-123');
  });

  it('throws AppError(UNAUTHORIZED) on invalid JWT', async () => {
    await expect(verifyAccessToken('invalid')).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
  });

  it('throws AppError(UNAUTHORIZED) on missing JWT', async () => {
    await expect(verifyAccessToken('')).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
npm test -- tests/unit/jwt.test.ts
```

기대: `Cannot find module '@/lib/jwt'`.

- [ ] **Step 3: 최소 구현**

```ts
// src/lib/jwt.ts
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AppError, ErrorCode } from './errors';

const JWKS_URL = process.env.SUPABASE_JWKS_URL ?? '';
const ISSUER = process.env.SUPABASE_JWT_ISSUER ?? '';

let cachedJWKS: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJWKS() {
  if (!cachedJWKS) {
    if (!JWKS_URL) {
      throw new AppError(ErrorCode.INTERNAL, 'SUPABASE_JWKS_URL not configured');
    }
    cachedJWKS = createRemoteJWKSet(new URL(JWKS_URL));
  }
  return cachedJWKS;
}

export async function verifyAccessToken(token: string): Promise<{ userId: string }> {
  if (!token) {
    throw new AppError(ErrorCode.UNAUTHORIZED, 'missing access token');
  }
  try {
    const { payload } = await jwtVerify(token, getJWKS(), {
      issuer: ISSUER || undefined,
      audience: 'authenticated',
    });
    if (typeof payload.sub !== 'string') {
      throw new AppError(ErrorCode.UNAUTHORIZED, 'jwt has no sub');
    }
    return { userId: payload.sub };
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError(ErrorCode.UNAUTHORIZED, 'invalid or expired token');
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/unit/jwt.test.ts
```

기대: `3 passed`.

- [ ] **Step 5: commit**

```bash
git add src/lib/jwt.ts tests/unit/jwt.test.ts
git commit -m "feat(bff): JWT verification via Supabase JWKS endpoint"
```

---

### Task 8: BFF — Supabase service role 클라이언트

**Files:**
- Create: `sharework-api/src/lib/supabase.ts`

- [ ] **Step 1: 구현**

```ts
// src/lib/supabase.ts
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let cached: SupabaseClient | null = null;

export function getServiceRoleClient(): SupabaseClient {
  if (!cached) {
    const url = process.env.SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) {
      throw new Error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing');
    }
    cached = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return cached;
}
```

- [ ] **Step 2: 빌드 확인**

```bash
npm run build
```

기대: PASS (사용처 없어서 컴파일만).

- [ ] **Step 3: commit**

```bash
git add src/lib/supabase.ts
git commit -m "feat(bff): service role Supabase client singleton"
```

---

### Task 9: BFF — `/api/me` endpoint (TDD)

**Files:**
- Create: `sharework-api/src/app/api/me/route.ts`
- Test: `sharework-api/tests/integration/me.test.ts`

- [ ] **Step 1: 통합 테스트 작성**

```ts
// tests/integration/me.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { GET } from '@/app/api/me/route';

vi.mock('@/lib/jwt', () => ({
  verifyAccessToken: vi.fn(async (token: string) => {
    if (token === 'valid') return { userId: 'user-123' };
    throw new (await import('@/lib/errors')).AppError(
      (await import('@/lib/errors')).ErrorCode.UNAUTHORIZED, 'invalid'
    );
  }),
}));

vi.mock('@/lib/supabase', () => ({
  getServiceRoleClient: vi.fn(() => ({
    from: vi.fn((table: string) => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          maybeSingle: vi.fn(async () => {
            if (table === 'profiles') {
              return {
                data: {
                  id: 'user-123',
                  phone: '+821012345678',
                  name: '5678',
                  role: 'worker',
                  created_at: '2026-05-10T00:00:00Z',
                },
                error: null,
              };
            }
            return { data: null, error: null };
          }),
        })),
      })),
    })),
  })),
}));

function makeReq(authHeader?: string) {
  const headers = new Headers();
  if (authHeader) headers.set('authorization', authHeader);
  return new Request('http://localhost/api/me', { headers });
}

describe('GET /api/me', () => {
  it('returns profile for valid JWT', async () => {
    const res = await GET(makeReq('Bearer valid'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data).toMatchObject({
      id: 'user-123',
      phone: '+821012345678',
      name: '5678',
      role: 'worker',
    });
  });

  it('returns 401 for missing JWT', async () => {
    const res = await GET(makeReq());
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error.code).toBe('UNAUTHORIZED');
  });

  it('returns 401 for invalid JWT', async () => {
    const res = await GET(makeReq('Bearer bogus'));
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
npm test -- tests/integration/me.test.ts
```

기대: `Cannot find module '@/app/api/me/route'`.

- [ ] **Step 3: 구현**

```ts
// src/app/api/me/route.ts
import { NextRequest } from 'next/server';
import { ok, fail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';

export async function GET(req: Request) {
  try {
    const auth = req.headers.get('authorization') ?? '';
    const token = auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
    const { userId } = await verifyAccessToken(token);

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('id, phone, name, role, created_at')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      return fail(ErrorCode.INTERNAL, error.message);
    }
    if (!data) {
      return fail(ErrorCode.NOT_FOUND, 'profile not found');
    }
    return ok(data);
  } catch (err) {
    if (err instanceof AppError) {
      return fail(err.code, err.message);
    }
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/integration/me.test.ts
```

기대: `3 passed`.

- [ ] **Step 5: commit**

```bash
git add src/app/api/me/route.ts tests/integration/me.test.ts
git commit -m "feat(bff): GET /api/me with JWT-verified profile lookup"
```

---

### Task 10: BFF — `/api/categories` endpoint (TDD)

**Files:**
- Create: `sharework-api/src/app/api/categories/route.ts`
- Test: `sharework-api/tests/integration/categories.test.ts`

- [ ] **Step 1: 테스트 작성**

```ts
// tests/integration/categories.test.ts
import { describe, it, expect, vi } from 'vitest';
import { GET } from '@/app/api/categories/route';

vi.mock('@/lib/jwt', () => ({
  verifyAccessToken: vi.fn(async (t: string) => {
    if (t === 'valid') return { userId: 'u1' };
    throw new (await import('@/lib/errors')).AppError(
      (await import('@/lib/errors')).ErrorCode.UNAUTHORIZED, 'x'
    );
  }),
}));

vi.mock('@/lib/supabase', () => ({
  getServiceRoleClient: vi.fn(() => ({
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        order: vi.fn(async () => ({
          data: [
            { id: 'c1', name: '카페', slug: 'cafe', sort_order: 1 },
            { id: 'c2', name: '식당', slug: 'restaurant', sort_order: 2 },
          ],
          error: null,
        })),
      })),
    })),
  })),
}));

function makeReq(token = 'valid') {
  return new Request('http://localhost/api/categories', {
    headers: { authorization: `Bearer ${token}` },
  });
}

describe('GET /api/categories', () => {
  it('returns category list with Cache-Control 1h', async () => {
    const res = await GET(makeReq());
    expect(res.status).toBe(200);
    expect(res.headers.get('Cache-Control')).toBe('public, max-age=3600');
    const body = await res.json();
    expect(body.data).toHaveLength(2);
    expect(body.data[0]).toMatchObject({ slug: 'cafe' });
  });

  it('returns 401 on missing JWT', async () => {
    const res = await GET(new Request('http://localhost/api/categories'));
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
npm test -- tests/integration/categories.test.ts
```

기대: `Cannot find module '@/app/api/categories/route'`.

- [ ] **Step 3: 구현**

```ts
// src/app/api/categories/route.ts
import { NextResponse } from 'next/server';
import { ok, fail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';

export async function GET(req: Request): Promise<NextResponse> {
  try {
    const auth = req.headers.get('authorization') ?? '';
    const token = auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
    await verifyAccessToken(token);

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from('job_categories')
      .select('id, name, slug, sort_order')
      .order('sort_order', { ascending: true });

    if (error) return fail(ErrorCode.INTERNAL, error.message);

    const res = ok(data ?? []);
    res.headers.set('Cache-Control', 'public, max-age=3600');
    return res;
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/integration/categories.test.ts
```

기대: `2 passed`.

- [ ] **Step 5: commit**

```bash
git add src/app/api/categories/route.ts tests/integration/categories.test.ts
git commit -m "feat(bff): GET /api/categories with 1h public cache"
```

---

### Task 11: BFF — zod 쿼리 스키마 (TDD)

**Files:**
- Create: `sharework-api/src/lib/schemas.ts`
- Test: `sharework-api/tests/unit/schemas.test.ts`

- [ ] **Step 1: 테스트 작성**

```ts
// tests/unit/schemas.test.ts
import { describe, it, expect } from 'vitest';
import { jobsQuerySchema } from '@/lib/schemas';

describe('jobsQuerySchema', () => {
  it('parses default page=1, limit=20', () => {
    const r = jobsQuerySchema.parse({});
    expect(r).toEqual({ page: 1, limit: 20 });
  });

  it('coerces string numbers', () => {
    const r = jobsQuerySchema.parse({ page: '3', limit: '10' });
    expect(r).toEqual({ page: 3, limit: 10 });
  });

  it('rejects limit > 50', () => {
    expect(() => jobsQuerySchema.parse({ limit: '100' })).toThrow();
  });

  it('rejects page < 1', () => {
    expect(() => jobsQuerySchema.parse({ page: '0' })).toThrow();
  });

  it('accepts category and q', () => {
    const r = jobsQuerySchema.parse({ category: 'cafe', q: '강남' });
    expect(r.category).toBe('cafe');
    expect(r.q).toBe('강남');
  });

  it('rejects q longer than 100', () => {
    expect(() => jobsQuerySchema.parse({ q: 'a'.repeat(101) })).toThrow();
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
npm test -- tests/unit/schemas.test.ts
```

- [ ] **Step 3: 구현**

```ts
// src/lib/schemas.ts
import { z } from 'zod';

export const jobsQuerySchema = z.object({
  category: z.string().min(1).max(50).optional(),
  q: z.string().max(100).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export type JobsQuery = z.infer<typeof jobsQuerySchema>;

export const jobIdParamSchema = z.object({
  id: z.string().uuid(),
});
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/unit/schemas.test.ts
```

기대: `6 passed`.

- [ ] **Step 5: commit**

```bash
git add src/lib/schemas.ts tests/unit/schemas.test.ts
git commit -m "feat(bff): zod schemas for jobs query + jobs/:id param"
```

---

### Task 12: BFF — `/api/jobs` 목록·검색·필터·페이지네이션 (TDD)

**Files:**
- Create: `sharework-api/src/app/api/jobs/route.ts`
- Test: `sharework-api/tests/integration/jobs-list.test.ts`

- [ ] **Step 1: 테스트 작성**

```ts
// tests/integration/jobs-list.test.ts
import { describe, it, expect, vi } from 'vitest';
import { GET } from '@/app/api/jobs/route';

const mockJobs = [
  { id: 'j1', title: '카페 알바', wage_won: 12000, category_id: 'c1' },
  { id: 'j2', title: '마트 알바', wage_won: 11000, category_id: 'c2' },
];

vi.mock('@/lib/jwt', () => ({
  verifyAccessToken: vi.fn(async (t: string) => {
    if (t === 'valid') return { userId: 'u1' };
    throw new (await import('@/lib/errors')).AppError(
      (await import('@/lib/errors')).ErrorCode.UNAUTHORIZED, 'x'
    );
  }),
}));

const builderState = { lastQuery: { category: null as string | null, q: null as string | null, page: 1, limit: 20 } };

vi.mock('@/lib/supabase', () => {
  function makeBuilder() {
    const builder: any = {};
    builder.select = vi.fn(() => builder);
    builder.eq = vi.fn((col: string, val: string) => {
      if (col === 'category_id') builderState.lastQuery.category = val;
      if (col === 'status') {/* expected 'active' */}
      return builder;
    });
    builder.ilike = vi.fn((_col: string, val: string) => {
      builderState.lastQuery.q = val;
      return builder;
    });
    builder.order = vi.fn(() => builder);
    builder.range = vi.fn(async (from: number, to: number) => {
      builderState.lastQuery.page = Math.floor(from / 20) + 1;
      builderState.lastQuery.limit = to - from + 1;
      return { data: mockJobs, error: null, count: 2 };
    });
    return builder;
  }
  return {
    getServiceRoleClient: vi.fn(() => ({
      from: vi.fn(() => makeBuilder()),
    })),
  };
});

function makeReq(qs = '', token = 'valid') {
  return new Request(`http://localhost/api/jobs?${qs}`, {
    headers: { authorization: `Bearer ${token}` },
  });
}

describe('GET /api/jobs', () => {
  it('returns paginated jobs with default page=1, limit=20', async () => {
    const res = await GET(makeReq());
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data).toHaveLength(2);
    expect(body.page).toEqual({ total: 2, page: 1, limit: 20 });
  });

  it('passes category filter to db query', async () => {
    builderState.lastQuery.category = null;
    await GET(makeReq('category=cafe-uuid'));
    expect(builderState.lastQuery.category).toBe('cafe-uuid');
  });

  it('passes q filter as ilike with %wrap%', async () => {
    builderState.lastQuery.q = null;
    await GET(makeReq('q=강남'));
    expect(builderState.lastQuery.q).toBe('%강남%');
  });

  it('returns 400 on limit > 50', async () => {
    const res = await GET(makeReq('limit=100'));
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 401 on missing JWT', async () => {
    const res = await GET(new Request('http://localhost/api/jobs'));
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
npm test -- tests/integration/jobs-list.test.ts
```

- [ ] **Step 3: 구현**

```ts
// src/app/api/jobs/route.ts
import { ok, fail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobsQuerySchema } from '@/lib/schemas';
import { z } from 'zod';

export async function GET(req: Request) {
  try {
    const auth = req.headers.get('authorization') ?? '';
    const token = auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
    await verifyAccessToken(token);

    const url = new URL(req.url);
    const queryRaw = Object.fromEntries(url.searchParams.entries());

    let query;
    try {
      query = jobsQuerySchema.parse(queryRaw);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return fail(ErrorCode.VALIDATION_ERROR, err.issues.map(i => i.message).join('; '));
      }
      throw err;
    }

    const { page, limit, category, q } = query;
    const supabase = getServiceRoleClient();

    let builder = supabase
      .from('jobs')
      .select(
        'id, giver_id, title, description, wage_won, schedule_text, status, category_id, location_address, location_lat, location_lng, created_at, updated_at',
        { count: 'exact' }
      )
      .eq('status', 'active');

    if (category) builder = builder.eq('category_id', category);
    if (q) builder = builder.ilike('title', `%${q}%`);

    builder = builder.order('created_at', { ascending: false });

    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const { data, error, count } = await builder.range(from, to);

    if (error) return fail(ErrorCode.INTERNAL, error.message);

    return ok(data ?? [], { page: { total: count ?? 0, page, limit } });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

```bash
npm test -- tests/integration/jobs-list.test.ts
```

기대: `5 passed`.

- [ ] **Step 5: commit**

```bash
git add src/app/api/jobs/route.ts tests/integration/jobs-list.test.ts
git commit -m "feat(bff): GET /api/jobs with category/q filter + pagination"
```

---

### Task 13: BFF — `/api/jobs/:id` (TDD)

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/route.ts`
- Test: `sharework-api/tests/integration/jobs-detail.test.ts`

- [ ] **Step 1: 테스트 작성**

```ts
// tests/integration/jobs-detail.test.ts
import { describe, it, expect, vi } from 'vitest';
import { GET } from '@/app/api/jobs/[id]/route';

vi.mock('@/lib/jwt', () => ({
  verifyAccessToken: vi.fn(async (t: string) => {
    if (t === 'valid') return { userId: 'u1' };
    throw new (await import('@/lib/errors')).AppError(
      (await import('@/lib/errors')).ErrorCode.UNAUTHORIZED, 'x'
    );
  }),
}));

const fixtures = {
  '11111111-1111-1111-1111-111111111111': {
    id: '11111111-1111-1111-1111-111111111111',
    title: '카페 알바',
    description: 'desc',
    wage_won: 12000,
    status: 'active',
  },
};

vi.mock('@/lib/supabase', () => ({
  getServiceRoleClient: vi.fn(() => ({
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          eq: vi.fn(() => ({
            maybeSingle: vi.fn(async () => {
              const id = '11111111-1111-1111-1111-111111111111';
              return { data: fixtures[id], error: null };
            }),
          })),
        })),
      })),
    })),
  })),
}));

function makeReq(token = 'valid') {
  return new Request('http://localhost/api/jobs/x', {
    headers: { authorization: `Bearer ${token}` },
  });
}

describe('GET /api/jobs/:id', () => {
  it('returns job for valid uuid', async () => {
    const res = await GET(
      makeReq(),
      { params: Promise.resolve({ id: '11111111-1111-1111-1111-111111111111' }) }
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.title).toBe('카페 알바');
  });

  it('returns 400 on non-uuid id', async () => {
    const res = await GET(makeReq(), { params: Promise.resolve({ id: 'not-uuid' }) });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 401 on missing JWT', async () => {
    const res = await GET(
      new Request('http://localhost/api/jobs/x'),
      { params: Promise.resolve({ id: '11111111-1111-1111-1111-111111111111' }) }
    );
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: 구현**

```ts
// src/app/api/jobs/[id]/route.ts
import { ok, fail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobIdParamSchema } from '@/lib/schemas';
import { z } from 'zod';

export async function GET(
  req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  try {
    const auth = req.headers.get('authorization') ?? '';
    const token = auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
    await verifyAccessToken(token);

    const rawParams = await ctx.params;
    let parsed;
    try {
      parsed = jobIdParamSchema.parse(rawParams);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return fail(ErrorCode.VALIDATION_ERROR, 'invalid job id');
      }
      throw err;
    }

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from('jobs')
      .select(
        'id, giver_id, title, description, wage_won, schedule_text, status, category_id, location_address, location_lat, location_lng, created_at, updated_at'
      )
      .eq('id', parsed.id)
      .eq('status', 'active')
      .maybeSingle();

    if (error) return fail(ErrorCode.INTERNAL, error.message);
    if (!data) return fail(ErrorCode.NOT_FOUND, 'job not found');

    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 4: 테스트 → PASS** (`3 passed`)

- [ ] **Step 5: commit**

```bash
git add src/app/api/jobs/[id]/route.ts tests/integration/jobs-detail.test.ts
git commit -m "feat(bff): GET /api/jobs/:id with uuid validation"
```

---

### Task 14: BFF — E2E 1건 + Vercel 배포

**Files:**
- Create: `sharework-api/tests/e2e/m1-flow.test.ts`
- Modify: `sharework-api/README.md`

- [ ] **Step 1: E2E 테스트 작성 (실 Supabase + 실 Vercel preview 대상)**

```ts
// tests/e2e/m1-flow.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.E2E_SUPABASE_URL ?? '';
const ANON_KEY = process.env.E2E_SUPABASE_ANON_KEY ?? '';
const BFF_BASE = process.env.E2E_BFF_BASE ?? 'http://localhost:3000';
const TEST_PHONE = process.env.E2E_TEST_PHONE ?? '+821012345678';
const TEST_OTP = process.env.E2E_TEST_OTP ?? '123456';

const skip = !SUPABASE_URL || !ANON_KEY;

describe.skipIf(skip)('M1 e2e flow', () => {
  let token = '';

  beforeAll(async () => {
    const supabase = createClient(SUPABASE_URL, ANON_KEY);
    await supabase.auth.signInWithOtp({ phone: TEST_PHONE });
    const { data, error } = await supabase.auth.verifyOtp({
      phone: TEST_PHONE,
      token: TEST_OTP,
      type: 'sms',
    });
    if (error) throw error;
    token = data.session?.access_token ?? '';
    expect(token).not.toBe('');
  }, 30_000);

  it('GET /api/me returns profile', async () => {
    const res = await fetch(`${BFF_BASE}/api/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.phone).toBe(TEST_PHONE);
  });

  it('GET /api/categories returns 9 categories', async () => {
    const res = await fetch(`${BFF_BASE}/api/categories`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.length).toBeGreaterThanOrEqual(9);
  });

  it('GET /api/jobs returns paginated active jobs', async () => {
    const res = await fetch(`${BFF_BASE}/api/jobs?limit=5`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.page.limit).toBe(5);
    expect(Array.isArray(body.data)).toBe(true);
  });
});
```

- [ ] **Step 1.5: 첫 사용자 인증 + dev seed jobs 1개 (Bug 3 fix)**

```bash
cd sharework-api
cp .env.example .env.local
# .env.local에 실제 값 넣기
npm run dev &
sleep 3
```

별도 terminal에서 첫 사용자 인증 (Flutter 앱 또는 supabase-js 직접):

```bash
# supabase-js로 1회 인증 (auth.users에 row 생성용)
node -e "
const { createClient } = require('@supabase/supabase-js');
const s = createClient('$SUPABASE_URL', '$ANON_KEY');
(async () => {
  await s.auth.signInWithOtp({ phone: '+821012345678' });
  const { data, error } = await s.auth.verifyOtp({
    phone: '+821012345678', token: '123456', type: 'sms'
  });
  console.log('user:', data.user?.id, 'error:', error?.message);
})();
"
```

dashboard `Authentication > Users`에서 첫 사용자 row 확인.

dashboard `SQL Editor`에서 dev seed jobs 1개 (runnable, 사용자 UUID 자동 lookup):

```sql
-- Bug 3 fix: 'YOUR-USER-UUID' placeholder 제거, runnable SQL
insert into public.jobs (giver_id, title, description, wage_won, schedule_text, category_id, location_address)
values (
  (select id from auth.users order by created_at desc limit 1),
  '카페 주말 알바',
  '강남역 카페에서 주말 오전~오후 일하실 분 모집합니다.',
  12000,
  '매주 토/일 09:00~18:00',
  (select id from public.job_categories where slug = 'cafe'),
  '서울시 강남구 테헤란로 152'
);
```

검증:
```sql
select count(*) from public.jobs where status = 'active';
-- 1
```

- [ ] **Step 2: 로컬에서 e2e 1회 실행**

```bash
E2E_SUPABASE_URL=$SUPABASE_URL E2E_SUPABASE_ANON_KEY=$ANON_KEY \
  E2E_TEST_PHONE='+821012345678' E2E_TEST_OTP='123456' \
  npm test -- tests/e2e/m1-flow.test.ts
```

기대: `3 passed`. 실패 시: trigger 미동작(Task 5) 또는 jobs row 0개(Step 1.5 누락) — diagnose 후 fix.

- [ ] **Step 3: Vercel 배포 (사용자 직접 실행 — interactive)**

⚠️ 이 step의 모든 `vercel` CLI 호출은 **사용자 직접 실행** 필요. 비대화형 subagent 환경에서는 hang됨. 대안: dashboard에서 GitHub 레포 import + env 등록 + auto-deploy 사용.

CLI 흐름 (사용자):
```bash
cd sharework-api
npx vercel link
# 프롬프트: personal team(account) 선택 → 신규 project 'sharework-api' 생성

# Production env 등록 (각 명령마다 값 prompt)
npx vercel env add SUPABASE_URL production
npx vercel env add SUPABASE_SERVICE_ROLE_KEY production
npx vercel env add SUPABASE_JWKS_URL production
npx vercel env add SUPABASE_JWT_ISSUER production

# 배포
npx vercel --prod
```

dashboard 흐름 (대안):
1. https://vercel.com/new 에서 sharework-api 레포 import (personal account)
2. `Settings > Environment Variables`에서 4개 env 등록
3. `Deployments > Redeploy` 또는 새 commit push로 자동 배포

기대: production URL 출력 (예: `https://sharework-api-xxx.vercel.app`).

- [ ] **Step 4: production 검증**

```bash
PROD_URL=https://sharework-api-xxx.vercel.app
# 인증 토큰 1개 (로컬 e2e와 동일 흐름으로) 후
curl -i "$PROD_URL/api/me" -H "Authorization: Bearer $TOKEN"
```

기대: HTTP/200 + `{"data": {...profile...}}`. 401이면 env 누락 의심.

- [ ] **Step 5: README 업데이트 + commit**

`sharework-api/README.md`에 다음 추가:

```markdown
# sharework-api

BFF for Sharework Flutter app — Supabase JWT verify + jobs/categories/me endpoints.

## Setup
1. `cp .env.example .env.local` and fill values from Supabase dashboard
2. `npm install`
3. `npm test` — runs unit + integration tests (mocked)
4. `npm run dev` — http://localhost:3000

## Deploy
- Vercel Hobby (personal account only)
- Required env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWKS_URL, SUPABASE_JWT_ISSUER

## E2E
Set E2E_SUPABASE_URL/E2E_SUPABASE_ANON_KEY/E2E_TEST_PHONE/E2E_TEST_OTP and run `npm test -- tests/e2e/`.
```

```bash
git add tests/e2e/m1-flow.test.ts README.md
git commit -m "feat(bff): M1 e2e test + Vercel deployment doc"
git push origin main
```

---

### Task 15: Flutter — 의존성 추가 + Supabase 초기화

**Files:**
- Modify: `sharework/pubspec.yaml`
- Modify: `sharework/lib/main.dart`
- Create: `sharework/lib/data/supabase_config.dart`

- [ ] **Step 1: pubspec.yaml 업데이트**

`dependencies:` 섹션에 추가 (기존 4개 뒤):

```yaml
  supabase_flutter: ^2.12.4
  dio: ^5.9.2
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
```

`dev_dependencies:`에 추가:

```yaml
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
```

- [ ] **Step 2: 의존성 설치**

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter pub get
```

기대: `Got dependencies!`.

- [ ] **Step 3: SupabaseConfig 작성**

```dart
// lib/data/supabase_config.dart
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String bffBase = String.fromEnvironment(
    'BFF_BASE',
    defaultValue: '',
  );

  static void assertConfigured() {
    if (url.isEmpty || anonKey.isEmpty || bffBase.isEmpty) {
      if (kReleaseMode) {
        throw StateError(
          'Supabase/BFF config missing. Pass --dart-define=SUPABASE_URL=... etc.',
        );
      } else {
        debugPrint('⚠️ Supabase/BFF config missing — running with empty values.');
      }
    }
  }
}
```

- [ ] **Step 4: main.dart 수정**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SupabaseConfig.assertConfigured();
  if (SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: false,
    );
  }

  runApp(const ShareworkMockupApp());
}

class ShareworkMockupApp extends StatelessWidget {
  const ShareworkMockupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sharework',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.config,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
    );
  }
}
```

- [ ] **Step 5: 빌드 + 기존 테스트 회귀 검증**

```bash
flutter analyze
flutter test
```

기대: analyze 0 issue + test 2 passed (기존 widget_test).

- [ ] **Step 6: 사이드로드 빌드 명령 정리 후 commit**

```bash
# 빌드 명령 (다음 task에서 import 추가되면 다시 해야 함)
flutter build ios --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=BFF_BASE=$BFF_BASE
```

```bash
git add pubspec.yaml pubspec.lock lib/data/supabase_config.dart lib/main.dart
git commit -m "feat(flutter): add supabase_flutter + dio + freezed + Supabase.initialize"
```

---

### Task 16: Flutter — freezed 모델 (Profile, Job, JobCategory)

**Files:**
- Create: `sharework/lib/data/api_models/profile.dart`
- Create: `sharework/lib/data/api_models/job.dart`
- Create: `sharework/lib/data/api_models/job_category.dart`
- Generated: `*.freezed.dart`, `*.g.dart` (build_runner 출력)

- [ ] **Step 1: Profile 모델**

```dart
// lib/data/api_models/profile.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String phone,
    String? name,
    @Default('worker') String role,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);
}
```

- [ ] **Step 2: Job 모델**

```dart
// lib/data/api_models/job.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class ApiJob with _$ApiJob {
  const factory ApiJob({
    required String id,
    @JsonKey(name: 'giver_id') required String giverId,
    required String title,
    required String description,
    @JsonKey(name: 'wage_won') required int wageWon,
    @JsonKey(name: 'schedule_text') String? scheduleText,
    required String status,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'location_address') required String locationAddress,
    @JsonKey(name: 'location_lat') double? locationLat,
    @JsonKey(name: 'location_lng') double? locationLng,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ApiJob;

  factory ApiJob.fromJson(Map<String, Object?> json) => _$ApiJobFromJson(json);
}
```

(`ApiJob`으로 명명 — 기존 `lib/models/models.dart`의 dummy `Job` 클래스와 충돌 방지.)

- [ ] **Step 3: JobCategory 모델**

```dart
// lib/data/api_models/job_category.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_category.freezed.dart';
part 'job_category.g.dart';

@freezed
class ApiJobCategory with _$ApiJobCategory {
  const factory ApiJobCategory({
    required String id,
    required String name,
    required String slug,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _ApiJobCategory;

  factory ApiJobCategory.fromJson(Map<String, Object?> json) =>
      _$ApiJobCategoryFromJson(json);
}
```

- [ ] **Step 4: build_runner 실행**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

기대: `Succeeded after Xs with X outputs (X actions)`. 6개 파일 생성: 3개 freezed + 3개 g.

- [ ] **Step 5: 모델 round-trip 테스트 (TDD 회귀)**

```dart
// test/api_models/profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_models/profile.dart';

void main() {
  test('Profile.fromJson round-trip', () {
    final json = {
      'id': 'u1',
      'phone': '+821012345678',
      'name': '5678',
      'role': 'worker',
      'created_at': '2026-05-10T00:00:00Z',
    };
    final p = Profile.fromJson(json);
    expect(p.id, 'u1');
    expect(p.phone, '+821012345678');
    expect(p.role, 'worker');
    expect(p.createdAt, isNotNull);
  });
}
```

```bash
flutter test test/api_models/profile_test.dart
```

기대: `1 passed`.

- [ ] **Step 6: commit**

```bash
git add lib/data/api_models/ test/api_models/
git commit -m "feat(flutter): freezed models for Profile/ApiJob/ApiJobCategory"
```

---

### Task 17: Flutter — ApiClient (dio + JWT 인터셉터) (TDD)

**Files:**
- Create: `sharework/lib/data/api_client.dart`
- Create: `sharework/lib/data/exceptions.dart`
- Test: `sharework/test/data/api_client_test.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// test/data/api_client_test.dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/api_client.dart';
import 'package:sharework_mockup/data/exceptions.dart';

class _FakeAdapter implements HttpClientAdapter {
  ResponseBody? respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond ?? ResponseBody.fromString('{"data":{}}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('attaches Bearer token from session provider', () async {
    final adapter = _FakeAdapter();
    final client = ApiClient(
      baseUrl: 'http://x',
      sessionTokenProvider: () => 'jwt-123',
    );
    client.dio.httpClientAdapter = adapter;

    await client.dio.get('/api/me');

    expect(adapter.lastRequest!.headers['authorization'], 'Bearer jwt-123');
  });

  test('rejects with DioException wrapping ApiException on non-2xx', () async {
    // Bug 2 fix: dio interceptor handler.reject(DioException(error: ApiException(...)))
    // 형태로 던지므로 호출자는 DioException을 받고 e.error로 ApiException 추출.
    final adapter = _FakeAdapter()
      ..respond = ResponseBody.fromString(
        '{"error":{"code":"NOT_FOUND","message":"job not found"}}',
        404,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
    final client = ApiClient(
      baseUrl: 'http://x',
      sessionTokenProvider: () => 't',
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      () => client.dio.get('/api/jobs/x'),
      throwsA(isA<DioException>()
          .having((e) => (e.error as ApiException).code, 'code', 'NOT_FOUND')
          .having((e) => (e.error as ApiException).statusCode, 'statusCode', 404)
          .having((e) => e.response?.statusCode, 'response.statusCode', 404)),
    );
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

```bash
flutter test test/data/api_client_test.dart
```

- [ ] **Step 3: exceptions.dart 구현**

```dart
// lib/data/exceptions.dart
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  ApiException({required this.code, required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
```

- [ ] **Step 4: ApiClient 구현**

```dart
// lib/data/api_client.dart
import 'package:dio/dio.dart';
import 'exceptions.dart';

typedef SessionTokenProvider = String? Function();
typedef OnUnauthorized = Future<void> Function();

class ApiClient {
  final Dio dio;
  final SessionTokenProvider sessionTokenProvider;
  final OnUnauthorized? onUnauthorized;

  ApiClient({
    required String baseUrl,
    required this.sessionTokenProvider,
    this.onUnauthorized,
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
          responseType: ResponseType.json,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = sessionTokenProvider();
        if (token != null && token.isNotEmpty) {
          options.headers['authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (e, handler) async {
        final res = e.response;
        if (res != null) {
          final body = res.data;
          if (body is Map && body['error'] is Map) {
            final err = body['error'] as Map;
            final code = (err['code'] ?? 'INTERNAL') as String;
            final message = (err['message'] ?? 'unknown') as String;
            if (code == 'UNAUTHORIZED' && onUnauthorized != null) {
              await onUnauthorized!();
            }
            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              response: res,
              error: ApiException(
                code: code,
                message: message,
                statusCode: res.statusCode ?? 0,
              ),
              type: DioExceptionType.badResponse,
            ));
          }
        }
        handler.next(e);
      },
    ));
  }
}
```

- [ ] **Step 5: 테스트 실행 → PASS**

```bash
flutter test test/data/api_client_test.dart
```

기대: `2 passed`. (호출자 측 catch 패턴: `try { ... } on DioException catch (e) { final api = e.error as ApiException; ... }`. Repository 코드는 화면 FutureBuilder의 `snap.hasError`로 처리하므로 별도 unwrap 불필요.)

- [ ] **Step 6: commit**

```bash
git add lib/data/api_client.dart lib/data/exceptions.dart test/data/
git commit -m "feat(flutter): ApiClient with JWT interceptor + envelope error mapping"
```

---

### Task 18: Flutter — AuthRepository (Supabase SDK wrapper) (TDD)

**Files:**
- Create: `sharework/lib/data/repositories/auth_repository.dart`
- Test: `sharework/test/repositories/auth_repository_test.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// test/repositories/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';

class _FakeAuthApi implements SupabaseAuthApi {
  String? sentPhone;
  String? verifiedPhone;
  String? verifiedToken;
  String? returnAccessToken = 'jwt-456';
  bool throwOnVerify = false;

  @override
  Future<void> sendOtp(String phone) async {
    sentPhone = phone;
  }

  @override
  Future<String?> verifyOtp({required String phone, required String token}) async {
    verifiedPhone = phone;
    verifiedToken = token;
    if (throwOnVerify) throw Exception('invalid otp');
    return returnAccessToken;
  }

  @override
  String? get currentAccessToken => returnAccessToken;

  @override
  Future<void> signOut() async {
    returnAccessToken = null;
  }
}

void main() {
  test('sendOtp calls supabase.signInWithOtp', () async {
    final api = _FakeAuthApi();
    final repo = AuthRepository(api);
    await repo.sendOtp('+821012345678');
    expect(api.sentPhone, '+821012345678');
  });

  test('verifyOtp returns true and stores token on success', () async {
    final api = _FakeAuthApi();
    final repo = AuthRepository(api);
    final ok = await repo.verifyOtp(phone: '+821012345678', token: '123456');
    expect(ok, true);
    expect(repo.accessToken, 'jwt-456');
  });

  test('verifyOtp returns false on exception', () async {
    final api = _FakeAuthApi()..throwOnVerify = true;
    final repo = AuthRepository(api);
    final ok = await repo.verifyOtp(phone: '+82x', token: 'bad');
    expect(ok, false);
  });

  test('signOut clears token', () async {
    final api = _FakeAuthApi();
    final repo = AuthRepository(api);
    await repo.signOut();
    expect(repo.accessToken, isNull);
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: 구현**

```dart
// lib/data/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseAuthApi {
  Future<void> sendOtp(String phone);
  Future<String?> verifyOtp({required String phone, required String token});
  String? get currentAccessToken;
  Future<void> signOut();
}

class _RealSupabaseAuthApi implements SupabaseAuthApi {
  @override
  Future<void> sendOtp(String phone) async {
    await Supabase.instance.client.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<String?> verifyOtp({required String phone, required String token}) async {
    final res = await Supabase.instance.client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    return res.session?.accessToken;
  }

  @override
  String? get currentAccessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  @override
  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}

class AuthRepository {
  final SupabaseAuthApi _api;

  AuthRepository([SupabaseAuthApi? api]) : _api = api ?? _RealSupabaseAuthApi();

  Future<void> sendOtp(String phone) => _api.sendOtp(phone);

  Future<bool> verifyOtp({required String phone, required String token}) async {
    try {
      final at = await _api.verifyOtp(phone: phone, token: token);
      return at != null && at.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String? get accessToken => _api.currentAccessToken;

  Future<void> signOut() => _api.signOut();
}
```

- [ ] **Step 4: 테스트 실행 → PASS** (`4 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/data/repositories/auth_repository.dart test/repositories/auth_repository_test.dart
git commit -m "feat(flutter): AuthRepository wrapping Supabase Phone Auth"
```

---

### Task 19: Flutter — MeRepository (TDD)

**Files:**
- Create: `sharework/lib/data/repositories/me_repository.dart`
- Test: `sharework/test/repositories/me_repository_test.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// test/repositories/me_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  String body;
  int status;
  _StubAdapter(this.body, this.status);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

void main() {
  test('getMe returns Profile on 200', () async {
    final dio = Dio()
      ..httpClientAdapter = _StubAdapter(
        '{"data":{"id":"u1","phone":"+821012345678","name":"5678","role":"worker","created_at":"2026-05-10T00:00:00Z"}}',
        200,
      );
    final repo = MeRepository(dio);
    final me = await repo.getMe();
    expect(me.id, 'u1');
    expect(me.phone, '+821012345678');
    expect(me.role, 'worker');
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: 구현**

```dart
// lib/data/repositories/me_repository.dart
import 'package:dio/dio.dart';
import '../api_models/profile.dart';

class MeRepository {
  final Dio _dio;
  MeRepository(this._dio);

  Future<Profile> getMe() async {
    final res = await _dio.get('/api/me');
    final data = (res.data as Map)['data'] as Map<String, Object?>;
    return Profile.fromJson(data);
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS**

- [ ] **Step 5: commit**

```bash
git add lib/data/repositories/me_repository.dart test/repositories/me_repository_test.dart
git commit -m "feat(flutter): MeRepository for GET /api/me"
```

---

### Task 20: Flutter — JobRepository (TDD)

**Files:**
- Create: `sharework/lib/data/repositories/job_repository.dart`
- Test: `sharework/test/repositories/job_repository_test.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// test/repositories/job_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  String? lastPath;
  Map<String, List<String>>? lastQuery;
  String body;
  int status;
  _StubAdapter(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastPath = o.path;
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, status,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

const _sampleJob = '{"id":"j1","giver_id":"g1","title":"카페","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","location_lat":null,"location_lng":null,"created_at":"2026-05-10T00:00:00Z","updated_at":"2026-05-10T00:00:00Z"}';

void main() {
  test('getJobs without filters', () async {
    final adapter = _StubAdapter('{"data":[$_sampleJob],"page":{"total":1,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    final res = await repo.getJobs();
    expect(res.items, hasLength(1));
    expect(res.items[0].title, '카페');
    expect(res.total, 1);
  });

  test('getJobs passes category and q as query params', () async {
    final adapter = _StubAdapter('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    await repo.getJobs(categoryId: 'cafe-uuid', q: '강남', page: 2, limit: 10);
    expect(adapter.lastQuery!['category'], ['cafe-uuid']);
    expect(adapter.lastQuery!['q'], ['강남']);
    expect(adapter.lastQuery!['page'], ['2']);
    expect(adapter.lastQuery!['limit'], ['10']);
  });

  test('getJobById returns job', () async {
    final adapter = _StubAdapter('{"data":$_sampleJob}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    final job = await repo.getJobById('j1');
    expect(job.id, 'j1');
    expect(adapter.lastPath, '/api/jobs/j1');
  });

  test('getCategories returns list', () async {
    final adapter = _StubAdapter('{"data":[{"id":"c1","name":"카페","slug":"cafe","sort_order":1}]}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    final cats = await repo.getCategories();
    expect(cats, hasLength(1));
    expect(cats[0].slug, 'cafe');
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: 구현**

```dart
// lib/data/repositories/job_repository.dart
import 'package:dio/dio.dart';
import '../api_models/job.dart';
import '../api_models/job_category.dart';

class JobsPage {
  final List<ApiJob> items;
  final int total;
  final int page;
  final int limit;
  JobsPage({required this.items, required this.total, required this.page, required this.limit});
}

class JobRepository {
  final Dio _dio;
  JobRepository(this._dio);

  Future<JobsPage> getJobs({
    String? categoryId,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final qp = <String, dynamic>{'page': page.toString(), 'limit': limit.toString()};
    if (categoryId != null) qp['category'] = categoryId;
    if (q != null && q.isNotEmpty) qp['q'] = q;

    final res = await _dio.get('/api/jobs', queryParameters: qp);
    final body = res.data as Map;
    final dataList = (body['data'] as List).cast<Map<String, Object?>>();
    final pageMeta = body['page'] as Map?;
    return JobsPage(
      items: dataList.map(ApiJob.fromJson).toList(),
      total: (pageMeta?['total'] ?? dataList.length) as int,
      page: (pageMeta?['page'] ?? page) as int,
      limit: (pageMeta?['limit'] ?? limit) as int,
    );
  }

  Future<ApiJob> getJobById(String id) async {
    final res = await _dio.get('/api/jobs/$id');
    final data = (res.data as Map)['data'] as Map<String, Object?>;
    return ApiJob.fromJson(data);
  }

  Future<List<ApiJobCategory>> getCategories() async {
    final res = await _dio.get('/api/categories');
    final list = ((res.data as Map)['data'] as List).cast<Map<String, Object?>>();
    return list.map(ApiJobCategory.fromJson).toList();
  }
}
```

- [ ] **Step 4: 테스트 실행 → PASS** (`4 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/data/repositories/job_repository.dart test/repositories/job_repository_test.dart
git commit -m "feat(flutter): JobRepository with getJobs/getJobById/getCategories"
```

---

### Task 21: Flutter — Repository wiring + 라우터 가드

**Files:**
- Create: `sharework/lib/data/repositories/repositories.dart` (DI 컨테이너)
- Modify: `sharework/lib/router/app_router.dart`

- [ ] **Step 1: DI 컨테이너 작성**

```dart
// lib/data/repositories/repositories.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api_client.dart';
import '../supabase_config.dart';
import 'auth_repository.dart';
import 'job_repository.dart';
import 'me_repository.dart';

class Repositories {
  static final AuthRepository auth = AuthRepository();

  static final ApiClient _api = ApiClient(
    baseUrl: SupabaseConfig.bffBase,
    sessionTokenProvider: () =>
        Supabase.instance.client.auth.currentSession?.accessToken,
    onUnauthorized: () async {
      await auth.signOut();
    },
  );

  static final MeRepository me = MeRepository(_api.dio);
  static final JobRepository job = JobRepository(_api.dio);
}
```

- [ ] **Step 2: 라우터 가드 추가**

`lib/router/app_router.dart` 시작부에 import 추가:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

`GoRouter config = GoRouter(...)` 생성 시 `redirect:` 인자 추가. **Supabase 미초기화 상태(테스트·dev 빈 env)에서 안전하게 동작하도록 try-catch 가드 포함**:

```dart
static final GoRouter config = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Minor flag fix: Supabase.instance 접근 시 미초기화면 AssertionError → 가드 비활성
    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      return null;
    }
    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/auth/') || loc == '/splash';
    final isOnboarding = loc.startsWith('/onboarding');
    if (session == null && !isAuthRoute && !isOnboarding) {
      return '/auth/phone';
    }
    return null;
  },
  routes: [...]
);
```

- [ ] **Step 3: 라우터 변경 회귀 검증**

```bash
flutter test
```

기대: `2 passed` (기존 widget_test 깨지지 않음 — Supabase.instance 접근 시 dummy session으로 인해 redirect 발생 가능). 만약 widget_test가 깨지면 test에서 `Supabase.initialize` mock 또는 redirect bypass 추가 (test main에서 fake URL 주입).

- [ ] **Step 4: commit**

```bash
git add lib/data/repositories/repositories.dart lib/router/app_router.dart
git commit -m "feat(flutter): Repositories DI + router auth guard"
```

---

### Task 22: Flutter — PhoneAuthScreen swap (TDD)

**Files:**
- Modify: `sharework/lib/screens/auth/phone_auth_screen.dart`
- Test: `sharework/test/screens/phone_auth_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성 (mock AuthRepository 주입)**

```dart
// test/screens/phone_auth_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';
import 'package:sharework_mockup/screens/auth/phone_auth_screen.dart';

class _MockAuth implements SupabaseAuthApi {
  String? lastPhone;
  String? lastToken;
  bool verifySucceeds;
  _MockAuth({this.verifySucceeds = true});
  @override
  Future<void> sendOtp(String phone) async { lastPhone = phone; }
  @override
  Future<String?> verifyOtp({required String phone, required String token}) async {
    lastToken = token;
    return verifySucceeds ? 'jwt-zzz' : null;
  }
  @override
  String? get currentAccessToken => null;
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('sendOtp on phone submit', (tester) async {
    final mock = _MockAuth();
    final repo = AuthRepository(mock);
    await tester.pumpWidget(MaterialApp(
      home: PhoneAuthScreen(authRepository: repo),
    ));
    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();
    expect(mock.lastPhone, '+821012345678');
  });

  testWidgets('verifyOtp on otp submit success shows next screen trigger', (tester) async {
    final mock = _MockAuth();
    final repo = AuthRepository(mock);
    bool advanced = false;
    await tester.pumpWidget(MaterialApp(
      home: PhoneAuthScreen(
        authRepository: repo,
        onAuthenticated: () => advanced = true,
      ),
    ));
    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tester.tap(find.byKey(const Key('verify-otp-button')));
    await tester.pump();
    expect(mock.lastToken, '123456');
    expect(advanced, true);
  });

  testWidgets('verifyOtp failure shows error message', (tester) async {
    final mock = _MockAuth(verifySucceeds: false);
    final repo = AuthRepository(mock);
    await tester.pumpWidget(MaterialApp(
      home: PhoneAuthScreen(authRepository: repo),
    ));
    await tester.enterText(find.byKey(const Key('phone-field')), '+82x');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('otp-field')), 'bad');
    await tester.tap(find.byKey(const Key('verify-otp-button')));
    await tester.pump();
    expect(find.textContaining('인증 실패'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: phone_auth_screen.dart 수정 (기존 dummy 흐름 → AuthRepository)**

기존 파일 전체를 다음과 같이 교체 (UI 구조는 기존을 보존하되 핵심 로직만 swap):

```dart
// lib/screens/auth/phone_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final VoidCallback? onAuthenticated;
  const PhoneAuthScreen({super.key, this.authRepository, this.onAuthenticated});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtl = TextEditingController();
  final _otpCtl = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  AuthRepository get _auth => widget.authRepository ?? Repositories.auth;

  Future<void> _sendOtp() async {
    setState(() { _busy = true; _error = null; });
    try {
      await _auth.sendOtp(_phoneCtl.text.trim());
      setState(() { _otpSent = true; });
    } catch (_) {
      setState(() { _error = '인증번호 발송 실패. 다시 시도해 주세요.'; });
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() { _busy = true; _error = null; });
    final ok = await _auth.verifyOtp(
      phone: _phoneCtl.text.trim(),
      token: _otpCtl.text.trim(),
    );
    setState(() { _busy = false; });
    if (ok) {
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else if (mounted) {
        context.go('/worker');
      }
    } else {
      setState(() { _error = '인증 실패. 번호와 인증번호를 확인해 주세요.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전화번호 인증')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('phone-field'),
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '전화번호 (예: +821012345678)',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('send-otp-button'),
              onPressed: _busy ? null : _sendOtp,
              child: const Text('인증번호 받기'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 24),
              TextField(
                key: const Key('otp-field'),
                controller: _otpCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '인증번호 6자리'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                key: const Key('verify-otp-button'),
                onPressed: _busy ? null : _verifyOtp,
                child: const Text('확인'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}
```

(`AppColors.error`가 없으면 `Colors.red`로 대체. 기존 파일의 다른 디자인 요소가 있다면 보존하되 위 위젯 트리는 유지.)

- [ ] **Step 4: 테스트 실행 → PASS** (`3 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/screens/auth/phone_auth_screen.dart test/screens/phone_auth_screen_test.dart
git commit -m "feat(flutter): PhoneAuthScreen wired to AuthRepository (Mock OTP)"
```

---

### Task 23: Flutter — WorkerHomeScreen swap (TDD, applied/hired pill 0/0)

**Files:**
- Modify: `sharework/lib/screens/worker/home/worker_home_screen.dart`
- Test: `sharework/test/screens/worker_home_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성**

```dart
// test/screens/worker_home_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/worker/home/worker_home_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  int status = 200;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

const _job = '{"id":"j1","giver_id":"g1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","location_lat":null,"location_lng":null,"created_at":"2026-05-10T00:00:00Z","updated_at":"2026-05-10T00:00:00Z"}';

JobRepository _repo(String body) {
  final dio = Dio()..httpClientAdapter = _Stub(body);
  return JobRepository(dio);
}

void main() {
  testWidgets('renders job list from JobRepository', (tester) async {
    final repo = _repo('{"data":[$_job],"page":{"total":1,"page":1,"limit":20}}');
    await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
  });

  testWidgets('shows empty state when no jobs', (tester) async {
    final repo = _repo('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('근처 공고가 없'), findsOneWidget);
  });

  testWidgets('shows error state on API failure', (tester) async {
    final dio = Dio();
    dio.httpClientAdapter = _Stub('{"error":{"code":"INTERNAL","message":"x"}}')..status = 500;
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });

  testWidgets('applied/hired pill always shows 0/0 in M1', (tester) async {
    final repo = _repo('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    final pill = find.byKey(const Key('status-pill-applied'));
    expect(pill, findsOneWidget);
    expect(find.descendant(of: pill, matching: find.text('0')), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행 → FAIL**

- [ ] **Step 3: worker_home_screen.dart 수정**

```dart
// lib/screens/worker/home/worker_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api_models/job.dart';
import '../../../data/permission_state.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../data/repositories/repositories.dart';
import '../../../screens/permissions/priming_sheets.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class WorkerHomeScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const WorkerHomeScreen({super.key, this.jobRepository});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late final JobRepository _repo;
  late Future<JobsPage> _future;

  // M1: applications API 미존재, M2 연결
  static const int _appliedCount = 0;
  static const int _hiredCount = 0;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? Repositories.job;
    _future = _repo.getJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _MapPlaceholder(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: _SearchBar(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16, right: 16,
            child: Row(
              children: [
                _StatusPill(
                  key: const Key('status-pill-applied'),
                  label: '지원중',
                  count: _appliedCount,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  key: const Key('status-pill-hired'),
                  label: '채용됨',
                  count: _hiredCount,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 130,
            child: FutureBuilder<JobsPage>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('연결이 불안정합니다'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _future = _repo.getJobs(); });
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data?.items ?? const <ApiJob>[];
                if (items.isEmpty) {
                  return const Center(child: Text('근처 공고가 없어요'));
                }
                return ListView.builder(
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('주변 일자리 ${items.length}건'),
                      );
                    }
                    final job = items[i - 1];
                    return ListTile(
                      title: Text(job.title),
                      subtitle: Text('${job.wageWon}원 · ${job.locationAddress}'),
                      onTap: () => context.push('/job/${job.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 기존 _MapPlaceholder, _SearchBar, _StatusPill 위젯 클래스는 이 파일 또는 ../widgets/에 보존
```

기존 파일에 있던 `_MapPlaceholder`, `_SearchBar`, `_StatusPill` private 클래스를 그대로 유지. `_StatusPill`이 `key` 파라미터를 받지 않으면 추가:

```dart
class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusPill({super.key, required this.label, required this.count, required this.color});
  // ...
}
```

- [ ] **Step 4: 테스트 실행 → PASS** (`4 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/screens/worker/home/worker_home_screen.dart test/screens/worker_home_screen_test.dart
git commit -m "feat(flutter): WorkerHomeScreen wired to JobRepository, applied/hired pill 0/0 (M1)"
```

---

### Task 24: Flutter — JobInfoScreen swap (TDD)

**Files:**
- Modify: `sharework/lib/screens/common/job_info_screen.dart`
- Test: `sharework/test/screens/job_info_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성**

```dart
// test/screens/job_info_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/common/job_info_screen.dart';

class _Stub implements HttpClientAdapter {
  final String body;
  final int status;
  _Stub(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

JobRepository _repo(String body, [int status = 200]) {
  final dio = Dio()..httpClientAdapter = _Stub(body, status);
  return JobRepository(dio);
}

void main() {
  testWidgets('renders job detail', (tester) async {
    final repo = _repo(
      '{"data":{"id":"j1","giver_id":"g1","title":"카페 알바","description":"디테일","wage_won":12000,"schedule_text":"토/일","status":"active","category_id":"c1","location_address":"서울시","location_lat":null,"location_lng":null,"created_at":"2026-05-10T00:00:00Z","updated_at":"2026-05-10T00:00:00Z"}}',
    );
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(jobId: 'j1', jobRepository: repo),
    ));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);
    expect(find.text('디테일'), findsOneWidget);
  });

  testWidgets('shows error on 404', (tester) async {
    final repo = _repo('{"error":{"code":"NOT_FOUND","message":"x"}}', 404);
    await tester.pumpWidget(MaterialApp(
      home: JobInfoScreen(jobId: 'missing', jobRepository: repo),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 → FAIL**

- [ ] **Step 3: 구현**

```dart
// lib/screens/common/job_info_screen.dart
import 'package:flutter/material.dart';

import '../../data/api_models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../theme/app_theme.dart';

class JobInfoScreen extends StatefulWidget {
  final String jobId;
  final JobRepository? jobRepository;
  const JobInfoScreen({super.key, required this.jobId, this.jobRepository});

  @override
  State<JobInfoScreen> createState() => _JobInfoScreenState();
}

class _JobInfoScreenState extends State<JobInfoScreen> {
  late Future<ApiJob> _future;
  late final JobRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? Repositories.job;
    _future = _repo.getJobById(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공고 상세')),
      body: FutureBuilder<ApiJob>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('연결이 불안정합니다'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _future = _repo.getJobById(widget.jobId);
                    }),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final job = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(job.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${job.wageWon}원 · ${job.locationAddress}'),
              const SizedBox(height: 16),
              if (job.scheduleText != null) Text('일정: ${job.scheduleText}'),
              const SizedBox(height: 16),
              Text(job.description),
            ],
          );
        },
      ),
    );
  }
}
```

라우터에서 `/job/:id`로 navigate 시 `JobInfoScreen(jobId: state.pathParameters['id']!)` 형태로 이미 호출되어 있어야 함. 라우트 정의가 다르면 `app_router.dart`에서 함께 수정.

- [ ] **Step 4: 테스트 → PASS** (`2 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/screens/common/job_info_screen.dart test/screens/job_info_screen_test.dart
git commit -m "feat(flutter): JobInfoScreen wired to JobRepository.getJobById"
```

---

### Task 25: Flutter — SearchScreen swap (TDD)

**Files:**
- Modify: `sharework/lib/screens/common/search_screen.dart`
- Test: `sharework/test/screens/search_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성**

```dart
// test/screens/search_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/common/search_screen.dart';

class _Stub implements HttpClientAdapter {
  Map<String, List<String>>? lastQuery;
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('searching by q triggers JobRepository.getJobs(q=...)', (tester) async {
    final adapter = _Stub('{"data":[],"page":{"total":0,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(home: SearchScreen(jobRepository: repo)));
    await tester.enterText(find.byKey(const Key('search-field')), '강남');
    await tester.tap(find.byKey(const Key('search-submit')));
    await tester.pumpAndSettle();
    expect(adapter.lastQuery!['q'], ['강남']);
    expect(find.textContaining('검색 결과가 없'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 → FAIL**

- [ ] **Step 3: 구현 (기존 파일 위젯 트리 보존하면서 데이터 로직 swap)**

```dart
// lib/screens/common/search_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/repositories.dart';

class SearchScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const SearchScreen({super.key, this.jobRepository});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctl = TextEditingController();
  late final JobRepository _repo;
  Future<JobsPage>? _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? Repositories.job;
  }

  void _runSearch() {
    setState(() {
      _future = _repo.getJobs(q: _ctl.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-field'),
          controller: _ctl,
          decoration: const InputDecoration(hintText: '검색어'),
          onSubmitted: (_) => _runSearch(),
        ),
        actions: [
          IconButton(
            key: const Key('search-submit'),
            icon: const Icon(Icons.search),
            onPressed: _runSearch,
          ),
        ],
      ),
      body: _future == null
          ? const Center(child: Text('검색어를 입력하세요'))
          : FutureBuilder<JobsPage>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('연결이 불안정합니다'));
                }
                final items = snap.data?.items ?? const <ApiJob>[];
                if (items.isEmpty) {
                  return const Center(child: Text('검색 결과가 없어요'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final j = items[i];
                    return ListTile(
                      title: Text(j.title),
                      subtitle: Text('${j.wageWon}원 · ${j.locationAddress}'),
                      onTap: () => context.push('/job/${j.id}'),
                    );
                  },
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 4: 테스트 → PASS** (`1 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/screens/common/search_screen.dart test/screens/search_screen_test.dart
git commit -m "feat(flutter): SearchScreen wired to JobRepository.getJobs(q)"
```

---

### Task 26: Flutter — CategoriesScreen + CategoryJobsScreen swap (TDD)

**Files:**
- Modify: `sharework/lib/screens/categories/categories_screen.dart`
- Modify: `sharework/lib/screens/categories/category_jobs_screen.dart`
- Test: `sharework/test/screens/categories_screen_test.dart`
- Test: `sharework/test/screens/category_jobs_screen_test.dart`

- [ ] **Step 1: categories_screen_test.dart**

```dart
// test/screens/categories_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/categories/categories_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, 200,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('renders categories from JobRepository', (tester) async {
    final dio = Dio()..httpClientAdapter = _Stub(
      '{"data":[{"id":"c1","name":"카페","slug":"cafe","sort_order":1},{"id":"c2","name":"식당","slug":"restaurant","sort_order":2}]}',
    );
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(home: CategoriesScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('식당'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    final dio = Dio()..httpClientAdapter = _Stub('{"data":[]}');
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(home: CategoriesScreen(jobRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.textContaining('카테고리가'), findsOneWidget);
  });
}
```

- [ ] **Step 2: category_jobs_screen_test.dart**

```dart
// test/screens/category_jobs_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/screens/categories/category_jobs_screen.dart';

class _Stub implements HttpClientAdapter {
  Map<String, List<String>>? lastQuery;
  String body;
  _Stub(this.body);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    lastQuery = o.uri.queryParametersAll;
    return ResponseBody.fromString(body, 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

const _job = '{"id":"j1","giver_id":"g1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","location_lat":null,"location_lng":null,"created_at":"2026-05-10T00:00:00Z","updated_at":"2026-05-10T00:00:00Z"}';

void main() {
  testWidgets('passes categoryId to getJobs', (tester) async {
    final adapter = _Stub('{"data":[$_job],"page":{"total":1,"page":1,"limit":20}}');
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = JobRepository(dio);
    await tester.pumpWidget(MaterialApp(
      home: CategoryJobsScreen(
        categoryId: 'c1',
        categoryName: '카페',
        jobRepository: repo,
      ),
    ));
    await tester.pumpAndSettle();
    expect(adapter.lastQuery!['category'], ['c1']);
    expect(find.text('카페 알바'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 테스트 → FAIL**

- [ ] **Step 4: categories_screen.dart 구현**

```dart
// lib/screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_models/job_category.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/repositories.dart';

class CategoriesScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  const CategoriesScreen({super.key, this.jobRepository});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final JobRepository _repo;
  late Future<List<ApiJobCategory>> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? Repositories.job;
    _future = _repo.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카테고리')),
      body: FutureBuilder<List<ApiJobCategory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('연결이 불안정합니다'),
                  ElevatedButton(
                    onPressed: () => setState(() { _future = _repo.getCategories(); }),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final items = snap.data ?? const <ApiJobCategory>[];
          if (items.isEmpty) {
            return const Center(child: Text('카테고리가 비어 있어요'));
          }
          return GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(16),
            children: items
                .map((c) => InkWell(
                      onTap: () => context.push('/categories/${c.id}',
                          extra: c.name),
                      child: Card(
                        child: Center(child: Text(c.name)),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: category_jobs_screen.dart 구현**

```dart
// lib/screens/categories/category_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/repositories.dart';

class CategoryJobsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final JobRepository? jobRepository;
  const CategoryJobsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.jobRepository,
  });
  @override
  State<CategoryJobsScreen> createState() => _CategoryJobsScreenState();
}

class _CategoryJobsScreenState extends State<CategoryJobsScreen> {
  late final JobRepository _repo;
  late Future<JobsPage> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? Repositories.job;
    _future = _repo.getJobs(categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: FutureBuilder<JobsPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return const Center(child: Text('연결이 불안정합니다'));
          final items = snap.data?.items ?? const <ApiJob>[];
          if (items.isEmpty) return const Center(child: Text('해당 카테고리에 공고가 없어요'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final j = items[i];
              return ListTile(
                title: Text(j.title),
                subtitle: Text('${j.wageWon}원 · ${j.locationAddress}'),
                onTap: () => context.push('/job/${j.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
```

`app_router.dart`의 `/categories/:id` 라우트가 위 시그니처와 일치하도록 수정. 기존 라우트 builder가 다르면 함께 수정:

```dart
GoRoute(
  path: '/categories/:id',
  builder: (ctx, state) => CategoryJobsScreen(
    categoryId: state.pathParameters['id']!,
    categoryName: (state.extra as String?) ?? '카테고리',
  ),
),
```

- [ ] **Step 6: 테스트 → PASS** (`3 passed` total)

- [ ] **Step 7: commit**

```bash
git add lib/screens/categories/ test/screens/categories_screen_test.dart test/screens/category_jobs_screen_test.dart lib/router/app_router.dart
git commit -m "feat(flutter): Categories + CategoryJobs screens wired to JobRepository"
```

---

### Task 27: Flutter — MyPageScreen swap (TDD)

**Files:**
- Modify: `sharework/lib/screens/worker/mypage/mypage_screen.dart`
- Test: `sharework/test/screens/mypage_screen_test.dart`

- [ ] **Step 1: 위젯 테스트 작성**

```dart
// test/screens/mypage_screen_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/screens/worker/mypage/mypage_screen.dart';

class _Stub implements HttpClientAdapter {
  String body;
  int status;
  _Stub(this.body, [this.status = 200]);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async =>
      ResponseBody.fromString(body, status,
          headers: {Headers.contentTypeHeader: ['application/json']});
  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('renders profile name', (tester) async {
    final dio = Dio()..httpClientAdapter = _Stub(
      '{"data":{"id":"u1","phone":"+821012345678","name":"5678","role":"worker","created_at":"2026-05-10T00:00:00Z"}}',
    );
    final repo = MeRepository(dio);
    await tester.pumpWidget(MaterialApp(
      home: MyPageScreen(appType: 'worker', meRepository: repo),
    ));
    await tester.pumpAndSettle();
    expect(find.text('5678'), findsOneWidget);
  });

  testWidgets('shows error on failure', (tester) async {
    final dio = Dio()..httpClientAdapter = _Stub(
      '{"error":{"code":"INTERNAL","message":"x"}}',
      500,
    );
    final repo = MeRepository(dio);
    await tester.pumpWidget(MaterialApp(
      home: MyPageScreen(appType: 'worker', meRepository: repo),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('연결이 불안정'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 → FAIL**

- [ ] **Step 3: 구현 (기존 메뉴 항목 보존, profile 영역만 swap)**

```dart
// lib/screens/worker/mypage/mypage_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api_models/profile.dart';
import '../../../data/repositories/me_repository.dart';
import '../../../data/repositories/repositories.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class MyPageScreen extends StatefulWidget {
  final String appType;
  final MeRepository? meRepository;
  const MyPageScreen({
    super.key,
    required this.appType,
    this.meRepository,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late final MeRepository _repo;
  late Future<Profile> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.meRepository ?? Repositories.me;
    _future = _repo.getMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: FutureBuilder<Profile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('연결이 불안정합니다'),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _future = _repo.getMe();
                    }),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final me = snap.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              InkWell(
                onTap: () => context.push('/profile/${me.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.brandSoft,
                        child: Icon(Icons.person, size: 36, color: AppColors.brandDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me.name ?? me.phone,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(me.phone, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _Tile(icon: Icons.edit, label: '내 프로필 수정', onTap: () => context.push('/me/edit')),
              _Tile(icon: Icons.verified, label: '본인 인증', onTap: () => context.push('/me/identity')),
              _Tile(icon: Icons.notifications, label: '알림 설정', onTap: () => context.push('/me/notification-settings')),
              _Tile(icon: Icons.security, label: '보안', onTap: () => context.push('/me/security')),
              _Tile(icon: Icons.bookmark, label: '저장한 검색', onTap: () => context.push('/me/saved-searches')),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
```

기존 mypage가 갖던 다른 메뉴 항목(워커 신뢰도·신원확인 등)이 더 있다면 보존. M1 변경은 profile 카드 영역(`me.name` / `me.phone`)만.

- [ ] **Step 4: 테스트 → PASS** (`2 passed`)

- [ ] **Step 5: commit**

```bash
git add lib/screens/worker/mypage/mypage_screen.dart test/screens/mypage_screen_test.dart
git commit -m "feat(flutter): MyPageScreen profile card wired to MeRepository (M1)"
```

---

### Task 28: Flutter — Integration test (m1_smoke)

**Files:**
- Create: `sharework/test/integration/m1_smoke_test.dart`

- [ ] **Step 1: smoke test 작성 (실 BFF 또는 mock dio 양쪽 지원)**

```dart
// test/integration/m1_smoke_test.dart
//
// M1 smoke flow: PhoneAuth → JWT 획득 → WorkerHome jobs 표시 → JobInfo 진입 → MyPage 프로필 표시
//
// 환경변수 SHAREWORK_E2E=1 일 때만 실 BFF 사용. 평소는 mock으로 빠르게 검증.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';
import 'package:sharework_mockup/data/repositories/job_repository.dart';
import 'package:sharework_mockup/data/repositories/me_repository.dart';
import 'package:sharework_mockup/screens/auth/phone_auth_screen.dart';
import 'package:sharework_mockup/screens/worker/home/worker_home_screen.dart';
import 'package:sharework_mockup/screens/worker/mypage/mypage_screen.dart';

class _MockAuth implements SupabaseAuthApi {
  String? token = 'jwt-zzz';
  @override
  Future<void> sendOtp(String phone) async {}
  @override
  Future<String?> verifyOtp({required String phone, required String token}) async => 'jwt-zzz';
  @override
  String? get currentAccessToken => token;
  @override
  Future<void> signOut() async { token = null; }
}

class _MockAdapter implements HttpClientAdapter {
  final Map<String, String> routes;
  _MockAdapter(this.routes);
  @override
  Future<ResponseBody> fetch(RequestOptions o, _, __) async {
    final body = routes[o.path] ?? '{"data":[]}';
    return ResponseBody.fromString(body, 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  final isE2E = Platform.environment['SHAREWORK_E2E'] == '1';

  testWidgets('M1 smoke flow (mock)', (tester) async {
    if (isE2E) return; // skip in e2e mode

    final auth = AuthRepository(_MockAuth());
    final dio = Dio()..httpClientAdapter = _MockAdapter({
      '/api/jobs': '{"data":[{"id":"j1","giver_id":"g1","title":"카페 알바","description":"d","wage_won":12000,"schedule_text":null,"status":"active","category_id":"c1","location_address":"서울시","location_lat":null,"location_lng":null,"created_at":"2026-05-10T00:00:00Z","updated_at":"2026-05-10T00:00:00Z"}],"page":{"total":1,"page":1,"limit":20}}',
      '/api/me': '{"data":{"id":"u1","phone":"+821012345678","name":"5678","role":"worker","created_at":"2026-05-10T00:00:00Z"}}',
    });
    final jobRepo = JobRepository(dio);
    final meRepo = MeRepository(dio);

    // 1. 인증
    await tester.pumpWidget(MaterialApp(
      home: PhoneAuthScreen(
        authRepository: auth,
        onAuthenticated: () {},
      ),
    ));
    await tester.enterText(find.byKey(const Key('phone-field')), '+821012345678');
    await tester.tap(find.byKey(const Key('send-otp-button')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tester.tap(find.byKey(const Key('verify-otp-button')));
    await tester.pumpAndSettle();
    expect(auth.accessToken, 'jwt-zzz');

    // 2. WorkerHome
    await tester.pumpWidget(MaterialApp(home: WorkerHomeScreen(jobRepository: jobRepo)));
    await tester.pumpAndSettle();
    expect(find.text('카페 알바'), findsOneWidget);

    // 3. MyPage
    await tester.pumpWidget(MaterialApp(home: MyPageScreen(appType: 'worker', meRepository: meRepo)));
    await tester.pumpAndSettle();
    expect(find.text('5678'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행**

```bash
flutter test test/integration/m1_smoke_test.dart
```

기대: `1 passed`.

- [ ] **Step 3: commit**

```bash
git add test/integration/m1_smoke_test.dart
git commit -m "test(flutter): M1 smoke flow integration test (mock)"
```

---

### Task 29: 회귀 검증 + 사이드로드 재검증

**Files:**
- (변경 없음, 검증만)

- [ ] **Step 1: BFF 전체 테스트 회귀**

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework-api
npm test
```

기대: 모든 unit·integration 통과 (`X passed`). e2e는 SHAREWORK_E2E=1로 별도.

- [ ] **Step 2: Flutter 전체 테스트 회귀**

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter analyze
flutter test
```

기대: analyze 0 issue. test: 기존 widget_test 1 + 신규 위젯/리포지토리/모델/통합 테스트 ≥ 17개 모두 PASS.

테스트 카운트 예상:
- widget_test (회귀): 1
- profile round-trip: 1
- ApiClient: 2
- AuthRepository: 4
- MeRepository: 1
- JobRepository: 4
- PhoneAuthScreen: 3
- WorkerHomeScreen: 4
- JobInfoScreen: 2
- SearchScreen: 1
- CategoriesScreen: 2
- CategoryJobsScreen: 1
- MyPageScreen: 2
- m1_smoke: 1
- **총 ≥ 29 passed**

- [ ] **Step 3: production 빌드 (실 env 주입)**

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=BFF_BASE=$BFF_BASE
```

기대: `Built /path/to/Runner.app (XX.XMB)`.

- [ ] **Step 4: 사이드로드 재설치**

```bash
DEVICE_ID=C228416D-4B4E-5F25-9732-FE2610416B7A
xcrun devicectl device install app --device $DEVICE_ID build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device $DEVICE_ID kr.sharework.app
```

기대: 앱 정상 실행. 사용자 직접 시나리오 1회:
1. PhoneAuthScreen — 등록한 test phone 입력 → OTP 입력 → /worker 진입
2. WorkerHome — jobs 1개 표시, applied/hired 0/0
3. /search — '카페' 검색 → 결과 1개
4. /categories → 카페 → jobs 표시
5. /me → 프로필 카드에 phone 끝 4자리 (예: 5678) 노출

- [ ] **Step 5: BFF production curl 검증**

```bash
PROD_URL=https://sharework-api-xxx.vercel.app
# 위 시나리오에서 받은 access token (Flutter dev tools 또는 supabase dashboard에서 user-id로 추적 가능)
# 단순 ping
curl -i $PROD_URL/api/categories -H "Authorization: Bearer $TOKEN"
```

기대: HTTP/200 + `Cache-Control: public, max-age=3600` + 9개 카테고리.

- [ ] **Step 6: 메모리 업데이트 + 최종 commit + push**

`~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/project_sharework.md`에 다음 추가:

```markdown
## M1 완료 (2026-05-XX)

- BFF: sharework-api {commit}, Vercel production https://sharework-api-xxx.vercel.app
- Flutter: main {commit}, iOS 사이드로드 재검증 통과
- 7 화면 dummy → 실 백엔드 swap 완료 (PhoneAuth, WorkerHome, JobInfo, Search, Categories, CategoryJobs, MyPage)
- 테스트: BFF X passed (unit + integration + e2e), Flutter ≥29 passed
- 외부 의존성 lock-in: Supabase Free tier, Vercel Hobby personal, Twilio 미가입(Mock 모드)
- 다음: M2 (Giver 흐름 + applications 테이블 + 사진 업로드 + applied/hired pill 실 데이터)
```

```bash
git add . # 의도적이지 않은 변경 없는지 status 확인 후
git commit -m "docs: M1 complete — auth + jobs + categories + me wired to backend"
git push origin main
```

(sharework-api repo도 별도로 push.)

---

## 최종 체크리스트

- [ ] R5 5개 모두 lock-in (위 표 참조)
- [ ] 사용자 결정 3개 lock-in (Q1 E 단독, Q2 0/0, Q3 개인 GitHub)
- [ ] 외부 의존성 0.1~0.6 모두 사용자 작업 완료
- [ ] BFF 28개 task 중 BFF 부분 (Task 1~14) 모두 완료, 모든 테스트 PASS
- [ ] Flutter Task 15~28 완료, 모든 테스트 PASS
- [ ] Vercel production 배포 + curl 200 검증
- [ ] iPhone 사이드로드 재검증 (5단계 시나리오)
- [ ] 메모리 업데이트 + 마지막 commit push

## 진행 중 발생 가능 BLOCKED 신호

다음 상황 발생 시 즉시 작업 중단 + 사용자 에스컬레이션:

1. Supabase dashboard에 Test phone numbers 기능이 노출되지 않음 → R5-1 fallback C 옵션(BFF mock-otp endpoint) 발동, plan 추가 작업 약 4시간
2. JWKS endpoint 응답 실패 또는 5xx → Supabase 프로젝트 region/연결 점검
3. Vercel Hobby tier 한도 초과 (1M invocations 등) → 베타 트래픽 추정치 재검토 필요
4. Flutter build 실패 (CocoaPods 또는 supabase_flutter native crash) → pubspec 버전 dump + iOS Podfile.lock 검토
5. RLS 정책 미동작 (anon으로 jobs 전체 조회 성공 등) → 즉시 마이그레이션 재검토 + service_role과 anon 동작 차이 재확인

---

## Self-Review

### Spec coverage

| spec 섹션 | 커버 task |
|----------|----------|
| §1 Architecture | Task 1, 8 (BFF), Task 15 (Flutter) |
| §2 Data Model: profiles | Task 2, 5 |
| §2 Data Model: jobs | Task 4 |
| §2 Data Model: job_categories + 시드 | Task 3 |
| §3 Auth Flow (Mock OTP) | Task 0 (dashboard 등록), Task 18 (Flutter Auth), Task 22 (PhoneAuth UI) |
| §3 BFF JWT 검증 | Task 7 |
| §4 BFF API: GET /api/me | Task 9 |
| §4 BFF API: GET /api/jobs | Task 12 |
| §4 BFF API: GET /api/jobs/:id | Task 13 |
| §4 BFF API: GET /api/categories | Task 10 |
| §5 Flutter Repository Pattern | Task 17, 18, 19, 20, 21 |
| §5 화면 변경 (7개) | Task 22, 23, 24, 25, 26 (2화면 묶음), 27 |
| §6 Error Handling & UX | Task 17 (인터셉터), 22~27 (각 화면 error state) |
| §6 라우터 가드 | Task 21 |
| §7 Testing Strategy (TDD) | 각 task의 Step 1 RED → Step 3 GREEN |
| §7 BFF Unit + Integration + E2E | Task 6, 7, 9, 10, 11, 12, 13, 14 |
| §7 Flutter Widget + Integration | Task 16, 17, 18, 19, 20, 22~28 |
| §8 Out of Scope | Task 23 (applied/hired 0/0 + 코멘트), 그 외 화면 미변경 |

### Placeholder scan

본 plan의 모든 step은 actual code/command 포함. "TBD", "implement later", "add appropriate ..." 표현 0건.

예외 케이스:
- Task 5 Step 3 dev seed jobs INSERT — `'YOUR-USER-UUID'` 자리는 사용자 dashboard에서 1회 복사 필요. 이는 외부 의존성과 동일한 성격(사용자 작업), placeholder 아님.
- Task 14 Step 4 `$TOKEN`은 Step 3에서 받은 JWT 변수.

### Type consistency

- **JWT helper**: `verifyAccessToken(token)` Task 7 정의 / Task 9, 10, 12, 13에서 동일 시그니처 사용 ✓
- **Envelope**: `ok(data, opts?)` / `fail(code, message)` Task 6 정의 / 이후 모든 endpoint task에서 동일 사용 ✓
- **ErrorCode**: `UNAUTHORIZED, NOT_FOUND, VALIDATION_ERROR, INTERNAL` Task 6 정의 / Task 7~13에서 동일 import ✓
- **Profile / ApiJob / ApiJobCategory**: Task 16 freezed 모델 / Task 19, 20에서 동일 import ✓
- **JobsPage**: Task 20 정의 (items, total, page, limit) / Task 23, 25, 26에서 동일 사용 ✓
- **AuthRepository.verifyOtp**: Task 18 정의 (`Future<bool>`) / Task 22 화면에서 동일 시그니처 호출 ✓
- **ApiClient.dio**: Task 17 노출 / Task 19, 20, 21에서 `_api.dio` 동일 접근 ✓
- **SupabaseAuthApi**: Task 18 abstract / Task 22 mock에서 동일 메서드 4개 (`sendOtp`, `verifyOtp`, `currentAccessToken`, `signOut`) ✓

### 추가 검토 (advisor 피드백 반영 완료 — 2026-05-10)

**Bug 1 fix**: Task 1 Step 3 vitest.config.ts에 `test.env`로 dummy 환경변수 4개 주입. jwt.ts의 `getJWKS()` module-level env 검사 통과 보장.

**Bug 2 fix**: Task 17 Step 1 테스트에 `import 'dart:typed_data';` 추가 + matcher를 `isA<DioException>().having((e) => (e.error as ApiException).code, ...)` 형태로 변경. dio interceptor가 `handler.reject(DioException(error: ApiException(...)))` 형식으로 reject하므로 호출자는 DioException을 받아 e.error로 unwrap.

**Bug 3 fix**: Task 5 Step 3의 dev seed jobs INSERT를 Task 14 Step 1.5로 이동. SQL은 `'YOUR-USER-UUID'` placeholder 제거 후 `(select id from auth.users order by created_at desc limit 1)`로 runnable하게 변경. 첫 사용자 인증(Step 1.5 첫 부분) 후 실행되므로 FK 충돌 없음.

**Minor flag 1 fix**: Task 21 Step 2 router redirect에 try-catch 가드 추가. `Supabase.instance` 미초기화 시 AssertionError를 캐치하고 redirect 비활성화. 테스트·dev 환경에서 안전.

**Minor flag 2 fix**: Task 14 Step 3에 vercel CLI 호출이 interactive임을 명시 + dashboard import 대안 흐름 추가. 비대화형 subagent 환경에서 hang 방지.

**기타 보존 사항**:
- Task 22 PhoneAuthScreen `AppColors.error` 참조 — 기존 theme에 없으면 `Colors.red` 대체 (코멘트로 안내).
- Task 23 WorkerHomeScreen `_StatusPill`/`_MapPlaceholder`/`_SearchBar` private 클래스 보존 명시.
- Task 위젯 테스트들은 MaterialApp 직접 사용, router 미경유 → Supabase 미초기화 영향 없음.

### Type consistency 재검증 (advisor 피드백 후)

- **JWT helper**: `verifyAccessToken(token)` 단일 진입점, vitest env 주입으로 `getJWKS()` 통과 ✓
- **ApiClient interceptor**: `handler.reject(DioException(error: ApiException))` 일관 사용, 테스트 matcher 일치 ✓
- **OtpType.sms**: pub.dev 직접 확인(supabase_flutter 2.12.4 OtpType enum의 8개 값 중 `sms`) — Task 18 `_RealSupabaseAuthApi.verifyOtp`의 시그니처 정확 ✓
- **dev seed FK**: `auth.users` 첫 row 생성(Task 14 Step 1.5 첫 부분) 직후 실행되므로 `(select id from auth.users ... limit 1)` 안전 ✓
- **Router 가드 + Supabase init**: Task 15 `Supabase.initialize` → Task 21 redirect 안전 진입. 미초기화 환경은 try-catch로 graceful degradation ✓

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-10-m1-auth-job-list.md`.**

두 가지 실행 옵션:

1. **Subagent-Driven (recommended)** — 각 task마다 fresh subagent 디스패치 + 두 단계 리뷰(스펙 컴플라이언스 + 코드 품질) + task 사이 메인 세션 검토. R3 룰 준수, 본 plan은 SDD 적합.

2. **Inline Execution** — 메인 세션에서 batch 실행 + 체크포인트마다 수동 검토. 빠르지만 컨텍스트 부담 큼 (29 task × 평균 5 step = ~145 step).

**Subagent-Driven 권장 — 어느 쪽으로 진행할까?**
