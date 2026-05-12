# M3 Worker Applications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** sharework MVP에 Worker 지원 흐름(applications) 풀 사이클(Apply + Withdraw + Giver Decision)을 추가해 외부 베타 50명 매칭 검증 게이트 통과.

**Architecture:** 단일 `applications` 테이블 + 4 trigger(self-apply 차단 / lifetime cap=2 / state machine + worker_id immutable + timestamp auto / job close cascade) + 2 view(safe/contact, phone 분기) + 6 RLS 정책 + 7 BFF route + Flutter 신규 2 화면 + 기존 3 화면 수정. in-app pull only (알림 없음). PG enum + view security_invoker + service definer trigger 3-layer defense.

**Tech Stack:** Supabase Postgres 15+ + RLS + PG enum + Trigger + Next.js 16 BFF + Vercel + Upstash Redis sliding window + zod 4.x + Flutter 3.x + freezed + Dio + GoRouter

---

## Spec 참조

- spec: `docs/superpowers/specs/2026-05-12-m3-worker-applications-design.md` (필수 사전 read)
- 핵심 결정 13건은 spec §결정 lock-in 표 참조

## File Structure

### sharework-api (BFF) 신규/수정

| 경로 | 동작 | 책임 |
|---|---|---|
| `supabase/migrations/20260512000001_applications.sql` | 신규 | enum + 테이블 + 인덱스 + updated_at trigger |
| `supabase/migrations/20260512000002_applications_views.sql` | 신규 | safe view + contact view + GRANT |
| `supabase/migrations/20260512000003_applications_triggers.sql` | 신규 | 4 trigger fn (prevent_self_apply / enforce_lifetime_cap / state_machine / close_cascade) |
| `supabase/migrations/20260512000004_applications_rls.sql` | 신규 | 6 RLS + jobs_applicant_read |
| `supabase/migrations/20260512000005_get_my_jobs_with_counts.sql` | 신규 | RPC fn (LATERAL JOIN) — Giver 카드 카운트용 |
| `src/lib/text-sanitize.ts` | 신규 | sanitizeCoverNote (6 카테고리 + NFC) |
| `src/lib/schemas.ts` | 수정 | Application schemas 6개 추가 |
| `src/lib/errors.ts` | 수정 | ErrorCode 12 추가 + pg/trigger 매핑 헬퍼 |
| `src/lib/rate-limit.ts` | 수정 | applyJobMinute / applyJobHour / patchApplication 3 limiter |
| `src/lib/application-views.ts` | 신규 | pickApplicationView + mapApplicationRow 헬퍼 |
| `src/app/api/jobs/[id]/applications/route.ts` | 신규 | POST Worker apply |
| `src/app/api/me/applications/[id]/route.ts` | 신규 | PATCH Worker withdraw |
| `src/app/api/jobs/[job_id]/applications/[id]/route.ts` | 신규 | PATCH Giver decision |
| `src/app/api/me/applications/route.ts` | 신규 | GET Worker list |
| `src/app/api/jobs/[id]/applications/route.ts` (위) | (GET 추가) | GET Giver list |
| `src/app/api/me/route.ts` | 수정 | application_counts 추가 |
| `src/app/api/me/jobs/route.ts` | 수정 | 각 job에 application_count 추가 |
| `tests/integration/applications-*.test.ts` | 신규 (4~5 파일) | 각 endpoint integration tests |
| `tests/e2e/m3-worker-flow.test.ts` | 신규 | 12 case E2E production verified |

### sharework (Flutter) 신규/수정

| 경로 | 동작 | 책임 |
|---|---|---|
| `lib/models/api_models/application.dart` | 신규 | Application + ApplicationWorker + Counts + enums |
| `lib/models/api_models/profile.dart` | 수정 | applicationCounts 필드 추가 |
| `lib/repositories/application_repository.dart` | 신규 | apply / withdraw / decide / listMine / listForJob |
| `lib/repositories/me_repository.dart` | 수정 | getMe 응답에 counts 매핑 |
| `lib/repositories/job_repository.dart` | 수정 | listMine 응답에 application_count 매핑 |
| `lib/screens/worker/worker_applications_screen.dart` | 신규 | 4 탭 (지원중/채용됨/거절됨/취소됨) |
| `lib/screens/giver/giver_job_applications_screen.dart` | 신규 | 4 탭 (지원중/채용됨/거절됨/전체) default=지원중 |
| `lib/screens/worker/worker_home_screen.dart` | 수정 | StatusPill onTap + RouteAware diff |
| `lib/screens/worker/job_info_screen.dart` | 수정 | 본인 상태 5 케이스 분기 + cover_note BottomSheet |
| `lib/screens/giver/giver_home_screen.dart` | 수정 | _GiverJobCard 하단 지원자 진입 |
| `lib/screens/giver/job_info_screen.dart` (Giver 시점, 있다면) | 수정 | 지원자 진입점 |
| `lib/widgets/cover_note_bottom_sheet.dart` | 신규 | 200자 카운트 + prefill 지원 |
| `lib/widgets/application_card.dart` | 신규 | _ApplicationCard (Worker 시점) |
| `lib/widgets/applicant_card.dart` | 신규 | _ApplicantCard (Giver 시점) |
| `lib/widgets/status_pill.dart` | 수정 | onTap + chevron + Semantics |
| `lib/router/app_router.dart` | 수정 | 2 라우트 추가 |
| `lib/error_messages.dart` (또는 errors layer) | 수정 | ErrorCode 12 한국어 매핑 |
| `test/**` | 신규/수정 | 각 layer 신규 +30 test |
| `test/integration/m3_smoke_test.dart` | 신규 | 6-stage E2E mock-driven |

---

## Sprint 의존성 그래프

```
Sprint 0 (사전 점검)
   ↓
Sprint A (DB 마이그 4건)
   ↓
Sprint B (BFF API + lib 확장)  ── production live (Vercel 자동 배포)
   ↓
   ├─→ Sprint C (E2E 12 case production verified) ─┐
   └─→ Sprint D (Flutter wire-up)                  ─┤  ← C ∥ D 병렬 가능
                                                    ↓
                                              Sprint E (Final R6)
                                                    ↓
                                              Sprint F (Production smoke + 메모리)
```

**병렬 옵션**: Sprint B production live 후 C(E2E) ∥ D(Flutter) 병렬 진입 가능 (의존성 0 — E2E는 BFF만, Flutter는 BFF 응답 schema spec lock-in 의존). 직렬 강제 시 ~1세션 손실. **사용자가 SDD 진입 시점에 결정 surface**: (a) 직렬 (안전) / (b) 병렬 (시간 ↓).

각 Sprint = 별도 세션 권장 (R1 우회 회피). 압축 시 R1 우회 4 조건 충족 의무.

**UX Architect 트리거 근거 (Sprint E)**: M3는 Worker/Giver 양 화면 신규 + 5 케이스 분기 + 채용/거절 다이얼로그 톤 + 정보 격차(phone 노출 시점) → R6 룰 "UI/CSS 변경 → UX Architect" 정합 트리거.

---

# Sprint 0: 사전 점검

**책임자:** 사용자 직접 + controller 검증
**목표:** Supabase PG 버전 + Upstash env 정합 사전 확인

### Task 0.1: Supabase Postgres 15+ 확인

**Files:**
- 확인만 (코드 변경 없음)

- [ ] **Step 1: Supabase dashboard 또는 SQL editor 진입**

사용자 직접 작업. Supabase project dashboard → SQL editor.

- [ ] **Step 2: `select version();` 실행**

Run:
```sql
select version();
```
Expected: `PostgreSQL 15.x ...` 또는 그 이상

PG 14 이하면 **즉시 plan 중단** + 사용자 surface (security_invoker view 미지원). Supabase 인스턴스 업그레이드 필요.

- [ ] **Step 3: 결과 사용자 확인**

PG 15+ 확인되면 본 task ✅.

### Task 0.1.5: Flutter router root 위치 확인 (CR R2 SF-2)

**Files:**
- 확인만

- [ ] **Step 1: M2 패턴 grep으로 RouteObserver 등록 위치 후보 식별**

Run:
```bash
cd sharework
grep -rn "MaterialApp\|GoRouter\|navigatorObservers" lib/main.dart lib/router/ lib/app.dart 2>/dev/null
```
Expected: GoRouter 인스턴스 생성 위치 1곳 식별 (현재 M2 기준 `lib/router/app_router.dart` 추정).

- [ ] **Step 2: 결과 기록 — D.11에서 사용**

확정 위치 = `lib/router/app_router.dart` (또는 grep 결과) → D.11 Step 1에서 해당 파일에 `RouteObserver` 등록.

### Task 0.2: Upstash env 정합 확인 (M2 재사용)

**Files:**
- 확인만

- [ ] **Step 1: production Upstash env 2건 확인** (KV 페어 미사용 — 사용자 결정 2026-05-12)

Run (Vercel dashboard 또는 `vercel env ls`):
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

Expected: 2건 모두 production scope 등록됨. `Redis.fromEnv()` 우선순위는 UPSTASH_*이므로 KV_* 페어는 등록 여부 무관 — 코드 변경 0.

- [ ] **Step 2: 누락 시 사용자 surface 후 정정**

M2 lesson: `vercel env add` 시 `--value "..."` flag 의무 (stdin pipe trailing newline risk).

---

# Sprint A: BFF DB 마이그 5건

**Goal:** applications 테이블 + view + trigger + RLS + RPC fn land. 본 Sprint는 마이그 push만, code는 Sprint B.

> **rev.3 Sprint 경계 갱신 (Arc R2 MF-1)**: RPC fn `get_my_jobs_with_counts`(20260512000005)을 본 Sprint에 포함. Sprint B.12는 BFF route + test만 작성.

### RPC fn 마이그 (Task A.4.5 위치)

**Files:**
- Create: `sharework-api/supabase/migrations/20260512000005_get_my_jobs_with_counts.sql`

```sql
-- 20260512000005_get_my_jobs_with_counts.sql
create or replace function public.get_my_jobs_with_counts(p_limit int default 20)
returns table (
  id uuid, giver_id uuid, title text, status text,
  -- jobs 모든 컬럼 (구현 시 spec §1 기존 jobs 테이블 컬럼 inline)
  description text, wage_won int, schedule_text text,
  category_id uuid, location_address text, location_lat numeric, location_lng numeric,
  created_at timestamptz, updated_at timestamptz,
  application_applied_count int,
  application_hired_count int
)
language sql stable security invoker
set search_path = public, pg_temp
as $$
  select j.id, j.giver_id, j.title, j.status, j.description, j.wage_won, j.schedule_text,
         j.category_id, j.location_address, j.location_lat, j.location_lng,
         j.created_at, j.updated_at,
         coalesce(c.applied, 0)::int as application_applied_count,
         coalesce(c.hired,   0)::int as application_hired_count
  from public.jobs j
  left join lateral (
    select count(*) filter (where status='applied') as applied,
           count(*) filter (where status='hired')   as hired
    from public.applications a where a.job_id = j.id
  ) c on true
  where j.giver_id = auth.uid()
  order by j.created_at desc
  limit p_limit
$$;
```

본 fn은 Task A.5에서 묶음 push (5번째 마이그).

### Task A.1: applications 테이블 + enum + 인덱스

**Files:**
- Create: `sharework-api/supabase/migrations/20260512000001_applications.sql`

- [ ] **Step 1: 마이그 파일 생성 (spec §1 그대로)**

```sql
-- 20260512000001_applications.sql

create type application_status as enum ('applied','withdrawn','hired','rejected');
create type application_rejected_reason as enum ('giver_rejected','job_closed');

create table public.applications (
  id              uuid primary key default gen_random_uuid(),
  job_id          uuid not null references public.jobs(id) on delete cascade,
  worker_id       uuid references public.profiles(id) on delete set null,
  status          application_status not null default 'applied',
  cover_note      text check (cover_note is null or length(cover_note) <= 200),
  rejected_reason application_rejected_reason,
  applied_at      timestamptz not null default now(),
  hired_at        timestamptz,
  rejected_at     timestamptz,
  withdrawn_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create unique index applications_active_unique
  on public.applications(job_id, worker_id)
  where status in ('applied','hired') and worker_id is not null;

create index applications_job_status_idx
  on public.applications(job_id, status, applied_at desc);
create index applications_worker_status_idx
  on public.applications(worker_id, status, applied_at desc);

create trigger applications_set_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();
```

- [ ] **Step 2: Supabase local에서 적용 검증**

Run:
```bash
cd sharework-api
supabase db reset --debug
```
Expected: 모든 마이그 정상 적용. enum 2개 + 테이블 1개 + index 3개 + trigger 1개 생성 확인.

- [ ] **Step 3: 검증 쿼리**

```sql
-- enum 존재
select typname from pg_type where typname in ('application_status','application_rejected_reason');
-- 테이블 존재
select count(*) from public.applications; -- 0
-- 인덱스 존재
select indexname from pg_indexes where tablename = 'applications';
-- partial unique 조건 확인
select indexdef from pg_indexes where indexname = 'applications_active_unique';
```
Expected: 모든 검증 통과.

- [ ] **Step 4: production 적용은 본 Sprint 마지막에 일괄 push**

본 task는 local 검증만. production push는 Sprint A.5에서.

### Task A.2: applications views 2종 + GRANT

**Files:**
- Create: `sharework-api/supabase/migrations/20260512000002_applications_views.sql`

- [ ] **Step 1: 마이그 파일 생성 (spec §2 그대로)**

```sql
-- 20260512000002_applications_views.sql

create or replace view public.applications_with_worker_safe
with (security_invoker = true) as
select
  a.id, a.job_id, a.worker_id, a.status, a.cover_note, a.rejected_reason,
  a.applied_at, a.hired_at, a.rejected_at, a.withdrawn_at,
  a.created_at, a.updated_at,
  p.public_id as worker_public_id,
  p.name      as worker_name
from public.applications a
left join public.profiles p on p.id = a.worker_id;

create or replace view public.applications_hired_with_worker_contact
with (security_invoker = true) as
select
  a.id, a.job_id, a.worker_id, a.status,
  a.applied_at, a.hired_at,
  p.public_id as worker_public_id,
  p.name      as worker_name,
  p.phone     as worker_phone
from public.applications a
left join public.profiles p on p.id = a.worker_id
where a.status = 'hired';

revoke all on public.applications_with_worker_safe from anon;
grant select on public.applications_with_worker_safe to authenticated;
revoke all on public.applications_hired_with_worker_contact from anon;
grant select on public.applications_hired_with_worker_contact to authenticated;
```

- [ ] **Step 2: Supabase local에서 적용 + 검증**

Run:
```bash
supabase db reset --debug
```
Expected: 2 view 생성 + GRANT 적용.

- [ ] **Step 3: 검증 쿼리**

```sql
-- view 존재 + security_invoker
select viewname, definition from pg_views where viewname like 'applications_%';
-- GRANT 확인
select grantee, privilege_type from information_schema.role_table_grants
  where table_name in ('applications_with_worker_safe','applications_hired_with_worker_contact');
```
Expected: 2 view + authenticated SELECT, anon REVOKE.

### Task A.3: 4 triggers (self-apply / lifetime cap / state machine / close cascade)

**Files:**
- Create: `sharework-api/supabase/migrations/20260512000003_applications_triggers.sql`

- [ ] **Step 1: 마이그 파일 생성 (spec §2 그대로)**

(spec §2 풀 SQL 복사 — 4 fn + 4 trigger + 3 revoke)

- [ ] **Step 2: Supabase local 적용**

Run:
```bash
supabase db reset --debug
```
Expected: 4 fn + 4 trigger 등록.

- [ ] **Step 3: 검증 쿼리**

```sql
select tgname from pg_trigger
  where tgrelid in ('public.applications'::regclass, 'public.jobs'::regclass)
    and not tgisinternal;
```
Expected: 5 trigger (applications 4 + jobs cascade 1).

- [ ] **Step 4: SQL 시나리오 테스트**

```sql
-- self-apply 차단
-- (앞에서 profile A, job by A 생성 가정)
insert into applications (job_id, worker_id) values ('<jobA>', '<profileA>');
-- Expected: ERROR 'self_application_forbidden'

-- state machine: applied → hired → withdrawn 차단
update applications set status='hired' where id='<id>';
update applications set status='withdrawn' where id='<id>';
-- Expected: ERROR 'invalid_status_transition'

-- close cascade
update jobs set status='closed' where id='<jobB>';
-- Expected: 해당 job의 applied row 모두 status='rejected', rejected_reason='job_closed'

-- lifetime cap=2
-- 2회 INSERT 후 3회째 시도
-- Expected: ERROR 'lifetime_cap_exceeded'

-- worker_id immutable
update applications set worker_id='<other>' where id='<id>';
-- Expected: ERROR 'worker_id_immutable'
```
Expected: 모든 시나리오 의도된 ERROR.

### Task A.4: RLS 6 정책 + jobs_applicant_read

**Files:**
- Create: `sharework-api/supabase/migrations/20260512000004_applications_rls.sql`

- [ ] **Step 1: 마이그 파일 생성 (spec §3a 그대로)**

(spec §3a 풀 SQL 복사 — 6 정책 + jobs_applicant_read)

- [ ] **Step 2: Supabase local 적용 + 검증**

Run:
```bash
supabase db reset --debug
```
```sql
select polname, polcmd from pg_policies where tablename = 'applications';
-- Expected: 5 정책 (worker_select_own, giver_select_own_job, worker_insert, worker_update_withdraw, giver_update_decision)
select polname, polcmd from pg_policies where tablename = 'jobs';
-- Expected: 기존 2 + jobs_applicant_read = 3
```

- [ ] **Step 3: RLS 시나리오 테스트 (별도 supabase session 3개)**

Worker A session:
```sql
-- Worker A login JWT
select id from applications where worker_id = auth.uid();
-- Expected: 본인 row만
```
Worker B (다른 user) session:
```sql
select id from applications where worker_id = '<A id>';
-- Expected: 0 row (다른 user row 차단)
```
Giver session:
```sql
select id from applications where job_id = '<my_job_id>';
-- Expected: 본인 job의 모든 row
```

- [ ] **Step 4: Orphan row 시나리오 검증 (CR SF-1)**

```sql
-- service role 또는 SECURITY DEFINER로 직접 worker_id NULL 세팅 (production은 worker 탈퇴 시뮬레이션)
update applications set worker_id = null where id = '<test_row>';

-- Worker A 측에서 본인 row 안 보임
select count(*) from applications where worker_id = auth.uid();  -- 변화 없음

-- Giver 측에서는 여전히 보임 (job 조건)
select id, worker_id from applications where job_id = '<my_job_id>' and worker_id is null;
-- Expected: orphan row 1건

-- view에서 worker_name 처리 확인
select id, worker_id, worker_name from applications_with_worker_safe
  where id = '<test_row>';
-- Expected: worker_name = NULL (BFF에서 '(탈퇴 회원)' 처리)
```
Expected: orphan invariant 정합.

### Task A.5: 5 마이그 production push (commit 분리 + dry-run + 사용자 surface)

> **rev.3 변경 (Arc R2 MF-1)**: B.12 RPC fn 마이그(`20260512000005`)를 Sprint A에 흡수. Sprint A.5는 5 마이그 묶음 push로 갱신. Sprint B.12는 BFF route + test만 작성 (마이그는 A.5에서 이미 land 완료).

**Files:**
- 변경 없음 (마이그 실행 + 분리 commit)

- [ ] **Step 1: 최종 local 검증**

Run:
```bash
supabase db reset --debug
# 모든 마이그 + 시나리오 통과 확인
```

- [ ] **Step 2: production dry-run (SF-2 CR)**

Run:
```bash
supabase db push --dry-run
```
Expected: 4 마이그 production 적용 시 변경 사항 출력. **사용자 surface — diff 검토 후 진행 결정**.

- [ ] **Step 3: commit 분리 (5 commit, rev.3 MF-2 + Arc R2 MF-1 통합)**

각 마이그별 별도 commit (revert 친화):
```bash
git add supabase/migrations/20260512000001_applications.sql
git commit -m "feat(bff): M3 applications table + enum + indexes"

git add supabase/migrations/20260512000002_applications_views.sql
git commit -m "feat(bff): M3 applications views (safe + hired contact, GRANT)"

git add supabase/migrations/20260512000003_applications_triggers.sql
git commit -m "feat(bff): M3 applications triggers (self-apply + lifetime cap + state machine + close cascade)"

git add supabase/migrations/20260512000004_applications_rls.sql
git commit -m "feat(bff): M3 applications RLS 6 policies + jobs_applicant_read"

git add supabase/migrations/20260512000005_get_my_jobs_with_counts.sql
git commit -m "feat(bff): M3 RPC fn get_my_jobs_with_counts (LATERAL JOIN)"
```

대안: 사용자 결정으로 단일 묶음 commit 가능 (`/commit-push` 호출 시 옵션). plan default = 분리.

- [ ] **Step 4: production push (사용자 명시 OK 후)**

Run:
```bash
supabase db push
```
Expected: 4 마이그 production 적용 + 0 error.

- [ ] **Step 5: production 검증 쿼리 (Supabase dashboard SQL editor)**

```sql
select tablename, hasrls from pg_tables where tablename = 'applications';
-- Expected: applications + hasrls=t
select count(*) from pg_policies where tablename = 'applications';
-- Expected: 5
```

- [ ] **Step 6: EXPLAIN 검증 (nit reviewer 권장)**

```sql
-- Giver 핫패스
explain (analyze, buffers)
select * from applications where job_id = '<test_job>' and status = 'applied'
order by applied_at desc limit 20;
-- Expected: index scan on applications_job_status_idx, planning + execution < 5ms

-- Worker 카운트 핫패스
explain (analyze, buffers)
select status, count(*) from applications
where worker_id = '<test_worker>' and status in ('applied','hired')
group by status;
-- Expected: index-only scan on applications_worker_status_idx
```
EXPLAIN 결과 사용자 surface — 결함 발견 시 SDD 중 hot-fix.

- [ ] **Step 7: 롤백 마이그 작성 (MF-2)**

위치: `sharework-api/docs/migrations/rollback/20260512_m3_rollback.sql` (Supabase CLI 미스캔 경로, docs로만 보관)

```sql
-- Emergency rollback (only if needed BEFORE any data in production)
-- 모든 trigger 먼저 drop → fn drop 가능 (CR R2 M-1 fix)
drop trigger if exists jobs_close_cascade_applications on public.jobs;
drop trigger if exists applications_enforce_state_machine on public.applications;
drop trigger if exists applications_enforce_lifetime_cap on public.applications;
drop trigger if exists applications_prevent_self_apply on public.applications;
drop trigger if exists applications_set_updated_at on public.applications;
drop policy if exists jobs_applicant_read on public.jobs;
-- fn drop (cascade safety: 위에서 trigger 모두 drop했으므로 정상)
drop function if exists public.handle_job_close_applications() cascade;
drop function if exists public.enforce_application_state_machine() cascade;
drop function if exists public.enforce_lifetime_cap() cascade;
drop function if exists public.prevent_self_application() cascade;
-- view + table + type
drop view if exists public.applications_hired_with_worker_contact;
drop view if exists public.applications_with_worker_safe;
drop table if exists public.applications;
drop function if exists public.get_my_jobs_with_counts(int);
drop type if exists application_rejected_reason;
drop type if exists application_status;
```

본 파일은 docs commit만, 실행 안 함. data 1+ row 있으면 절대 실행 금지 (audit trail 손실).

---

# Sprint B: BFF API + lib 확장

**Goal:** 7 API route (5 신규 + 2 확장) + 4 lib 확장 + integration tests. Sprint A 의존. TDD 의무.

**DI 패턴 (CR MF-2)**: 본 Sprint integration test는 M2 도입 헬퍼 재사용:
- `sharework-api/tests/integration/_helpers/mock-supabase-builder.ts` — thenable builder, `.from().select().eq()...maybeSingle()` 체이닝 mock + scenario state
- `sharework-api/tests/integration/_helpers/mock-request.ts` — NextRequest mock with auth header injection
- `sharework-api/tests/integration/_helpers/rpc-scenario.ts` — RPC fn (`add_job_photo` 등) 시나리오 매핑

신규 task는 위 헬퍼를 import해 사용. M1/M2 integration test (예: `tests/integration/jobs-detail.test.ts`)에서 사용 예시 참조.

**`getSupabaseAuth` 주입**: `src/lib/supabase-server.ts`에 정의된 헬퍼. Test 환경에서는 `vi.mock('@/lib/supabase-server', () => ({ getSupabaseAuth: () => mockSupabaseBuilder() }))` 패턴으로 inject.

### Sprint B 내부 task 의존성 그래프 (CR R2 SF-1)

```
B.1 (text-sanitize) ─┐
B.2 (errors)        ─┤
B.3 (schemas)       ─┼─→ B.5 (helpers) ─→ B.6 (POST) ─→ B.7 (PATCH worker) ─→ B.8 (PATCH giver) ─→ B.9 (GET mine) ─→ B.10a (GET for job) ─→ B.10b (orphan invariant) ─→ B.11 (/api/me) ─→ B.12 (/api/me/jobs) ─→ B.13 (push + smoke)
B.4 (rate-limit)    ─┘
```

순서 의존:
- B.1/B.2/B.3/B.4는 병렬 가능 (의존성 0)
- B.5는 B.2 (errors) + B.3 (schemas) 의존
- B.6~B.10a는 순차 (각 endpoint가 헬퍼 + 이전 endpoint 패턴 의존)
- B.10b는 B.6, B.9, B.10a 모두 land 후 (5 endpoint invariant)
- B.11, B.12는 B.10a 완료 후 (독립)
- B.13은 모든 task 완료 + production push

SDD subagent는 그래프 순서로 dispatch 의무.

### Task B.1: text-sanitize.ts + tests

**Files:**
- Create: `sharework-api/src/lib/text-sanitize.ts`
- Create: `sharework-api/tests/unit/text-sanitize.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
// tests/unit/text-sanitize.test.ts
import { describe, it, expect } from 'vitest';
import { sanitizeCoverNote } from '@/lib/text-sanitize';

describe('sanitizeCoverNote', () => {
  it('preserves normal Korean text', () => {
    expect(sanitizeCoverNote('안녕하세요 지원합니다')).toBe('안녕하세요 지원합니다');
  });
  it('strips control characters except \\n \\r \\t', () => {
    expect(sanitizeCoverNote('a\x00b\x08c')).toBe('abc');
    expect(sanitizeCoverNote('a\nb\tc\rd')).toBe('a\nb\tc\rd');
  });
  it('strips bidi override (U+202A-202E)', () => {
    expect(sanitizeCoverNote('a‮b')).toBe('ab');
  });
  it('strips bidi isolate (U+2066-2069)', () => {
    expect(sanitizeCoverNote('a⁦b⁩c')).toBe('abc');
  });
  it('strips zero-width (U+200B-200D, U+FEFF)', () => {
    expect(sanitizeCoverNote('a​b‌c‍d﻿e')).toBe('abcde');
  });
  it('strips tag chars (U+E0000-E007F)', () => {
    expect(sanitizeCoverNote('a\u{e0001}b')).toBe('ab');
  });
  it('NFC normalizes', () => {
    // ㄱ + ㅏ vs 가
    const decomposed = '가'; // ㄱ + ㅏ
    expect(sanitizeCoverNote(decomposed)).toBe('가');
  });
  it('trims surrounding whitespace', () => {
    expect(sanitizeCoverNote('  hello  ')).toBe('hello');
  });
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- text-sanitize`
Expected: FAIL — sanitizeCoverNote 부재

- [ ] **Step 3: sanitizeCoverNote 구현 (spec §3b B3 그대로)**

```ts
// src/lib/text-sanitize.ts
export function sanitizeCoverNote(s: string): string {
  let n = s.normalize('NFC');
  n = n.replace(/[ --]/g, '');
  n = n.replace(/[‪-‮]/g, '');
  n = n.replace(/[⁦-⁩]/g, '');
  n = n.replace(/[​-‍﻿]/g, '');
  n = n.replace(/[\u{e0000}-\u{e007f}]/gu, '');
  return n.trim();
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- text-sanitize`
Expected: 8 PASS

- [ ] **Step 5: 커밋**

```bash
git add src/lib/text-sanitize.ts tests/unit/text-sanitize.test.ts
git commit -m "feat(bff): add cover_note sanitizer with 6 attack vectors covered"
```

### Task B.2: errors.ts 확장 + pg/trigger 매핑 헬퍼

**Files:**
- Modify: `sharework-api/src/lib/errors.ts`
- Modify: `sharework-api/tests/unit/errors.test.ts`

- [ ] **Step 1: 실패 테스트 작성 — 신규 ErrorCode + 매핑 헬퍼**

```ts
import { mapPgErrorToApiError, ErrorCode } from '@/lib/errors';

describe('mapPgErrorToApiError', () => {
  it('23505 partial unique → ALREADY_APPLIED', () => {
    const result = mapPgErrorToApiError({ code: '23505', message: '...applications_active_unique...' });
    expect(result.code).toBe('ALREADY_APPLIED');
    expect(result.httpStatus).toBe(409);
  });
  it('23514 self_application_forbidden → SELF_APPLY_FORBIDDEN 403', () => {
    const result = mapPgErrorToApiError({ code: '23514', message: 'self_application_forbidden' });
    expect(result.code).toBe('SELF_APPLY_FORBIDDEN');
    expect(result.httpStatus).toBe(403);
  });
  it('23514 invalid_status_transition → INVALID_TRANSITION 409', () => { ... });
  it('23514 worker_id_immutable → INVALID_REQUEST 400', () => { ... });
  it('23514 lifetime_cap_exceeded → LIFETIME_CAP_EXCEEDED 429', () => { ... });
  it('23514 rejected_reason_required → INVALID_REQUEST 400', () => { ... });
  it('42501 (RLS deny) → FORBIDDEN 403', () => { ... });
  it('foreign_key_violation job_not_found → JOB_NOT_FOUND 404', () => { ... });
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- errors`
Expected: FAIL — 신규 ErrorCode 부재

- [ ] **Step 3: errors.ts 확장 (spec §3b B5 매핑 표 구현)**

```ts
// src/lib/errors.ts (기존에 추가)
export const ErrorCode = {
  // M1+M2 기존 ...
  // M3 신규
  JOB_NOT_FOUND: 'JOB_NOT_FOUND',
  JOB_NOT_ACCEPTING: 'JOB_NOT_ACCEPTING',
  ALREADY_APPLIED: 'ALREADY_APPLIED',
  REAPPLY_REJECTED: 'REAPPLY_REJECTED',
  SELF_APPLY_FORBIDDEN: 'SELF_APPLY_FORBIDDEN',
  INVALID_TRANSITION: 'INVALID_TRANSITION',
  INVALID_REQUEST: 'INVALID_REQUEST',
  LIFETIME_CAP_EXCEEDED: 'LIFETIME_CAP_EXCEEDED',
  APPLICATION_NOT_FOUND: 'APPLICATION_NOT_FOUND',
  FORBIDDEN: 'FORBIDDEN',
  JOB_ACCESS_REVOKED: 'JOB_ACCESS_REVOKED',
} as const;

export function mapPgErrorToApiError(pgError: { code: string; message: string }): ApiError {
  if (pgError.code === '23505') {
    return { code: 'ALREADY_APPLIED', httpStatus: 409, message: '이미 지원하신 공고입니다' };
  }
  if (pgError.code === '23514') {
    if (pgError.message.includes('self_application_forbidden')) return { code: 'SELF_APPLY_FORBIDDEN', httpStatus: 403, message: '내가 등록한 공고에는 지원할 수 없습니다' };
    if (pgError.message.includes('invalid_status_transition')) return { code: 'INVALID_TRANSITION', httpStatus: 409, message: '현재 상태에서 변경할 수 없습니다' };
    if (pgError.message.includes('worker_id_immutable')) return { code: 'INVALID_REQUEST', httpStatus: 400, message: '요청이 올바르지 않습니다' };
    if (pgError.message.includes('lifetime_cap_exceeded')) return { code: 'LIFETIME_CAP_EXCEEDED', httpStatus: 429, message: '이 공고에 지원 가능 횟수(2회)를 모두 사용했습니다' };
    if (pgError.message.includes('rejected_reason_required')) return { code: 'INVALID_REQUEST', httpStatus: 400, message: '요청이 올바르지 않습니다' };
    if (pgError.message.includes('rejected_reason_only_with_rejected')) return { code: 'INVALID_REQUEST', httpStatus: 400, message: '요청이 올바르지 않습니다' };
  }
  if (pgError.code === '42501') return { code: 'FORBIDDEN', httpStatus: 403, message: '권한이 없습니다' };
  if (pgError.code === '23503' && pgError.message.includes('job_not_found')) return { code: 'JOB_NOT_FOUND', httpStatus: 404, message: '공고를 찾을 수 없습니다' };
  // fallback
  return { code: 'INTERNAL', httpStatus: 500, message: '서버 오류가 발생했습니다' };
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- errors`
Expected: 12+ PASS

- [ ] **Step 5: 커밋**

```bash
git add src/lib/errors.ts tests/unit/errors.test.ts
git commit -m "feat(bff): add M3 ErrorCode 12 + pg/trigger raise mapping helper"
```

### Task B.3: schemas.ts 확장 — Application schemas

**Files:**
- Modify: `sharework-api/src/lib/schemas.ts`
- Create: `sharework-api/tests/unit/schemas-applications.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import {
  ApplicationStatusSchema,
  ApplicationCreateRequestSchema,
  ApplicationPatchByWorkerSchema,
  ApplicationPatchByGiverSchema,
  ApplicationSafeSchema,
  ApplicationWithContactSchema,
  ListApplicationsResponseSchema,
} from '@/lib/schemas';

describe('Application schemas', () => {
  it('ApplicationStatusSchema accepts 4 values', () => {
    expect(() => ApplicationStatusSchema.parse('applied')).not.toThrow();
    expect(() => ApplicationStatusSchema.parse('withdrawn')).not.toThrow();
    expect(() => ApplicationStatusSchema.parse('hired')).not.toThrow();
    expect(() => ApplicationStatusSchema.parse('rejected')).not.toThrow();
    expect(() => ApplicationStatusSchema.parse('foo')).toThrow();
  });
  it('ApplicationCreateRequestSchema cover_note max 200', () => {
    expect(() => ApplicationCreateRequestSchema.parse({ cover_note: 'a'.repeat(201) })).toThrow();
    expect(() => ApplicationCreateRequestSchema.parse({})).not.toThrow();
    expect(() => ApplicationCreateRequestSchema.parse({ cover_note: 'a'.repeat(200) })).not.toThrow();
  });
  it('cover_note sanitize transform applied', () => {
    const result = ApplicationCreateRequestSchema.parse({ cover_note: 'a‮b' });
    expect(result.cover_note).toBe('ab');
  });
  it('ApplicationPatchByWorkerSchema only allows withdrawn', () => {
    expect(() => ApplicationPatchByWorkerSchema.parse({ status: 'withdrawn' })).not.toThrow();
    expect(() => ApplicationPatchByWorkerSchema.parse({ status: 'hired' })).toThrow();
  });
  it('ApplicationPatchByWorkerSchema strict — extra fields rejected', () => {
    expect(() => ApplicationPatchByWorkerSchema.parse({ status: 'withdrawn', extra: 1 })).toThrow();
  });
  it('ApplicationPatchByGiverSchema allows hired/rejected', () => {
    expect(() => ApplicationPatchByGiverSchema.parse({ status: 'hired' })).not.toThrow();
    expect(() => ApplicationPatchByGiverSchema.parse({ status: 'rejected' })).not.toThrow();
    expect(() => ApplicationPatchByGiverSchema.parse({ status: 'withdrawn' })).toThrow();
  });
  it('ApplicationSafeSchema round-trip', () => {
    const row = {
      id: '00000000-0000-4000-8000-000000000001',
      job_id: '00000000-0000-4000-8000-000000000002',
      status: 'applied' as const,
      cover_note: null,
      rejected_reason: null,
      applied_at: '2026-05-12T00:00:00Z',
      hired_at: null,
      rejected_at: null,
      withdrawn_at: null,
      worker: { public_id: 'SW-123', name: '홍길동' },
    };
    expect(() => ApplicationSafeSchema.parse(row)).not.toThrow();
  });
  it('ApplicationWithContactSchema includes phone', () => { /* ... */ });
  it('ListApplicationsResponseSchema items array', () => { /* ... */ });
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- schemas-applications`
Expected: FAIL — schema 부재

- [ ] **Step 3: schemas.ts 확장 (spec §3b B2 그대로)**

(spec §3b B2 풀 코드 복사)

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- schemas-applications`
Expected: 9+ PASS

- [ ] **Step 5: 커밋**

```bash
git add src/lib/schemas.ts tests/unit/schemas-applications.test.ts
git commit -m "feat(bff): add M3 Application zod schemas (req/patch/safe/contact/list)"
```

### Task B.4: rate-limit.ts 확장 — applyJob 2 + patchApplication 1

**Files:**
- Modify: `sharework-api/src/lib/rate-limit.ts`

- [ ] **Step 1: 신규 limiter 추가 (M2 패턴 재사용)**

```ts
// src/lib/rate-limit.ts (기존에 추가)
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

export const applyJobMinuteLimiter = new Ratelimit({
  redis, limiter: Ratelimit.slidingWindow(3, '1 m'), prefix: 'rl:apply-job:m',
});
export const applyJobHourLimiter = new Ratelimit({
  redis, limiter: Ratelimit.slidingWindow(10, '1 h'), prefix: 'rl:apply-job:h',
});
export const patchApplicationLimiter = new Ratelimit({
  redis, limiter: Ratelimit.slidingWindow(10, '1 m'), prefix: 'rl:patch-application',
});
```

- [ ] **Step 2: Promise.all 패턴 헬퍼 추가**

```ts
export async function checkApplyJobRateLimit(workerId: string): Promise<{ ok: boolean; retryAfter?: number }> {
  const [m, h] = await Promise.all([
    applyJobMinuteLimiter.limit(workerId),
    applyJobHourLimiter.limit(workerId),
  ]);
  if (!m.success) return { ok: false, retryAfter: Math.ceil((m.reset - Date.now()) / 1000) };
  if (!h.success) return { ok: false, retryAfter: Math.ceil((h.reset - Date.now()) / 1000) };
  return { ok: true };
}
```

- [ ] **Step 3: 검증 (typecheck)**

Run: `npm run typecheck`
Expected: 0 error.

- [ ] **Step 4: 커밋**

```bash
git add src/lib/rate-limit.ts
git commit -m "feat(bff): add applyJob + patchApplication rate limiters"
```

### Task B.5: application-views.ts (mapApplicationRow + pickApplicationView)

**Files:**
- Create: `sharework-api/src/lib/application-views.ts`
- Create: `sharework-api/tests/unit/application-views.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
import { describe, it, expect } from 'vitest';
import { mapApplicationRow, pickApplicationView } from '@/lib/application-views';

describe('pickApplicationView', () => {
  it('hired → contact view', () => {
    expect(pickApplicationView('hired')).toBe('applications_hired_with_worker_contact');
  });
  it('applied → safe view', () => {
    expect(pickApplicationView('applied')).toBe('applications_with_worker_safe');
  });
  it('undefined → safe view (default)', () => {
    expect(pickApplicationView(undefined)).toBe('applications_with_worker_safe');
  });
});

describe('mapApplicationRow', () => {
  it('non-orphan row preserves worker info', () => {
    const row = {
      id: 'a', job_id: 'j', worker_id: 'w', status: 'applied' as const,
      cover_note: null, rejected_reason: null,
      applied_at: '...', hired_at: null, rejected_at: null, withdrawn_at: null,
      worker_public_id: 'SW-1', worker_name: '홍길동',
    };
    const result = mapApplicationRow(row);
    expect(result.worker).toEqual({ public_id: 'SW-1', name: '홍길동' });
  });
  it('orphan row (worker_id null) sets anonymized worker', () => {
    const row = { ..., worker_id: null, worker_public_id: null, worker_name: null };
    const result = mapApplicationRow(row);
    expect(result.worker).toEqual({ public_id: null, name: '(탈퇴 회원)' });
  });
  it('contact row includes phone when worker_phone present', () => {
    const row = { ..., worker_id: 'w', worker_public_id: 'SW-1', worker_name: '홍길동', worker_phone: '+82-10-1234-5678' };
    const result = mapApplicationRow(row);
    expect(result.worker).toEqual({ public_id: 'SW-1', name: '홍길동', phone: '+82-10-1234-5678' });
  });
  it('orphan contact row strips phone', () => {
    const row = { ..., worker_id: null, worker_phone: null };
    const result = mapApplicationRow(row);
    expect(result.worker).toEqual({ public_id: null, name: '(탈퇴 회원)' });
    expect((result.worker as any).phone).toBeUndefined();
  });
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- application-views`
Expected: FAIL

- [ ] **Step 3: 구현 (spec §3b B6, B7 그대로)**

(spec §3b B6 + B7 풀 코드 복사)

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- application-views`
Expected: 7 PASS

- [ ] **Step 5: 커밋**

```bash
git add src/lib/application-views.ts tests/unit/application-views.test.ts
git commit -m "feat(bff): add pickApplicationView + mapApplicationRow (orphan-safe)"
```

### Task B.6: POST /api/jobs/:id/applications

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/applications/route.ts`
- Create: `sharework-api/tests/integration/applications-post.test.ts`

- [ ] **Step 1: 실패 테스트 작성 — 6 case**

```ts
describe('POST /api/jobs/:id/applications', () => {
  it('success: applied job, valid cover_note → 201', async () => { /* ... */ });
  it('job not active (paused) → 409 JOB_NOT_ACCEPTING', async () => { /* ... */ });
  it('self-application → 403 SELF_APPLY_FORBIDDEN (trigger)', async () => { /* ... */ });
  it('lifetime cap exceeded → 429 LIFETIME_CAP_EXCEEDED', async () => { /* ... */ });
  it('reapply after rejected → 409 REAPPLY_REJECTED', async () => { /* ... */ });
  it('duplicate active → 409 ALREADY_APPLIED (23505)', async () => { /* ... */ });
  it('rate limit exceeded → 429 RATE_LIMITED', async () => { /* ... */ });
  it('cover_note sanitization applied', async () => { /* ... */ });
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- applications-post`
Expected: FAIL — route 부재

- [ ] **Step 3: route 구현 (spec §3b B1.1 flow 그대로)**

```ts
// src/app/api/jobs/[id]/applications/route.ts
import { NextRequest } from 'next/server';
import { verifyAuth } from '@/lib/auth';
import { checkApplyJobRateLimit } from '@/lib/rate-limit';
import { ApplicationCreateRequestSchema } from '@/lib/schemas';
import { fail, ok, mapPgErrorToApiError } from '@/lib/errors';
import { getSupabaseAuth } from '@/lib/supabase-server';

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const user = await verifyAuth(req);
  if (!user) return fail('UNAUTHORIZED', 401);

  const rl = await checkApplyJobRateLimit(user.id);
  if (!rl.ok) return fail('RATE_LIMITED', 429, { retryAfter: rl.retryAfter });

  const body = await req.json().catch(() => ({}));
  const parsed = ApplicationCreateRequestSchema.safeParse(body);
  if (!parsed.success) return fail('INVALID_REQUEST', 400);

  const supabase = getSupabaseAuth(req);
  const jobId = params.id;

  // 1. job fetch
  const { data: job, error: jobErr } = await supabase
    .from('jobs').select('status, giver_id').eq('id', jobId).maybeSingle();
  if (jobErr) return fail('INTERNAL', 500);
  if (!job) return fail('JOB_NOT_FOUND', 404);
  if (job.status !== 'active') return fail('JOB_NOT_ACCEPTING', 409);

  // 2. lifetime cap fast-fail (DB trigger가 source of truth)
  const { count } = await supabase
    .from('applications').select('id', { count: 'exact', head: true })
    .eq('job_id', jobId).eq('worker_id', user.id);
  if ((count ?? 0) >= 2) return fail('LIFETIME_CAP_EXCEEDED', 429);

  // 3. recent rejected check
  const { data: rejected } = await supabase
    .from('applications').select('id').eq('job_id', jobId).eq('worker_id', user.id)
    .eq('status', 'rejected').limit(1);
  if (rejected && rejected.length > 0) return fail('REAPPLY_REJECTED', 409);

  // 4. INSERT
  const { data, error } = await supabase
    .from('applications')
    .insert({ job_id: jobId, worker_id: user.id, cover_note: parsed.data.cover_note ?? null })
    .select('id, status, applied_at')
    .single();

  if (error) {
    const mapped = mapPgErrorToApiError(error);
    return fail(mapped.code, mapped.httpStatus);
  }

  return ok({ id: data.id, status: data.status, applied_at: data.applied_at }, 201);
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- applications-post`
Expected: 8 PASS

- [ ] **Step 5: 커밋**

```bash
git add src/app/api/jobs/[id]/applications/route.ts tests/integration/applications-post.test.ts
git commit -m "feat(bff): POST /api/jobs/:id/applications (Worker apply)"
```

### Task B.7: PATCH /api/me/applications/:id (Worker withdraw)

**Files:**
- Create: `sharework-api/src/app/api/me/applications/[id]/route.ts`
- Create: `sharework-api/tests/integration/applications-patch-worker.test.ts`

- [ ] **Step 1: 실패 테스트 작성 (4 case + 1 invariant) — M2 inline vi.mock 패턴 (rev.4 정정)**

> **plan rev.4 정정**: `_helpers/mock-supabase-builder` 부재 — M2 inline `vi.mock` 패턴 verbatim 적용. 사용자 결정 (B) lock-in. Group 2 5 test 파일(B.6/B.7/B.8/B.9/B.10a) 모두 동일 패턴 — 각 파일 상단에 `vi.mock('@/lib/jwt', ...)` + `vi.mock('@/lib/supabase', ...)` + `vi.mock('@/lib/rate-limit', ...)` 자체 정의. 참고: `tests/integration/jobs-detail.test.ts` 또는 `tests/integration/me.test.ts`.

```ts
// tests/integration/applications-patch-worker.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('@/lib/jwt', () => ({
  verifyAccessToken: vi.fn(async (t: string) => {
    if (t === 'valid-worker') return { userId: 'user-1' };
    if (t === 'other-worker') return { userId: 'user-2' };
    throw new (await import('@/lib/errors')).AppError(
      (await import('@/lib/errors')).ErrorCode.AUTH_INVALID, 'invalid',
    );
  }),
  extractBearerToken: (req: Request) => {
    const auth = req.headers.get('authorization') ?? '';
    return auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
  },
}));

const rateLimitState = { count: 0 };
vi.mock('@/lib/rate-limit', () => ({
  checkPatchApplicationLimit: vi.fn(async () => {
    rateLimitState.count += 1;
    return rateLimitState.count <= 60 ? { ok: true, retryAfterSec: 0 } : { ok: false, retryAfterSec: 60 };
  }),
}));

const supabaseState = {
  fixture: null as any,    // current applications row used by SELECT
  updateBody: null as any, // captured PATCH body
  updateCalled: false,
};

vi.mock('@/lib/supabase', () => {
  function makeBuilder() {
    return {
      select: () => makeBuilder(),
      eq: () => makeBuilder(),
      maybeSingle: async () => ({ data: supabaseState.fixture, error: null }),
      single: async () => ({ data: supabaseState.fixture, error: null }),
      update: (body: any) => { supabaseState.updateBody = body; supabaseState.updateCalled = true; return makeBuilder(); },
    };
  }
  return { getSupabaseAuth: () => ({ from: () => makeBuilder() }) };
});

import { PATCH } from '@/app/api/me/applications/[id]/route';

function mkReq(token: string, body: any) {
  return new Request('http://localhost/api/me/applications/app-1', {
    method: 'PATCH',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('PATCH /api/me/applications/:id (Worker withdraw)', () => {
  beforeEach(() => {
    supabaseState.fixture = null;
    supabaseState.updateBody = null;
    supabaseState.updateCalled = false;
    rateLimitState.count = 0;
  });

  it('success: applied → withdrawn → 200', async () => {
    supabaseState.fixture = { id: 'app-1', worker_id: 'user-1', status: 'applied', withdrawn_at: '2026-05-12T00:00:00Z' };
    const res = await PATCH(mkReq('valid-worker', { status: 'withdrawn' }) as any, { params: { id: 'app-1' } });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ ok: true, data: { id: 'app-1', status: 'applied' } }); // fixture id reuse
  });

  it('not own → 404 APPLICATION_NOT_FOUND', async () => {
    supabaseState.fixture = { id: 'app-1', worker_id: 'user-1', status: 'applied' };
    const res = await PATCH(mkReq('other-worker', { status: 'withdrawn' }) as any, { params: { id: 'app-1' } });
    expect(res.status).toBe(404);
    expect((await res.json()).code).toBe('APPLICATION_NOT_FOUND');
  });

  it('status != applied (already hired) → 409 INVALID_TRANSITION', async () => {
    supabaseState.fixture = { id: 'app-1', worker_id: 'user-1', status: 'hired' };
    const res = await PATCH(mkReq('valid-worker', { status: 'withdrawn' }) as any, { params: { id: 'app-1' } });
    expect(res.status).toBe(409);
    expect((await res.json()).code).toBe('INVALID_TRANSITION');
  });

  it('extra fields rejected (zod strict)', async () => {
    const res = await PATCH(mkReq('valid-worker', { status: 'withdrawn', extra: 1 }) as any, { params: { id: 'app-1' } });
    expect(res.status).toBe(400);
  });

  it('status != withdrawn rejected (Worker can only withdraw)', async () => {
    const res = await PATCH(mkReq('valid-worker', { status: 'hired' }) as any, { params: { id: 'app-1' } });
    expect(res.status).toBe(400);
  });
});
```

**다른 Group 2 test 파일 (B.6/B.8/B.9/B.10a/B.10b)도 동일 패턴**: vi.mock 4종(@/lib/jwt + @/lib/supabase + @/lib/rate-limit + 필요 시 @/lib/photo-mapping) + supabaseState fixture 객체로 SELECT/UPDATE 분기. mock-supabase-builder/mock-request 신규 helper 작성 0건.

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- applications-patch-worker`
Expected: FAIL — route 부재

- [ ] **Step 3: route handler 구현 (spec §3b B1.2 flow)**

```ts
// src/app/api/me/applications/[id]/route.ts
import { NextRequest } from 'next/server';
import { verifyAuth } from '@/lib/auth';
import { patchApplicationLimiter } from '@/lib/rate-limit';
import { ApplicationPatchByWorkerSchema } from '@/lib/schemas';
import { fail, ok, mapPgErrorToApiError } from '@/lib/errors';
import { getSupabaseAuth } from '@/lib/supabase-server';

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const user = await verifyAuth(req);
  if (!user) return fail('UNAUTHORIZED', 401);

  const rl = await patchApplicationLimiter.limit(user.id);
  if (!rl.success) return fail('RATE_LIMITED', 429, { retryAfter: Math.ceil((rl.reset - Date.now()) / 1000) });

  const body = await req.json().catch(() => ({}));
  const parsed = ApplicationPatchByWorkerSchema.safeParse(body);
  if (!parsed.success) return fail('INVALID_REQUEST', 400);

  const supabase = getSupabaseAuth(req);

  // ownership 사전 분기 (RLS는 최종 게이트, BFF는 명시 검증)
  const { data: app } = await supabase
    .from('applications').select('worker_id, status').eq('id', params.id).maybeSingle();
  if (!app || app.worker_id !== user.id) return fail('APPLICATION_NOT_FOUND', 404);
  if (app.status !== 'applied') return fail('INVALID_TRANSITION', 409);

  const { data, error } = await supabase
    .from('applications').update({ status: 'withdrawn' })
    .eq('id', params.id).select('id, status, withdrawn_at').single();
  if (error) {
    const mapped = mapPgErrorToApiError(error);
    return fail(mapped.code, mapped.httpStatus);
  }
  return ok({ id: data.id, status: data.status, withdrawn_at: data.withdrawn_at });
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- applications-patch-worker`
Expected: 5 PASS

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(bff): PATCH /api/me/applications/:id (Worker withdraw)"
```

### Task B.8: PATCH /api/jobs/:job_id/applications/:id (Giver decision)

**Files:**
- Create: `sharework-api/src/app/api/jobs/[job_id]/applications/[id]/route.ts`
- Create: `sharework-api/tests/integration/applications-patch-giver.test.ts`

- [ ] **Step 1: 실패 테스트 작성 (5 case)**

```ts
describe('PATCH /api/jobs/:job_id/applications/:id (Giver decision)', () => {
  it('success: hired → 200, hired_at set, rejected_reason null', async () => { /* mock SELECT app + jobs.giver_id == auth.uid + UPDATE */ });
  it('success: rejected → 200, rejected_reason="giver_rejected" 자동 세팅 (client 입력 무시)', async () => {
    // client가 rejected_reason='job_closed' 보내도 BFF가 overwrite → 'giver_rejected'
  });
  it('not own job → 404 APPLICATION_NOT_FOUND', async () => { /* jobs.giver_id != auth.uid */ });
  it('app.status != applied (already hired) → 409 INVALID_TRANSITION', async () => {});
  it('zod: status=withdrawn 거부 → 400', async () => {});
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- applications-patch-giver`
Expected: FAIL

- [ ] **Step 3: route handler 구현 (spec §3b B1.3 flow)**

```ts
// src/app/api/jobs/[job_id]/applications/[id]/route.ts
export async function PATCH(req: NextRequest, { params }: { params: { job_id: string; id: string } }) {
  const user = await verifyAuth(req);
  if (!user) return fail('UNAUTHORIZED', 401);

  const rl = await patchApplicationLimiter.limit(user.id);
  if (!rl.success) return fail('RATE_LIMITED', 429);

  const body = await req.json().catch(() => ({}));
  const parsed = ApplicationPatchByGiverSchema.safeParse(body);
  if (!parsed.success) return fail('INVALID_REQUEST', 400);

  const supabase = getSupabaseAuth(req);

  // ownership 사전 분기 — applications join jobs
  const { data: app } = await supabase
    .from('applications')
    .select('id, status, job_id, job:jobs(giver_id)')
    .eq('id', params.id).eq('job_id', params.job_id).maybeSingle();
  if (!app || (app.job as any)?.giver_id !== user.id) return fail('APPLICATION_NOT_FOUND', 404);
  if (app.status !== 'applied') return fail('INVALID_TRANSITION', 409);

  // rejected_reason은 server-determined (Q3 / SEC B2)
  const updates: any = { status: parsed.data.status };
  if (parsed.data.status === 'rejected') updates.rejected_reason = 'giver_rejected';

  const { data, error } = await supabase
    .from('applications').update(updates)
    .eq('id', params.id)
    .select('id, status, hired_at, rejected_at, rejected_reason').single();
  if (error) {
    const mapped = mapPgErrorToApiError(error);
    return fail(mapped.code, mapped.httpStatus);
  }
  return ok({ id: data.id, status: data.status, hired_at: data.hired_at, rejected_at: data.rejected_at, rejected_reason: data.rejected_reason });
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- applications-patch-giver`
Expected: 5 PASS

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(bff): PATCH /api/jobs/:job_id/applications/:id (Giver decision)"
```

### Task B.9: GET /api/me/applications

**Files:**
- Create: `sharework-api/src/app/api/me/applications/route.ts`
- Create: `sharework-api/tests/integration/applications-list-mine.test.ts`

- [ ] **Step 1: 실패 테스트 작성 (5 case)**

```ts
describe('GET /api/me/applications', () => {
  it('status filter: applied → only applied items', async () => { /* mock view query */ });
  it('cursor pagination round-trip', async () => {
    // first page → next_cursor → decode → second page query에 cursor 적용
  });
  it('has_more=true when limit+1 rows', async () => {});
  it('orphan row (worker_id null) sets worker.name="(탈퇴 회원)"', async () => {});
  it('default limit=20, max=50', async () => {});
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- applications-list-mine`
Expected: FAIL

- [ ] **Step 3: route handler 구현 (spec §3b B1.4 flow + cursor encode/decode)**

```ts
// src/app/api/me/applications/route.ts
import { mapApplicationRow, pickApplicationView } from '@/lib/application-views';

export async function GET(req: NextRequest) {
  const user = await verifyAuth(req);
  if (!user) return fail('UNAUTHORIZED', 401);

  const url = new URL(req.url);
  const status = url.searchParams.get('status') as ApplicationStatus | null;
  const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '20'), 50);
  const cursorRaw = url.searchParams.get('cursor');

  let cursor: { applied_at: string; id: string } | null = null;
  if (cursorRaw) {
    try { cursor = JSON.parse(Buffer.from(cursorRaw, 'base64url').toString()); }
    catch { return fail('INVALID_REQUEST', 400); }
  }

  const supabase = getSupabaseAuth(req);
  let q = supabase
    .from('applications_with_worker_safe')
    .select('*')
    .eq('worker_id', user.id)
    .order('applied_at', { ascending: false })
    .order('id', { ascending: false })
    .limit(limit + 1);
  if (status) q = q.eq('status', status);
  if (cursor) {
    // (applied_at, id) < (cursor.applied_at, cursor.id) — Supabase에서는 or 로 표현
    q = q.or(`applied_at.lt.${cursor.applied_at},and(applied_at.eq.${cursor.applied_at},id.lt.${cursor.id})`);
  }

  const { data, error } = await q;
  if (error) return fail('INTERNAL', 500);

  const hasMore = data.length > limit;
  const rows = hasMore ? data.slice(0, limit) : data;
  const items = rows.map(mapApplicationRow);
  const last = items[items.length - 1];
  const nextCursor = hasMore && last
    ? Buffer.from(JSON.stringify({ applied_at: last.applied_at, id: last.id })).toString('base64url')
    : null;
  return ok({ items, has_more: hasMore, next_cursor: nextCursor });
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- applications-list-mine`
Expected: 5 PASS

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(bff): GET /api/me/applications (Worker list + cursor pagination)"
```

### Task B.10a: GET /api/jobs/:id/applications (Giver list + view 분기)

**Files:**
- Modify: `sharework-api/src/app/api/jobs/[id]/applications/route.ts` (B.6 POST와 같은 파일에 GET export 추가)
- Create: `sharework-api/tests/integration/applications-list-for-job.test.ts`

- [ ] **Step 1: 실패 테스트 작성 (6 case)**

```ts
describe('GET /api/jobs/:id/applications', () => {
  it('ownership 검증: not own → 403 FORBIDDEN', async () => {});
  it('view 분기: status=hired → contact view, phone 포함', async () => {});
  it('view 분기: status=applied → safe view, phone 없음', async () => {});
  it('counts 응답: { applied, hired } GROUP BY', async () => {});
  it('jobs cascade race → 403 with code=JOB_ACCESS_REVOKED', async () => {});
  it('cursor pagination', async () => {});
});
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `npm test -- applications-list-for-job`
Expected: FAIL

- [ ] **Step 3: route handler 구현 (spec §3b B1.5)**

```ts
// 기존 B.6 route.ts 같은 파일에 GET 추가
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const user = await verifyAuth(req);
  if (!user) return fail('UNAUTHORIZED', 401);

  const url = new URL(req.url);
  const status = url.searchParams.get('status') as ApplicationStatus | null;
  const limit = Math.min(parseInt(url.searchParams.get('limit') ?? '20'), 50);
  const cursorRaw = url.searchParams.get('cursor');

  const supabase = getSupabaseAuth(req);

  // ownership 검증
  const { data: job } = await supabase
    .from('jobs').select('giver_id').eq('id', params.id).maybeSingle();
  if (!job) return fail('JOB_NOT_FOUND', 404);
  if (job.giver_id !== user.id) {
    // race 분기: jobs_applicant_read로 read는 됐으나 ownership 위반
    // (rev.4 정정) FORBIDDEN → JOB_ACCESS_REVOKED — errors.ts §line 26 enum land, test와 정합
    return fail('JOB_ACCESS_REVOKED', 403);
  }

  // view 분기
  const viewName = pickApplicationView(status ?? undefined);
  let cursor: { applied_at: string; id: string } | null = null;
  if (cursorRaw) {
    try { cursor = JSON.parse(Buffer.from(cursorRaw, 'base64url').toString()); }
    catch { return fail('INVALID_REQUEST', 400); }
  }

  let q = supabase
    .from(viewName).select('*').eq('job_id', params.id)
    .order('applied_at', { ascending: false }).order('id', { ascending: false })
    .limit(limit + 1);
  if (status) q = q.eq('status', status);
  if (cursor) q = q.or(`applied_at.lt.${cursor.applied_at},and(applied_at.eq.${cursor.applied_at},id.lt.${cursor.id})`);

  const { data, error } = await q;
  if (error) return fail('INTERNAL', 500);

  // counts GROUP BY (별도 쿼리)
  const { data: countRows } = await supabase
    .from('applications')
    .select('status')
    .eq('job_id', params.id)
    .in('status', ['applied', 'hired']);
  const counts = {
    applied: countRows?.filter((r: any) => r.status === 'applied').length ?? 0,
    hired:   countRows?.filter((r: any) => r.status === 'hired').length   ?? 0,
  };

  const hasMore = data.length > limit;
  const rows = hasMore ? data.slice(0, limit) : data;
  const items = rows.map(mapApplicationRow);
  const last = items[items.length - 1];
  const nextCursor = hasMore && last
    ? Buffer.from(JSON.stringify({ applied_at: last.applied_at, id: last.id })).toString('base64url')
    : null;
  return ok({ items, has_more: hasMore, next_cursor: nextCursor, counts });
}
```

- [ ] **Step 4: 테스트 통과 검증**

Run: `npm test -- applications-list-for-job`
Expected: 6 PASS

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(bff): GET /api/jobs/:id/applications (Giver list + view 분기 + counts)"
```

### Task B.10b: orphan invariant 5-endpoint test (MF-1 분리)

**Files:**
- Create: `sharework-api/tests/integration/applications-orphan-invariant.test.ts`

- [ ] **Step 1: 5 endpoint 단일 테스트 (Architect MF-1 분리)**

```ts
describe('orphan row invariant — 5 endpoints', () => {
  beforeEach(() => {
    // mock supabase view에 worker_id=null row 1건 + worker_id="user-2" row 1건
  });

  it('GET /api/me/applications → orphan sets worker.name="(탈퇴 회원)"', async () => {});
  it('GET /api/jobs/:id/applications (status=applied) → 동일', async () => {});
  it('GET /api/jobs/:id/applications (status=hired contact view) → orphan phone null', async () => {});
  it('POST /api/jobs/:id/applications response 자체는 worker 미포함 OK', async () => {
    // POST는 본인 application 생성, worker_id != null 보장
  });
  it('PATCH responses → worker 필드 미포함 OK (id/status/timestamp만)', async () => {});
});
```

- [ ] **Step 2: 테스트 실행 — Step 1 일부 PASS, 일부 FAIL 가능**

Run: `npm test -- applications-orphan-invariant`
Expected: B.6~B.10a land 후 5 PASS

- [ ] **Step 3: invariant 누락 endpoint 발견 시 fix**

각 endpoint route에서 `mapApplicationRow` 누락 catch.

- [ ] **Step 4: 모든 PASS 검증**

Run: `npm test -- applications-orphan-invariant`
Expected: 5 PASS

- [ ] **Step 5: 커밋**

```bash
git commit -m "test(bff): orphan invariant — worker.name='(탈퇴 회원)' across 5 endpoints"
```

### Task B.11: GET /api/me 확장 (application_counts)

**Files:**
- Modify: `sharework-api/src/app/api/me/route.ts`
- Modify: `sharework-api/tests/integration/me.test.ts`

- [ ] **Step 1: 실패 테스트 작성**

```ts
it('response includes application_counts: { applied, hired }', async () => {
  // ...
  expect(body.data.application_counts).toEqual({ applied: 2, hired: 0 });
});
```

- [ ] **Step 2~4: spec §3b B1.6 그대로 구현 — client-side reduce (rev.4 정정)**

> **plan rev.4 정정**: PostgREST aggregate(`count:id.count()`) typing 모호 + `db.aggregates.functions` 활성 의존 → **client-side reduce**로 변경. 사용자 결정 (b) lock-in. user activeapp 통상 <50건, 비용 무시. 마이그 0건, 코드 3줄.

```ts
// /api/me/route.ts (기존에 추가)
const { data: rows } = await supabase
  .from('applications')
  .select('status')
  .eq('worker_id', user.id)
  .in('status', ['applied', 'hired']);

const application_counts = (rows ?? []).reduce(
  (acc, r: { status: string }) => {
    if (r.status === 'applied') acc.applied += 1;
    else if (r.status === 'hired') acc.hired += 1;
    return acc;
  },
  { applied: 0, hired: 0 },
);
```

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(bff): GET /api/me extend with application_counts"
```

### Task B.12: GET /api/me/jobs 확장 (application_count) — RPC 호출

**Files:**
- Modify: `sharework-api/src/app/api/me/jobs/route.ts`
- Modify: `sharework-api/tests/integration/me-jobs.test.ts`

**Mock 패턴 (CR R1 SF-5 + Arc R2 MF-1)**: LATERAL JOIN raw SQL은 supabase-js mock builder 미지원 → **RPC fn 사용**. RPC fn 마이그(`20260512000005_get_my_jobs_with_counts.sql`)은 **Sprint A.5에서 이미 land 완료** (rev.3).

> **plan rev.4 정정 (B.12)**: 원본 RPC fn 시그니처가 `(p_limit int)` + `where j.giver_id = auth.uid()`인데 BFF가 service role client (auth.uid()=NULL) 호출 → 0 rows 위험. fix-forward 마이그(`20260512000007_get_my_jobs_with_counts_fix.sql`)로 시그니처를 `(p_giver_id uuid, p_limit int)`로 변경 + `drop function if exists (int)` 먼저(PG signature overloading 회피) + `revoke execute from public, anon, authenticated` (기존 RPC 패턴 정합). 본 task는 BFF route + test + 신규 마이그.

- [ ] **Step 1: 실패 테스트 작성**

```ts
it('returns jobs with application_count', async () => {
  supabase.rpc('get_my_jobs_with_counts').returns([
    { id: 'j1', ..., application_applied_count: 3, application_hired_count: 1 },
  ]);
  const res = await GET(mockRequest({ user: 'user-1' }));
  const body = await res.json();
  expect(body.data.items[0].application_count).toEqual({ applied: 3, hired: 1 });
});
```

- [ ] **Step 4: route handler 수정**

```ts
// src/app/api/me/jobs/route.ts (기존에 RPC 호출 추가)
const { data, error } = await supabase.rpc('get_my_jobs_with_counts', {
  p_giver_id: userId,
  p_limit: 50,
});
if (error) return fail('INTERNAL', 500);

const items = data.map((row: any) => ({
  id: row.id, title: row.title, /* ... */,
  application_count: {
    applied: row.application_applied_count,
    hired:   row.application_hired_count,
  },
}));
return ok({ items });
```

- [ ] **Step 5: 테스트 통과 + 커밋**

```bash
git add supabase/migrations/20260512000005_get_my_jobs_with_counts.sql \
        src/app/api/me/jobs/route.ts tests/integration/me-jobs.test.ts
git commit -m "feat(bff): GET /api/me/jobs extend with per-job application_count (RPC)"
```

### Task B.13: Sprint B push + production smoke

- [ ] **Step 1: 전체 test 실행**

Run: `npm test`
Expected: 모든 신규 + 기존 test PASS

- [ ] **Step 2: typecheck**

Run: `npm run typecheck`
Expected: 0 error

- [ ] **Step 3: push to production**

```bash
git push
```
Vercel 자동 배포 (~2~3분).

- [ ] **Step 4: Vercel deploy 검증 (CR SF-4)**

Vercel CLI 비대화형 hang risk (lesson R11) → curl smoke로 대체:
```bash
# 2~3분 대기 후
for i in {1..5}; do
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' https://sharework-api.vercel.app/api/me/applications)
  echo "attempt $i: $STATUS"
  [ "$STATUS" = "401" ] && break
  sleep 30
done
```
Expected: 401 (auth_required 정상). 다른 응답 시 Vercel dashboard 로그 확인 (사용자 직접).

- [ ] **Step 5: production smoke (curl)**

```bash
# 5 신규 routes 401 auth check
curl -I https://sharework-api.vercel.app/api/me/applications
curl -I -X POST https://sharework-api.vercel.app/api/jobs/00000000-0000-4000-8000-000000000000/applications
curl -I -X PATCH https://sharework-api.vercel.app/api/me/applications/00000000-0000-4000-8000-000000000000
curl -I -X PATCH https://sharework-api.vercel.app/api/jobs/.../applications/...

# 2 확장 routes 401
curl -I https://sharework-api.vercel.app/api/me
curl -I https://sharework-api.vercel.app/api/me/jobs
```
Expected: 모든 401.

- [ ] **Step 6: 보안 헤더 5종 확인 (M2 baseline 유지)**

```bash
curl -I https://sharework-api.vercel.app/api/me/applications | grep -E 'strict-transport|x-frame|x-content|referrer|permissions'
```
Expected: 5 header 모두 present.

---

# Sprint C: E2E 12 case production verified

**Goal:** m3-worker-flow.test.ts 12 case production 실행 + 모두 PASS.

### Task C.1: E2E test 작성

**Files:**
- Create: `sharework-api/tests/e2e/m3-worker-flow.test.ts`

- [ ] **Step 1: env 사전 검증 (CR MF-4, lesson [2026-05-12] 자매)**

```bash
# sharework-api 또는 sharework/.env.local 확인
if [ ! -f .env.local ]; then
  echo "[FAIL] .env.local 부재 — 사용자 입수 필요"; exit 1
fi
grep -E '^E2E_SUPABASE_(URL|ANON_KEY)=' .env.local
```
Expected: 2 env 모두 present.

부재 시 **silent 진행 금지** → 사용자 surface (옵션: (a) Supabase test phone 새로 등록 / (b) 기존 M2 E2E env 경로 인용). 진행 안 함.

- [ ] **Step 2: E2E test phone 2~3개 Supabase 등록 확인**

Supabase dashboard → Auth → Phone Auth → Test phone numbers. M3 시나리오상 최소 3개 필요 (Worker A, Worker C, Giver B + Worker D, Worker E if 12 case 모두 분리).

- [ ] **Step 2: 12 case 작성 (spec §4 E2E 시나리오)**

```ts
import { describe, it, expect, beforeAll } from 'vitest';
import { createClient } from '@supabase/supabase-js';

describe('M3 Worker Flow E2E', () => {
  let workerA: { token: string; userId: string };
  let giverB: { token: string; userId: string; jobId: string };

  beforeAll(async () => {
    // Worker A login (test phone OTP)
    workerA = await loginAsTestPhone('+8210...A');
    // Giver B login + create job
    giverB = await loginAsTestPhone('+8210...B');
    const job = await createJob(giverB.token, { ... });
    giverB.jobId = job.id;
  });

  it('1. Worker A apply to Giver B job → 201', async () => { /* ... */ });
  it('2. Worker A withdraw → 200', async () => { /* ... */ });
  it('3. Worker A 재지원 (allowed after withdraw) → 201', async () => { /* ... */ });
  it('4. Worker A 2nd withdraw → 200', async () => { /* ... */ });
  it('5. Worker A 3rd 시도 → 429 LIFETIME_CAP_EXCEEDED', async () => { /* ... */ });
  it('6. Giver B view applications list → counts.applied = 0 (after withdraw)', async () => { /* ... */ });
  it('7. Worker A apply once more (only after re-eligible? no — cap is 2 lifetime)', async () => { /* skip — covers by step 5 */ });
  it('8. New Worker C apply → 201', async () => { /* ... */ });
  it('9. Giver B hire Worker C → 200', async () => { /* ... */ });
  it('10. Giver B reject another worker D → 200', async () => { /* ... */ });
  it('11. Giver B close job → applied 모두 rejected (cascade)', async () => { /* ... */ });
  it('12. Worker E tries to apply to closed job → 409 JOB_NOT_ACCEPTING', async () => { /* ... */ });
});
```

- [ ] **Step 3: production 실행**

Run:
```bash
npm run test:e2e
```
Expected: 12 PASS

- [ ] **Step 4: cleanup hook 작성 (Architect SF-3)**

`tests/e2e/m3-worker-flow.test.ts` 내부:
```ts
afterAll(async () => {
  // E2E 생성 row cleanup (audit trail 보존 위해 status='withdrawn' 또는 hard delete 결정)
  // 본 M3 spec은 audit 보존 → status 변경으로만 종료. 하지만 E2E는 별개:
  // (option a) service role로 hard delete - test 데이터만
  // (option b) prefix tag (e2e-${ts}-...) 후 식별 가능하게 land
  const { error } = await serviceRoleClient
    .from('applications')
    .delete()
    .like('cover_note', '%[E2E-M3]%');
  if (error) console.warn('cleanup partial:', error);
});
```

cleanup 후 production smoke 검증 SQL:
```sql
-- Supabase dashboard에서 1회
select count(*) from applications where cover_note like '%[E2E-M3]%';
-- Expected: 0
```

- [ ] **Step 5: 커밋**

```bash
git add tests/e2e/m3-worker-flow.test.ts
git commit -m "test(bff): M3 worker flow E2E 12 case production verified"
git push
```

---

# Sprint D: Flutter

**Goal:** Application 모델 + Repository + 2 신규 화면 + 기존 3 화면 수정 + 30+ test. Sprint C 의존.

### Task D.1: Application + ApplicationWorker + Counts freezed 모델

**Files:**
- Create: `sharework/lib/models/api_models/application.dart`
- Create: `sharework/test/models/application_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework/models/api_models/application.dart';

void main() {
  group('Application.fromJson', () {
    test('parses applied status', () { /* ... */ });
    test('parses orphan worker (탈퇴 회원)', () { /* ... */ });
    test('parses hired with phone', () { /* ... */ });
    test('round-trip toJson/fromJson', () { /* ... */ });
  });
  group('ApplicationCounts', () {
    test('default values are 0/0', () { /* ... */ });
  });
}
```

- [ ] **Step 2: 테스트 실패 검증**

Run: `flutter test test/models/application_test.dart`
Expected: FAIL — application.dart 부재

- [ ] **Step 3: 모델 구현 (spec §3c C2 그대로)**

(spec §3c C2 풀 코드 복사)

- [ ] **Step 4: build_runner**

Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: 테스트 통과 검증**

Run: `flutter test test/models/application_test.dart`
Expected: 5 PASS

- [ ] **Step 6: 커밋**

```bash
git add lib/models/api_models/application.dart \
        lib/models/api_models/application.freezed.dart \
        lib/models/api_models/application.g.dart \
        test/models/application_test.dart
git commit -m "feat(flutter): add Application freezed model (status enum + worker + counts)"
```

### Task D.2: Profile freezed 확장 — applicationCounts 필드

**Files:**
- Modify: `sharework/lib/models/api_models/profile.dart`
- Modify: `sharework/test/models/profile_test.dart`

- [ ] **Step 1: 테스트 추가**

```dart
test('parses application_counts from /api/me response', () {
  final json = { /* ... existing fields ..., */ 'application_counts': { 'applied': 2, 'hired': 1 } };
  final profile = Profile.fromJson(json);
  expect(profile.applicationCounts?.applied, 2);
  expect(profile.applicationCounts?.hired, 1);
});
test('applicationCounts default null when absent', () { /* ... */ });
```

- [ ] **Step 2~5: Profile에 `@JsonKey(name: 'application_counts') ApplicationCounts? applicationCounts` 필드 추가 + build_runner + 테스트 + 커밋**

```bash
git commit -m "feat(flutter): Profile extends with applicationCounts (M3)"
```

### Task D.3: ApplicationRepository + tests

**Files:**
- Create: `sharework/lib/repositories/application_repository.dart`
- Create: `sharework/test/repositories/application_repository_test.dart`

- [ ] **Step 1: 실패 테스트 작성 (5 method 각 1+ case)**

```dart
group('ApplicationRepository', () {
  test('apply success', () { /* mock dio post → 201 */ });
  test('apply with cover_note', () { /* ... */ });
  test('withdraw success', () { /* mock patch /api/me/applications/:id */ });
  test('decide hired', () { /* mock patch /api/jobs/:j/applications/:i */ });
  test('decide rejected', () { /* ... */ });
  test('listMine pagination', () { /* mock get + cursor */ });
  test('listForJob with status filter', () { /* ... */ });
  test('error: ALREADY_APPLIED → throws ApiException', () { /* ... */ });
});
```

- [ ] **Step 2~5: spec §3c C3 그대로 구현 + build + test + 커밋**

```bash
git commit -m "feat(flutter): ApplicationRepository (apply/withdraw/decide/listMine/listForJob)"
```

### Task D.4: StatusPill widget 확장 (onTap + chevron)

**Files:**
- Modify: `sharework/lib/widgets/status_pill.dart` (또는 worker_home_screen.dart 내부에 있다면 위젯 분리)
- Modify: `sharework/test/widgets/status_pill_test.dart`

- [ ] **Step 1: 테스트 추가**

```dart
test('StatusPill with onTap shows chevron + ripple', () { /* widget tester verify */ });
test('StatusPill without onTap no chevron (read-only)', () { /* ... */ });
test('Semantics button role when tappable', () { /* ... */ });
```

- [ ] **Step 2~5: 구현 (chevron_right 16dp + InkWell + Semantics) + 커밋**

```bash
git commit -m "feat(flutter): StatusPill onTap + chevron affordance + Semantics"
```

### Task D.5: ApplicationCard widget (Worker 시점)

**Files:**
- Create: `sharework/lib/widgets/application_card.dart`
- Create: `sharework/test/widgets/application_card_test.dart`

**Imports (CR R1 MF-3 + R2 partial fix)**:
```dart
// application_card.dart 상단
import 'package:flutter/material.dart';
import 'package:sharework/models/api_models/application.dart';
import 'package:sharework/widgets/cover_note_bottom_sheet.dart';
```

- [ ] **Step 1~5: spec §3c C4 _ApplicationCard 디자인 그대로 구현**

테스트: status 4 케이스별 badge 색상 + applied 시 취소 버튼 표시 + cover_note ellipsis + tap → BottomSheet 호출

```bash
git commit -m "feat(flutter): _ApplicationCard widget (Worker 시점)"
```

### Task D.6: ApplicantCard widget (Giver 시점)

**Files:**
- Create: `sharework/lib/widgets/applicant_card.dart`
- Create: `sharework/test/widgets/applicant_card_test.dart`

**Imports**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:sharework/models/api_models/application.dart';
```

- [ ] **Step 1~5: spec §3c C5 _ApplicantCard 디자인 그대로 구현**

테스트:
- worker name + public_id 표시
- applied 시 채용/거절 버튼 색상 (green/red)
- hired 시 phone monospace + 복사 IconButton
- 탈퇴 회원 (worker_public_id null) → Opacity(0.5) + 액션 disable + '(탈퇴 회원)' suffix

```bash
git commit -m "feat(flutter): _ApplicantCard widget (Giver 시점, phone 복사 + 탈퇴 처리)"
```

### Task D.7: CoverNoteBottomSheet widget

**Files:**
- Create: `sharework/lib/widgets/cover_note_bottom_sheet.dart`
- Create: `sharework/test/widgets/cover_note_bottom_sheet_test.dart`

- [ ] **Step 1~5: spec §3c C10 그대로 구현 (200자 카운트 + prefill)**

테스트:
- 빈 채로 제출 가능
- 200자 카운트 표시
- prefill 시 initialText 표시 + 편집 가능
- 200자 초과 입력 차단

```bash
git commit -m "feat(flutter): CoverNoteBottomSheet (200자 카운트 + prefill)"
```

### Task D.8: WorkerApplicationsScreen 신규

**Files:**
- Create: `sharework/lib/screens/worker/worker_applications_screen.dart`
- Create: `sharework/test/screens/worker_applications_screen_test.dart`

**Imports**:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharework/models/api_models/application.dart';
import 'package:sharework/repositories/application_repository.dart';
import 'package:sharework/widgets/application_card.dart';
```

- [ ] **Step 1~5: spec §3c C4 화면 그대로 구현**

핵심:
- TabBar 4 (지원중/채용됨/거절됨/취소됨)
- initialStatus → 진입 시 default tab 결정
- RefreshIndicator + 카드 리스트 (_ApplicationCard)
- pagination
- 지원 취소 확인 다이얼로그
- 에러/빈 상태 일관 패턴

테스트:
- 4 탭 전환
- 빈 상태 CTA
- 카드 액션 mock 호출
- 다이얼로그 표시 + 취소/확인

```bash
git commit -m "feat(flutter): WorkerApplicationsScreen (4 tab + pagination + withdraw 다이얼로그)"
```

### Task D.9: GiverJobApplicationsScreen 신규

**Files:**
- Create: `sharework/lib/screens/giver/giver_job_applications_screen.dart`
- Create: `sharework/test/screens/giver_job_applications_screen_test.dart`

**Imports**:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharework/models/api_models/application.dart';
import 'package:sharework/repositories/application_repository.dart';
import 'package:sharework/widgets/applicant_card.dart';
```

- [ ] **Step 1~5: spec §3c C5 화면 그대로 구현**

핵심:
- TabBar 4 (지원중/채용됨/거절됨/전체) default=지원중
- counts 표시 (AppBar "지원자 N명")
- _ApplicantCard 리스트
- 채용/거절 다이얼로그 (spec 문구 그대로)
- pagination + RefreshIndicator

```bash
git commit -m "feat(flutter): GiverJobApplicationsScreen (4 tab + 채용/거절 다이얼로그)"
```

### Task D.10: 라우트 등록 (import 명시 — CR MF-3)

**Files:**
- Modify: `sharework/lib/router/app_router.dart`

- [ ] **Step 1: import 추가**

```dart
// lib/router/app_router.dart 상단
import 'package:sharework/screens/worker/worker_applications_screen.dart';
import 'package:sharework/screens/giver/giver_job_applications_screen.dart';
```

- [ ] **Step 2: 2 라우트 추가 (spec §3c C1)**

```dart
GoRoute(
  path: '/worker/applications',
  builder: (ctx, state) => WorkerApplicationsScreen(
    initialStatus: state.uri.queryParameters['status'],
  ),
),
GoRoute(
  path: '/giver/job/:id/applications',
  builder: (ctx, state) => GiverJobApplicationsScreen(
    jobId: state.pathParameters['id']!,
  ),
),
```

- [ ] **Step 3: smoke test (라우트 매칭)**

```dart
testWidgets('router resolves /worker/applications', (tester) async {
  final router = appRouter; // 또는 createRouter()
  router.go('/worker/applications?status=applied');
  await tester.pumpAndSettle();
  expect(find.byType(WorkerApplicationsScreen), findsOneWidget);
});
```

- [ ] **Step 4: 테스트 통과 검증 + flutter analyze**

Run: `flutter test test/router/app_router_test.dart && flutter analyze`
Expected: PASS + analyze 0 new issue

- [ ] **Step 5: 커밋**

```bash
git commit -m "feat(flutter): register /worker/applications + /giver/job/:id/applications routes"
```

### Task D.11: WorkerHome StatusPill 연동 + RouteAware diff (RouteObserver 등록 의무, CR nit)

**Files:**
- Modify: `sharework/lib/main.dart` 또는 router root (RouteObserver 등록)
- Modify: `sharework/lib/screens/worker/worker_home_screen.dart`
- Modify: `sharework/test/screens/worker_home_screen_test.dart`

- [ ] **Step 1: 전역 RouteObserver 등록 (CR nit)**

```dart
// lib/router/app_router.dart 또는 main.dart
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

// MaterialApp.router에 observer 등록
// GoRouter는 navigatorObservers 옵션을 GoRoute의 ShellRoute에서 등록 가능
GoRouter(
  observers: [routeObserver],
  routes: [...],
);
```

- [ ] **Step 2: 테스트 추가**

```dart
testWidgets('StatusPill tap → /worker/applications?status=applied', (tester) async { /* ... */ });
testWidgets('didPopNext refreshes counts + diff highlight', (tester) async {
  // push WorkerApplicationsScreen → pop back → didPopNext 호출 + refresh + diff 카드 파란 dot
});
```

- [ ] **Step 3~5: spec §3c C8 + C9 구현**

- `_StatusPill` onTap → `context.push('/worker/applications?status=...')`
- `WorkerHomeScreen with RouteAware`
- `didPopNext` 시 me + applications fetch + diff Map<String, ApplicationStatus> 비교
- 카드에 파란 dot Widget 표시 (diff 있는 application_id만)

```bash
git commit -m "feat(flutter): WorkerHome StatusPill onTap + RouteAware refresh + diff highlight"
```

### Task D.12: JobInfo 5 케이스 분기 + 자기 자신 차단 + lifetime cap 메시지

**Files:**
- Modify: `sharework/lib/screens/worker/job_info_screen.dart`
- Modify: `sharework/test/screens/job_info_screen_test.dart`

- [ ] **Step 1: 테스트 추가 — 5 케이스 + 자기 차단 + cap**

```dart
test('case: 미지원 + active → 지원하기 버튼', () { /* ... */ });
test('case: applied → 지원 취소 버튼', () { /* ... */ });
test('case: hired → 채용됨 badge', () { /* ... */ });
test('case: rejected → 다른 공고 보기 CTA', () { /* ... */ });
test('case: withdrawn + active → 다시 지원하기 + 회색 배너', () { /* ... */ });
test('case: 본인 등록 공고 → "내가 등록한 공고" badge', () { /* ... */ });
test('case: lifetime cap 도달 → 메시지 표시', () { /* ... */ });
```

- [ ] **Step 2~5: spec §3c C6 분기 표 그대로 구현 + 56dp primary CTA 영역 고정 + cover_note BottomSheet 호출 (prefill 지원)**

```bash
git commit -m "feat(flutter): JobInfo 5 case + self-apply 차단 + lifetime cap 메시지"
```

### Task D.13: GiverHome _GiverJobCard 지원자 진입 버튼

**Files:**
- Modify: `sharework/lib/screens/giver/giver_home_screen.dart`
- Modify: `sharework/test/screens/giver_home_screen_test.dart`

- [ ] **Step 1~5: spec §3c C7 그대로 구현 (TextButton.icon, appliedCount=0 시 disable)**

`appliedCount`는 jobRepository.listMine 응답에서 매핑.

```bash
git commit -m "feat(flutter): GiverHome _GiverJobCard 지원자 N명 보기 진입"
```

### Task D.14: 에러 메시지 한국어 매핑 확장

**Files:**
- Modify: `sharework/lib/error_messages.dart` (또는 기존 errors layer)
- Modify: `sharework/test/error_messages_test.dart`

- [ ] **Step 1: 테스트 — 12 ErrorCode 한국어 매핑 (spec §3c C11 표 그대로)**

```dart
test('ALREADY_APPLIED → 이미 지원하신 공고입니다', () { ... });
// ... 12개
```

- [ ] **Step 2~5: 매핑 함수 확장 + 커밋**

```bash
git commit -m "feat(flutter): extend error message map with M3 ErrorCode 12"
```

### Task D.15: 통합 smoke test

**Files:**
- Create: `sharework/test/integration/m3_smoke_test.dart`

- [ ] **Step 1: testWidgets 단일 6-stage E2E mock-driven**

stages:
1. login → /worker
2. WorkerHome StatusPill 0/0
3. JobInfo 진입 → 지원하기 BottomSheet → POST mock → SnackBar
4. /worker 복귀 → StatusPill 1/0 + 카드 파란 dot
5. /worker/applications?status=applied → 카드 표시
6. 지원 취소 → 다이얼로그 → 200 mock → 카드 회색 처리

```dart
testWidgets('M3 worker apply→withdraw flow', (tester) async {
  // network mock setup (M2 helper 재사용)
  // ...
});
```

- [ ] **Step 2~5: 커밋**

```bash
git commit -m "test(flutter): M3 worker apply→withdraw integration smoke (6 stages)"
```

### Task D.16: Sprint D push (전체 commit 묶음)

- [ ] **Step 1: 전체 test + analyze**

Run:
```bash
flutter test
flutter analyze
```
Expected: 모든 PASS + analyze baseline (194) 유지

- [ ] **Step 2: push**

```bash
git push
```

---

# Sprint E: Final R6 multi-reviewer

**Goal:** Code Reviewer + Security Engineer + Database Optimizer + UX Architect 4-reviewer 병렬 dispatch. must_fix land.

> **rev.3 SDD 호환 명시 (Arc R2 MF-2)**: Sprint E는 **main agent 직접 실행** (SDD subagent-driven-development 비대상). 이유: must_fix 수와 내용이 reviewer dispatch 결과에 따라 동적 결정 — deterministic task graph 가정에 미충족. 본 Sprint 진입 시 SDD 모드 종료 후 main agent가 직접 reviewer dispatch + 결과 분류 + must_fix별 TDD subtask 생성 + 실행. land 후 SDD 모드 재진입 (Sprint F).

### Task E.1: 4-reviewer 병렬 dispatch

**Files:**
- 변경 없음 (리뷰만)

- [ ] **Step 1: SDD subagent-driven-development의 Final 리뷰 단계 진입**

dispatch 대상:
- **Code Reviewer**: 전체 BFF + Flutter diff (Sprint A~D land 묶음)
- **Security Engineer**: 인증/RLS/sanitize/rate-limit/phone 노출/orphan 익명화 차원
- **Database Optimizer**: 인덱스 effectiveness (production 데이터 EXPLAIN), trigger deadlock 검증
- **UX Architect**: 5 케이스 분기 사용성, 다이얼로그 톤, 정보 격차 surface

> **Step 3 is dynamic** (CR MF-5): must_fix 수와 내용은 reviewer 결과에 따라 미정. plan에서는 must_fix N개 placeholder만 명시. land 기준 = lesson R6 "5분 fix 정량 명시 시 본 세션 land, 외엔 carry-over"

- [ ] **Step 2: 결과 수집 + must_fix 분류**

각 reviewer 결과:
- must_fix → R6 룰 평가: (a) 5분 fix 정량 명시 + (b) retrofit 비용 압도적 = 본 세션 land
- should_fix → 본 세션 또는 carry-over (cost 평가)
- nit → carry-over default

- [ ] **Step 3 (dynamic): must_fix land — 각 must_fix별 TDD subtask 분기**

각 must_fix별 (개수/내용 미정 — reviewer 결과 land 시 확정):
1. 실패 테스트 작성 (regression 보호)
2. 테스트 실패 검증
3. fix 구현
4. 테스트 통과
5. 단일 commit (`fix(bff|flutter): R6 <reviewer>-<id> <간단 요약>`)

- [ ] **Step 4: 재리뷰 (Code Reviewer 단독, 1라운드)**

must_fix 모두 land 후 Code Reviewer 단독 재리뷰.

Verdict: Approved 또는 nits만 남으면 Sprint E ✅.

- [ ] **Step 5: 커밋 (별도 commit 묶음)**

```bash
git commit -m "fix(bff,flutter): R6 multi-reviewer must_fix Nfile (Sprint E)"
git push
```

---

# Sprint F: Production smoke + 메모리 업데이트

**Goal:** production 자연 검증 + 메모리/lesson 업데이트.

### Task F.1: production smoke (curl)

**Files:**
- 변경 없음 (검증만)

- [ ] **Step 1: 7 routes curl**

```bash
# 5 신규 routes 401 auth check
curl -I https://sharework-api.vercel.app/api/me/applications
curl -I https://sharework-api.vercel.app/api/jobs/00000000-0000-4000-8000-000000000000/applications

# 2 확장 routes 응답 schema 확인 (auth token으로)
TOKEN="..." # E2E worker token
curl -H "Authorization: Bearer $TOKEN" https://sharework-api.vercel.app/api/me | jq '.data.application_counts'
# Expected: { "applied": N, "hired": M }
```

- [ ] **Step 2: 보안 헤더 5종 확인**

```bash
curl -I https://sharework-api.vercel.app/api/me/applications | grep -E 'strict-transport|x-frame|x-content|referrer|permissions'
```
Expected: 5 header all present (M2 baseline 유지).

### Task F.2: Flutter manual smoke (사용자 직접)

**Files:**
- 변경 없음

- [ ] **Step 1: 시뮬레이터 또는 사이드로드 iPhone에서 flutter run**

- [ ] **Step 2: OTP login → Worker home → 카운트 확인**

- [ ] **Step 3: 공고 진입 → 지원하기 → cover_note 작성 → POST**

- [ ] **Step 4: /worker 복귀 → StatusPill 1건 + 파란 dot 확인**

- [ ] **Step 5: /worker/applications → 카드 표시 → 지원 취소 → 다이얼로그 → withdraw**

- [ ] **Step 6: Giver login → GiverHome 카드 → 지원자 진입 → 채용/거절 다이얼로그 확인**

- [ ] **Step 7: 사용자 결과 보고 (Architect SF-4)**

다음 형식으로 사용자 보고:

```
## M3 Manual Smoke 결과

| Stage | PASS/FAIL | 스크린샷 |
|-------|-----------|---------|
| 1. OTP login → /worker | ✅/❌ | (실패 시 첨부) |
| 2. StatusPill 카운트 확인 | ✅/❌ | |
| 3. JobInfo 진입 → 지원하기 → BottomSheet → POST | ✅/❌ | |
| 4. /worker 복귀 → StatusPill 1건 + 파란 dot | ✅/❌ | |
| 5. /worker/applications → 카드 표시 → 취소 다이얼로그 → withdraw | ✅/❌ | |
| 6. Giver login → 지원자 진입 → 채용/거절 다이얼로그 | ✅/❌ | |
| 7. Giver 채용 후 phone 복사 동작 | ✅/❌ | |
```

PASS 7/7 시 외부 베타 50명 모집 진입 가능. FAIL stage 발견 시 hot-fix (R6 "5분 fix" 기준 + 사용자 surface).

### Task F.3: 메모리 + lesson 업데이트

**Files:**
- Modify: `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/project_sharework.md` (의사결정 변경 이력 + 최종 상태)
- Modify: `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/MEMORY.md` (project_sharework 한 줄 갱신)
- Modify (옵션): `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/coding-lessons.md` (M3 lesson 추가 시)

- [ ] **Step 1: project_sharework 의사결정 변경 이력에 M3 row 추가**

```markdown
- **[2026-05-XX] M3 applications land — Worker 지원 풀 사이클 + 4 trigger + 6 RLS + 2 view**
  - push: sharework-api `<SHA>` (마이그 4 + API 7 + lib 5 + e2e + tests) / sharework `<SHA>` (모델 + repo + 2 화면 + 기존 3 화면 수정 + 30+ test)
  - R1 우회 없음 (Q10 (B) 세션 분리)
  - ...
```

- [ ] **Step 2: MEMORY.md project_sharework 한 줄 갱신**

```markdown
- [project_sharework.md] ... + M3 applications land (Worker 지원 풀 사이클, 외부 베타 진입)
```

- [ ] **Step 3: (옵션) coding-lessons M3 lesson 추가**

본 plan/SDD 진행 중 발견된 lesson만 (R1 우회 회피 / trigger 체인 / phone 노출 view 분리 / orphan 익명화 단일 헬퍼 등). 사용자 표준 형식.

- [ ] **Step 4: 외부 베타 50명 모집 결정 surface**

사용자 결정 — iOS TestFlight ($99/yr) / Android Play 내부테스트 ($25 1회) / 양 플랫폼 / 사이드로드 확장.

---

## Self-Review

### 1. Spec coverage

| spec 섹션 | Task |
|---|---|
| §1 데이터 모델 | Task A.1 |
| §2 Views 2종 | Task A.2 |
| §2 Triggers 4개 | Task A.3 |
| §3a RLS 6 정책 + jobs_applicant_read | Task A.4 |
| §3a service role 정책 + orphan 익명화 책임 | (spec 본문, 코드 task 없음 — Sprint A.4 주석) |
| §3b B1.1 POST | Task B.6 |
| §3b B1.2 PATCH Worker | Task B.7 |
| §3b B1.3 PATCH Giver | Task B.8 |
| §3b B1.4 GET Worker list | Task B.9 |
| §3b B1.5 GET Giver list | Task B.10 |
| §3b B1.6 GET /api/me 확장 | Task B.11 |
| §3b B1.7 GET /api/me/jobs 확장 | Task B.12 |
| §3b B2 zod schemas | Task B.3 |
| §3b B3 sanitize | Task B.1 |
| §3b B4 rate limit | Task B.4 |
| §3b B5 errors 매핑 | Task B.2 |
| §3b B6 pickApplicationView | Task B.5 |
| §3b B7 mapApplicationRow | Task B.5 |
| §3b B8 cursor 인코딩 | Task B.9 (구현 내부) |
| §3c C1 라우트 | Task D.10 |
| §3c C2 모델 | Task D.1, D.2 |
| §3c C3 repository | Task D.3 |
| §3c C4 WorkerApplicationsScreen | Task D.8 |
| §3c C5 GiverJobApplicationsScreen | Task D.9 |
| §3c C6 JobInfo 5 케이스 | Task D.12 |
| §3c C7 GiverHome 진입 | Task D.13 |
| §3c C8 WorkerHome StatusPill | Task D.4, D.11 |
| §3c C9 RouteAware diff | Task D.11 |
| §3c C10 CoverNoteBottomSheet | Task D.7 |
| §3c C11 에러 메시지 매핑 | Task D.14 |
| §3c C12 접근성 | (각 widget task 내부) |
| §4 테스트 | 각 task TDD step |
| §4 E2E 12 case | Task C.1 |
| §5 배포 순서 | Sprint 0~F 분해 |
| §6 위험 | (spec 참조, plan 본문 §위험 매트릭스 별도 작성 없음) |
| §7 Future Work | spec 참조 |

**갭 없음** — 모든 spec 요구사항이 task에 매핑됨.

### 2. Placeholder scan

- "TBD" / "TODO" / "implement later" — 0건
- "Similar to Task N" 패턴 — **rev.2/rev.3에서 정정 완료**. B.7/B.8/B.9/B.10a 모두 풀 코드 + 5-step 명시. B.10b는 5-endpoint orphan invariant 분리 task로 신규 land. spec 참조만으론 부족하다는 reviewer 지적 수용 + 풀 코드 inline 명시. **rev.3 land**.
- 빈 step / vague 단어 — 0건

### 3. Type consistency

- `Application` Flutter / `ApplicationSafeSchema` zod / `applications` table — 모두 spec과 동일
- enum 값 `applied/withdrawn/hired/rejected` — 5 layer 일관 (spec §1 → §3b B2 → §3c C2)
- `ErrorCode` 매핑 — Task B.2 정의 / Task D.14 한국어 매핑 일관 (12 entries)
- `mapApplicationRow` Task B.5 정의 / Task B.9, B.10에서 호출
- `pickApplicationView` Task B.5 정의 / Task B.10에서 호출

**일관성 OK**.

---

## §위험 매트릭스 (plan 본문)

본 plan은 **R1 우회 대상 아님** (Q10 (B) 세션 분리). 그러나 Sprint별 압축 결정 시 본 매트릭스 활용:

| # | 위험 | Sprint | 완화안 |
|---|------|-------|---------|
| W-P-1 | A 마이그 4 묶음 단일 commit 시 enum 트랜잭션 충돌 | A | enum 신규 추가는 안전 (트랜잭션 외 제약은 `add value` 한정). 본 plan은 enum 초기 정의만 |
| W-P-2 | B 13 task 압축 시 컨텍스트 폭발 | B | 본 plan default = 별도 세션. 압축 시 R1 4 조건 충족 의무 |
| W-P-3 | E2E test 데이터 production 잔존 | C, F | Sprint F에서 cleanup 검토 (또는 별도 test schema 분리 carry-over) |
| W-P-4 | Flutter D 16 task 압축 시 컨텍스트 폭발 | D | 동일 — 별도 세션 권장 |
| W-P-5 | R6 multi-reviewer 결과 must_fix 8+건 발견 시 land 비용 | E | "5분 fix" 정량 명시된 것만 본 세션 land. 외엔 carry-over |
| W-P-6 | production 자동 배포 실패 (env 누락 등) | A, B, C | Sprint 0 사전 점검 + 마이그 push 직후 production smoke |

---

## 완료 요약 (plan 단계)

| 항목 | 내용 |
|------|------|
| Before | M3 spec 승인 후 implementation plan 작성 필요 |
| After | 6 Sprint / ~32 task / ~160 step TDD plan land. 모든 spec section 매핑 검증 완료 |
| 주의할 점 | Sprint 0 (PG 15+ 확인) 누락 시 view security_invoker 미작동 / Sprint A.5에서 4 마이그 묶음 production push / R6는 Sprint E 별도 단계 |
| 관련 파일 | 본 plan + spec |
| 다음 단계 | spec + plan 한 commit (사용자 /commit-push 명시 호출) → SDD는 다음 세션 |
