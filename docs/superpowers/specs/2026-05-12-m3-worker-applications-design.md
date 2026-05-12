# M3 Spec — Worker 지원 흐름 (applications)

날짜: 2026-05-12
범위: BFF (sharework-api) + Flutter (sharework) 양쪽
선행: M1 land (auth + jobs list) + M2 land (Giver 공고 등록/수정 + 사진 + 상태)
다음 단계: writing-plans → SDD (다음 세션 예정, 본 세션은 spec + plan land까지)

## §0 작업 배경

M1에서 WorkerHome `지원중 0건` / `채용됨 0건` pill 하드코딩 land (U3 carry). M3에서 applications 테이블 신규 + Worker/Giver 풀 사이클(Apply + Withdraw + Giver Decision)을 구현해 외부 베타 50명 매칭 검증의 핵심 가치를 확보한다. 알림은 도입하지 않고 in-app pull only로 단순 베타 운영.

## §결정 lock-in 표

| # | 결정 | 근거 |
|---|------|------|
| Q1 | 범위 = Apply + Withdraw + Giver Decision (알림 없음) | 핵심 매칭 검증을 가장 좁은 풀 사이클로. 푸시는 M4+ |
| Q2 | status enum = `applied/withdrawn/hired/rejected` 4개 | Worker withdrawn ≠ Giver rejected 분리, UX 메시지 명확 |
| Q3 | closed 진입 시 applied 자동 rejected, paused 진입 시 새 지원 차단 | dead state 차단 + SQL trigger 단일 진실 |
| Q4 | 다수 채용 무제한 (Giver 명시 close까지) | 단기 알바 행사형 케이스 유연 대응 |
| Q5 | partial unique `(applied,hired) and worker_id is not null` + lifetime cap=2 | withdrawn 재지원 허용 + rejected 차단 + abuse 정찰 차단 |
| Q6 | 신규 `/giver/job/:id/applications` 화면 | 다수 채용 + 정렬/필터 확장 여지 |
| Q7 | WorkerHome pill 클릭 → `/worker/applications?status=...` | 기존 land된 pill 활용 |
| Q8 | 평소 public_id+name, hired 시 phone 공개 (view 2종 분리) | privacy 보호 + 매칭 후 실용성 양립 |
| Q9 | optional `cover_note` (max 200자) | Worker 차별화 + Giver 정보 ↑, 강제 안 함 |
| Q10 | 본 세션 = spec + plan land. SDD/구현은 다음 세션 | R1 우회 회피, 컨텍스트 안전 |
| 추가 | Plan A: 단일 테이블 + 명시 컬럼 + SQL trigger | DB 단일 진실 + audit 인프라 재사용 |
| 추가 | lifetime cap 메시지 = 수치 노출 (2회까지) | UX 친화 우선 (Security 정찰 risk 수용) |
| 추가 | PATCH endpoint 분리 (Worker `/api/me/applications/:id` + Giver `/api/jobs/:job_id/applications/:id`) | ownership 명확, OpenAPI 명료 |

## §부록 환경 점검 의무

- **Supabase Postgres 15+ 필수** — view `with (security_invoker = true)` 옵션은 PG 15+ 전용. land 직전 `select version()` 또는 Supabase dashboard 버전 확인. PG 14 이하 환경이면 view 정의자 권한으로 실행 → leak risk.
- **enum 확장은 별도 마이그 + commit 분리** — `alter type ... add value`는 트랜잭션 외 commit 필요 (PG 12+). 본 M3는 4 status + 2 reason 안정. 향후 확장 시 별도 마이그 파일.
- **Next.js 16 docs 사전 read** — sharework-api/AGENTS.md 룰. 새 라우트 핸들러 작성 전 `node_modules/next/dist/docs/` 참조.

---

## §1 데이터 모델

### 마이그 `20260512000001_applications.sql`

```sql
-- enum 타입 (SEC-N2 채택: text+check 대신 PG enum으로 tampering 표면 축소)
create type application_status as enum ('applied','withdrawn','hired','rejected');
create type application_rejected_reason as enum ('giver_rejected','job_closed');

create table public.applications (
  id              uuid primary key default gen_random_uuid(),
  job_id          uuid not null references public.jobs(id) on delete cascade,
  -- worker_id nullable + on delete set null (DB-S4):
  -- Worker 탈퇴 시 hired 정보 보존 + GDPR/PIPL 삭제권 정합. orphan row는 BFF에서 익명화.
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

-- partial unique: active 중복 차단 + withdrawn 재지원 허용 (Q5)
-- worker_id IS NOT NULL guard (DB-R2-M1): NULL row가 unique 검사에서 제외되지 않도록
create unique index applications_active_unique
  on public.applications(job_id, worker_id)
  where status in ('applied','hired') and worker_id is not null;

-- 핫패스 인덱스
-- Giver 화면: WHERE job_id=$ AND status=$ ORDER BY applied_at DESC
create index applications_job_status_idx
  on public.applications(job_id, status, applied_at desc);
-- Worker 화면 + counts: WHERE worker_id=$ AND status=$ ORDER BY applied_at DESC, GROUP BY status
create index applications_worker_status_idx
  on public.applications(worker_id, status, applied_at desc);

-- updated_at trigger 재사용 (M2 도입 set_updated_at)
create trigger applications_set_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();
```

### 인덱스 근거

| 인덱스 | 핫패스 쿼리 | 평가 |
|---|---|---|
| applications_active_unique | INSERT 시 active 중복 차단 | partial unique, NULL guard 적용 |
| applications_job_status_idx | GET /api/jobs/:id/applications | (job_id, status, applied_at desc) — covering index, 정렬 포함 |
| applications_worker_status_idx | GET /api/me/applications + counts GROUP BY | (worker_id, status, applied_at desc) — covering, GROUP BY status 가능 |

EXPLAIN 검증은 SDD task 진입 시 production 데이터로 1회. M2 패턴과 동일.

---

## §2 View 2종 + Triggers 4개

### 마이그 `20260512000002_applications_views.sql`

```sql
-- 평소 view: phone 미포함 (Worker/Giver 어디서든 안전)
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

-- hired view: phone 포함 (Giver가 hired 지원자 조회 시만 호출)
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

-- 권한 명시 (SEC-R2-M3)
revoke all on public.applications_with_worker_safe from anon;
grant select on public.applications_with_worker_safe to authenticated;
revoke all on public.applications_hired_with_worker_contact from anon;
grant select on public.applications_hired_with_worker_contact to authenticated;
```

### 마이그 `20260512000003_applications_triggers.sql`

```sql
-- ─── Trigger 1: self-application 차단 (SEC-M1) ─────────────────
-- CHECK constraint는 subquery 제한 있어서 BEFORE INSERT trigger로 처리
create or replace function public.prevent_self_application()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_giver_id uuid;
begin
  select giver_id into v_giver_id from public.jobs where id = NEW.job_id;
  if v_giver_id is null then
    raise exception 'job_not_found' using errcode = 'foreign_key_violation';
  end if;
  if v_giver_id = NEW.worker_id then
    raise exception 'self_application_forbidden' using errcode = 'check_violation';
  end if;
  return NEW;
end;
$$;

create trigger applications_prevent_self_apply
  before insert on public.applications
  for each row execute function public.prevent_self_application();

-- public revoke (SEC-R2-M1): client 직접 호출 차단. trigger context는 영향 없음
revoke execute on function public.prevent_self_application() from public;

-- ─── Trigger 2: lifetime cap=2 강제 (SEC race fix) ─────────────
-- DB layer 강제. BFF pre-INSERT SELECT는 fast-fail UX용, DB가 source of truth
create or replace function public.enforce_lifetime_cap()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count int;
begin
  select count(*) into v_count
    from public.applications
   where worker_id = NEW.worker_id and job_id = NEW.job_id;
  if v_count >= 2 then
    raise exception 'lifetime_cap_exceeded' using errcode = 'check_violation';
  end if;
  return NEW;
end;
$$;

create trigger applications_enforce_lifetime_cap
  before insert on public.applications
  for each row execute function public.enforce_lifetime_cap();

revoke execute on function public.enforce_lifetime_cap() from public;

-- ─── Trigger 3: state machine 강제 + timestamp 자동 + worker_id immutable (SEC-M2, SEC-M1) ──
-- timestamp tampering 차단 (SEC-R2-M2): OLD 값으로 복원 후 transition 자동 세팅
create or replace function public.enforce_application_state_machine()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- worker_id immutable (SEC-M1)
  if NEW.worker_id is distinct from OLD.worker_id then
    raise exception 'worker_id_immutable' using errcode = 'check_violation';
  end if;

  -- terminal 상태 변경 차단
  if OLD.status in ('withdrawn','hired','rejected')
     and OLD.status is distinct from NEW.status then
    raise exception 'invalid_status_transition' using errcode = 'check_violation';
  end if;

  -- rejected_reason 정합
  if NEW.status <> 'rejected' and NEW.rejected_reason is not null then
    raise exception 'rejected_reason_only_with_rejected' using errcode = 'check_violation';
  end if;
  if NEW.status = 'rejected' and NEW.rejected_reason is null then
    raise exception 'rejected_reason_required' using errcode = 'check_violation';
  end if;

  -- timestamp tampering 차단 — OLD 값으로 강제 복원 (SEC-R2-M2)
  NEW.applied_at    := OLD.applied_at;
  NEW.withdrawn_at  := OLD.withdrawn_at;
  NEW.hired_at      := OLD.hired_at;
  NEW.rejected_at   := OLD.rejected_at;

  -- transition 시점에만 자동 세팅
  if NEW.status = 'withdrawn' and OLD.status <> 'withdrawn' then NEW.withdrawn_at := now(); end if;
  if NEW.status = 'hired'     and OLD.status <> 'hired'     then NEW.hired_at     := now(); end if;
  if NEW.status = 'rejected'  and OLD.status <> 'rejected'  then NEW.rejected_at  := now(); end if;

  return NEW;
end;
$$;

create trigger applications_enforce_state_machine
  before update on public.applications
  for each row execute function public.enforce_application_state_machine();

-- ─── Trigger 4: closed cascade — jobs.status = 'closed' 진입 시 applied 자동 rejected ─
-- AFTER UPDATE OF status로 fire 범위 최소화. hired/withdrawn/rejected는 보존.
create or replace function public.handle_job_close_applications()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if (TG_OP = 'UPDATE' and OLD.status <> 'closed' and NEW.status = 'closed') then
    update public.applications
       set status = 'rejected', rejected_reason = 'job_closed'
       -- rejected_at은 state_machine trigger가 자동 세팅
     where job_id = NEW.id and status = 'applied';
  end if;
  return NEW;
end;
$$;

create trigger jobs_close_cascade_applications
  after update of status on public.jobs
  for each row execute function public.handle_job_close_applications();

revoke execute on function public.handle_job_close_applications() from public;
```

### Trigger 연쇄 실행 순서 검증

INSERT:
1. `prevent_self_application` (BEFORE INSERT) — self-apply 차단
2. `enforce_lifetime_cap` (BEFORE INSERT) — count ≥ 2 차단
3. partial unique constraint — active 중복 차단
4. RLS WITH CHECK — worker_id = auth.uid() + status = 'applied'

UPDATE (Worker withdraw):
1. RLS USING + WITH CHECK — `worker_id = auth.uid() AND status = 'applied'` (USING) + `worker_id = auth.uid() AND status = 'withdrawn'` (CHECK)
2. `enforce_application_state_machine` (BEFORE UPDATE) — applied→withdrawn 통과 + withdrawn_at 자동
3. `set_updated_at` (BEFORE UPDATE) — updated_at 갱신

UPDATE (Giver hired/rejected):
1. RLS USING + WITH CHECK — Giver job 소유 + status IN (hired, rejected)
2. `enforce_application_state_machine` — applied→{hired,rejected} 통과 + 해당 timestamp 자동 + rejected_reason 정합 검증
3. `set_updated_at`

UPDATE (close cascade):
1. `handle_job_close_applications` (security definer로 RLS 우회) UPDATE 발화
2. cascade UPDATE에 대해 `enforce_application_state_machine` 발화 — applied→rejected 통과 + rejected_reason='job_closed' + rejected_at 자동
3. `set_updated_at`

DELETE: RLS 정책 없음 = default deny. service role 또는 SECURITY DEFINER fn만 가능.

---

## §3a RLS 정책

### 마이그 `20260512000004_applications_rls.sql`

```sql
alter table public.applications enable row level security;

-- 1. Worker 본인 application read
-- worker_id NULL 시 NULL = uuid → NULL → RLS false 처리 (Postgres 표준)
-- → 탈퇴한 Worker 본인은 row 못 봄. 정합.
create policy applications_worker_select_own
  on public.applications for select to authenticated
  using (worker_id = auth.uid());

-- 2. Giver 본인 job의 application read
-- worker_id NULL row도 read 가능 → BFF view layer가 익명화
create policy applications_giver_select_own_job
  on public.applications for select to authenticated
  using (
    exists (
      select 1 from public.jobs
      where jobs.id = applications.job_id
        and jobs.giver_id = auth.uid()
    )
  );

-- 3. Worker INSERT — status='applied'만, worker_id = self
-- self-apply는 prevent_self_application trigger가 차단 (2-layer defense)
create policy applications_worker_insert
  on public.applications for insert to authenticated
  with check (
    worker_id = auth.uid()
    and status = 'applied'::application_status
  );

-- 4. Worker withdraw UPDATE — 본인 applied row를 withdrawn으로 (ARC-M1 fix)
create policy applications_worker_update_withdraw
  on public.applications for update to authenticated
  using (
    worker_id = auth.uid()
    and status = 'applied'::application_status  -- 출발 상태 강제
  )
  with check (
    worker_id = auth.uid()
    and status = 'withdrawn'::application_status
  );

-- 5. Giver decision UPDATE — 본인 job의 applied row를 hired/rejected로
create policy applications_giver_update_decision
  on public.applications for update to authenticated
  using (
    exists (
      select 1 from public.jobs
      where jobs.id = applications.job_id
        and jobs.giver_id = auth.uid()
    )
  )
  with check (
    status in ('hired'::application_status, 'rejected'::application_status)
    and exists (
      select 1 from public.jobs
      where jobs.id = applications.job_id
        and jobs.giver_id = auth.uid()
    )
  );

-- 6. DELETE: 명시 policy 없음 = default deny.
--    audit trail 보존 의도. Admin cleanup은 SECURITY DEFINER fn 전용.
```

### jobs RLS 보강

```sql
-- 기존: jobs_active_read (status='active' authenticated read), jobs_giver_owner_full
-- 추가: Worker는 본인이 지원한 job은 status 무관 read 가능 (paused/closed도 OK)
create policy jobs_applicant_read
  on public.jobs for select to authenticated
  using (
    exists (
      select 1 from public.applications
      where applications.job_id = jobs.id
        and applications.worker_id = auth.uid()
    )
  );
```

### 부록 — service role 사용 정책

- **M3 범위에서 service_role을 사용하는 BFF endpoint: 0건.**
- 향후 cron/admin은 SECURITY DEFINER fn 화이트리스트만 허용:
  - `cleanup_orphan_applications()` (Sprint 4+ carry-over, 현재 미도입)
  - `admin_force_close_job()` (M5+ admin tool 시점)
- 임의 BFF route에서 service_role key 사용 금지. PR 리뷰 가드.

### 부록 — orphan row 익명화 책임

BFF view layer 의무: `worker_id IS NULL` row 응답 시
- `worker_name` → `'(탈퇴 회원)'`
- `worker_public_id` → `null`
- `worker_phone` → `null` (hired view 응답에서도)

GDPR/PIPL 정합. RLS는 row 가시성, 익명화는 view layer 책임 분리.

---

## §3b BFF API + zod + rate limit + errors

### B1 API 라우트 (분리 구조)

| Method · Path | Role | 핵심 flow |
|---|---|---|
| `POST /api/jobs/:id/applications` | Worker | rate-limit → zod → job fetch (active 여부) → recent rejected exists → INSERT (4-layer enforce) → 23505/trigger 매핑 |
| `PATCH /api/me/applications/:id` | Worker | rate-limit → zod (withdrawn only) → SELECT ownership 사전 분기 → UPDATE → trigger 매핑 |
| `PATCH /api/jobs/:job_id/applications/:id` | Giver | rate-limit → zod (hired/rejected) → SELECT ownership 사전 분기 → BFF rejected_reason='giver_rejected' overwrite → UPDATE → trigger 매핑 |
| `GET /api/me/applications` | Worker | view=safe, params: `?status=&limit=&cursor=`, cursor pagination |
| `GET /api/jobs/:id/applications` | Giver | view 분기 (status='hired'면 contact view 외엔 safe), ownership 검증, counts 포함 |
| `GET /api/me` (확장) | 양쪽 | 기존 응답 + `application_counts: { applied, hired }` |
| `GET /api/me/jobs` (확장) | Giver | 기존 응답 + 각 job에 `application_count: { applied, hired }` (GiverHome 카드용) |

### B1.1 POST /api/jobs/:id/applications flow 상세

```
1. auth (verifyJwt)
2. rate-limit:
   - rl:apply-job:{worker_id} 분당 3건
   - rl:apply-job:{worker_id} 시간당 10건 (sliding window)
   Promise.all로 둘 다 체크
3. zod parse body: { cover_note?: string transform sanitize max 200 }
4. SELECT jobs.status, jobs.giver_id WHERE id=$1
   - 부재 → 404 JOB_NOT_FOUND
   - status != 'active' → 409 JOB_NOT_ACCEPTING
5. lifetime cap fast-fail check: SELECT count(*) FROM applications WHERE job_id=$ AND worker_id=$
   - >= 2 → 429 LIFETIME_CAP_EXCEEDED (DB trigger가 source of truth, BFF는 UX용)
6. recent rejected check (Q5 (B)): SELECT 1 FROM applications WHERE worker_id=$ AND job_id=$ AND status='rejected' LIMIT 1
   - exists → 409 REAPPLY_REJECTED
7. INSERT applications (worker_id=auth.uid, job_id=$1, status default 'applied', cover_note sanitized)
   - 23505 catch → 409 ALREADY_APPLIED
   - 23514 catch with message 매핑:
     - 'self_application_forbidden' → 403 SELF_APPLY_FORBIDDEN
     - 'lifetime_cap_exceeded' → 429 LIFETIME_CAP_EXCEEDED
     - 'job_not_found' → 404 JOB_NOT_FOUND
   - 42501 (insufficient_privilege) → 403 FORBIDDEN
8. 201 { ok: true, data: { id, status, applied_at } }
```

### B1.2 PATCH /api/me/applications/:id (Worker withdraw)

```
1. auth
2. rate-limit rl:patch-application:{user_id} 분당 10
3. zod parse: { status: literal 'withdrawn' } .strict()
4. SELECT applications.worker_id, status FROM applications WHERE id=$1
   - 부재 또는 worker_id != auth.uid() → 404 APPLICATION_NOT_FOUND
   - status != 'applied' → 409 INVALID_TRANSITION (trigger 보완)
5. UPDATE applications SET status='withdrawn' WHERE id=$1
   - 23514 'invalid_status_transition' → 409 INVALID_TRANSITION
   - 23514 'worker_id_immutable' → 400 INVALID_REQUEST (방어, 정상 흐름 미발생)
   - 42501 → 403 FORBIDDEN
6. 200 { ok: true, data: { id, status, withdrawn_at } }
```

### B1.3 PATCH /api/jobs/:job_id/applications/:id (Giver decision)

```
1. auth
2. rate-limit rl:patch-application:{user_id} 분당 10
3. zod parse: { status: enum(['hired','rejected']) } .strict()
4. SELECT a.id, a.status, j.giver_id FROM applications a JOIN jobs j ON j.id=a.job_id
   WHERE a.id=$application_id AND a.job_id=$job_id
   - 부재 또는 j.giver_id != auth.uid() → 404 APPLICATION_NOT_FOUND
   - a.status != 'applied' → 409 INVALID_TRANSITION
5. UPDATE applications SET status=$, rejected_reason=$
   - status='rejected'면 BFF가 rejected_reason='giver_rejected' overwrite (client 입력 무시)
   - status='hired'면 rejected_reason=NULL 명시
   - 23514 / 42501 → 매핑
6. 200 { ok: true, data: { id, status, hired_at | rejected_at, rejected_reason? } }
```

### B1.4 GET /api/me/applications

```
1. auth
2. zod params: { status?: enum, limit?: 20 default max 50, cursor?: base64url }
3. view = applications_with_worker_safe
4. cursor decode: { applied_at, id } | null
5. supabase SELECT FROM <view>
   WHERE worker_id = auth.uid()                             -- RLS도 동일
     AND ($status IS NULL OR status = $status::application_status)
     AND (cursor 적용: (applied_at, id) < (cursor.applied_at, cursor.id))
   ORDER BY applied_at DESC, id DESC
   LIMIT limit + 1                                          -- has_more 판정
6. items = mapApplicationRow(row) for each row (orphan 익명화 헬퍼 경유)
7. has_more = items.length > limit (true면 last item drop)
8. next_cursor = base64url({ applied_at: last.applied_at, id: last.id }) | null
9. 200 { ok: true, data: { items, has_more, next_cursor } }
```

### B1.5 GET /api/jobs/:id/applications

```
1. auth
2. zod params: { status?: enum, limit?: 20 default max 50, cursor?: base64url }
3. SELECT jobs.giver_id WHERE id=$1
   - jobs row 부재 → 404 JOB_NOT_FOUND
   - giver_id != auth.uid() → 403 FORBIDDEN
   - (jobs cascade delete 직후 race 케이스는 403 + code=JOB_ACCESS_REVOKED 메시지)
4. view = pickApplicationView(status)  // status='hired'면 contact view 외엔 safe
5. SELECT FROM <view> WHERE job_id=$1 AND (status filter) ORDER BY applied_at DESC, id DESC LIMIT limit+1
6. items = mapApplicationRow(row) for each (phone 포함은 view에 한정)
7. counts: SELECT status, count(*) FROM applications WHERE job_id=$1 AND status IN ('applied','hired') GROUP BY status
8. 200 { ok: true, data: { items, has_more, next_cursor, counts: { applied, hired } } }
```

### B1.6 GET /api/me (확장)

기존 응답 + `application_counts`:

```
SELECT status, count(*) FROM applications
WHERE worker_id = auth.uid() AND status IN ('applied','hired')
GROUP BY status
```

Profile + counts 1 round trip — 핫패스. 캐싱(Upstash 30s TTL)은 M4+ carry-over.

### B1.7 GET /api/me/jobs (확장)

기존 응답에서 각 job에 `application_count: { applied, hired }` 추가. CTE 또는 LEFT JOIN으로 N+1 회피:

```sql
SELECT j.*,
       coalesce(c.applied, 0) as application_applied_count,
       coalesce(c.hired,   0) as application_hired_count
FROM jobs j
LEFT JOIN LATERAL (
  SELECT count(*) filter (where status='applied') as applied,
         count(*) filter (where status='hired')   as hired
  FROM applications a
  WHERE a.job_id = j.id
) c ON true
WHERE j.giver_id = auth.uid()
ORDER BY j.created_at DESC
```

### B2 zod schemas (`src/lib/schemas.ts` 확장)

```ts
export const ApplicationStatusSchema = z.enum(['applied','withdrawn','hired','rejected']);
export const ApplicationRejectedReasonSchema = z.enum(['giver_rejected','job_closed']);

export const ApplicationCreateRequestSchema = z.object({
  cover_note: z.string().max(200).transform(sanitizeCoverNote).optional(),
}).strict();

// Worker PATCH — withdrawn 전용
export const ApplicationPatchByWorkerSchema = z.object({
  status: z.literal('withdrawn'),
}).strict();

// Giver PATCH — hired/rejected 전용. rejected_reason은 BFF가 server-determined (client 입력 무시)
export const ApplicationPatchByGiverSchema = z.object({
  status: z.enum(['hired', 'rejected']),
}).strict();

// 응답 schemas
export const ApplicationWorkerSchema = z.object({
  public_id: z.string().nullable(),
  name: z.string().nullable(),   // '(탈퇴 회원)' 가능
});

export const ApplicationSafeSchema = z.object({
  id: z.string().uuid(),
  job_id: z.string().uuid(),
  status: ApplicationStatusSchema,
  cover_note: z.string().nullable(),
  rejected_reason: ApplicationRejectedReasonSchema.nullable(),
  applied_at: z.string().datetime(),
  hired_at: z.string().datetime().nullable(),
  rejected_at: z.string().datetime().nullable(),
  withdrawn_at: z.string().datetime().nullable(),
  worker: ApplicationWorkerSchema.nullable(),
});

export const ApplicationWithContactSchema = ApplicationSafeSchema.extend({
  worker: ApplicationWorkerSchema.extend({ phone: z.string().nullable() }).nullable(),
});

export const ListApplicationsResponseSchema = z.object({
  items: z.array(z.union([ApplicationSafeSchema, ApplicationWithContactSchema])),
  has_more: z.boolean(),
  next_cursor: z.string().nullable(),
  counts: z.object({
    applied: z.number().int().nonnegative(),
    hired: z.number().int().nonnegative(),
  }).optional(),
});

export const ApplicationCountsSchema = z.object({
  applied: z.number().int().nonnegative(),
  hired: z.number().int().nonnegative(),
});

// MeResponseSchema 확장 (기존 schema에 application_counts 추가)
```

### B3 sanitizeCoverNote (`src/lib/text-sanitize.ts` 신규)

```ts
export function sanitizeCoverNote(s: string): string {
  let n = s.normalize('NFC');
  // 제어 문자 (\n \r \t는 허용)
  n = n.replace(/[ --]/g, '');
  // bidi override
  n = n.replace(/[‪-‮]/g, '');
  // bidi isolate
  n = n.replace(/[⁦-⁩]/g, '');
  // zero-width
  n = n.replace(/[​-‍﻿]/g, '');
  // tag chars
  n = n.replace(/[\u{e0000}-\u{e007f}]/gu, '');
  return n.trim();
}
```

### B4 Rate limit (Upstash sliding window — M2 패턴 재사용)

| Key | Window | 적용 |
|---|---|---|
| `rl:apply-job:{worker_id}` | 분당 3건 | POST /api/jobs/:id/applications |
| `rl:apply-job:{worker_id}` | 시간당 10건 | (sliding) |
| `rl:patch-application:{user_id}` | 분당 10건 | PATCH /api/me/applications/:id, PATCH /api/jobs/:job_id/applications/:id |

```ts
// Promise.all 패턴
const [minuteResult, hourResult] = await Promise.all([
  applyJobMinuteLimiter.limit(`rl:apply-job:${workerId}:m`),
  applyJobHourLimiter.limit(`rl:apply-job:${workerId}:h`),
]);
if (!minuteResult.success || !hourResult.success) {
  return rateLimitedResponse(); // 429 RATE_LIMITED, Retry-After header
}
```

### B5 Errors 매핑 표 (`src/lib/errors.ts` 확장)

| ErrorCode | HTTP | 원인 |
|---|---|---|
| `JOB_NOT_FOUND` | 404 | jobs row 부재 |
| `JOB_NOT_ACCEPTING` | 409 | jobs.status != 'active' (paused/closed) |
| `ALREADY_APPLIED` | 409 | 23505 partial unique catch (generic, constraint 이름 미노출) |
| `REAPPLY_REJECTED` | 409 | rejected row 잔존 시 재지원 |
| `SELF_APPLY_FORBIDDEN` | 403 | trigger `self_application_forbidden` |
| `INVALID_TRANSITION` | 409 | trigger `invalid_status_transition` 또는 BFF 사전 분기 |
| `INVALID_REQUEST` | 400 | trigger `worker_id_immutable`, `rejected_reason_required`, `rejected_reason_only_with_rejected` |
| `LIFETIME_CAP_EXCEEDED` | 429 | trigger `lifetime_cap_exceeded` 또는 BFF fast-fail (body에 cap 수치 미노출) |
| `RATE_LIMITED` | 429 | Upstash sliding window 초과 (Retry-After header) |
| `APPLICATION_NOT_FOUND` | 404 | row 부재 또는 RLS deny (정규화) |
| `FORBIDDEN` | 403 | pg 42501 (RLS deny) 정규화 |
| `JOB_ACCESS_REVOKED` | 403 | jobs_applicant_read race로 401 |

envelope: M2 동일 `{ ok: false, code, message }`.

### B6 View 매핑 헬퍼

```ts
export function pickApplicationView(status?: ApplicationStatus): string {
  return status === 'hired'
    ? 'applications_hired_with_worker_contact'
    : 'applications_with_worker_safe';
}
```

### B7 Orphan 익명화 헬퍼 (단일 진입)

```ts
type SafeRow = {
  id: string; job_id: string; worker_id: string | null;
  status: ApplicationStatus; cover_note: string | null;
  rejected_reason: ApplicationRejectedReason | null;
  applied_at: string; hired_at: string | null;
  rejected_at: string | null; withdrawn_at: string | null;
  worker_public_id: string | null; worker_name: string | null;
};
type ContactRow = SafeRow & { worker_phone: string | null };

export function mapApplicationRow(row: SafeRow | ContactRow) {
  const isOrphan = row.worker_id === null;
  return {
    id: row.id,
    job_id: row.job_id,
    status: row.status,
    cover_note: row.cover_note,
    rejected_reason: row.rejected_reason,
    applied_at: row.applied_at,
    hired_at: row.hired_at,
    rejected_at: row.rejected_at,
    withdrawn_at: row.withdrawn_at,
    worker: isOrphan
      ? { public_id: null, name: '(탈퇴 회원)' }
      : {
          public_id: row.worker_public_id,
          name: row.worker_name,
          ...('worker_phone' in row && row.worker_phone
            ? { phone: row.worker_phone }
            : {}),
        },
  };
}
```

**invariant**: 5 endpoint 모두 이 헬퍼 경유 의무. 테스트로 강제 — `it('orphan row sets worker.public_id=null and phone=null in all 5 endpoints')`.

### B8 Cursor 인코딩

```
cursor = base64url(JSON.stringify({ applied_at, id }))
```

- `worker_id` 미포함 (abuse 정찰 차단)
- HMAC signing은 M4+ Future Work
- decode 실패 시 400 INVALID_REQUEST

---

## §3c Flutter UI

### C1 신규 라우트 2개 (`lib/router/app_router.dart` 추가)

```dart
GoRoute(
  path: '/worker/applications',
  builder: (ctx, state) => WorkerApplicationsScreen(
    initialStatus: state.uri.queryParameters['status'], // 'applied' | 'hired' | 'rejected' | 'withdrawn' | null
  ),
),
GoRoute(
  path: '/giver/job/:id/applications',
  builder: (ctx, state) => GiverJobApplicationsScreen(
    jobId: state.pathParameters['id']!,
  ),
),
```

### C2 신규 freezed 모델 (`lib/models/api_models/application.dart`)

```dart
enum ApplicationStatus {
  @JsonValue('applied')    applied,
  @JsonValue('withdrawn')  withdrawn,
  @JsonValue('hired')      hired,
  @JsonValue('rejected')   rejected,
}

enum ApplicationRejectedReason {
  @JsonValue('giver_rejected') giverRejected,
  @JsonValue('job_closed')     jobClosed,
}

@freezed
class ApplicationWorker with _$ApplicationWorker {
  const factory ApplicationWorker({
    @JsonKey(name: 'public_id') String? publicId,
    String? name,
    String? phone,  // hired view 한정
  }) = _ApplicationWorker;
  factory ApplicationWorker.fromJson(Map<String, dynamic> json) =>
      _$ApplicationWorkerFromJson(json);
}

@freezed
class Application with _$Application {
  const factory Application({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    required ApplicationStatus status,
    @JsonKey(name: 'cover_note') String? coverNote,
    @JsonKey(name: 'rejected_reason') ApplicationRejectedReason? rejectedReason,
    @JsonKey(name: 'applied_at') required DateTime appliedAt,
    @JsonKey(name: 'hired_at') DateTime? hiredAt,
    @JsonKey(name: 'rejected_at') DateTime? rejectedAt,
    @JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,
    ApplicationWorker? worker,
  }) = _Application;
  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
}

@freezed
class ApplicationCounts with _$ApplicationCounts {
  const factory ApplicationCounts({
    @Default(0) int applied,
    @Default(0) int hired,
  }) = _ApplicationCounts;
  factory ApplicationCounts.fromJson(Map<String, dynamic> json) =>
      _$ApplicationCountsFromJson(json);
}
```

### C3 ApplicationRepository (`lib/repositories/application_repository.dart`)

```dart
class ApplicationRepository {
  ApplicationRepository(this._dio);
  final Dio _dio;

  Future<Application> apply({required String jobId, String? coverNote}) async {
    final res = await _dio.post('/api/jobs/$jobId/applications',
        data: { if (coverNote != null && coverNote.isNotEmpty) 'cover_note': coverNote });
    return Application.fromJson(_unwrap(res));
  }

  Future<Application> withdraw({required String applicationId}) async {
    final res = await _dio.patch('/api/me/applications/$applicationId',
        data: { 'status': 'withdrawn' });
    return Application.fromJson(_unwrap(res));
  }

  Future<Application> decide({
    required String jobId,
    required String applicationId,
    required ApplicationStatus to,  // hired or rejected only
  }) async {
    assert(to == ApplicationStatus.hired || to == ApplicationStatus.rejected);
    final res = await _dio.patch(
      '/api/jobs/$jobId/applications/$applicationId',
      data: { 'status': to == ApplicationStatus.hired ? 'hired' : 'rejected' },
    );
    return Application.fromJson(_unwrap(res));
  }

  Future<({List<Application> items, bool hasMore, String? nextCursor})>
      listMine({ApplicationStatus? status, String? cursor, int limit = 20}) async {
    final res = await _dio.get('/api/me/applications', queryParameters: {
      if (status != null) 'status': _statusToString(status),
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = _unwrap(res);
    return (
      items: (data['items'] as List).cast<Map<String, dynamic>>().map(Application.fromJson).toList(),
      hasMore: data['has_more'] as bool,
      nextCursor: data['next_cursor'] as String?,
    );
  }

  Future<({
    List<Application> items, bool hasMore, String? nextCursor,
    int appliedCount, int hiredCount
  })> listForJob({
    required String jobId,
    ApplicationStatus? status,
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _dio.get('/api/jobs/$jobId/applications', queryParameters: {
      if (status != null) 'status': _statusToString(status),
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = _unwrap(res);
    return (
      items: (data['items'] as List).cast<Map<String, dynamic>>().map(Application.fromJson).toList(),
      hasMore: data['has_more'] as bool,
      nextCursor: data['next_cursor'] as String?,
      appliedCount: (data['counts']?['applied'] as int?) ?? 0,
      hiredCount:   (data['counts']?['hired']   as int?) ?? 0,
    );
  }
}
```

### C4 WorkerApplicationsScreen (신규)

| 영역 | 디자인 |
|---|---|
| AppBar | "지원 내역" + 뒤로 |
| 탭 | **4 탭** (지원중 / 채용됨 / 거절됨 / 취소됨) — `TabBar` + `TabBarView` |
| 진입 default tab | `initialStatus` queryParam에 따라 (applied → 0번, hired → 1번, rejected → 2번, withdrawn → 3번, null → 0번) |
| 카드 (`_ApplicationCard`) | 공고 제목 + wage + applied_at + cover_note 2 lines ellipsis (tap → BottomSheet 풀 표시) + status badge + (applied 시 `지원 취소` outline 버튼) |
| 상태 badge 색상 (WCAG AA) | applied=`orange.shade700`, hired=`green.shade700`, rejected=`grey.shade600`, withdrawn=`grey.shade400` + 취소선 |
| 빈 상태 | `Icons.inbox_outlined` 64dp + "아직 지원한 공고가 없어요" + CTA "공고 둘러보기" → `/worker` |
| 에러 | M2 패턴 (네트워크 메시지 + `다시 시도` 버튼) |
| pull-to-refresh | RefreshIndicator |
| pagination | cursor + ScrollController 끝 도달 시 fetch more |
| 지원 취소 확인 다이얼로그 | "이 공고에 대한 지원을 취소하시겠어요? (다시 지원 가능)" + 취소/취소 확인 |

### C5 GiverJobApplicationsScreen (신규)

| 영역 | 디자인 |
|---|---|
| AppBar | "지원자 N명" (counts.applied 표시) + 뒤로 |
| 탭 | **4 탭** (지원중 / 채용됨 / 거절됨 / 전체) — **default = "지원중"** |
| 카드 (`_ApplicantCard`) | worker.name (또는 '(탈퇴 회원)' 회색) + public_id + applied_at + cover_note 2 lines ellipsis + status badge + (applied 시 채용/거절 2 버튼) + (hired 시 phone 표시 monospace + 복사 IconButton) + (탈퇴 회원이면 `Opacity(0.5)` + 액션 disable) |
| 채용 버튼 | `FilledButton` primary green |
| 거절 버튼 | `OutlinedButton` + `red.shade700` 텍스트 |
| 채용 확인 다이얼로그 | "이 지원자를 채용합니다. 다른 지원자도 추가 채용할 수 있습니다." + 취소/채용 |
| 거절 확인 다이얼로그 | "이 지원자를 거절합니다. 거절 후 변경할 수 없습니다." + 취소/거절 |
| 빈 상태 | "아직 지원자가 없어요" |
| pull-to-refresh + pagination | 동일 패턴 |
| 정렬 | applied_at desc (server-side) |

### C6 JobInfo 화면 수정 (Worker 시점 5 케이스 분기)

primary CTA 영역 56dp 고정. 상태 banner는 그 위에 배치 (레이아웃 점프 방지).

| 본인 상태 | UI |
|---|---|
| 미지원 + job.status='active' + job.giver_id ≠ self | `지원하기` primary 버튼 → BottomSheet (cover_note 작성, optional, 200자 카운트) → POST → `완료` SnackBar + WorkerHome refresh |
| 미지원 + job.status='active' + job.giver_id == self | `내가 등록한 공고` badge (self-apply 차단, 친절 UX) — trigger 의존 + client 사전 차단 |
| 미지원 + job.status≠'active' | 비활성 버튼 + "현재 지원 받지 않습니다" |
| applied | `지원 취소` outline 버튼 + "지원하신 공고입니다" badge |
| hired | "채용됨 ✓" green badge + "고용주 연락 대기 안내" 회색 박스. **M3 범위에서는 Giver→Worker 단방향 phone 공개만** (Q8 (C) 결정 한정). Worker가 Giver phone을 보지 않음 — Giver가 먼저 연락하는 흐름 강제. Worker→Giver phone 양방향 노출은 §7 Future Work carry-over. |
| rejected | "지원이 마감되었습니다" + "다른 공고 보기" CTA → /worker |
| withdrawn + job.status='active' | 회색 배너 "이전 지원을 취소하셨습니다" + `다시 지원하기` outline 버튼 → BottomSheet (이전 cover_note prefill, 편집 가능) → POST |
| withdrawn + job.status≠'active' | 회색 배너 "이전 지원을 취소하셨습니다" + 비활성 버튼 |
| 모든 케이스 lifetime cap 도달 | 비활성 버튼 + "이 공고에 지원 가능 횟수(2회)를 모두 사용했습니다" |

### C7 GiverHome 카드 진입 버튼 추가

기존 `_GiverJobCard` 하단에 TextButton:

```dart
TextButton.icon(
  icon: const Icon(Icons.people_outline, size: 18),
  label: Text(
    appliedCount > 0 ? '지원자 ${appliedCount}명 보기' : '아직 지원자 없음',
  ),
  onPressed: appliedCount > 0
      ? () => context.push('/giver/job/${job.id}/applications')
      : null,
),
```

`appliedCount`는 GET /api/me/jobs 확장 응답 (`application_count.applied`)에서. JobInfo (Giver 시점)에도 동일 진입점.

### C8 WorkerHome StatusPill 연동 (기존 화면 수정)

```dart
_StatusPill(
  label: '지원중',
  count: applicationCounts.applied,
  onTap: () => context.push('/worker/applications?status=applied'),
),
_StatusPill(
  label: '채용됨',
  count: applicationCounts.hired,
  onTap: () => context.push('/worker/applications?status=hired'),
),
```

`_StatusPill` widget에 `onTap` 콜백 + `chevron_right` 16dp + InkWell ripple + `Semantics(button: true, label: '...로 이동')` 추가.

### C9 WorkerHome 자동 refresh + diff highlight (UX-M1 land)

`RouteAware` 패턴 — WorkerHome이 `didPopNext` 시 `/api/me` + 본인 application 목록 fetch + 마지막 본 상태 vs 현재 상태 diff 시 카드 파란 dot 표시:

```dart
class _WorkerHomeState extends State<WorkerHomeScreen> with RouteAware {
  Map<String, ApplicationStatus> _lastSeenStatus = {};  // application_id → status

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshCountsAndDiff();
  }

  Future<void> _refreshCountsAndDiff() async {
    final me = await meRepository.getMe();
    setState(() {
      _applicationCounts = me.applicationCounts;
    });
    final mine = await applicationRepository.listMine(limit: 20);
    final diff = <String>{};
    for (final app in mine.items) {
      final last = _lastSeenStatus[app.id];
      if (last != null && last != app.status) {
        diff.add(app.id);
      }
      _lastSeenStatus[app.id] = app.status;
    }
    setState(() {
      _diffHighlights = diff;
    });
  }
}
```

본 spec은 idx 패턴만 명시. 풀 구현은 plan/SDD 단계.

### C10 cover_note BottomSheet (재사용 widget)

```dart
class CoverNoteBottomSheet extends StatefulWidget {
  final String? initialText;  // withdrawn 재지원 시 prefill
  ...
}
```

UX:
- 200자 카운트 우하단 (`120/200`)
- placeholder: "지원 시 전하고 싶은 말 (선택)"
- 빈 채로 제출 가능
- 트라이/리트라이 동작

### C11 에러 메시지 한국어 매핑 (ErrorCode → 메시지)

`lib/error_messages.dart` 또는 기존 errors layer 확장:

| ErrorCode | 메시지 |
|---|---|
| `ALREADY_APPLIED` | 이미 지원하신 공고입니다 |
| `REAPPLY_REJECTED` | 거절된 공고에는 다시 지원할 수 없습니다 |
| `JOB_NOT_ACCEPTING` | 현재 지원을 받지 않는 공고입니다 |
| `SELF_APPLY_FORBIDDEN` | 내가 등록한 공고에는 지원할 수 없습니다 |
| `INVALID_TRANSITION` | 현재 상태에서 변경할 수 없습니다 |
| `LIFETIME_CAP_EXCEEDED` | 이 공고에 지원 가능 횟수(2회)를 모두 사용했습니다 |
| `RATE_LIMITED` | 잠시 후 다시 시도해주세요 |
| `APPLICATION_NOT_FOUND` | 지원 내역을 찾을 수 없습니다 |
| `JOB_NOT_FOUND` | 공고를 찾을 수 없습니다 |
| `FORBIDDEN` | 권한이 없습니다 |
| `JOB_ACCESS_REVOKED` | 탈퇴한 지원자의 정보는 더 이상 조회할 수 없습니다 |
| `INVALID_REQUEST` | 요청이 올바르지 않습니다 |

### C12 접근성

- 모든 IconButton에 `tooltip` + `Semantics(label)` 의무
- 다이얼로그 cancel `autofocus`
- 48dp 터치 타겟
- 색상 대비 WCAG AA 4.5:1

### C13 Dark mode

M2 light only 가정. M3도 light only 유지. dark mode 도입은 M4+ carry-over.

---

## §4 테스트 전략

### BFF (sharework-api)

| 레이어 | 테스트 |
|---|---|
| Unit (zod, sanitize, error 매핑) | sanitizeCoverNote 6 카테고리 (NFC + control + bidi + isolate + zero-width + tag) / cursor encode-decode round-trip / mapApplicationRow orphan 분기 |
| Unit (BFF logic) | pickApplicationView 분기 / rate-limit 2-key 동시 체크 |
| Integration (mock supabase builder) | POST /api/jobs/:id/applications 6 case (success / job not active / self-apply / lifetime cap / reapply rejected / 23505) / PATCH worker withdraw / PATCH giver decision / GET lists pagination |
| Integration (orphan invariant) | 'orphan row sets worker.public_id=null and phone=null in all 5 endpoints' |
| Integration (state machine) | applied → withdrawn → 재지원 / applied → hired (terminal) / hired → withdrawn 차단 / closed cascade |

목표: 신규 테스트 +40 (M2 baseline 123 → ~163 PASS). M2 mock builder + RPC scenario state 패턴 재사용.

### Flutter (sharework)

| 레이어 | 테스트 |
|---|---|
| Unit (freezed) | Application.fromJson 풀 round-trip / ApplicationCounts default |
| Unit (repository) | apply / withdraw / decide / listMine / listForJob 각 패턴 mock dio + RPC matrix |
| Widget (screens) | WorkerApplicationsScreen 4 tab 전환 / 빈 상태 / 카드 액션 / GiverJobApplicationsScreen 4 tab / 채용·거절 다이얼로그 / JobInfo 5 케이스 분기 / WorkerHome StatusPill onTap |
| Integration (smoke) | testWidgets 단일 6-stage E2E mock-driven — login → JobInfo 지원 → WorkerHome refresh → /worker/applications → withdraw → 재지원 |

목표: 신규 테스트 +30 (M2 baseline 106 → ~136 PASS). M2 `test/helpers/network_mock.dart` 헬퍼 재사용.

### E2E (sharework-api tests/e2e/)

`m3-worker-flow.test.ts` 신규 — production verified. 12 case 목표:
1. Worker A login
2. Worker A apply to Giver B's job
3. Worker A withdraw
4. Worker A 재지원 (allowed)
5. Worker A 2nd withdraw
6. Worker A 3rd 시도 → 429 LIFETIME_CAP
7. Giver B view applications list
8. Giver B hire Worker A
9. Giver B reject another worker
10. Giver B close job → applied 자동 rejected
11. Worker A view application status (rejected after close)
12. Worker C tries to apply to closed job → 409 JOB_NOT_ACCEPTING

E2E env: `E2E_SUPABASE_URL` + `E2E_SUPABASE_ANON_KEY` (이미 .env.local에 존재, M2 재사용)

### Production smoke (push 후)

- 6 routes curl: 5 401 (auth) + 1 405 (POST-only) — M2 패턴
- 보안 헤더 5건 (M2 유지)
- Vercel 자동 배포 자연 검증 (2~3분)

---

## §5 마이그 / 배포 순서

### 마이그 파일 (총 4개 신규)

```
20260512000001_applications.sql           # 테이블 + enum + 인덱스 + updated_at trigger
20260512000002_applications_views.sql      # 2 view + GRANT
20260512000003_applications_triggers.sql   # 4 trigger fn + 트리거 + REVOKE
20260512000004_applications_rls.sql        # 6 RLS + jobs_applicant_read
```

### 배포 순서 (Push 흐름)

1. **Sprint 0 (사전 점검)**: Supabase Postgres 15+ 확인 (`select version()`), Upstash env 4건 재확인
2. **Sprint M3-A (BFF DB)**: 마이그 4개 push → Supabase 자동 적용 (production)
3. **Sprint M3-B (BFF API)**: 7 API 라우트 (5 신규 + 2 확장) + zod + sanitize + rate-limit. push → Vercel 자동 배포
4. **Sprint M3-C (BFF E2E)**: m3-worker-flow.test.ts 12 case production verified
5. **Sprint M3-D (Flutter)**: 모델 + repository + 2 신규 화면 + JobInfo/WorkerHome/GiverHome 수정
6. **Sprint M3-E (Final R6)**: Code Reviewer + Security Engineer + Database Optimizer 병렬 통합 리뷰 + must_fix land
7. **Sprint M3-F (Production smoke + 메모리 업데이트)**

각 Sprint = 별도 세션 또는 같은 세션 묶음 (사용자 결정). 본 spec은 결정 미정 (plan 단계에서 task graph 확정).

---

## §6 위험 + 완화안 (R1 우회 회피 대비 표)

본 spec은 **R1 우회 대상 아님** — Q10 (B)로 본 세션은 spec + plan land만, SDD/구현은 다음 세션. 그러나 plan 단계에서 압축 결정 시 본 표가 위험 매트릭스로 활용됨.

| # | 위험 | 발생 조건 | 완화안 |
|---|------|---------|---------|
| W-1 | 단일 트랜잭션 5+ 마이그 시 enum 트랜잭션 제약 충돌 | enum 신규 시 `alter type ... add value` 같은 트랜잭션 사용 | 본 spec은 enum 초기 정의만, 확장은 별도 마이그 commit 분리 의무 |
| W-2 | view `security_invoker = true` PG 15+ 환경 미충족 | Supabase PG 14 이하 | Sprint 0에서 `select version()` 확인. 14면 land 중단 + 사용자 surface |
| W-3 | 대량 applied(50+) job close 시 trigger deadlock | 베타 1 job당 5~10명 예상이라 도달 어려움 | BFF close 액션에 `lock_timeout` 짧게 + 재시도 패턴 (post-beta 검증) |
| W-4 | partial unique race + lifetime cap race | 동시 INSERT 요청 | partial unique + lifetime_cap trigger가 DB layer source of truth. BFF SELECT는 fast-fail UX용 |
| W-5 | 컨텍스트 폭발 (R1 우회 시) | spec + plan + SDD + R6 + commit/push 모두 같은 세션 압축 | Q10 (B) 분리 default. plan 진입 시 사용자 명시 surface |
| W-6 | UX vs Security cap 메시지 충돌 | lifetime cap 메시지 정책 | 사용자 결정 = (A) 수치 노출 lock-in (UX 우선) |
| W-7 | service role 누수 risk | 임의 BFF route에서 service role 사용 | M3 범위에서 service_role endpoint 0건 명시 + PR 리뷰 가드 |
| W-8 | orphan row 익명화 누락 | BFF 매핑 헬퍼 미경유 | mapApplicationRow 단일 헬퍼 invariant + 테스트 강제 |
| W-9 | trigger raise message → ErrorCode 매핑 누락 | BFF errors layer 미반영 | B5 매핑 표 의무 land + 테스트로 매핑 표 invariant 검증 |
| W-10 | abuse 정찰 (계정 재가입 cap reset) | phone OTP 재가입 비용 ↓ | M3 범위 밖. Sprint 4+ phone-level rate limit carry-over |

---

## §7 Future Work / Carry-over

### 본 spec 범위 밖 (M4+)

- **푸시/Realtime 알림** (Q1 (C) 미채택) — APNs/FCM 또는 Supabase Realtime broadcast
- **application_events 테이블** (audit trail 강화) — SEC-S1 carry-over
- **cleanup_orphan_applications() cron** (SECURITY DEFINER fn) — Sprint 4+ post-beta sweeper
- **HMAC signed cursor** — base64 JSON → HMAC suffix로 cursor tampering 명시 차단
- **application_counts caching** (Upstash 30s TTL) — WorkerHome 핫패스 측정 후 결정
- **headcount 컬럼** (jobs.headcount + auto-close on hired==headcount) — Q4 (B) 다수 채용 + 명시 정원 도입 시
- **phone-level rate limit** — 재가입 abuse 차단
- **dark mode** — UI 시스템 전체 도입 시 묶음
- **Giver→Worker phone 공개** — 현재 hired view는 Worker→Giver만. 양방향 노출 시 별도 결정

### Sprint 4 carry-over (M3 종료 후 외부 베타 윈도우)

- **SE-F2 (a) BFF content-type defense-in-depth** (~2h, R5 사전 — supabase-js docs read 필수)
- **SE-F4 orphan storage cleanup cron** (~2h, post-beta sweeper)
- **CR-S1 e2e unhappy path 3 case** (closed DELETE / FORBIDDEN / PHOTO_LIMIT)
- **CR-S3 PopScope busy 차단** (10분)
- **DB-S1/S2 인덱스** (jobs.category_id leading + me/jobs status filter, pg_stat_statements 데이터 확보 후 결정)
- **SE-F5 me.test.ts phone 패턴 → stub literal** (5분)

---

## §완료 요약 (spec 단계)

| 항목 | 내용 |
|------|------|
| Before | M3 brainstorming 시작 시 applications 미존재, WorkerHome 0/0 하드코딩 |
| After | 13 결정 lock-in + 4 마이그 + 7 API + 2 Flutter 화면 + 12 ErrorCode + 4 trigger + 6 RLS spec land |
| 주의할 점 | Supabase PG 15+ 필수 / enum 확장은 별도 commit / service_role endpoint 금지 / orphan 익명화 헬퍼 단일 진입 invariant |
| 관련 파일 | 본 spec (sharework/docs/superpowers/specs/2026-05-12-m3-worker-applications-design.md) |
| 다음 단계 | writing-plans 스킬 호출 → plan 작성 → SDD/구현은 다음 세션 |
