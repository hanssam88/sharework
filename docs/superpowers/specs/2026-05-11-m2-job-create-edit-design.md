# M2 Design Spec — 공고 등록·수정 (Giver) + 사진 업로드

**작성일**: 2026-05-11
**대상 레포**: `sharework-api` (BFF, Next.js 16 + Supabase) + `sharework` (Flutter)
**선행 마일스톤**: M1 SMS 인증 + 공고 조회 (sharework-api `c2266eb`, sharework `1eae51a`, 외부 베타 land 완료 2026-05-10)
**추정 세션**: 2 (BFF 1 + Flutter 1, 또는 통합 1 + 마무리 1)

---

## 1. 개요 / 배경

M1으로 공고 조회·읽기 흐름이 외부 베타 land 상태 (`https://sharework-api.vercel.app`, BFF 135 unit/integration + 3 e2e + Flutter 243 PASS, multi-agent R6 1라운드 hardening 9건 적용). M2는 Giver 시점의 핵심 흐름인 **공고 등록·수정·상태 전환·사진 업로드**를 추가한다.

본 spec은 M2 brainstorming 결정사항을 결정 lock-in 표 + 아키텍처·schema·API·Storage·Flutter·테스트 6 layer로 land한 내용이다. M1 plan 패턴 (`docs/superpowers/plans/2026-05-10-m1-auth-job-list.md`, 4107 lines) 그대로 승계.

---

## 2. 결정 lock-in (2026-05-11 brainstorming)

| ID | 결정 | 값 | 근거 |
|----|------|---|------|
| D1 | M2 scope | 등록 + 수정 + 상태 전환 (active⇄paused, →closed final) + 사진 (1~5장) | 마장 공고 이력 삽진 관리 기본세트, M3 지원자 흐름과 직교 |
| D2 | 사진 업로드 흐름 | 클라이언트 직접 + BFF가 signed URL 발급 (A) | Supabase 표준, Vercel 트래픽 최소, M3+(채팅 첨부) 동일 패턴 재사용 |
| D3 | giver_id 외부 ID 매핑 (Sec M-2.1 carry-over) | `profiles.public_id` 신규 컬럼 + Nano-ID 22자 | 베타 종료 전 land가 retrofit보다 저렴, M3+ worker_id·채팅 발신자에 동일 적용 |
| D4 | Status 전환 API | PATCH /jobs/:id에 통합 + `closed` final | 단일 엔드포인트, 의도 충돌 없음, state machine 단순 |
| D5 | 사진 정책 | 1~5장 / jpeg·png·webp / 10MB / 1600px 압축 / private+signed URL TTL 24h | 일반 공고 사진 적정, webp 용량 절감, private+signed로 closed 공고 보안 |
| D6 | Rate limiting (Sec M-4 carry-over) | Upstash Redis + sliding window 30/min/user (write 통합) | easy-travel-korea-api 검증 패턴, key=`user:{profile_id}` |
| D7 | 사진 라이프사이클 | Incremental (개별 추가·삭제·순서 변경) + 별도 `job_photos` 테이블 | UX 자연스러움, 1장만 수정해도 1장만 재업로드 |
| D8 | Flutter wire-up 범위 | Giver 4화면 (home, job_create, job_preview, job_edit) + image_picker + flutter_image_compress | M2 = end-to-end, M1 패턴 그대로 |
| D9 | M1 carry-over 6건 처리 | M2 spec 직접 포함 (2건): Sec M-2.1·Sec M-4. M2 e2e 자연 포함 (1건): CR S-5 phone normalize. M2 SDD 마지막 task (3건): Sec I-5·L-2·nits | 분산 land로 retrofit 비용 최소 |
| D10 | advisor 호출 시점 | spec 확정 후 plan 진입 직전 1회 | M1 PM4 패턴, 사전 환경 검증 + spec 가정 catch |

**Anti-goals (본 M2에서 하지 않는 것)**:
- 지원자 관리·채팅 (M3)
- 결제·에스크로 (M5)
- 위치 SDK (M6)
- 사업자 인증 (M7)
- Health endpoint, orphan storage cleanup 스크립트 (별도 운영 작업)

---

## 3. 외부 의존성 (M2 시작 전 사용자 작업)

| 순서 | 항목 | 소요 | 비고 |
|------|------|------|------|
| 1 | Supabase Storage 버킷 `job-photos` 생성 (private) | 3분 | Supabase dashboard 직접 또는 마이그레이션에서 SQL insert |
| 2 | Upstash Redis 데이터베이스 생성 (free tier) | 5분 | https://console.upstash.com → REST URL/TOKEN 발급 |
| 3 | Vercel env 추가: `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` (production + preview) | 2분 | R11 주의: 따옴표 제거 후 등록 |
| 4 | Flutter pubspec 의존성 추가: `image_picker ^1.1.2`, `flutter_image_compress ^2.4.0` | 1분 | M2 Flutter task 시작 시 SDD가 처리 |

**총 외부 작업 시간**: ~10분 (1·2·3은 M2 BFF 시작 전 필수, 4는 SDD가 자동 처리).

---

## 4. 아키텍처

```
┌────────────┐          ┌──────────────────────┐          ┌─────────────────┐
│  Flutter   │  HTTPS   │  sharework-api       │  HTTPS   │   Supabase      │
│  (Giver)   │◀────────▶│  Next.js 16          │◀────────▶│   Postgres+RLS  │
│            │          │  Vercel              │          │   Auth + Storage│
└─────┬──────┘          └──────────┬───────────┘          └────────┬────────┘
      │  signed URL (5분 TTL)       │                               │
      │◀───────────────────────────┘                               │
      │  PUT 직접 업로드 (1~5장 병렬)                                │
      └────────────────────────────────────────────────────────────▶│
                                                            (private bucket)
```

**보안 모델 (defense-in-depth)**:
1. JWT 인증 (M1 그대로) — 모든 write 엔드포인트 통과
2. RLS (Postgres) — `jobs` / `job_photos` `giver_id = auth.uid()`
3. Storage RLS — bucket-level + path-prefix (`{job_id}/...`) backstop
4. signed URL TTL — upload 5분, download 24시간
5. Rate limiting (Upstash) — write 통합 30/min/user

**모든 Storage 작업은 BFF가 service role로 수행** (Storage RLS는 직접 access 시도 backstop). 클라이언트는 signed URL만 직접 호출.

**M1 패턴 재사용**: envelope ok/fail, ErrorCode enum, JWKS 검증, extractBearerToken, service role Supabase 싱글톤.

---

## 5. Schema 변경

신규 마이그레이션 3개 (R12 룰: 적용된 본문 수정 금지, 모두 신규 파일).

### 5.1 `20260511000001_profiles_public_id.sql`

```sql
-- profiles.public_id : 외부 노출용 (Sec M-2.1 해소)
alter table public.profiles add column public_id text;

-- backfill: 22자 URL-safe random
update public.profiles
set public_id = translate(substr(encode(gen_random_bytes(16), 'base64'), 1, 22), '+/=', 'XYZ')
where public_id is null;

alter table public.profiles alter column public_id set not null;
alter table public.profiles add constraint profiles_public_id_unique unique (public_id);
create index profiles_public_id_idx on public.profiles(public_id);

-- handle_new_user 트리거 업데이트: 새 row 자동 생성
create or replace function public.handle_new_user()
returns trigger as $$
begin
  if new.phone is null then return new; end if;  -- 005 트리거 가드 유지
  insert into public.profiles (id, phone, public_id)
  values (
    new.id,
    new.phone,
    translate(substr(encode(gen_random_bytes(16), 'base64'), 1, 22), '+/=', 'XYZ')
  );
  return new;
end;
$$ language plpgsql security definer;
```

### 5.2 `20260511000002_job_photos.sql`

```sql
create table public.job_photos (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  storage_path text not null unique,
  position int not null check (position between 1 and 5),
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  file_size_bytes int not null check (file_size_bytes between 1 and 10485760),
  width int,
  height int,
  created_at timestamptz not null default now(),
  unique (job_id, position)
);
create index job_photos_job_position_idx on public.job_photos(job_id, position);

alter table public.job_photos enable row level security;

create policy "job_photos_read"
  on public.job_photos for select to authenticated
  using (
    exists (
      select 1 from public.jobs j
      where j.id = job_id and (j.status = 'active' or j.giver_id = auth.uid())
    )
  );

create policy "job_photos_giver_owner"
  on public.job_photos for all to authenticated
  using (exists (select 1 from public.jobs j where j.id = job_id and j.giver_id = auth.uid()))
  with check (exists (select 1 from public.jobs j where j.id = job_id and j.giver_id = auth.uid()));

-- Race-safe insert RPC
create or replace function public.add_job_photo(
  p_job_id uuid, p_storage_path text, p_mime text,
  p_size int, p_w int, p_h int
) returns public.job_photos as $$
declare
  v_max_pos int;
  v_count int;
  v_photo public.job_photos;
begin
  perform 1 from public.jobs
  where id = p_job_id and giver_id = auth.uid()
  for update;
  if not found then raise exception 'forbidden' using errcode = '42501'; end if;

  select count(*), coalesce(max(position), 0)
    into v_count, v_max_pos
  from public.job_photos where job_id = p_job_id;

  if v_count >= 5 then raise exception 'photo_limit' using errcode = 'P0001'; end if;

  insert into public.job_photos
    (job_id, storage_path, position, mime_type, file_size_bytes, width, height)
  values (p_job_id, p_storage_path, v_max_pos + 1, p_mime, p_size, p_w, p_h)
  returning * into v_photo;
  return v_photo;
end;
$$ language plpgsql security definer set search_path = public;

-- Reorder RPC (전체 photo_id 일치 + 순서 일괄 update)
create or replace function public.reorder_job_photos(
  p_job_id uuid, p_order uuid[]
) returns setof public.job_photos as $$
declare
  v_count int;
begin
  perform 1 from public.jobs
  where id = p_job_id and giver_id = auth.uid()
  for update;
  if not found then raise exception 'forbidden' using errcode = '42501'; end if;

  select count(*) into v_count from public.job_photos where job_id = p_job_id;
  if v_count <> array_length(p_order, 1) then
    raise exception 'order_mismatch' using errcode = 'P0002';
  end if;

  update public.job_photos jp
  set position = idx
  from unnest(p_order) with ordinality as o(photo_id, idx)
  where jp.job_id = p_job_id and jp.id = o.photo_id;

  return query select * from public.job_photos where job_id = p_job_id order by position;
end;
$$ language plpgsql security definer set search_path = public;
```

### 5.3 `20260511000003_storage_job_photos.sql`

```sql
insert into storage.buckets (id, name, public)
values ('job-photos', 'job-photos', false)
on conflict (id) do nothing;

-- 모든 Storage 작업은 BFF service role 경유 — 본 정책은 backstop
create policy "job_photos_storage_giver_write"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'job-photos'
    and auth.uid() = (
      select giver_id from public.jobs
      where id = ((storage.foldername(name))[1])::uuid
    )
  );

create policy "job_photos_storage_giver_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'job-photos'
    and auth.uid() = (
      select giver_id from public.jobs
      where id = ((storage.foldername(name))[1])::uuid
    )
  );

-- SELECT 정책 없음 = 거부 (signed URL만 통함)
```

---

## 6. API 엔드포인트

### 6.1 M1 변경 (응답 schema only)

| 엔드포인트 | 변경 |
|-----------|------|
| `GET /api/jobs` | `giver_id` 제거, `giver: { public_id, name }` 추가, `photos: [{ id, position, signed_url }]` cover (position=1)만 1개 |
| `GET /api/jobs/:id` | `giver: { public_id, name }`, `photos[]` 전체 (signed URL TTL 24h) |
| `GET /api/me` | `public_id` 추가 |

### 6.2 M2 신규 7개

| 메소드 | 경로 | 역할 | Rate limit |
|--------|------|------|-----------|
| `GET` | `/api/me/jobs` | 본인 공고 (status 무관) | 없음 |
| `POST` | `/api/jobs` | 공고 등록 | write 통합 |
| `PATCH` | `/api/jobs/:id` | 공고 수정 + status 전환 | write 통합 |
| `POST` | `/api/jobs/:id/photos/upload-url` | signed URL 발급 (5분 TTL) | write 통합 |
| `POST` | `/api/jobs/:id/photos/confirm` | DB 등록 (race-safe RPC) | write 통합 |
| `DELETE` | `/api/jobs/:id/photos/:photoId` | 사진 삭제 | write 통합 |
| `PATCH` | `/api/jobs/:id/photos/reorder` | 사진 순서 변경 | write 통합 |

### 6.3 Request/Response shape

#### POST /api/jobs

```typescript
// Request (zod)
{
  title: z.string().min(1).max(100),
  description: z.string().min(1).max(2000),
  wage_won: z.number().int().min(0),
  schedule_text: z.string().max(200).optional(),
  category_id: z.string().uuid(),
  location_address: z.string().min(1).max(200),
  location_lat: z.number().optional(),
  location_lng: z.number().optional(),
}
// Response: { ok: true, data: Job (cover photo X — 별도 photo upload 후) }
```

#### PATCH /api/jobs/:id

```typescript
// Request (zod)
{
  title?, description?, wage_won?, schedule_text?,
  category_id?, location_address?, location_lat?, location_lng?,
  status?: z.enum(['active', 'paused', 'closed']),
}
// State machine 검증 (BFF):
// - 현재 closed: status 외 모든 필드 거부 → JOB_STATE_INVALID
// - status closed → active|paused: JOB_STATE_INVALID
// Response: { ok: true, data: Job }
```

#### POST /api/jobs/:id/photos/upload-url

```typescript
// Request
{ mime_type: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  file_size_bytes: z.number().int().min(1).max(10485760) }

// 처리:
// 1. JWT verify + jobs.giver_id = auth.uid() 검증
// 2. select count(*) from job_photos where job_id=:id (검증용, lock 없음)
// 3. count >= 5: PHOTO_LIMIT_EXCEEDED
// 4. photo_id = uuidv4(), ext = mime → ('jpg'|'png'|'webp')
// 5. storage_path = `${job_id}/${photo_id}.${ext}`
// 6. supabase.storage.from('job-photos').createSignedUploadUrl(storage_path, 300)
// Response: { ok: true, data: { photo_id, storage_path, upload_url, expires_at } }
```

#### POST /api/jobs/:id/photos/confirm

```typescript
// Request
{ photo_id: uuid, mime_type, file_size_bytes, width?: number, height?: number }

// 처리:
// 1. JWT verify
// 2. storage_path = `${job_id}/${photo_id}.${ext}` 재구성 (Request photo_id + mime로)
// 3. Storage HEAD: supabase.storage.from('job-photos').list with prefix
// 4. 미존재 → cleanup 불필요, PHOTO_NOT_UPLOADED 반환
// 5. RPC add_job_photo(job_id, storage_path, mime, size, w, h)
// 6. RPC 'photo_limit' (P0001) → cleanup remove([storage_path]) → PHOTO_LIMIT_EXCEEDED
// 7. RPC 'forbidden' (42501) → FORBIDDEN
// Response: { ok: true, data: photo }
```

#### DELETE /api/jobs/:id/photos/:photoId

```typescript
// 처리:
// 1. JWT verify
// 2. select storage_path from job_photos where id=:photoId and job_id=:id (RLS 자동)
// 3. delete from job_photos where id=:photoId
// 4. supabase.storage.from('job-photos').remove([storage_path]) — best-effort, 실패 시 log
// Response: { ok: true, data: { deleted: true } }
```

#### PATCH /api/jobs/:id/photos/reorder

```typescript
// Request: { order: uuid[] }
// 처리: RPC reorder_job_photos(job_id, order) — race-safe
// Response: { ok: true, data: photos[] (정렬됨) }
```

#### GET /api/me/jobs

```typescript
// Query: ?status=active|paused|closed (옵션, 기본 모두)
// 처리:
// 1. JWT verify → profile_id
// 2. select * from jobs where giver_id=:profile_id (RLS 자동)
// 3. cover photo signed URL 발급 (each job)
// Response: { ok: true, data: { items, page_info } }
```

### 6.4 ErrorCode 확장

```typescript
// M1
AUTH_REQUIRED, AUTH_INVALID, NOT_FOUND, VALIDATION, INTERNAL, FORBIDDEN

// M2 추가
STORAGE_FAIL          // signed URL 발급/Storage HEAD 실패
RATE_LIMITED          // Upstash sliding window 초과
PHOTO_LIMIT_EXCEEDED  // 5장 초과
PHOTO_FILE_INVALID    // MIME / size 거부 (zod에서 차단되는 게 보통)
PHOTO_NOT_UPLOADED    // confirm 시 Storage HEAD 미존재
JOB_STATE_INVALID     // closed 상태 수정 / closed → active 전환 시도
```

### 6.5 State machine

```
active ⇄ paused
active | paused → closed (final)
closed → ❌ (JOB_STATE_INVALID)
```

---

## 7. Storage 정책 + 사진 흐름

### 7.1 Storage 작업 라우팅

| 작업 | 권한 모드 | 호출자 | 비고 |
|------|----------|--------|------|
| Upload (PUT signed URL) | service role 발급 → 클라이언트 PUT | Flutter | RLS bypass (signed URL 자체가 권한) |
| Download (GET signed URL) | service role 발급 → 클라이언트 GET | Flutter | TTL 24h |
| Delete (Storage object) | service role | BFF | DB DELETE 후 best-effort |
| HEAD (존재 확인) | service role | BFF | confirm 시 검증 |

### 7.2 사진 업로드 시퀀스

```
Flutter                BFF                    Supabase
  │ 1. POST upload-url  │                        │
  │  {mime, size}       │                        │
  ├────────────────────▶│                        │
  │                     │ count(*)<5 검증          │
  │                     │ photo_id 사전 발급        │
  │                     │ createSignedUploadUrl    │
  │                     │◀───────────────────────▶│
  │  signed_url         │                        │
  │◀────────────────────┤                        │
  │                                              │
  │ 2. PUT signed_url (압축 binary)               │
  ├─────────────────────────────────────────────▶│
  │                                  Storage 직접 쓰기│
  │  204 No Content                              │
  │◀─────────────────────────────────────────────┤
  │                     │                        │
  │ 3. POST confirm     │                        │
  │  {photo_id, w, h}   │                        │
  ├────────────────────▶│                        │
  │                     │ Storage HEAD 검증         │
  │                     │ RPC add_job_photo        │
  │                     │ (lock + insert)          │
  │  photo metadata     │                        │
  │◀────────────────────┤                        │
```

### 7.3 Race condition 처리

| Race | 해소 |
|------|------|
| upload-url ↔ confirm 사이 5장 초과 | RPC `add_job_photo`가 jobs row FOR UPDATE 후 count + insert atomic |
| confirm 거부 시 Storage orphan | BFF가 `storage.remove([path])` cleanup 호출 (best-effort) |
| photo 삭제 후 position 갭 | 자동 재정렬 안 함 (gap 허용). 명시적 reorder 엔드포인트로 처리 |
| closed 상태 race | PATCH 시점 jobs row FOR UPDATE 후 status 검증 |

### 7.4 Signed URL 갱신 정책

| 응답 | URL 발급 시점 | TTL |
|------|--------------|-----|
| GET /api/jobs (목록) | 매 요청마다 cover 1장 | 24h |
| GET /api/jobs/:id (상세) | 매 요청마다 모든 사진 | 24h |
| GET /api/me/jobs | 매 요청마다 cover 1장 | 24h |

→ 클라이언트는 캐시 가능, 만료 시 부모 응답 다시 가져옴 (별도 refresh 엔드포인트 불필요).

---

## 8. Flutter Wire-up

### 8.1 4 화면 변경

| 파일 | 변경 |
|------|-----|
| `lib/screens/giver/home/giver_home_screen.dart` | dummy 본인 공고 → `GET /api/me/jobs` (paused/closed 포함, 상태별 필터 탭) |
| `lib/screens/giver/job_create/job_create_screen.dart` | form → `POST /api/jobs` → 사진 업로드 시퀀스 → preview |
| `lib/screens/giver/job_create/job_preview_screen.dart` | create state에서 미리보기 (네트워크 호출 없음) |
| `lib/screens/giver/job_edit/job_edit_screen.dart` | `GET /api/jobs/:id` → 편집 → `PATCH /api/jobs/:id` + status 토글 |

### 8.2 신규 파일

```
lib/data/
├── repositories/
│   └── job_repository.dart         (확장: create/update/listMine/photo*)
└── services/
    └── photo_upload_service.dart   (image_picker + flutter_image_compress + dio PUT 시퀀스)

lib/widgets/
├── photo_upload_grid.dart          (1~5 사진 grid, add/remove/long-press reorder)
└── job_status_toggle.dart          (active/paused 토글 + close 확인 dialog)
```

### 8.3 photo_upload_service 핵심 흐름

```dart
Future<JobPhoto> uploadPhoto({required String jobId, required XFile picked}) async {
  // 1. 클라이언트 압축 (1600px 긴 변, quality 85, jpeg 변환)
  final compressed = await FlutterImageCompress.compressWithFile(
    picked.path, minWidth: 1600, minHeight: 1600, quality: 85, format: CompressFormat.jpeg,
  );
  final mime = 'image/jpeg';
  final size = compressed.length;

  // 2. BFF에서 signed URL 발급
  final uploadInfo = await api.post('/api/jobs/$jobId/photos/upload-url',
      body: {'mime_type': mime, 'file_size_bytes': size});

  // 3. signed URL에 직접 PUT (Authorization 헤더 X)
  final putRes = await dioPlain.put(uploadInfo.uploadUrl,
      data: compressed,
      options: Options(headers: {'content-type': mime, 'x-upsert': 'false'}));
  if (putRes.statusCode != 200 && putRes.statusCode != 204) {
    throw StorageUploadException(putRes.statusCode);
  }

  // 4. confirm
  return api.post('/api/jobs/$jobId/photos/confirm',
      body: {'photo_id': uploadInfo.photoId, 'mime_type': mime,
             'file_size_bytes': size, 'width': null, 'height': null});
}
```

`dioPlain` = M1에서 도입한 인증 인터셉터 적용 안 한 별도 dio.

### 8.4 신규 의존성

```yaml
image_picker: ^1.1.2          # 갤러리/카메라
flutter_image_compress: ^2.4.0 # 네이티브 압축
# dio: ^5.x.x                 # M1에서 도입됨
# flutter_secure_storage      # M1에서 도입됨
```

### 8.5 권한

- iOS `Info.plist` `NSPhotoLibraryUsageDescription` (S14 priming 흐름 land됨)
- Android `READ_MEDIA_IMAGES` (API 33+) — image_picker 자동 처리

### 8.6 Status 토글 UX

```
[Active]  [Paused]  [⚠ Close]
   ●         ○         ○

탭 동작:
  active → paused: 즉시 PATCH (확인 없음)
  paused → active: 즉시 PATCH
  active|paused → closed: confirm dialog ("마감 후 복구 불가")
```

### 8.7 State management

M1 패턴 그대로 따라감 (plan 단계에서 grep으로 확인 후 lock-in).

---

## 9. 에러 처리 + Rate Limiting

### 9.1 Rate Limiter 구현

```typescript
// src/lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();
export const jobWriteLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(30, '1 m'),
  prefix: 'rl:job-write',
  analytics: true,
});

// route handler
const { success, reset } = await jobWriteLimiter.limit(`user:${profileId}`);
if (!success) {
  const retryAfter = Math.ceil((reset - Date.now()) / 1000);
  return fail('RATE_LIMITED', `${retryAfter}s 후 재시도`, 429);
}
```

**키 식별**: `user:{profile_id}` (UUID, JWT에서 추출). IP 기반 아님 (NAT 영향 회피).

**env**:
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

### 9.2 ErrorCode → HTTP → Flutter UX 매핑

| ErrorCode | HTTP | Flutter 처리 |
|-----------|------|--------------|
| AUTH_REQUIRED / AUTH_INVALID | 401 | 로그인 화면 redirect (M1 인터셉터) |
| FORBIDDEN | 403 | "권한 없음" snackbar |
| NOT_FOUND | 404 | "공고를 찾을 수 없습니다" + 목록 갱신 |
| VALIDATION | 400 | 폼 필드별 에러 표시 (zod issue path) |
| JOB_STATE_INVALID | 409 | "마감된 공고는 수정할 수 없습니다" |
| PHOTO_LIMIT_EXCEEDED | 409 | "최대 5장까지 업로드 가능" |
| PHOTO_FILE_INVALID | 400 | "지원되지 않는 형식 또는 10MB 초과" |
| PHOTO_NOT_UPLOADED | 422 | confirm 시 Storage 미존재 → 재시도 버튼 |
| STORAGE_FAIL | 500 | "사진 업로드 실패" + 재시도 |
| RATE_LIMITED | 429 | "잠시 후 다시 시도 (Xs)" |
| INTERNAL | 500 | "일시적 오류" + 재시도 |

### 9.3 Partial 업로드 복구

| 실패 지점 | 복구 |
|----------|------|
| upload-url 발급 실패 | 사용자 확인 후 재시도 |
| signed URL PUT 네트워크 실패 | 자동 재시도 1회, 실패 시 사용자 confirm |
| signed URL 5분 만료 | upload-url 재발급 후 재시도 (자동) |
| confirm 5장 초과 race | BFF cleanup remove + Flutter "5장 초과" |
| confirm Storage HEAD 미존재 | Flutter PUT 재시도 |
| confirm 후 Flutter crash | DB 등록됨, 재진입 시 정상 |

### 9.4 Logging 정책 (M1 그대로 + 확장)

```typescript
// PII 금지 (phone, email)
log.info('job_created', { profile_id_hashed: hash(pid), category_id, has_location });
log.error('photo_confirm_storage_head_fail', { job_id_hashed: hash(jid), photo_id });
// storage_path 로깅 X (job_id 추출 가능)
```

### 9.5 비대화형 logs (R11)

```bash
vercel logs sharework-api --no-follow -x --since 5m
```

---

## 10. 테스트 전략

### 10.1 BFF Unit/Integration

- POST /jobs zod 검증 + RLS 우회 추적
- PATCH /jobs/:id state machine 7 케이스
- add_job_photo RPC race (5장 동시 confirm — 1만 성공)
- photo upload-url MIME/size 거부 4 케이스
- photo confirm Storage HEAD 미존재 → cleanup
- DELETE photo Storage best-effort
- reorder 검증 (누락 photo_id 거부)
- GET /api/me/jobs paused/closed 포함
- envelope giver_id → giver_public_id 변환
- Rate limiter (Upstash mock + sliding window 시뮬)

### 10.2 BFF E2E (`tests/e2e/m2-giver-flow.test.ts`)

- 실 Supabase + 실 Storage
- Giver 시나리오: OTP → POST /jobs → photo upload (1장 PUT + confirm) → PATCH 수정 → status paused → status active → status closed → 재수정 거부 → DELETE photo
- **CR S-5 carry-over 자연 land**: phone E.164 normalize 검증

### 10.3 Flutter

- `photo_upload_service`: 압축 + signed URL PUT + confirm 시퀀스 (dio mock)
- `photo_upload_grid` widget: add/remove/reorder
- `job_status_toggle` widget: pause/active 토글 + close confirm dialog
- `job_create_screen` form validation
- `job_edit_screen` state load + status 변경

### 10.4 통과 게이트

- BFF: 165+ unit/integration + 4 e2e (M1 135+3 baseline + M2 추가)
- Flutter: 280+ test (M1 243 baseline + M2 추가)
- Code Reviewer + Security Engineer + Database Optimizer 병렬 R6 1라운드 통과

---

## 11. M1 Carry-over 처리 (D9)

| ID | 항목 | M2 처리 |
|----|------|---------|
| Sec M-2.1 | giver_id 외부 ID | ✅ M2 spec D3 직접 포함 (profiles.public_id) |
| Sec M-4 | Rate limiting | ✅ M2 spec D6 직접 포함 (Upstash) |
| CR S-5 | e2e phone format normalize | ✅ M2 e2e (10.2) 자연 포함 |
| Sec I-5 | next.config.ts 보안 헤더 (HSTS, X-Frame, CSP 등) | M2 SDD 마지막 task (T_LAST) |
| Sec L-2 | env requireEnv 헬퍼 | M2 SDD 마지막 task (T_LAST) |
| Nits | dbFail 단위 테스트, N1~N5, DB N1·C1~C7 | M2 SDD 마지막 task (T_LAST) |

T_LAST = 별도 commit (R12 사전 정리 vs 본 작업 분리 동일 패턴 — M2 본 작업 commit과 분리).

---

## 12. 룰 적용 (R5/R11/R12)

- **R5 (training data 가정 금지)**: AGENTS.md `node_modules/next/dist/docs/` 사전 read 의무 — plan/SDD 진입 직전. Next.js 16 breaking changes 인지.
- **R5 (Vercel/Upstash docs)**: Upstash REST 패키지 버전 + Vercel env 등록 절차 docs 직접 grep. training data lag 회피.
- **R11 (DEV/Prod 분리 layer)**: env 등록 시 따옴표 strip 의무. production curl 1회 즉시 검증.
- **R11 (비대화형 logs)**: `vercel logs --no-follow -x --since 5m` 옵션 명시.
- **R12 (사전 정리 vs 본 작업 분리)**: M1 carry-over hardening (T_LAST) commit과 M2 본 작업 commit 분리.
- **R6 (멀티 에이전트 병렬 리뷰)**: SDD 완료 후 Code Reviewer + Security Engineer + Database Optimizer 병렬 R6 1라운드 hardening.

---

## 13. 위험 + 완화안

| ID | 위험 | 완화 |
|----|------|------|
| W1 | Storage signed URL 누출 (24h TTL) | private 버킷 + 짧은 TTL 갱신, 누출 시 영향 24h 한정 |
| W2 | Upstash 무료 tier 한도 (10K commands/day) | 베타 50명 × 30/min × 10분 활동/일 = 15K 추정 → 한도 근접 시 paid tier ($0.2/100K) |
| W3 | 5장 동시 confirm race | RPC add_job_photo FOR UPDATE 캡슐화로 atomic |
| W4 | Storage orphan 파일 누적 | M2 scope 외, 별도 cleanup cron (M3 이후) |
| W5 | Vercel Hobby tier 트래픽 (D2 클라이언트 직접 흐름으로 회피) | Storage URL 직접 PUT으로 BFF 트래픽 최소 |
| W6 | image_picker iOS 권한 거부 | priming 흐름(S14) land됨, 거부 시 안내 dialog |
| W7 | flutter_image_compress heic 미지원 | jpeg 변환 출력으로 회피 (D5) |
| W8 | profiles.public_id backfill 실패 (대용량 시) | 베타 50명 → 무시 가능. 향후 정식 출시 시 batch backfill 재검토 |
| W9 | Next.js 16 API 변화 (R5 위반 시 retrofit) | plan 진입 직전 `node_modules/next/dist/docs/` 사전 read |
| W10 | M1 carry-over (T_LAST) 작업 누락 | SDD 마지막 task 등재 + commit 분리 강제 |

---

## 14. SDD 분해 미리보기 (writing-plans 단계로 land)

본 spec은 brainstorming 산출물. 다음 세션(`/writing-plans`)에서 정밀 SDD task 분해. 미리보기:

| Phase | Task | 산출물 |
|-------|------|--------|
| P0 | Supabase Storage 버킷 + Upstash 가입 (사용자 직접) | `job-photos` 버킷 + Redis URL/TOKEN |
| P0 | Vercel env 추가 (사용자 직접) | UPSTASH_REDIS_REST_URL/TOKEN |
| P1 | 마이그레이션 3개 작성 + push | profiles.public_id, job_photos, storage policy |
| P2 | BFF 라이브러리 (rate-limit.ts, schemas 확장) | 단위 테스트 PASS |
| P3 | API 엔드포인트 7개 신규 + 3개 응답 변경 | unit/integration PASS |
| P4 | Flutter repositories/services/widgets | dart analyze + unit test PASS |
| P5 | Flutter 4 화면 wire-up | analyze + widget test PASS |
| P6 | E2E (m2-giver-flow.test.ts) | e2e PASS |
| P7 | M1 carry-over T_LAST (Sec I-5, L-2, nits) | 별도 commit |
| P8 | 멀티 에이전트 R6 1라운드 (Code Reviewer + Security + DB Optimizer 병렬) | hardening land |
| P9 | Production deploy + smoke | https://sharework-api.vercel.app M2 routes HTTP 401 (auth normal) |

---

## 15. 다음 단계

1. **사용자 spec 리뷰 게이트** — 본 문서 검토, 변경 요청 시 수정
2. **승인 시 advisor 호출** — D10 사전 환경 검증 + spec 가정 catch
3. **`/writing-plans` 스킬 진입** — 정밀 SDD task 분해 + plan 본문 작성
4. **Plan 리뷰 루프 (1~2회)** — Software Architect + Code Reviewer
5. **사용자 승인 시 SDD 진입** — `superpowers:subagent-driven-development`
6. **R6 멀티 에이전트 통합 리뷰 + commit/push**
