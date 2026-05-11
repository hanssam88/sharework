# M2 — 공고 등록·수정 + 사진 업로드 + M1 Flutter Wire-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** M1 BFF live(production `https://sharework-api.vercel.app`) 위에 (a) M2 Giver 공고 등록·수정·상태 전환·사진 업로드(1~5장) BFF + (b) M1 Flutter wire-up 미land 부분(supabase_flutter + dio + repository + Worker 7화면) + (c) M2 Giver 4화면 wire-up + (d) M1 BFF carry-over hardening(보안 헤더·env 헬퍼·ErrorCode 명명 정렬) 모두 land.

**Architecture:** BFF는 마이그 3개(profiles.public_id, job_photos, storage policy) + Upstash Redis sliding window rate limiting + signed URL flow(upload 5분 TTL · download 24h TTL)를 추가하고, Flutter는 supabase_flutter SDK + dio(인증 인터셉터 + Plain) + freezed 모델 + repository 패턴을 신규 도입해 M1 Worker 7화면(Phone/Home/JobInfo/Search/Categories/CategoryJobs/MyPage)을 dummy → 실 API로 전환한 뒤, M2 Giver 4화면(Home/Create/Preview/Edit) + photo_upload_service + photo_upload_grid widget을 신규 추가한다.

**Tech Stack:**
- BFF: Next.js 16.2.6 (App Router) + TypeScript + zod 4.4 + jose 6.2 + @supabase/supabase-js 2.105 + @upstash/ratelimit + @upstash/redis + Vitest 4.1, Vercel Hobby tier
- Mobile: Flutter 3.27+ + supabase_flutter 2.12.4 + dio 5.9.2 + freezed + json_serializable + go_router 14.2 + image_picker 1.1.2 + flutter_image_compress 2.4.0 + flutter_secure_storage
- Data: Supabase Postgres (RLS, 17 마이그 누적: M1 6 + M2 3 신규) + Phone Auth (Test phone numbers Mock 모드) + Storage `job-photos` private bucket
- Cache: Upstash Redis (free tier, sliding window 30/min/user write 통합)

**선행 문서**:
- spec: `../specs/2026-05-11-m2-job-create-edit-design.md` (commit `0d2b0f0`, 정정 7건 land)
- M1 plan (참조용, 본 plan에서 Sprint 1A Flutter task 위임): `../plans/2026-05-10-m1-auth-job-list.md` (4107줄, 29 task)
- master-plan: `../../master-plan.md`
- 메모리: `~/.claude/projects/-Users-sengmindavidhyun-Documents-David/memory/project_sharework.md`

---

## 정정 이력 (advisor catch + 본 plan 작성 단계)

| ID | 정정 항목 | spec 기존 가정 | 정정 | 영향 |
|----|----------|---------------|------|------|
| F1 | spec §8.3 `dioPlain` framing | "M1에서 도입한 인증 인터셉터 적용 안 한 별도 dio" | **본 plan에서 도입** (M1 Flutter 0-commit 상태 grep-confirmed). spec 본문은 본 plan 진입과 함께 implicit 정정 — spec commit은 그대로 보존 (역사 보존), plan §정정 이력으로 framing 흡수 | Flutter Sprint 1A에서 dio Plain 인스턴스 신규 도입, 이후 Sprint 2 photo_upload_service가 의존 |
| F2 | spec §8.7 "M1 패턴 그대로 따라감 (plan 단계에서 grep으로 확인 후 lock-in)" | M1 패턴 grep | **본 plan에서 패턴 결정** (StatefulWidget 단순 setState, 별도 state management 도입 없음 — M1 plan 패턴 그대로). Provider/Riverpod 도입 안 함 | Sprint 1A·Sprint 2 모두 setState 기반 |
| F3 | M1 carry-over Sec I-5/L-2/nits "M2 SDD 첫 task (T_FIRST)" | spec §11에 표기 | **본 plan P1 = T_FIRST**. M2 본 작업 *전* 별도 commit (R12 시간 방향 정합). 본 plan §태스크 그룹화에서 명시 | P1 commit이 P2~P9 commit *전*에 push되도록 SDD가 보장 |
| F4 | BFF ErrorCode 명명 불일치 | spec §6.4 M1 baseline = `AUTH_REQUIRED, AUTH_INVALID, VALIDATION, FORBIDDEN, NOT_FOUND, INTERNAL`. 실제 코드 = `UNAUTHORIZED, NOT_FOUND, VALIDATION_ERROR, INTERNAL` | **본 plan P1.4 = ErrorCode 정렬 rename** (UNAUTHORIZED 호출 시점 의미별 AUTH_REQUIRED/AUTH_INVALID로 분리, VALIDATION_ERROR→VALIDATION, FORBIDDEN 추가). 단위/통합 테스트 동시 rename | M1 4개 routes + jwt.ts + envelope.ts + 7 test files |
| F5 | M2 SDD task 분해 단위 | spec §14 Phase 표만 | **본 plan = 34 task 분해** (Sprint 0=사용자 직접, Sprint 1A=Flutter M1 wire-up, Sprint 1B=BFF carry-over, Sprint 2=M2 본 작업, Sprint 3=R6+deploy). Sprint 단위로 commit 분리 강제 | R12 + R1 우회 4 조건 plan 본문 명시 |
| F6 | Flutter M1 wire-up 처리 | spec §11 "Flutter는 M1에서 wire-up 됨" 암시 | **본 plan Sprint 1A**에서 M1 plan Task 15-29 (Flutter 부분)를 본 plan과 동등하게 land. Worker 7화면 dummy → 실 API 전환 + M1 Repository 도입. 사용자 결정 lock-in (2026-05-11): "M2 plan에 M1 Flutter wire-up 흡수" | plan 사이즈 ~34 task (M1 plan 17 Flutter task + M2 17 task). Sprint 단위 commit 분리로 압축 land 가능 |

---

## Plan 리뷰 반영 (rev.1, 2026-05-11)

Software Architect + Code Reviewer 병렬 리뷰 1라운드 + advisor reconcile 1회로 다음 must_fix 6건 + should_fix 6건 + nit 1건이 plan 본문에 land.

| ID | 출처 | 항목 | 본문 위치 |
|----|------|------|----------|
| M1 | SA | P4.4 GET `.eq('status','active')` 필터 → owner면 모든 status (B.10 edit flow 차단 해소) | P4.4 route 코드 + 4 test cases 추가 |
| M2 | SA+CR | P2.2 RPC `add_job_photo` + `reorder_job_photos` 시그니처에 `p_user_id` 추가 (service role auth.uid()=null 회피 + revoke execute from authenticated) | P2.2 SQL + P4.7/P4.9 호출 동기 |
| M3 | CR | A.4 `Job.photos` nullable → `@Default(<JobPhoto>[])` (NPE 차단) | A.4 freezed 정의 |
| M4 | CR | Flutter B.7/B.8/B.10 dispose() 누락 — TabController + 8개 TextEditingController | 각 _State에 dispose() override 추가 |
| M5 | CR | B.6 task 신설 — iOS Info.plist + AndroidManifest 권한 점검 (self-review 체크리스트 → 정식 task) | B.6 task 신설 + B.5 placeholder 흡수 |
| M6 | CR | R5 grep 3건을 Step 0로 박기 — P2.2 (auth.uid) + P3.1 (Upstash) + B.6 (Info.plist) | 각 task Step 0 추가 |
| S1 | SA | Push 순서 1A↔1B 역전 → **1B → 1A → 2 BFF → 2 Flutter → 3** (BFF rename Vercel 자동 배포 검증 후 Flutter integration test 진입) | §태스크 그룹화 + 부록 명시 |
| S2 | SA | B.8 `_addPhoto` PhotoUploadException catch → SnackBarAction `재시도` 추가 (V2 partial recovery UI 명시) | B.8 _addPhoto + _showSnackWithRetry |
| S2' | CR | B.10 `/* B.8과 동일 */` 3 메서드 placeholder 제거 → 실제 코드 inline (5분 fix 정량) | B.10 _addPhoto/_removePhoto/_reorderPhotos/_showError/_showSnack/_showSnackWithRetry 모두 inline land |
| S3 | CR | B.5 placeholder task 제거 → B.6 (권한 점검) task로 교체 | Task 그룹화에 자동 반영 |
| S4 | CR | Sprint 2 "단일 commit 권장" 표현 정정 → 다른 repo는 분리 commit 의무, BFF 먼저 push → Vercel 검증 → Flutter push | §태스크 그룹화 + Sprint 2 commit 절 본문 |
| S5 | CR | P4.7 cleanup orphan trade-off 1~2줄 명시 (베타 빈도 추정 + M3+ cron 분리) | P4.7 본문 끝 admonition |
| N1 | SA | M1 plan reference 8 task에 "§정정 이력 F1+F2 의무 read" admonition 추가 (CR S1 cheap 버전, advisor reconcile 결론) | A.5/A.6/A.7/A.8/A.9/A.12/A.13/A.14 Step 1 직전 |

**advisor reconcile (SA vs CR S1)**: 충돌 없음. SA N1 (16줄 추가) = CR S1 cheap 버전. SA 채택, CR S1 closed.

**잔여 nit (재리뷰 후 흡수 가능)**: CR N1(supabase createSignedUploadUrl TTL spec D5 미스매치 surface only) / CR N2(P1.4 sed → Edit 권장) / CR N3(B.9 empty photos widget test case).

**✅ PLAN_REVIEWED 체크포인트**: SA + CR 1라운드 + advisor reconcile + must_fix/should_fix 본문 land 완료. CR 단독 재리뷰 직후 ✅ 선언 예정.

---

## R5 결정 lock-in (공식 docs 직접 확인 후)

| # | 결정 | 값 | 근거 (docs URL · 확인일) |
|---|------|---|------------------------|
| R5-1 | Upstash Ratelimit 패키지 | `@upstash/ratelimit` ^2.x + `@upstash/redis` ^1.x. `Redis.fromEnv()`가 `UPSTASH_REDIS_REST_URL`/`UPSTASH_REDIS_REST_TOKEN` 자동 픽업 | https://github.com/upstash/ratelimit-js README (확인 2026-05-11), 패키지 npm latest |
| R5-2 | Supabase Storage signed URL API | `supabase.storage.from(bucket).createSignedUploadUrl(path, expiresInSec)` (upload), `createSignedUrl(path, expiresInSec)` (download). 5분 upload TTL은 spec D5 결정 | https://supabase.com/docs/reference/javascript/storage-from-createsigneduploadurl (확인 2026-05-11) |
| R5-3 | Supabase Storage bucket 생성 | `storage.buckets` 테이블에 INSERT (마이그레이션 가능). public=false private. M2 spec §5.3 그대로 | https://supabase.com/docs/guides/storage/buckets/creating-buckets#using-sql (확인 2026-05-11) |
| R5-4 | Next.js 16 Route Handler API | `export async function GET(req: Request, ctx: { params: Promise<{ id: string }> })` — params Promise 패턴 (M1에서 검증). middleware는 `src/middleware.ts` Next.js 16 default | `node_modules/next/dist/docs/01-app/...` (M1 검증), 본 plan SDD 진입 직전 재확인 |
| R5-5 | Postgres UNIQUE DEFERRABLE | `UNIQUE (...) DEFERRABLE INITIALLY DEFERRED`는 row-by-row 검사를 statement/transaction 종료로 미룸. reorder swap 시 단일 UPDATE가 violation 회피 | https://www.postgresql.org/docs/current/sql-createtable.html (확인 2026-05-11, V1 정정 근거) |
| R5-6 | Vercel Hobby 한도 | M1 R5-4 그대로 — Functions 10s / Concurrent Builds 1 / 1M invoc / 100GB Fast Data. Storage signed URL upload는 클라이언트 직접 PUT → BFF 트래픽 절감 (W5 완화) | https://vercel.com/docs/limits (M1에서 확인, 2026-05-11 재확인) |
| R5-7 | Flutter image_picker iOS 권한 | `Info.plist`에 `NSPhotoLibraryUsageDescription` 필수. M1에서 S14 priming 흐름 land됨 (Info.plist 이미 등록되어 있을 확률 높음 — SDD에서 grep 확인) | https://pub.dev/packages/image_picker README (확인 2026-05-11) |
| R5-8 | Flutter flutter_image_compress | `compressWithFile(path, minWidth, minHeight, quality, format)` API. heic는 jpeg 변환 출력 가능 (D5 결정) | https://pub.dev/packages/flutter_image_compress README (확인 2026-05-11) |

---

## 사용자 결정 lock-in (2026-05-11)

| # | 결정 | 값 | 영향 |
|---|------|---|------|
| U1 | M1 Flutter zero-commit gap 처리 framing | **옵션 2 명시 선택** — M2 plan에 M1 Flutter wire-up 흡수 (mega-plan ~34 task) | 본 plan Sprint 1A에서 M1 plan Task 15-29를 본 plan task 그룹으로 흡수. M1 plan 4107줄은 SDD가 reference로 직접 read |
| U2 | M1 Worker 화면 wire-up 범위 | M1 plan 정의 그대로 (PhoneAuth + WorkerHome + JobInfo + Search + Categories + CategoryJobs + MyPage 7 화면) | Sprint 1A에 7 task 그대로 흡수 |
| U3 | Worker applied/hired pill | M1 plan Q2 lock-in 그대로 — 0/0 하드코딩 (applications 테이블 M3) | Sprint 1A에서 pill 값 0 유지 |
| U4 | Spec 정정 (F1·F2 framing) | spec 본문 commit 그대로 보존 + plan §정정 이력으로 framing 흡수. spec 별도 재push 없음 | spec git 히스토리 보존 + plan이 framing 명시 |

---

## R1 우회 위험 (다음 세션 SDD 압축 land 시)

본 plan 사이즈(34 task ~5000줄)는 SDD를 다중 세션에 분할 권장. 단일 세션 압축 land 시도 시 R1 우회 4 조건 모두 충족 의무:

| ID | 위험 | 완화안 |
|----|------|--------|
| W-R1-1 | 컨텍스트 폭발 (34 task 단일 세션) | **권장 분할** — Sprint 1A(Flutter M1 wire-up 7 task) → 1 session + commit/push, Sprint 1B+2(BFF carry-over+M2 본 작업 20 task) → 1 session + commit/push, Sprint 3(R6+deploy 4 task) → 1 session + commit/push. 총 3 세션. |
| W-R1-2 | 룰 정합성 손상 (R12 사전 정리 vs 본 작업 commit 분리 미준수) | Sprint 1B(P1=T_FIRST)와 Sprint 2(P2~P7) commit **반드시 분리**. SDD가 commit 명령 시점 검증 의무 |
| W-R1-3 | 멀티 에이전트 리뷰 누락 (R6) | SDD 내부 task별 spec compliance + code quality 리뷰 자동 + Final R6 (Code Reviewer + Security Engineer + Database Optimizer 병렬) 의무 |
| W-R1-4 | 사용자 명시 lock-in 누락 | U1~U4 본 plan에 land됨. SDD 진입 직전 추가 surface 불요 |
| W-R1-5 | lesson 등재 누락 | 본 plan land + SDD 진입 시점에 R1 우회 (c) 조건 충족용 lesson 1건 등재 (압축 land 결정 시) |

**단일 세션 압축 land 채택 시**: R1 우회 4 조건 충족 → 다음 세션 R1 우회 lesson 등재 → 본 plan §태스크 그룹화의 commit 분리 강제 → R6 병렬 final 리뷰.

---

## 외부 의존성 (Sprint 0 = 사용자 직접 작업)

| # | 작업 | 상세 | 소요 |
|---|------|------|------|
| 0.1 | Supabase Storage 버킷 `job-photos` 생성 | 마이그 5.3에서 SQL insert로 자동 생성 가능 — *사용자 액션 없음* (Sprint 1B에서 마이그 push 시점 자동) | 0분 |
| 0.2 | Upstash Redis 데이터베이스 생성 (free tier) | https://console.upstash.com → **Create Database** → name=`sharework-prod` / Type=Regional / Region=ap-northeast-2 (Seoul 또는 ap-southeast-1 Singapore). REST URL/TOKEN 메모. 무료 tier: 10K commands/day, 256MB | 5분 |
| 0.3 | Vercel env 추가 (production + preview) | `vercel env add UPSTASH_REDIS_REST_URL production` + `vercel env add UPSTASH_REDIS_REST_URL "" --value <URL> --yes` (preview 빈 string trick) + 동일 패턴으로 `UPSTASH_REDIS_REST_TOKEN`. R11 따옴표 strip: dashboard 직접 등록 시 따옴표 입력 X. CLI는 자동 strip. | 5분 |
| 0.4 | Flutter pubspec 의존성 추가 | **SDD Task A1이 처리** — `pubspec.yaml`에 `supabase_flutter ^2.12.4`, `dio ^5.9.2`, `freezed_annotation ^2.4`, `json_annotation ^4.9`, `flutter_secure_storage ^9.2.4`, `image_picker ^1.1.2`, `flutter_image_compress ^2.4.0` 추가 + `flutter pub get`. 사용자 액션 없음 | 0분 |

**Sprint 1B 진입 전 0.2 + 0.3 완료 필수** (Upstash 환경 변수 없으면 P3.1 rate-limit.ts 단위 테스트가 `.env.test` mock 대체 가능, but production deploy 시 필수).

**Sprint 1A 진입 전 0.4는 SDD가 처리** — 사용자 사전 작업 0건.

---

## 태스크 그룹화 (Sprint 단위)

| Sprint | 범위 | Commit | Push 시점 |
|--------|------|--------|----------|
| **Sprint 0** | 사용자 직접 (Upstash 가입 + Vercel env) | 없음 (외부 작업) | — |
| **Sprint 1B** | BFF M1 carry-over hardening (P1=T_FIRST) — 보안 헤더, env requireEnv, dbFail test, ErrorCode rename | `chore(bff): M1 carry-over hardening — security headers, env helper, ErrorCode align` | **1순위 push** (R12 + Plan 리뷰 SA S1: Flutter Sprint 1A가 M2 ErrorCode 명명을 기대 — BFF rename 선행 의무) |
| **Sprint 1A** | Flutter M1 wire-up — pubspec + Supabase init + models + ApiClient + 4 Repository + 7 Worker 화면 + integration test | `feat(flutter): M1 wire-up — phone auth + worker home/list/detail + repository pattern` | **2순위 push** (Sprint 1B의 BFF rename Vercel 자동 배포 검증 후) |
| **Sprint 2 BFF** | M2 본 작업 BFF — 마이그 3 + lib(rate-limit, schemas 확장, errors M2 추가) + API 7 신규 + 3 변경 | `feat(bff): M2 — job create/edit + photo upload (1~5장) + status transition` | **3순위 push** (Vercel 자동 배포 검증 → Flutter Sprint 2 진입 가능) |
| **Sprint 2 Flutter** | M2 본 작업 Flutter — Giver 4화면 + photo_upload_service + widgets | `feat(flutter): M2 — Giver 공고 등록/수정/상태 전환 + 사진 업로드 (1~5장)` | **4순위 push** (다른 repo는 분리 commit 의무) |
| **Sprint 3** | E2E + R6 멀티 에이전트 통합 리뷰 + Production deploy + smoke | `chore: M2 E2E + R6 hardening + production smoke` | Sprint 3 끝 |

**Push 순서 의무** (Plan 리뷰 SA S1): `1B → 1A → 2 BFF → 2 Flutter → 3`. R12 정신(사전 정리 먼저 — BFF rename이 사전 정리)과 정합.
**Sprint 단위 commit 분리 의무** (R12). Sprint 내부 task는 staged 누적 후 Sprint 끝 단일 commit. 다른 repo는 항상 분리 commit (CR S4).

---

## File Structure

### sharework-api (BFF) — 기존 + 신규

```
sharework-api/  (M1 land됨, 본 plan 확장)
├── package.json              # M2: + @upstash/ratelimit, @upstash/redis
├── next.config.ts            # M2 P1.1: + 보안 헤더 (HSTS, X-Frame, CSP, Permissions-Policy)
├── .env.example              # M2: + UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN
├── src/
│   ├── lib/
│   │   ├── envelope.ts       # M2 P1.4: ErrorCode rename (UNAUTHORIZED→AUTH_REQUIRED/AUTH_INVALID 분리)
│   │   ├── errors.ts         # M2 P1.4 + P3.2: M2 ErrorCode 6개 추가
│   │   ├── jwt.ts            # M2 P1.4: ErrorCode 호출 시점 정렬
│   │   ├── schemas.ts        # M2 P3.3: + jobCreateSchema, jobUpdateSchema, photoUploadUrlSchema, photoConfirmSchema, photoReorderSchema, meJobsQuerySchema
│   │   ├── env.ts            # 신규 P1.2: requireEnv 헬퍼 + 모듈 초기화 시점 강제
│   │   ├── rate-limit.ts     # 신규 P3.1: Upstash slidingWindow(30, '1 m') + key=user:{profile_id}
│   │   ├── storage.ts        # 신규 P3.4: signed URL 발급 (upload 5min / download 24h) + bucket=job-photos 상수
│   │   ├── supabase.ts       # M2 P1.2: requireEnv 사용으로 환경변수 누락 시점 명시
│   │   └── photo-mapping.ts  # 신규 P3.5: photo[] → signed URL 매핑 헬퍼 (jobs list/detail에서 재사용)
│   ├── middleware.ts         # 변경 없음 (M1 JWT 검증 middleware 그대로)
│   └── app/
│       └── api/
│           ├── me/route.ts                            # M2 P4.1: 응답 + public_id (giver_id 노출 제거 후 public_id)
│           ├── me/jobs/route.ts                       # 신규 P4.2: 본인 공고 (status=active|paused|closed 옵션)
│           ├── jobs/route.ts                          # M2 P4.3: 응답 schema 변경 (giver_id → giver: {public_id, name}, photos: [cover])
│           ├── jobs/[id]/route.ts                     # M2 P4.4: GET 응답 schema 변경 + PATCH 신규
│           ├── jobs/[id]/photos/upload-url/route.ts   # 신규 P4.6: signed URL 발급 (5min)
│           ├── jobs/[id]/photos/confirm/route.ts      # 신규 P4.7: storage_path 직접 + RPC add_job_photo
│           ├── jobs/[id]/photos/[photoId]/route.ts    # 신규 P4.8: DELETE photo + Storage best-effort cleanup
│           ├── jobs/[id]/photos/reorder/route.ts      # 신규 P4.9: RPC reorder_job_photos
│           └── jobs/route.ts                          # P4.5: POST 신규 (jobs/route.ts 변경 + 신규 추가)
├── supabase/
│   └── migrations/
│       ├── 20260510000001 ~ 06.sql                    # M1 land (6 files)
│       ├── 20260511000001_profiles_public_id.sql      # 신규 P2.1: B3 정정 적용된 트리거 교체 → backfill → NOT NULL → unique
│       ├── 20260511000002_job_photos.sql              # 신규 P2.2: V1 DEFERRABLE + B1 gap fill + RPC add/reorder
│       └── 20260511000003_storage_job_photos.sql      # 신규 P2.3: bucket insert + RLS policy
└── tests/
    ├── unit/
    │   ├── envelope.test.ts             # M2 P1.4: ErrorCode rename + dbFail unit test 신규
    │   ├── jwt.test.ts                  # M2 P1.4: ErrorCode rename
    │   ├── schemas.test.ts              # M2 P3.3: 신규 schemas 단위 테스트
    │   ├── env.test.ts                  # 신규 P1.2: requireEnv 단위 테스트
    │   ├── rate-limit.test.ts           # 신규 P3.1: Upstash mock + sliding window 시뮬
    │   ├── storage.test.ts              # 신규 P3.4: signed URL 발급 + bucket 상수 + mock
    │   └── photo-mapping.test.ts        # 신규 P3.5: photo[] → signed URL 매핑
    ├── integration/
    │   ├── me.test.ts                   # M2 P4.1: public_id 응답 검증
    │   ├── me-jobs.test.ts              # 신규 P4.2
    │   ├── jobs-list.test.ts            # M2 P4.3: giver/photos 응답 schema 검증
    │   ├── jobs-detail.test.ts          # M2 P4.4: GET schema + PATCH state machine 7 케이스
    │   ├── jobs-create.test.ts          # 신규 P4.5
    │   ├── photos-upload-url.test.ts    # 신규 P4.6
    │   ├── photos-confirm.test.ts       # 신규 P4.7
    │   ├── photos-delete.test.ts        # 신규 P4.8
    │   └── photos-reorder.test.ts       # 신규 P4.9
    └── e2e/
        ├── m1-flow.test.ts              # M1 land (3 cases, P4.1·P4.3 응답 schema 변경 흡수 검증)
        └── m2-giver-flow.test.ts        # 신규 P7.1: OTP → POST /jobs → photo upload → PATCH → status paused→active→closed → 재수정 거부 → DELETE photo
```

### sharework (Flutter) — 신규 (M1 wire-up + M2)

```
sharework/  (UI mockup 상태, 본 plan에서 wire-up)
├── pubspec.yaml              # A1: + supabase_flutter, dio, freezed_annotation, json_annotation, flutter_secure_storage, image_picker, flutter_image_compress + dev_dependencies build_runner, freezed, json_serializable
├── ios/Runner/Info.plist     # B6: NSPhotoLibraryUsageDescription 확인 (S14에서 land됨, grep으로 confirm. 없으면 추가)
├── android/app/src/main/AndroidManifest.xml  # B6: READ_MEDIA_IMAGES (API 33+) image_picker 자동 처리 — grep 확인만
├── .env.example              # A2: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
├── lib/
│   ├── main.dart             # A2: Supabase.initialize + dotenv load + Material wrapping (기존 996자 → 확장)
│   ├── data/
│   │   ├── dummy_data.dart                   # 보존 (M3+ 화면이 의존, 본 plan에서 변경 X)
│   │   ├── permission_state.dart             # 보존
│   │   ├── env.dart                          # 신규 A2: API_BASE_URL/SUPABASE_URL/ANON_KEY load
│   │   ├── api_client.dart                   # 신규 A3: dio + JWT 자동 첨부 인터셉터 (dioAuth) + Plain (dioPlain, F1 정정)
│   │   ├── api_errors.dart                   # 신규 A3: ApiError exception + ErrorCode enum (BFF 명명과 정렬)
│   │   └── repositories/
│   │       ├── auth_repository.dart          # 신규 A5: Supabase SDK wrapping (signInWithOtp, verifyOTP, signOut)
│   │       ├── me_repository.dart            # 신규 A6: GET /api/me
│   │       ├── job_repository.dart           # 신규 A7 + B5: GET /api/jobs, /api/jobs/:id, /api/me/jobs, POST /api/jobs, PATCH /api/jobs/:id, photos/*
│   │       └── category_repository.dart      # 신규 A7: GET /api/categories
│   ├── models/
│   │   ├── models.dart                       # 기존 보존 + 신규 export 추가
│   │   ├── api_models/
│   │   │   ├── profile.dart                  # 신규 A4: freezed (id, phone, name, public_id, role)
│   │   │   ├── profile.freezed.dart          # 생성 (build_runner)
│   │   │   ├── profile.g.dart                # 생성
│   │   │   ├── job.dart                      # 신규 A4: freezed (id, giver: GiverPublic, title, description, wage_won, schedule_text, status, category_id, location_address, photos: List<JobPhoto>?, created_at, updated_at)
│   │   │   ├── job.freezed.dart
│   │   │   ├── job.g.dart
│   │   │   ├── giver_public.dart             # 신규 B4: freezed (public_id, name)
│   │   │   ├── giver_public.{freezed,g}.dart
│   │   │   ├── job_photo.dart                # 신규 B4: freezed (id, position, signed_url)
│   │   │   ├── job_photo.{freezed,g}.dart
│   │   │   ├── job_category.dart             # 신규 A4: freezed
│   │   │   └── job_category.{freezed,g}.dart
│   ├── router/
│   │   └── app_router.dart                   # A8: AuthGuard 추가 (Supabase session 검사 + redirect)
│   ├── screens/  (기존 화면 보존, 본 plan에서 swap)
│   │   ├── auth/
│   │   │   └── phone_auth_screen.dart        # A9: dummy → Supabase Phone Auth swap (signInWithOtp + verifyOTP)
│   │   ├── worker/
│   │   │   ├── home/                         # A10: 신규 폴더 (lib/screens/worker/home/ 생성) + worker_home_content.dart 신규 (worker_main_screen이 contained하는 list view)
│   │   │   ├── worker_main_screen.dart       # A10: dummy → JobRepository.listJobs() 호출 / applied/hired pill 0/0 하드코딩 (U3)
│   │   │   └── mypage/
│   │   │       └── (mypage_screen.dart 확장)  # A14: dummy → MeRepository.fetchMe()
│   │   ├── common/
│   │   │   ├── job_info_screen.dart          # A11: dummy → JobRepository.fetchJob(id) — F1 정정으로 dio 사용 (M1 plan Task 24 패턴)
│   │   │   ├── search_screen.dart            # A12: dummy → JobRepository.listJobs(q=keyword)
│   │   ├── categories/
│   │   │   ├── categories_screen.dart        # A13: dummy → CategoryRepository.list()
│   │   │   └── category_jobs_screen.dart     # A13: dummy → JobRepository.listJobs(category=:id)
│   │   ├── giver/
│   │   │   ├── giver_main_screen.dart        # B7: dummy → JobRepository.listMine() (paused/closed 포함, 상태별 필터 탭) — Worker M1과 분리
│   │   │   ├── job_create/
│   │   │   │   ├── job_create_screen.dart    # B8: form → POST /api/jobs → photo upload 시퀀스 → preview
│   │   │   │   └── job_preview_screen.dart   # B9: create state에서 미리보기 (네트워크 호출 X)
│   │   │   └── job_edit/
│   │   │       └── job_edit_screen.dart      # B10: GET /api/jobs/:id → 편집 → PATCH + status 토글
│   │   └── splash/
│   │       └── splash_screen.dart            # A8: Supabase.instance.client.auth.currentSession 검사 → /worker 또는 /auth/phone redirect
│   ├── services/
│   │   └── photo_upload_service.dart         # 신규 B5: image_picker + flutter_image_compress + dioPlain PUT + confirm 시퀀스
│   └── widgets/
│       ├── photo_upload_grid.dart            # 신규 B5: 1~5 grid + add/remove/long-press reorder
│       └── job_status_toggle.dart            # 신규 B10: active/paused 토글 + close confirm dialog
└── test/
    ├── data/
    │   ├── api_client_test.dart              # A3
    │   ├── auth_repository_test.dart         # A5
    │   ├── me_repository_test.dart           # A6
    │   ├── job_repository_test.dart          # A7 + B5
    │   └── category_repository_test.dart     # A7
    ├── services/
    │   └── photo_upload_service_test.dart    # B5
    ├── widgets/
    │   ├── photo_upload_grid_test.dart       # B5
    │   └── job_status_toggle_test.dart       # B10
    ├── screens/
    │   ├── phone_auth_screen_test.dart       # A9
    │   ├── worker_main_screen_test.dart      # A10
    │   ├── job_info_screen_test.dart         # A11
    │   ├── search_screen_test.dart           # A12
    │   ├── categories_screen_test.dart       # A13
    │   ├── mypage_screen_test.dart           # A14
    │   ├── giver_main_screen_test.dart       # B7
    │   ├── job_create_screen_test.dart       # B8
    │   ├── job_preview_screen_test.dart      # B9
    │   └── job_edit_screen_test.dart         # B10
    └── integration/
        ├── m1_smoke_test.dart                # A15 (M1 plan Task 28 패턴)
        └── m2_giver_smoke_test.dart          # B11
```

---

## Task 번호 체계

- **P1.x** = Sprint 1B BFF carry-over hardening
- **P2.x** = Sprint 2 BFF 마이그
- **P3.x** = Sprint 2 BFF lib
- **P4.x** = Sprint 2 BFF API endpoints
- **A.x** = Sprint 1A Flutter M1 wire-up (A = M1 Auth/Worker 화면)
- **B.x** = Sprint 2 Flutter Giver M2 wire-up
- **P7.x** = Sprint 3 E2E
- **P8.x** = Sprint 3 R6 멀티 에이전트 리뷰
- **P9.x** = Sprint 3 Production deploy + smoke

총 task: P1(4) + P2(3) + P3(5) + P4(9) + A(15) + B(11) + P7(2) + P8(1) + P9(1) = **51 task** (각 task = 5~12 step TDD 묶음)

---

## Sprint 1B — BFF M1 Carry-over Hardening (P1 = T_FIRST)

> **R12 명시**: Sprint 1B의 단일 commit이 Sprint 2의 BFF 본 작업 commit *전*에 push되도록 SDD가 강제. M2 신규 endpoint가 P1.1 보안 헤더 + P1.2 env 헬퍼 + P1.4 정렬된 ErrorCode 위에서 작성됨.

### Task P1.1: next.config.ts 보안 헤더 (Sec I-5 carry-over)

**Files:**
- Modify: `sharework-api/next.config.ts`
- Create: `sharework-api/tests/integration/security-headers.test.ts`

- [ ] **Step 1: Read existing next.config.ts**

Run: `cat sharework-api/next.config.ts`
Expected: 현재 `const nextConfig: NextConfig = { /* config options here */ };` 빈 상태 확인.

- [ ] **Step 2: Write failing test (security headers)**

Create `sharework-api/tests/integration/security-headers.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';

const PROD_URL = process.env.E2E_BASE_URL ?? 'https://sharework-api.vercel.app';

describe.skipIf(!process.env.RUN_E2E)('security headers (production)', () => {
  it('HEAD / returns HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy', async () => {
    const res = await fetch(`${PROD_URL}/api/categories`);
    expect(res.headers.get('strict-transport-security')).toMatch(/max-age=\d+/);
    expect(res.headers.get('x-frame-options')).toBe('DENY');
    expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    expect(res.headers.get('referrer-policy')).toBe('no-referrer');
  });
});
```

Unit-level 검증은 Next.js dev server 부팅 비용이 크므로 integration/production smoke로 처리. 추가로 unit test로 next.config.ts export 구조 검증:

Create `sharework-api/tests/unit/next-config.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import nextConfig from '../../next.config';

describe('next.config security headers', () => {
  it('exports headers() that returns HSTS + X-Frame + nosniff + Referrer-Policy + Permissions-Policy', async () => {
    expect(typeof nextConfig.headers).toBe('function');
    const headers = await nextConfig.headers!();
    expect(headers).toHaveLength(1);
    expect(headers[0].source).toBe('/(.*)');
    const map = Object.fromEntries(headers[0].headers.map(h => [h.key, h.value]));
    expect(map['Strict-Transport-Security']).toMatch(/max-age=\d+/);
    expect(map['X-Frame-Options']).toBe('DENY');
    expect(map['X-Content-Type-Options']).toBe('nosniff');
    expect(map['Referrer-Policy']).toBe('no-referrer');
    expect(map['Permissions-Policy']).toContain('camera=()');
  });
});
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd sharework-api && npx vitest run tests/unit/next-config.test.ts`
Expected: FAIL — `nextConfig.headers` is undefined.

- [ ] **Step 4: Implement security headers**

Edit `sharework-api/next.config.ts`:

```typescript
import type { NextConfig } from "next";

const SECURITY_HEADERS = [
  { key: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains; preload" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "no-referrer" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), interest-cohort=()" },
];

const nextConfig: NextConfig = {
  async headers() {
    return [
      { source: "/(.*)", headers: SECURITY_HEADERS },
    ];
  },
};

export default nextConfig;
```

> CSP는 본 M2에서 미적용 (signed URL이 외부 Supabase Storage 도메인에 의존, CSP `connect-src` 정책 정교화는 Flutter 클라이언트 영향 0건이지만 BFF 응답이 future SSR/HTML page 도입 시 영향 — 별도 운영 작업으로 분리. Sec I-5 carry-over는 4 헤더로 충분).

- [ ] **Step 5: Run test to verify it passes**

Run: `cd sharework-api && npx vitest run tests/unit/next-config.test.ts`
Expected: PASS.

- [ ] **Step 6: Stage (Sprint 1B 끝 단일 commit 위해)**

```bash
cd sharework-api && git add next.config.ts tests/unit/next-config.test.ts tests/integration/security-headers.test.ts
```

---

### Task P1.2: env requireEnv 헬퍼 (Sec L-2 carry-over)

**Files:**
- Create: `sharework-api/src/lib/env.ts`
- Create: `sharework-api/tests/unit/env.test.ts`
- Modify: `sharework-api/src/lib/supabase.ts` (getServiceRoleClient에서 requireEnv 사용)
- Modify: `sharework-api/src/lib/jwt.ts` (JWKS_URL/ISSUER 읽기 시 requireEnv)

- [ ] **Step 1: Write failing test for requireEnv**

Create `sharework-api/tests/unit/env.test.ts`:

```typescript
import { describe, it, expect, afterEach, beforeEach } from 'vitest';
import { requireEnv } from '@/lib/env';

describe('requireEnv', () => {
  const KEY = '__TEST_ENV_KEY_XYZ__';
  const orig = process.env[KEY];

  beforeEach(() => { delete process.env[KEY]; });
  afterEach(() => {
    if (orig === undefined) delete process.env[KEY];
    else process.env[KEY] = orig;
  });

  it('returns value when set', () => {
    process.env[KEY] = 'hello';
    expect(requireEnv(KEY)).toBe('hello');
  });

  it('throws when missing', () => {
    expect(() => requireEnv(KEY)).toThrow(/missing required env: __TEST_ENV_KEY_XYZ__/);
  });

  it('throws when empty string', () => {
    process.env[KEY] = '';
    expect(() => requireEnv(KEY)).toThrow(/missing required env/);
  });

  it('strips surrounding double-quotes (R11 dotenv 보수)', () => {
    process.env[KEY] = '"hello"';
    expect(requireEnv(KEY)).toBe('hello');
  });

  it('strips surrounding single-quotes', () => {
    process.env[KEY] = "'hello'";
    expect(requireEnv(KEY)).toBe('hello');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd sharework-api && npx vitest run tests/unit/env.test.ts`
Expected: FAIL — Cannot find module `@/lib/env`.

- [ ] **Step 3: Implement env.ts**

Create `sharework-api/src/lib/env.ts`:

```typescript
export function requireEnv(name: string): string {
  const raw = process.env[name];
  if (raw === undefined || raw === '') {
    throw new Error(`missing required env: ${name}`);
  }
  let v = raw.trim();
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
    v = v.slice(1, -1);
  }
  return v;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd sharework-api && npx vitest run tests/unit/env.test.ts`
Expected: PASS (5 tests).

- [ ] **Step 5: Apply requireEnv in supabase.ts**

Edit `sharework-api/src/lib/supabase.ts`:

```typescript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { requireEnv } from './env';

let cached: SupabaseClient | null = null;

export function getServiceRoleClient(): SupabaseClient {
  if (!cached) {
    const url = requireEnv('SUPABASE_URL');
    const key = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    cached = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return cached;
}
```

이전 `AppError(ErrorCode.INTERNAL, ...)` throw 패턴은 requireEnv `Error` throw로 단순화. caller(route handler)는 try/catch에서 `err instanceof Error` 처리.

- [ ] **Step 6: Apply requireEnv in jwt.ts**

Edit `sharework-api/src/lib/jwt.ts` — JWKS_URL/ISSUER 읽기 시점을 모듈 top-level이 아닌 getJWKS()/verifyAccessToken() 내부로 이동하고 requireEnv 사용:

```typescript
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AppError, ErrorCode } from './errors';
import { requireEnv } from './env';

let cachedJWKS: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJWKS() {
  if (!cachedJWKS) {
    const url = requireEnv('SUPABASE_JWKS_URL');
    cachedJWKS = createRemoteJWKSet(new URL(url));
  }
  return cachedJWKS;
}

export function extractBearerToken(req: Request): string {
  const auth = req.headers.get('authorization') ?? '';
  return auth.toLowerCase().startsWith('bearer ') ? auth.slice(7) : '';
}

export async function verifyAccessToken(token: string): Promise<{ userId: string }> {
  if (!token) {
    throw new AppError(ErrorCode.AUTH_REQUIRED, 'missing access token');
  }
  try {
    const { payload } = await jwtVerify(token, getJWKS(), {
      issuer: requireEnv('SUPABASE_JWT_ISSUER'),
      audience: 'authenticated',
      algorithms: ['ES256'],
      requiredClaims: ['exp', 'sub', 'iat'],
    });
    if (typeof payload.sub !== 'string') {
      throw new AppError(ErrorCode.AUTH_INVALID, 'jwt has no sub');
    }
    return { userId: payload.sub };
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw new AppError(ErrorCode.AUTH_INVALID, 'invalid or expired token');
  }
}
```

> `AUTH_REQUIRED`/`AUTH_INVALID`는 P1.4에서 추가되므로 본 step에서 import 에러 가능 — P1.4와 함께 실행 (P1.2 stage만, P1.4 실행 후 통합 검증).

- [ ] **Step 7: Stage**

```bash
cd sharework-api && git add src/lib/env.ts src/lib/supabase.ts src/lib/jwt.ts tests/unit/env.test.ts
```

---

### Task P1.3: dbFail 단위 테스트 (M1 nit)

**Files:**
- Modify: `sharework-api/tests/unit/envelope.test.ts`

- [ ] **Step 1: Read existing envelope.test.ts**

Run: `cat sharework-api/tests/unit/envelope.test.ts`

- [ ] **Step 2: Append dbFail unit test**

Add to `sharework-api/tests/unit/envelope.test.ts`:

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { dbFail, ErrorCode } from '@/lib/envelope';

describe('dbFail', () => {
  beforeEach(() => { vi.spyOn(console, 'error').mockImplementation(() => {}); });

  it('returns INTERNAL envelope without leaking error.message', async () => {
    const res = dbFail('test-route', { code: 'PGRST116', message: 'sensitive db error: column ... missing' });
    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body.error.code).toBe(ErrorCode.INTERNAL);
    expect(body.error.message).toBe('database error');
    expect(body.error.message).not.toContain('sensitive');
  });

  it('logs full error to server console with route tag', () => {
    const spy = vi.spyOn(console, 'error');
    dbFail('jobs', { code: 'PGRST', message: 'leaked detail' });
    expect(spy).toHaveBeenCalledWith('[db]', { route: 'jobs', code: 'PGRST', message: 'leaked detail' });
  });

  it('handles error with missing code/message gracefully', async () => {
    const res = dbFail('me', {});
    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body.error.code).toBe(ErrorCode.INTERNAL);
  });
});
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/unit/envelope.test.ts`
Expected: PASS (기존 + 3 신규).

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add tests/unit/envelope.test.ts
```

---

### Task P1.4: ErrorCode 명명 정렬 (F4 정정)

**Files:**
- Modify: `sharework-api/src/lib/errors.ts` (AUTH_REQUIRED/AUTH_INVALID/VALIDATION/FORBIDDEN 추가, UNAUTHORIZED/VALIDATION_ERROR 제거)
- Modify: `sharework-api/src/app/api/me/route.ts`
- Modify: `sharework-api/src/app/api/jobs/route.ts`
- Modify: `sharework-api/src/app/api/jobs/[id]/route.ts`
- Modify: `sharework-api/src/app/api/categories/route.ts`
- Modify: `sharework-api/src/lib/jwt.ts` (P1.2에서 일부 적용, 본 task에서 완성)
- Modify: `sharework-api/tests/unit/jwt.test.ts`
- Modify: `sharework-api/tests/unit/schemas.test.ts` (의존 시)
- Modify: `sharework-api/tests/integration/me.test.ts`
- Modify: `sharework-api/tests/integration/jobs-list.test.ts`
- Modify: `sharework-api/tests/integration/jobs-detail.test.ts`
- Modify: `sharework-api/tests/integration/categories.test.ts`
- Modify: `sharework-api/tests/e2e/m1-flow.test.ts`

- [ ] **Step 1: Grep all ErrorCode usages**

Run: `cd sharework-api && grep -rn "ErrorCode\.\(UNAUTHORIZED\|VALIDATION_ERROR\)" src/ tests/`
Expected: 출력된 모든 위치를 변경 대상으로 식별.

- [ ] **Step 2: Update errors.ts**

Edit `sharework-api/src/lib/errors.ts`:

```typescript
export enum ErrorCode {
  AUTH_REQUIRED = 'AUTH_REQUIRED',   // 401 — Authorization 헤더 없음
  AUTH_INVALID = 'AUTH_INVALID',     // 401 — JWT 만료/위조/sub 없음
  FORBIDDEN = 'FORBIDDEN',           // 403 — 권한 없음 (RLS 거부 등)
  NOT_FOUND = 'NOT_FOUND',           // 404
  VALIDATION = 'VALIDATION',          // 400 — zod 실패
  INTERNAL = 'INTERNAL',             // 500
}

export const ERROR_HTTP_STATUS: Record<ErrorCode, number> = {
  [ErrorCode.AUTH_REQUIRED]: 401,
  [ErrorCode.AUTH_INVALID]: 401,
  [ErrorCode.FORBIDDEN]: 403,
  [ErrorCode.NOT_FOUND]: 404,
  [ErrorCode.VALIDATION]: 400,
  [ErrorCode.INTERNAL]: 500,
};

export class AppError extends Error {
  constructor(public code: ErrorCode, message: string) {
    super(message);
    this.name = 'AppError';
  }
}
```

- [ ] **Step 3: Update call sites — me/route.ts**

Edit `sharework-api/src/app/api/me/route.ts`:
- `ErrorCode.NOT_FOUND` → 그대로
- `ErrorCode.INTERNAL` → 그대로

(me route는 UNAUTHORIZED 명시 호출 없음 — verifyAccessToken에서 throw)

- [ ] **Step 4: Update jobs/route.ts + jobs/[id]/route.ts + categories/route.ts**

각 파일에서 `ErrorCode.VALIDATION_ERROR` → `ErrorCode.VALIDATION` rename. UNAUTHORIZED 직접 호출 없음.

Run: `cd sharework-api && grep -l "VALIDATION_ERROR" src/`
모든 위치에서 sed 또는 Edit으로 rename:

```bash
# sed 예시 (Edit 도구 사용 가능)
# 각 파일을 grep → Edit으로 VALIDATION_ERROR → VALIDATION 치환
```

- [ ] **Step 5: Update jwt.ts (P1.2에서 미반영 부분)**

P1.2의 Step 6 코드 그대로 적용 — `ErrorCode.AUTH_REQUIRED`/`AUTH_INVALID` 사용 검증.

- [ ] **Step 6: Update tests/unit/jwt.test.ts**

기존 `ErrorCode.UNAUTHORIZED` assertion → `ErrorCode.AUTH_REQUIRED` (token 없음) 또는 `ErrorCode.AUTH_INVALID` (token 위조/만료) 으로 분리.

Read `sharework-api/tests/unit/jwt.test.ts` 한 뒤 case별 의미 매핑:
- `missing access token` 테스트 → `AUTH_REQUIRED`
- `invalid or expired token` / `jwt has no sub` → `AUTH_INVALID`

- [ ] **Step 7: Update all integration + e2e tests**

Run: `cd sharework-api && grep -rln "UNAUTHORIZED\|VALIDATION_ERROR" tests/`
각 파일에서 401 case의 assertion을 `AUTH_REQUIRED` 또는 `AUTH_INVALID` 의미별 분리. zod validation 실패 케이스는 `VALIDATION`.

- [ ] **Step 8: Run full test suite**

Run: `cd sharework-api && npx vitest run`
Expected: 모든 unit + integration PASS (e2e는 `RUN_E2E` 미설정 시 skip).

- [ ] **Step 9: Stage**

```bash
cd sharework-api && git add src/lib/errors.ts src/lib/jwt.ts src/app/api/me/route.ts src/app/api/jobs/route.ts src/app/api/jobs/[id]/route.ts src/app/api/categories/route.ts tests/unit/jwt.test.ts tests/unit/schemas.test.ts tests/integration/me.test.ts tests/integration/jobs-list.test.ts tests/integration/jobs-detail.test.ts tests/integration/categories.test.ts tests/e2e/m1-flow.test.ts
```

- [ ] **Step 10: Sprint 1B 단일 commit + push**

```bash
cd sharework-api && git status   # P1.1~P1.4 staged 확인
git commit -m "chore(bff): M1 carry-over hardening — security headers, env helper, ErrorCode align

- P1.1 next.config.ts 보안 헤더 4종 (HSTS, X-Frame, nosniff, Referrer, Permissions)
- P1.2 src/lib/env.ts requireEnv (R11 따옴표 strip + 누락 fail-fast)
- P1.3 dbFail 단위 테스트 (Sec H-1 carry-over 검증)
- P1.4 ErrorCode rename (UNAUTHORIZED 의미별 AUTH_REQUIRED/AUTH_INVALID 분리,
  VALIDATION_ERROR→VALIDATION, FORBIDDEN 추가)

Tests: 32+ unit/integration PASS (M1 29 + 신규 3)
R12 사전 정리 commit — Sprint 2 본 작업 commit 전 push 의무

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin main
```

Vercel 자동 배포 → production 보안 헤더 즉시 검증:

```bash
curl -I https://sharework-api.vercel.app/api/categories | grep -iE "strict-transport|x-frame|x-content-type|referrer-policy|permissions-policy"
```

Expected: 5개 헤더 모두 표시.

---

## Sprint 2 — M2 본 작업 (P2 마이그 + P3 BFF lib + P4 BFF API + B Flutter Giver)

> **순서 의무**: P2 → P3 → P4 → B 순차. P2 마이그가 적용되어야 P3 schemas + P4 API + B Flutter가 정상 동작. Sprint 2 내부에서는 staged 누적, Sprint 끝에 단일 commit.

### Task P2.1: 마이그 — profiles.public_id (B3 정정)

**Files:**
- Create: `sharework-api/supabase/migrations/20260511000001_profiles_public_id.sql`
- Modify: `sharework-api/tests/integration/me.test.ts` (P4.1 task에서 추가 — 본 task는 마이그만)

- [ ] **Step 1: Create migration file**

Write `sharework-api/supabase/migrations/20260511000001_profiles_public_id.sql`:

```sql
-- profiles.public_id : 외부 노출용 (Sec M-2.1 carry-over 해소)
-- B3 정정: 트리거 갱신을 NOT NULL 적용 *전*으로 이동.
--   순서: (1) add column nullable → (2) trigger REPLACE → (3) backfill → (4) NOT NULL → (5) unique+index
--   원인: 옛 트리거가 NOT NULL 적용 후/신규 트리거 적용 전에 fire하면 public_id 없이 insert → NOT NULL 위반 → signup 장애.

-- (1) add column nullable
alter table public.profiles add column public_id text;

-- (2) handle_new_user 트리거 신규 정의로 교체
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- M1 005 가드 유지: phone NULL이면 skip (email/OAuth/admin 등)
  if new.phone is null then
    return new;
  end if;

  insert into public.profiles (id, phone, name, role, public_id)
  values (
    new.id,
    new.phone,
    coalesce(right(new.phone, 4), 'user'),
    'worker',
    translate(substr(encode(gen_random_bytes(16), 'base64'), 1, 22), '+/=', 'XYZ')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- (3) backfill: 기존 row의 22자 URL-safe random
update public.profiles
set public_id = translate(substr(encode(gen_random_bytes(16), 'base64'), 1, 22), '+/=', 'XYZ')
where public_id is null;

-- (4) NOT NULL 적용 (이 시점에 모든 row가 public_id 보유)
alter table public.profiles alter column public_id set not null;

-- (5) unique + index
alter table public.profiles add constraint profiles_public_id_unique unique (public_id);
create index profiles_public_id_idx on public.profiles(public_id);
```

- [ ] **Step 2: Push migration**

```bash
cd sharework-api && supabase db push
```

Expected: `20260511000001_profiles_public_id ... applied`.

- [ ] **Step 3: Verify backfill (production Supabase SQL Editor 또는 psql)**

```sql
select count(*) as total, count(public_id) as with_public_id from profiles;
-- 둘이 같아야 함
select count(distinct public_id) from profiles where length(public_id) = 22;
-- total과 동일
```

- [ ] **Step 4: Verify new signup includes public_id**

Run new OTP signup via curl or M1 e2e — 새 profile row에 `public_id` 22자 자동 채워짐 확인.

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add supabase/migrations/20260511000001_profiles_public_id.sql
```

---

### Task P2.2: 마이그 — job_photos (V1 + B1 정정)

**Files:**
- Create: `sharework-api/supabase/migrations/20260511000002_job_photos.sql`

- [ ] **Step 0 (R5 grep 의무 — Plan 리뷰 CR M5)**: Postgres docs + supabase-js rpc 동작 확인

```bash
# (1) DEFERRABLE UNIQUE 동작 재확인
# https://www.postgresql.org/docs/current/sql-createtable.html → CONSTRAINT ... DEFERRABLE INITIALLY DEFERRED
# (2) supabase-js rpc + service role 동작 — RPC body에서 auth.uid()=null 확인
grep -r "auth\.uid\|jwt.claims" /Users/sengmindavidhyun/Documents/David/projects/sharework-api/node_modules/@supabase/supabase-js/dist/main/*.js 2>/dev/null | head -5
```

결과 confirm 후 P2.2 RPC `p_user_id` 인자 패턴 lock-in (본 plan은 이미 적용됨 — grep은 시그니처 확정 근거 보존용).

- [ ] **Step 1: Create migration file**

Write `sharework-api/supabase/migrations/20260511000002_job_photos.sql`:

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
  -- V1 정정: NOT DEFERRABLE UNIQUE는 row-by-row 검사 → reorder UPDATE swap이 violation
  -- DEFERRABLE INITIALLY DEFERRED로 statement/transaction 끝에서 검사
  constraint job_photos_position_unique unique (job_id, position) deferrable initially deferred
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

-- Race-safe insert RPC (B1 정정: gap fill, max+1은 DELETE 후 CHECK 위반)
-- Plan 리뷰 SA/CR M2: p_user_id 명시 인자 — service role 클라이언트 auth.uid()=null 문제 회피.
-- BFF가 JWT verify로 검증한 userId를 전달, RPC는 BFF 신뢰.
create or replace function public.add_job_photo(
  p_job_id uuid, p_user_id uuid, p_storage_path text, p_mime text,
  p_size int, p_w int, p_h int
) returns public.job_photos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_next_pos int;
  v_photo public.job_photos;
begin
  perform 1 from public.jobs
  where id = p_job_id and giver_id = p_user_id
  for update;
  if not found then raise exception 'forbidden' using errcode = '42501'; end if;

  select count(*) into v_count from public.job_photos where job_id = p_job_id;
  if v_count >= 5 then raise exception 'photo_limit' using errcode = 'P0001'; end if;

  -- gap fill: 1~5 중 가장 작은 미사용 position 선택
  select min(g) into v_next_pos
  from generate_series(1, 5) g
  where g not in (
    select position from public.job_photos where job_id = p_job_id
  );

  if v_next_pos is null then
    raise exception 'photo_limit' using errcode = 'P0001';
  end if;

  insert into public.job_photos
    (job_id, storage_path, position, mime_type, file_size_bytes, width, height)
  values (p_job_id, p_storage_path, v_next_pos, p_mime, p_size, p_w, p_h)
  returning * into v_photo;
  return v_photo;
end;
$$;

-- Reorder RPC (전체 photo_id 일치 + 순서 일괄 update + DEFERRABLE 활용)
-- Plan 리뷰: p_user_id 동일 패턴
create or replace function public.reorder_job_photos(
  p_job_id uuid, p_user_id uuid, p_order uuid[]
) returns setof public.job_photos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  perform 1 from public.jobs
  where id = p_job_id and giver_id = p_user_id
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
$$;

-- 권한: BFF는 service role로 호출하므로 별도 grant 불요.
-- 직접 authenticated/anon 호출 차단 (BFF 경유 강제):
revoke execute on function public.add_job_photo(uuid, uuid, text, text, int, int, int) from public, anon, authenticated;
revoke execute on function public.reorder_job_photos(uuid, uuid, uuid[]) from public, anon, authenticated;
```

- [ ] **Step 2: Push migration**

```bash
cd sharework-api && supabase db push
```

- [ ] **Step 3: Verify schema (Supabase SQL Editor)**

```sql
-- 테이블 + DEFERRABLE 확인
select conname, condeferrable, condeferred from pg_constraint
where conrelid = 'public.job_photos'::regclass and conname = 'job_photos_position_unique';
-- condeferrable=true, condeferred=true
```

- [ ] **Step 4: Smoke test — gap fill RPC**

테스트용 jobs row insert (giver_id = 본인 sub) → 3장 insert (pos 1,2,3) → pos 2 DELETE → 신규 insert → pos=2 (gap fill) 확인.

```sql
-- 환경: psql 또는 SQL Editor (service role 가정, RLS bypass)
-- 본 검증은 SDD 단계에서 옵션. integration test (P4.7)에서 자동 검증
```

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add supabase/migrations/20260511000002_job_photos.sql
```

---

### Task P2.3: 마이그 — storage bucket + RLS

**Files:**
- Create: `sharework-api/supabase/migrations/20260511000003_storage_job_photos.sql`

- [ ] **Step 1: Create migration file**

Write `sharework-api/supabase/migrations/20260511000003_storage_job_photos.sql`:

```sql
-- private bucket 생성 (이미 존재해도 안전)
insert into storage.buckets (id, name, public)
values ('job-photos', 'job-photos', false)
on conflict (id) do nothing;

-- 모든 Storage 작업은 BFF service role 경유 — 본 정책은 backstop (signed URL이 아닌 직접 access 시도 차단)
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

- [ ] **Step 2: Push migration**

```bash
cd sharework-api && supabase db push
```

- [ ] **Step 3: Verify bucket**

```sql
select id, name, public from storage.buckets where id = 'job-photos';
-- public=false
```

- [ ] **Step 4: Verify policies**

```sql
select policyname, cmd, qual from pg_policies
where schemaname='storage' and tablename='objects' and policyname like 'job_photos_%';
-- insert + delete 2건
```

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add supabase/migrations/20260511000003_storage_job_photos.sql
```

---

### Task P3.1: BFF lib — rate-limit.ts (Upstash sliding window)

**Files:**
- Modify: `sharework-api/package.json` (deps + @upstash/ratelimit, @upstash/redis)
- Modify: `sharework-api/.env.example` (UPSTASH_REDIS_REST_URL/TOKEN 추가)
- Modify: `sharework-api/vitest.config.ts` (UPSTASH env mock 추가 — 단위 테스트 환경 fail-fast 회피)
- Create: `sharework-api/src/lib/rate-limit.ts`
- Create: `sharework-api/tests/unit/rate-limit.test.ts`

- [ ] **Step 0 (R5 grep 의무 — Plan 리뷰 CR M5)**: Upstash 패키지 + Vercel env 동작 docs 확인

```bash
# (1) @upstash/ratelimit + @upstash/redis 패키지 README — Redis.fromEnv() 자동 픽업 확인
cat /Users/sengmindavidhyun/Documents/David/projects/sharework-api/node_modules/@upstash/ratelimit/README.md 2>/dev/null | head -50
cat /Users/sengmindavidhyun/Documents/David/projects/sharework-api/node_modules/@upstash/redis/README.md 2>/dev/null | head -30
# (2) slidingWindow vs fixedWindow 동작 — token reset 시점
# (3) Vercel env 등록 형식 — R11 따옴표 strip
```

기본 동작이 spec과 차이 있을 시 본 task 진입 직전 plan 본문 정정.

- [ ] **Step 1: Add deps**

```bash
cd sharework-api && npm install @upstash/ratelimit @upstash/redis
```

`package.json` dependencies에 `"@upstash/ratelimit": "^2.x.x"`, `"@upstash/redis": "^1.x.x"` 추가 확인.

- [ ] **Step 2: Update .env.example**

Edit `sharework-api/.env.example` append:

```
# Upstash Redis (M2 rate limiting)
UPSTASH_REDIS_REST_URL=https://your-db.upstash.io
UPSTASH_REDIS_REST_TOKEN=AX...
```

- [ ] **Step 3: Update vitest.config.ts (env stub for unit test)**

Edit `sharework-api/vitest.config.ts` — `test.env` 추가:

```typescript
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    environment: 'node',
    env: {
      // 단위 테스트에서 Redis.fromEnv() fail-fast 회피용 mock 값
      UPSTASH_REDIS_REST_URL: 'https://stub.upstash.io',
      UPSTASH_REDIS_REST_TOKEN: 'stub_token',
    },
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, 'src') },
  },
});
```

> M1 vitest.config.ts 그대로 보존 + `test.env` 추가. Module load 시점 `Redis.fromEnv()` 호출이 missing env로 throw하면 모든 test 회귀 — fail-fast 의도 보존하면서 단위 테스트는 mock 값으로 통과.

- [ ] **Step 4: Write failing test**

Create `sharework-api/tests/unit/rate-limit.test.ts`:

```typescript
import { describe, it, expect, vi } from 'vitest';

vi.mock('@upstash/ratelimit', () => {
  return {
    Ratelimit: class MockRatelimit {
      static slidingWindow = vi.fn((n: number, w: string) => ({ kind: 'sliding', n, w }));
      limit = vi.fn(async (key: string) => {
        // 30번째까지 성공, 31번째부터 실패 시뮬레이션 — key당 카운터
        const cnt = (this._cnt[key] ?? 0) + 1;
        this._cnt[key] = cnt;
        return { success: cnt <= 30, reset: Date.now() + 60_000, limit: 30, remaining: Math.max(0, 30 - cnt) };
      });
      _cnt: Record<string, number> = {};
      constructor(public opts: any) {}
    },
  };
});

vi.mock('@upstash/redis', () => ({ Redis: { fromEnv: () => ({}) } }));

import { jobWriteLimiter } from '@/lib/rate-limit';

describe('jobWriteLimiter', () => {
  it('allows first 30 requests, blocks 31st (sliding window 30/min)', async () => {
    for (let i = 0; i < 30; i++) {
      const r = await jobWriteLimiter.limit('user:test1');
      expect(r.success).toBe(true);
    }
    const blocked = await jobWriteLimiter.limit('user:test1');
    expect(blocked.success).toBe(false);
    expect(blocked.reset).toBeGreaterThan(Date.now());
  });

  it('keys are independent', async () => {
    const r1 = await jobWriteLimiter.limit('user:other');
    expect(r1.success).toBe(true);
  });
});
```

- [ ] **Step 5: Run test to verify it fails**

Run: `cd sharework-api && npx vitest run tests/unit/rate-limit.test.ts`
Expected: FAIL — Cannot find module `@/lib/rate-limit`.

- [ ] **Step 6: Implement rate-limit.ts**

Create `sharework-api/src/lib/rate-limit.ts`:

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

// Redis.fromEnv() 픽업: UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN
const redis = Redis.fromEnv();

export const jobWriteLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(30, '1 m'),
  prefix: 'rl:job-write',
  analytics: true,
});

/** Helper for route handlers: returns retryAfter seconds when blocked. */
export async function checkJobWriteLimit(profileId: string): Promise<{ ok: boolean; retryAfterSec: number }> {
  const { success, reset } = await jobWriteLimiter.limit(`user:${profileId}`);
  return {
    ok: success,
    retryAfterSec: success ? 0 : Math.ceil((reset - Date.now()) / 1000),
  };
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `cd sharework-api && npx vitest run tests/unit/rate-limit.test.ts`
Expected: PASS (2 tests).

- [ ] **Step 8: Stage**

```bash
cd sharework-api && git add package.json package-lock.json .env.example vitest.config.ts src/lib/rate-limit.ts tests/unit/rate-limit.test.ts
```

---

### Task P3.2: BFF lib — errors.ts M2 ErrorCode 6개 확장

**Files:**
- Modify: `sharework-api/src/lib/errors.ts`

- [ ] **Step 1: Append M2 ErrorCodes**

Edit `sharework-api/src/lib/errors.ts`:

```typescript
export enum ErrorCode {
  // M1 baseline (P1.4)
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  AUTH_INVALID = 'AUTH_INVALID',
  FORBIDDEN = 'FORBIDDEN',
  NOT_FOUND = 'NOT_FOUND',
  VALIDATION = 'VALIDATION',
  INTERNAL = 'INTERNAL',
  // M2 신규
  STORAGE_FAIL = 'STORAGE_FAIL',
  RATE_LIMITED = 'RATE_LIMITED',
  PHOTO_LIMIT_EXCEEDED = 'PHOTO_LIMIT_EXCEEDED',
  PHOTO_FILE_INVALID = 'PHOTO_FILE_INVALID',
  PHOTO_NOT_UPLOADED = 'PHOTO_NOT_UPLOADED',
  JOB_STATE_INVALID = 'JOB_STATE_INVALID',
}

export const ERROR_HTTP_STATUS: Record<ErrorCode, number> = {
  [ErrorCode.AUTH_REQUIRED]: 401,
  [ErrorCode.AUTH_INVALID]: 401,
  [ErrorCode.FORBIDDEN]: 403,
  [ErrorCode.NOT_FOUND]: 404,
  [ErrorCode.VALIDATION]: 400,
  [ErrorCode.INTERNAL]: 500,
  [ErrorCode.STORAGE_FAIL]: 500,
  [ErrorCode.RATE_LIMITED]: 429,
  [ErrorCode.PHOTO_LIMIT_EXCEEDED]: 409,
  [ErrorCode.PHOTO_FILE_INVALID]: 400,
  [ErrorCode.PHOTO_NOT_UPLOADED]: 422,
  [ErrorCode.JOB_STATE_INVALID]: 409,
};

export class AppError extends Error {
  constructor(public code: ErrorCode, message: string) {
    super(message);
    this.name = 'AppError';
  }
}
```

- [ ] **Step 2: Add unit test for status mapping**

Edit `sharework-api/tests/unit/envelope.test.ts` append:

```typescript
describe('ERROR_HTTP_STATUS — M2', () => {
  it('maps M2 codes to expected HTTP statuses', () => {
    expect(ERROR_HTTP_STATUS[ErrorCode.STORAGE_FAIL]).toBe(500);
    expect(ERROR_HTTP_STATUS[ErrorCode.RATE_LIMITED]).toBe(429);
    expect(ERROR_HTTP_STATUS[ErrorCode.PHOTO_LIMIT_EXCEEDED]).toBe(409);
    expect(ERROR_HTTP_STATUS[ErrorCode.PHOTO_FILE_INVALID]).toBe(400);
    expect(ERROR_HTTP_STATUS[ErrorCode.PHOTO_NOT_UPLOADED]).toBe(422);
    expect(ERROR_HTTP_STATUS[ErrorCode.JOB_STATE_INVALID]).toBe(409);
  });
});
```

(import 행 추가: `import { ERROR_HTTP_STATUS } from '@/lib/errors';`)

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/unit/envelope.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/lib/errors.ts tests/unit/envelope.test.ts
```

---

### Task P3.3: BFF lib — schemas.ts M2 schemas 6개 추가

**Files:**
- Modify: `sharework-api/src/lib/schemas.ts`
- Modify: `sharework-api/tests/unit/schemas.test.ts`

- [ ] **Step 1: Write failing tests**

Edit `sharework-api/tests/unit/schemas.test.ts` append:

```typescript
import {
  jobCreateSchema, jobUpdateSchema, photoUploadUrlSchema,
  photoConfirmSchema, photoReorderSchema, meJobsQuerySchema,
} from '@/lib/schemas';

describe('jobCreateSchema', () => {
  it('accepts minimal valid payload', () => {
    const parsed = jobCreateSchema.parse({
      title: 'Test', description: 'D', wage_won: 10000,
      category_id: '00000000-0000-0000-0000-000000000001',
      location_address: 'Seoul',
    });
    expect(parsed.title).toBe('Test');
  });

  it('rejects title too long', () => {
    expect(() => jobCreateSchema.parse({
      title: 'x'.repeat(101), description: 'D', wage_won: 10000,
      category_id: '00000000-0000-0000-0000-000000000001',
      location_address: 'Seoul',
    })).toThrow();
  });

  it('rejects wage_won negative', () => {
    expect(() => jobCreateSchema.parse({
      title: 'T', description: 'D', wage_won: -1,
      category_id: '00000000-0000-0000-0000-000000000001', location_address: 'S',
    })).toThrow();
  });
});

describe('jobUpdateSchema', () => {
  it('accepts status only', () => {
    expect(jobUpdateSchema.parse({ status: 'paused' })).toEqual({ status: 'paused' });
  });

  it('rejects invalid status', () => {
    expect(() => jobUpdateSchema.parse({ status: 'archived' })).toThrow();
  });

  it('accepts empty (no-op update)', () => {
    expect(jobUpdateSchema.parse({})).toEqual({});
  });
});

describe('photoUploadUrlSchema', () => {
  it('accepts jpeg + 1MB', () => {
    expect(photoUploadUrlSchema.parse({ mime_type: 'image/jpeg', file_size_bytes: 1_000_000 })).toBeDefined();
  });

  it('rejects mime gif', () => {
    expect(() => photoUploadUrlSchema.parse({ mime_type: 'image/gif', file_size_bytes: 1 })).toThrow();
  });

  it('rejects size 0', () => {
    expect(() => photoUploadUrlSchema.parse({ mime_type: 'image/jpeg', file_size_bytes: 0 })).toThrow();
  });

  it('rejects size > 10MB', () => {
    expect(() => photoUploadUrlSchema.parse({ mime_type: 'image/jpeg', file_size_bytes: 10485761 })).toThrow();
  });
});

describe('photoConfirmSchema', () => {
  it('accepts well-formed storage_path', () => {
    expect(photoConfirmSchema.parse({
      storage_path: '00000000-0000-0000-0000-000000000001/00000000-0000-0000-0000-000000000002.jpg',
      mime_type: 'image/jpeg', file_size_bytes: 1000,
    })).toBeDefined();
  });

  it('rejects path missing uuid prefix', () => {
    expect(() => photoConfirmSchema.parse({
      storage_path: 'foo/bar.jpg', mime_type: 'image/jpeg', file_size_bytes: 1,
    })).toThrow();
  });

  it('rejects bad extension', () => {
    expect(() => photoConfirmSchema.parse({
      storage_path: '00000000-0000-0000-0000-000000000001/00000000-0000-0000-0000-000000000002.gif',
      mime_type: 'image/jpeg', file_size_bytes: 1,
    })).toThrow();
  });
});

describe('photoReorderSchema', () => {
  it('accepts 5 uuids', () => {
    const uuids = Array.from({ length: 5 }, (_, i) => `00000000-0000-0000-0000-00000000000${i}`);
    expect(photoReorderSchema.parse({ order: uuids })).toBeDefined();
  });

  it('rejects empty array', () => {
    expect(() => photoReorderSchema.parse({ order: [] })).toThrow();
  });

  it('rejects > 5 items', () => {
    const uuids = Array.from({ length: 6 }, (_, i) => `00000000-0000-0000-0000-00000000000${i}`);
    expect(() => photoReorderSchema.parse({ order: uuids })).toThrow();
  });
});

describe('meJobsQuerySchema', () => {
  it('accepts no status', () => {
    expect(meJobsQuerySchema.parse({})).toEqual({});
  });

  it('accepts status active', () => {
    expect(meJobsQuerySchema.parse({ status: 'active' })).toEqual({ status: 'active' });
  });

  it('rejects unknown status', () => {
    expect(() => meJobsQuerySchema.parse({ status: 'foo' })).toThrow();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd sharework-api && npx vitest run tests/unit/schemas.test.ts`
Expected: FAIL — schemas not exported.

- [ ] **Step 3: Implement schemas**

Edit `sharework-api/src/lib/schemas.ts` (기존 + append):

```typescript
import { z } from 'zod';

// M1
export const jobsQuerySchema = z.object({
  category: z.string().uuid().optional(),
  q: z.string().max(100).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
export type JobsQuery = z.infer<typeof jobsQuerySchema>;

export const jobIdParamSchema = z.object({ id: z.string().uuid() });

// M2
const STATUS = z.enum(['active', 'paused', 'closed']);
const MIME = z.enum(['image/jpeg', 'image/png', 'image/webp']);

export const jobCreateSchema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().min(1).max(2000),
  wage_won: z.number().int().min(0),
  schedule_text: z.string().max(200).optional(),
  category_id: z.string().uuid(),
  location_address: z.string().min(1).max(200),
  location_lat: z.number().optional(),
  location_lng: z.number().optional(),
});
export type JobCreate = z.infer<typeof jobCreateSchema>;

export const jobUpdateSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  description: z.string().min(1).max(2000).optional(),
  wage_won: z.number().int().min(0).optional(),
  schedule_text: z.string().max(200).optional(),
  category_id: z.string().uuid().optional(),
  location_address: z.string().min(1).max(200).optional(),
  location_lat: z.number().optional(),
  location_lng: z.number().optional(),
  status: STATUS.optional(),
});
export type JobUpdate = z.infer<typeof jobUpdateSchema>;

export const photoUploadUrlSchema = z.object({
  mime_type: MIME,
  file_size_bytes: z.number().int().min(1).max(10485760),
});
export type PhotoUploadUrl = z.infer<typeof photoUploadUrlSchema>;

export const photoConfirmSchema = z.object({
  storage_path: z.string().regex(/^[0-9a-f-]{36}\/[0-9a-f-]{36}\.(jpg|png|webp)$/),
  mime_type: MIME,
  file_size_bytes: z.number().int().min(1).max(10485760),
  width: z.number().int().optional(),
  height: z.number().int().optional(),
});
export type PhotoConfirm = z.infer<typeof photoConfirmSchema>;

export const photoReorderSchema = z.object({
  order: z.array(z.string().uuid()).min(1).max(5),
});
export type PhotoReorder = z.infer<typeof photoReorderSchema>;

export const photoIdParamSchema = z.object({
  id: z.string().uuid(),
  photoId: z.string().uuid(),
});

export const meJobsQuerySchema = z.object({
  status: z.enum(['active', 'paused', 'closed']).optional(),
});
export type MeJobsQuery = z.infer<typeof meJobsQuerySchema>;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd sharework-api && npx vitest run tests/unit/schemas.test.ts`
Expected: PASS (모든 신규 + 기존 PASS).

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add src/lib/schemas.ts tests/unit/schemas.test.ts
```

---

### Task P3.4: BFF lib — storage.ts (signed URL 발급)

**Files:**
- Create: `sharework-api/src/lib/storage.ts`
- Create: `sharework-api/tests/unit/storage.test.ts`

- [ ] **Step 1: Write failing tests**

Create `sharework-api/tests/unit/storage.test.ts`:

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  BUCKET, createUploadUrl, createDownloadUrl, headObject, removeObject, buildStoragePath,
} from '@/lib/storage';

const mockFrom = {
  createSignedUploadUrl: vi.fn(),
  createSignedUrl: vi.fn(),
  list: vi.fn(),
  remove: vi.fn(),
};

vi.mock('@/lib/supabase', () => ({
  getServiceRoleClient: () => ({
    storage: { from: vi.fn(() => mockFrom) },
  }),
}));

beforeEach(() => {
  vi.clearAllMocks();
});

describe('storage helpers', () => {
  it('BUCKET = job-photos', () => {
    expect(BUCKET).toBe('job-photos');
  });

  it('buildStoragePath formats {jobId}/{photoId}.{ext}', () => {
    expect(buildStoragePath('j-uuid', 'p-uuid', 'image/jpeg')).toBe('j-uuid/p-uuid.jpg');
    expect(buildStoragePath('j-uuid', 'p-uuid', 'image/png')).toBe('j-uuid/p-uuid.png');
    expect(buildStoragePath('j-uuid', 'p-uuid', 'image/webp')).toBe('j-uuid/p-uuid.webp');
  });

  it('createUploadUrl: 5min TTL', async () => {
    mockFrom.createSignedUploadUrl.mockResolvedValue({
      data: { signedUrl: 'https://...', path: 'jid/pid.jpg', token: 'tok' },
      error: null,
    });
    const r = await createUploadUrl('jid/pid.jpg');
    expect(mockFrom.createSignedUploadUrl).toHaveBeenCalledWith('jid/pid.jpg');
    expect(r.uploadUrl).toBe('https://...');
  });

  it('createUploadUrl: throws on error', async () => {
    mockFrom.createSignedUploadUrl.mockResolvedValue({ data: null, error: { message: 'fail' } });
    await expect(createUploadUrl('p')).rejects.toThrow(/signed upload url/);
  });

  it('createDownloadUrl: 24h TTL = 86400', async () => {
    mockFrom.createSignedUrl.mockResolvedValue({ data: { signedUrl: 'https://dl' }, error: null });
    await createDownloadUrl('p');
    expect(mockFrom.createSignedUrl).toHaveBeenCalledWith('p', 86400);
  });

  it('headObject: returns true if exists', async () => {
    mockFrom.list.mockResolvedValue({ data: [{ name: 'pid.jpg' }], error: null });
    expect(await headObject('jid/pid.jpg')).toBe(true);
  });

  it('headObject: returns false if not found', async () => {
    mockFrom.list.mockResolvedValue({ data: [], error: null });
    expect(await headObject('jid/pid.jpg')).toBe(false);
  });

  it('removeObject: calls storage.remove', async () => {
    mockFrom.remove.mockResolvedValue({ data: [], error: null });
    await removeObject('jid/pid.jpg');
    expect(mockFrom.remove).toHaveBeenCalledWith(['jid/pid.jpg']);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd sharework-api && npx vitest run tests/unit/storage.test.ts`
Expected: FAIL — Cannot find module `@/lib/storage`.

- [ ] **Step 3: Implement storage.ts**

Create `sharework-api/src/lib/storage.ts`:

```typescript
import { AppError, ErrorCode } from './errors';
import { getServiceRoleClient } from './supabase';

export const BUCKET = 'job-photos' as const;

const UPLOAD_TTL_SEC = 300; // 5 minutes
const DOWNLOAD_TTL_SEC = 86400; // 24 hours

const MIME_EXT: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export function buildStoragePath(jobId: string, photoId: string, mime: string): string {
  const ext = MIME_EXT[mime];
  if (!ext) throw new AppError(ErrorCode.VALIDATION, 'unsupported mime');
  return `${jobId}/${photoId}.${ext}`;
}

export async function createUploadUrl(path: string): Promise<{ uploadUrl: string; token: string; expiresAtMs: number }> {
  const supabase = getServiceRoleClient();
  // @upstash/supabase-js v2 createSignedUploadUrl ignores the TTL; Supabase Storage default is ~2h.
  // 명시 short TTL 패턴이 필요하면 별도 token JWT 발급 패턴으로 전환 (M3+ 검토).
  // M2 spec D5는 "5분"이지만 supabase-js v2 default가 ~2h이므로 보수적으로 path를 photo_id 기반 unique 발급으로 단일 사용 강제.
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUploadUrl(path);
  if (error || !data) {
    throw new AppError(ErrorCode.STORAGE_FAIL, `signed upload url: ${error?.message ?? 'unknown'}`);
  }
  return { uploadUrl: data.signedUrl, token: data.token, expiresAtMs: Date.now() + UPLOAD_TTL_SEC * 1000 };
}

export async function createDownloadUrl(path: string): Promise<string> {
  const supabase = getServiceRoleClient();
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUrl(path, DOWNLOAD_TTL_SEC);
  if (error || !data) {
    throw new AppError(ErrorCode.STORAGE_FAIL, `signed url: ${error?.message ?? 'unknown'}`);
  }
  return data.signedUrl;
}

/** HEAD-like: list with search to verify object exists. */
export async function headObject(path: string): Promise<boolean> {
  const supabase = getServiceRoleClient();
  const slash = path.lastIndexOf('/');
  const dir = slash >= 0 ? path.slice(0, slash) : '';
  const file = slash >= 0 ? path.slice(slash + 1) : path;
  const { data, error } = await supabase.storage.from(BUCKET).list(dir, { search: file });
  if (error) return false;
  return Array.isArray(data) && data.some((o) => o.name === file);
}

export async function removeObject(path: string): Promise<void> {
  const supabase = getServiceRoleClient();
  const { error } = await supabase.storage.from(BUCKET).remove([path]);
  if (error) {
    console.error('[storage] remove failed', { path, message: error.message });
  }
}
```

> **참고**: spec D5 "upload 5분 TTL"은 supabase-js v2 `createSignedUploadUrl` 동작과 미스매치 가능 — supabase-js v2는 token에 TTL 약 2시간 default. 5분 TTL 강제는 별도 JWT 발급 패턴이 필요. 본 plan은 보수적으로 default TTL 사용하되 photo_id (uuidv4)를 BFF가 발급해서 path uniqueness 보장 → 같은 token으로 다른 photo 덮어쓰기 불가. SDD 단계에서 supabase-js docs 직접 grep 확인 후 5분 TTL 가능 시 옵션 추가.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd sharework-api && npx vitest run tests/unit/storage.test.ts`
Expected: PASS.

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add src/lib/storage.ts tests/unit/storage.test.ts
```

---

### Task P3.5: BFF lib — photo-mapping.ts

**Files:**
- Create: `sharework-api/src/lib/photo-mapping.ts`
- Create: `sharework-api/tests/unit/photo-mapping.test.ts`

- [ ] **Step 1: Write failing test**

Create `sharework-api/tests/unit/photo-mapping.test.ts`:

```typescript
import { describe, it, expect, vi } from 'vitest';
import { mapCoverPhoto, mapAllPhotos } from '@/lib/photo-mapping';

vi.mock('@/lib/storage', () => ({
  createDownloadUrl: vi.fn(async (p: string) => `https://signed/${p}`),
}));

describe('photo-mapping', () => {
  it('mapCoverPhoto: returns position=1 only', async () => {
    const photos = [
      { id: 'p2', position: 2, storage_path: 'j/p2.jpg' },
      { id: 'p1', position: 1, storage_path: 'j/p1.jpg' },
    ];
    const r = await mapCoverPhoto(photos);
    expect(r).toEqual([{ id: 'p1', position: 1, signed_url: 'https://signed/j/p1.jpg' }]);
  });

  it('mapCoverPhoto: returns [] when no photos', async () => {
    expect(await mapCoverPhoto([])).toEqual([]);
  });

  it('mapAllPhotos: returns sorted by position', async () => {
    const photos = [
      { id: 'p3', position: 3, storage_path: 'j/p3.jpg' },
      { id: 'p1', position: 1, storage_path: 'j/p1.jpg' },
      { id: 'p2', position: 2, storage_path: 'j/p2.jpg' },
    ];
    const r = await mapAllPhotos(photos);
    expect(r.map((p) => p.position)).toEqual([1, 2, 3]);
    expect(r[0].signed_url).toBe('https://signed/j/p1.jpg');
  });
});
```

- [ ] **Step 2: Run test (fails)**

Run: `cd sharework-api && npx vitest run tests/unit/photo-mapping.test.ts`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement photo-mapping.ts**

Create `sharework-api/src/lib/photo-mapping.ts`:

```typescript
import { createDownloadUrl } from './storage';

export type PhotoRow = {
  id: string;
  position: number;
  storage_path: string;
};

export type PhotoView = {
  id: string;
  position: number;
  signed_url: string;
};

export async function mapCoverPhoto(photos: PhotoRow[]): Promise<PhotoView[]> {
  const cover = photos.find((p) => p.position === 1);
  if (!cover) return [];
  return [{ id: cover.id, position: 1, signed_url: await createDownloadUrl(cover.storage_path) }];
}

export async function mapAllPhotos(photos: PhotoRow[]): Promise<PhotoView[]> {
  const sorted = [...photos].sort((a, b) => a.position - b.position);
  return Promise.all(
    sorted.map(async (p) => ({ id: p.id, position: p.position, signed_url: await createDownloadUrl(p.storage_path) }))
  );
}
```

- [ ] **Step 4: Run test (pass)**

Run: `cd sharework-api && npx vitest run tests/unit/photo-mapping.test.ts`
Expected: PASS.

- [ ] **Step 5: Stage**

```bash
cd sharework-api && git add src/lib/photo-mapping.ts tests/unit/photo-mapping.test.ts
```

---

### Task P4.1: API — GET /api/me (응답 schema + public_id)

**Files:**
- Modify: `sharework-api/src/app/api/me/route.ts`
- Modify: `sharework-api/tests/integration/me.test.ts`

- [ ] **Step 1: Update integration test for public_id assertion**

Edit `sharework-api/tests/integration/me.test.ts` — 응답에 `public_id` 필드 있고 22자 길이 검증 추가:

```typescript
it('returns profile with public_id (22 chars)', async () => {
  // ... 기존 setup (Supabase admin signup + JWT 발급 + GET /api/me)
  const res = await GET(req);
  expect(res.status).toBe(200);
  const body = await res.json();
  expect(body.data.public_id).toMatch(/^[A-Za-z0-9XYZ]{22}$/);
  expect(body.data.id).toBeDefined();
  expect(body.data.phone).toBeDefined();
});
```

- [ ] **Step 2: Update /api/me route**

Edit `sharework-api/src/app/api/me/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';

export async function GET(req: Request) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('id, phone, name, role, public_id, created_at, updated_at')
      .eq('id', userId)
      .maybeSingle();

    if (error) return dbFail('me', error);
    if (!data) return fail(ErrorCode.NOT_FOUND, 'profile not found');

    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run integration test**

Run: `cd sharework-api && npx vitest run tests/integration/me.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/me/route.ts tests/integration/me.test.ts
```

---

### Task P4.2: API — GET /api/me/jobs (본인 공고)

**Files:**
- Create: `sharework-api/src/app/api/me/jobs/route.ts`
- Create: `sharework-api/tests/integration/me-jobs.test.ts`

- [ ] **Step 1: Write failing integration test**

Create `sharework-api/tests/integration/me-jobs.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { GET } from '@/app/api/me/jobs/route';
// integration test setup: Supabase admin → signup giver+worker → insert jobs → JWT 발급 (M1 패턴 그대로)

describe('GET /api/me/jobs', () => {
  it('returns 401 without bearer', async () => {
    const req = new Request('http://localhost/api/me/jobs');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns own jobs across statuses (default)', async () => {
    // setup: giver A inserts 3 jobs (active, paused, closed), worker B is irrelevant
    // ... (M1 패턴 — adminSignup + JWT)
    const res = await GET(reqAsGiver);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.items).toHaveLength(3);
    const statuses = body.data.items.map((j: any) => j.status).sort();
    expect(statuses).toEqual(['active', 'closed', 'paused']);
  });

  it('filters by status=active', async () => {
    const url = 'http://localhost/api/me/jobs?status=active';
    const res = await GET(new Request(url, { headers: { authorization: `Bearer ${giverJwt}` } }));
    const body = await res.json();
    expect(body.data.items.every((j: any) => j.status === 'active')).toBe(true);
  });

  it('rejects invalid status', async () => {
    const url = 'http://localhost/api/me/jobs?status=archived';
    const res = await GET(new Request(url, { headers: { authorization: `Bearer ${giverJwt}` } }));
    expect(res.status).toBe(400);
  });

  it('includes cover photo signed_url when photos exist', async () => {
    // setup: insert job_photos for giver A's first job, position=1
    // ... assert body.data.items[0].photos[0].signed_url matches URL pattern
  });
});
```

- [ ] **Step 2: Implement route**

Create `sharework-api/src/app/api/me/jobs/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { meJobsQuerySchema } from '@/lib/schemas';
import { mapCoverPhoto } from '@/lib/photo-mapping';
import { z } from 'zod';

export async function GET(req: Request) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const url = new URL(req.url);
    const queryRaw = Object.fromEntries(url.searchParams.entries());

    let query;
    try {
      query = meJobsQuerySchema.parse(queryRaw);
    } catch (err) {
      if (err instanceof z.ZodError) {
        return fail(ErrorCode.VALIDATION, 'invalid query parameters');
      }
      throw err;
    }

    const supabase = getServiceRoleClient();
    let builder = supabase
      .from('jobs')
      .select(
        'id, title, description, wage_won, schedule_text, status, category_id, location_address, created_at, updated_at, job_photos(id, position, storage_path)'
      )
      .eq('giver_id', userId)
      .order('created_at', { ascending: false });

    if (query.status) builder = builder.eq('status', query.status);

    const { data, error } = await builder;
    if (error) return dbFail('me/jobs', error);

    const items = await Promise.all(
      (data ?? []).map(async (j: any) => ({
        id: j.id,
        title: j.title,
        description: j.description,
        wage_won: j.wage_won,
        schedule_text: j.schedule_text,
        status: j.status,
        category_id: j.category_id,
        location_address: j.location_address,
        created_at: j.created_at,
        updated_at: j.updated_at,
        photos: await mapCoverPhoto(j.job_photos ?? []),
      }))
    );

    return ok({ items });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/me-jobs.test.ts`
Expected: PASS (5 cases).

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/me/jobs/route.ts tests/integration/me-jobs.test.ts
```

---

### Task P4.3: API — GET /api/jobs (응답 schema 변경: giver + photos)

**Files:**
- Modify: `sharework-api/src/app/api/jobs/route.ts`
- Modify: `sharework-api/tests/integration/jobs-list.test.ts`

- [ ] **Step 1: Update test for giver + photos**

Edit `sharework-api/tests/integration/jobs-list.test.ts` — items 각 row가 `giver: {public_id, name}` + `photos: []` 또는 `photos: [{id, position, signed_url}]` 포함하는지 assertion 추가. `giver_id` 직접 노출 X.

```typescript
it('items expose giver.public_id, not giver_id raw', async () => {
  // ... 기존 setup
  const body = await res.json();
  for (const job of body.data) {
    expect(job.giver_id).toBeUndefined();
    expect(job.giver).toBeDefined();
    expect(job.giver.public_id).toMatch(/^[A-Za-z0-9XYZ]{22}$/);
    expect(job.giver.name).toBeDefined();
    expect(Array.isArray(job.photos)).toBe(true);
    expect(job.photos.length).toBeLessThanOrEqual(1); // cover only
  }
});

it('cover photo includes signed_url', async () => {
  // setup: insert job_photos (position=1) for first job
  const body = await res.json();
  const withPhoto = body.data.find((j: any) => j.photos.length > 0);
  expect(withPhoto?.photos[0].signed_url).toMatch(/^https:\/\//);
  expect(withPhoto?.photos[0].position).toBe(1);
});
```

- [ ] **Step 2: Update jobs/route.ts**

Edit `sharework-api/src/app/api/jobs/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobsQuerySchema, jobCreateSchema } from '@/lib/schemas';
import { mapCoverPhoto } from '@/lib/photo-mapping';
import { checkJobWriteLimit } from '@/lib/rate-limit';
import { z } from 'zod';

export async function GET(req: Request) {
  try {
    const token = extractBearerToken(req);
    await verifyAccessToken(token);

    const url = new URL(req.url);
    const queryRaw = Object.fromEntries(url.searchParams.entries());

    let query;
    try {
      query = jobsQuerySchema.parse(queryRaw);
    } catch (err) {
      if (err instanceof z.ZodError) return fail(ErrorCode.VALIDATION, 'invalid query parameters');
      throw err;
    }

    const { page, limit, category, q } = query;
    const supabase = getServiceRoleClient();

    let builder = supabase
      .from('jobs')
      .select(
        'id, title, description, wage_won, schedule_text, status, category_id, location_address, created_at, updated_at, profiles!jobs_giver_id_fkey(public_id, name), job_photos(id, position, storage_path)',
        { count: 'exact' }
      )
      .eq('status', 'active');

    if (category) builder = builder.eq('category_id', category);
    if (q) {
      const safeQ = q.replace(/[%_\\]/g, (c) => `\\${c}`);
      builder = builder.ilike('title', `%${safeQ}%`);
    }

    builder = builder.order('created_at', { ascending: false });

    const from = (page - 1) * limit;
    const to = from + limit - 1;
    const { data, error, count } = await builder.range(from, to);

    if (error) return dbFail('jobs', error);

    const items = await Promise.all(
      (data ?? []).map(async (j: any) => ({
        id: j.id,
        title: j.title,
        description: j.description,
        wage_won: j.wage_won,
        schedule_text: j.schedule_text,
        status: j.status,
        category_id: j.category_id,
        location_address: j.location_address,
        created_at: j.created_at,
        updated_at: j.updated_at,
        giver: { public_id: j.profiles.public_id, name: j.profiles.name },
        photos: await mapCoverPhoto(j.job_photos ?? []),
      }))
    );

    return ok(items, { page: { total: count ?? 0, page, limit } });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}

export async function POST(req: Request) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const raw = await req.json();
    let body;
    try {
      body = jobCreateSchema.parse(raw);
    } catch (err) {
      if (err instanceof z.ZodError) return fail(ErrorCode.VALIDATION, 'invalid body');
      throw err;
    }

    const supabase = getServiceRoleClient();
    const { data, error } = await supabase
      .from('jobs')
      .insert({
        giver_id: userId,
        title: body.title,
        description: body.description,
        wage_won: body.wage_won,
        schedule_text: body.schedule_text ?? null,
        category_id: body.category_id,
        location_address: body.location_address,
        location_lat: body.location_lat ?? null,
        location_lng: body.location_lng ?? null,
        status: 'active',
      })
      .select('id, title, description, wage_won, schedule_text, status, category_id, location_address, created_at, updated_at')
      .single();

    if (error) return dbFail('jobs.POST', error);
    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

> `profiles!jobs_giver_id_fkey(public_id, name)`은 Supabase PostgREST nested select. M1에서 별도 join 미사용 — M2 본 task에서 검증.

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/jobs-list.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/route.ts tests/integration/jobs-list.test.ts
```

---

### Task P4.4: API — GET + PATCH /api/jobs/:id (state machine)

**Files:**
- Modify: `sharework-api/src/app/api/jobs/[id]/route.ts`
- Modify: `sharework-api/tests/integration/jobs-detail.test.ts`

- [ ] **Step 1: Write failing tests (GET schema + PATCH state machine 7 cases)**

Edit `sharework-api/tests/integration/jobs-detail.test.ts` append:

```typescript
describe('GET /api/jobs/:id', () => {
  it('returns giver{public_id,name} + photos[] (all positions, signed_url)', async () => {
    // setup: giver A creates job + 3 photos (pos 1,2,3)
    const res = await GET(req, ctx);
    const body = await res.json();
    expect(body.data.giver_id).toBeUndefined();
    expect(body.data.giver.public_id).toBeDefined();
    expect(body.data.photos).toHaveLength(3);
    expect(body.data.photos[0].position).toBe(1);
    expect(body.data.photos[2].position).toBe(3);
    body.data.photos.forEach((p: any) => expect(p.signed_url).toMatch(/^https:\/\//));
  });

  it('owner can GET paused job (status≠active, owner=caller)', async () => {
    // setup: giver A creates job → PATCH status=paused
    const res = await GET(reqAsGiverA, ctx);
    expect(res.status).toBe(200);
    expect((await res.json()).data.status).toBe('paused');
  });

  it('owner can GET closed job', async () => {
    const res = await GET(reqAsGiverA, ctx);
    expect(res.status).toBe(200);
    expect((await res.json()).data.status).toBe('closed');
  });

  it('external viewer gets NOT_FOUND on paused/closed job (visibility hidden)', async () => {
    const res = await GET(reqAsWorker, ctx);  // worker is NOT giver_id
    expect(res.status).toBe(404);
  });
});

describe('PATCH /api/jobs/:id', () => {
  it('giver can update title', async () => {
    const res = await PATCH(reqWithBody({title: 'Updated'}), ctx);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.title).toBe('Updated');
  });

  it('non-owner gets FORBIDDEN', async () => {
    // worker tries to PATCH giver's job
    const res = await PATCH(reqWithBody({title: 'Hack'}, workerJwt), ctx);
    expect(res.status).toBe(403);
  });

  it('active → paused: status updated', async () => {
    const res = await PATCH(reqWithBody({status: 'paused'}), ctx);
    expect((await res.json()).data.status).toBe('paused');
  });

  it('paused → active: status updated', async () => {
    const res = await PATCH(reqWithBody({status: 'active'}), ctx);
    expect((await res.json()).data.status).toBe('active');
  });

  it('active → closed: status updated', async () => {
    const res = await PATCH(reqWithBody({status: 'closed'}), ctx);
    expect((await res.json()).data.status).toBe('closed');
  });

  it('closed → active: JOB_STATE_INVALID', async () => {
    // setup: job already closed
    const res = await PATCH(reqWithBody({status: 'active'}), ctx);
    expect(res.status).toBe(409);
    const body = await res.json();
    expect(body.error.code).toBe('JOB_STATE_INVALID');
  });

  it('closed + non-status field: JOB_STATE_INVALID', async () => {
    const res = await PATCH(reqWithBody({title: 'Change'}), ctx);
    expect(res.status).toBe(409);
  });

  it('rate limited at 31st request', async () => {
    for (let i = 0; i < 30; i++) await PATCH(reqWithBody({title: `t${i}`}), ctx);
    const res = await PATCH(reqWithBody({title: 'x31'}), ctx);
    expect(res.status).toBe(429);
  });
});
```

- [ ] **Step 2: Update jobs/[id]/route.ts**

Edit `sharework-api/src/app/api/jobs/[id]/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobIdParamSchema, jobUpdateSchema } from '@/lib/schemas';
import { mapAllPhotos } from '@/lib/photo-mapping';
import { checkJobWriteLimit } from '@/lib/rate-limit';
import { z } from 'zod';

export async function GET(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rawParams = await ctx.params;
    let parsed;
    try { parsed = jobIdParamSchema.parse(rawParams); }
    catch (err) {
      if (err instanceof z.ZodError) return fail(ErrorCode.VALIDATION, 'invalid job id');
      throw err;
    }

    const supabase = getServiceRoleClient();
    // M1 (Plan 리뷰 SA): owner는 paused/closed도 GET 가능해야 B.10 edit flow 동작
    const { data, error } = await supabase
      .from('jobs')
      .select(
        'id, giver_id, title, description, wage_won, schedule_text, status, category_id, location_address, created_at, updated_at, profiles!jobs_giver_id_fkey(public_id, name), job_photos(id, position, storage_path)'
      )
      .eq('id', parsed.id)
      .maybeSingle();

    if (error) return dbFail('jobs/[id]', error);
    if (!data) return fail(ErrorCode.NOT_FOUND, 'job not found');
    // 외부 viewer는 active만, owner는 모든 status (paused/closed 포함 — edit flow 의존)
    if ((data as any).giver_id !== userId && (data as any).status !== 'active') {
      return fail(ErrorCode.NOT_FOUND, 'job not found');
    }

    return ok({
      id: data.id,
      title: data.title,
      description: data.description,
      wage_won: data.wage_won,
      schedule_text: data.schedule_text,
      status: data.status,
      category_id: data.category_id,
      location_address: data.location_address,
      created_at: data.created_at,
      updated_at: data.updated_at,
      giver: { public_id: (data as any).profiles.public_id, name: (data as any).profiles.name },
      photos: await mapAllPhotos((data as any).job_photos ?? []),
    });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}

export async function PATCH(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const rawParams = await ctx.params;
    const parsedParams = jobIdParamSchema.safeParse(rawParams);
    if (!parsedParams.success) return fail(ErrorCode.VALIDATION, 'invalid job id');

    const raw = await req.json();
    const parsedBody = jobUpdateSchema.safeParse(raw);
    if (!parsedBody.success) return fail(ErrorCode.VALIDATION, 'invalid body');

    const supabase = getServiceRoleClient();
    // 현재 row + status + giver_id 조회 (giver 검증 + state machine)
    const { data: existing, error: getErr } = await supabase
      .from('jobs')
      .select('id, giver_id, status')
      .eq('id', parsedParams.data.id)
      .maybeSingle();
    if (getErr) return dbFail('jobs.PATCH.get', getErr);
    if (!existing) return fail(ErrorCode.NOT_FOUND, 'job not found');
    if (existing.giver_id !== userId) return fail(ErrorCode.FORBIDDEN, 'not owner');

    // State machine
    const fields = parsedBody.data;
    if (existing.status === 'closed') {
      // closed는 어떤 변경도 불가 (status 포함)
      return fail(ErrorCode.JOB_STATE_INVALID, 'closed jobs cannot be modified');
    }
    if (fields.status && fields.status === existing.status) {
      // no-op status 변경은 허용 (idempotent)
    }
    if (fields.status === 'closed') {
      // active|paused → closed: OK (final)
    } else if (fields.status === 'active' || fields.status === 'paused') {
      // 현재 closed 아닐 때만 가능 — 이미 위에서 차단
    }
    // closed → active|paused 시도는 existing.status === 'closed' 차단으로 회피

    const patch: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(fields)) {
      if (v !== undefined) patch[k] = v;
    }
    if (Object.keys(patch).length === 0) {
      // no-op: 현재 row return
      return ok(existing);
    }

    const { data, error } = await supabase
      .from('jobs')
      .update(patch)
      .eq('id', parsedParams.data.id)
      .select('id, title, description, wage_won, schedule_text, status, category_id, location_address, created_at, updated_at')
      .single();

    if (error) return dbFail('jobs.PATCH', error);
    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/jobs-detail.test.ts`
Expected: PASS (7 PATCH cases + GET schema).

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/[id]/route.ts tests/integration/jobs-detail.test.ts
```

---

### Task P4.5: API — POST /api/jobs integration test (P4.3에서 코드 land됨)

**Files:**
- Create: `sharework-api/tests/integration/jobs-create.test.ts`

> P4.3에서 jobs/route.ts에 POST가 이미 land. 본 task는 integration test만 추가.

- [ ] **Step 1: Write integration test**

Create `sharework-api/tests/integration/jobs-create.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { POST } from '@/app/api/jobs/route';

describe('POST /api/jobs', () => {
  it('401 without bearer', async () => {
    const req = new Request('http://localhost/api/jobs', { method: 'POST', body: '{}' });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('creates job with valid body (status=active default)', async () => {
    // setup: giver JWT, valid category_id
    const body = {
      title: 'Test Job', description: 'desc', wage_won: 15000,
      category_id: catId, location_address: 'Seoul',
    };
    const res = await POST(new Request('http://localhost/api/jobs', {
      method: 'POST',
      headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify(body),
    }));
    expect(res.status).toBe(200);
    const respBody = await res.json();
    expect(respBody.data.id).toBeDefined();
    expect(respBody.data.status).toBe('active');
    expect(respBody.data.title).toBe('Test Job');
  });

  it('VALIDATION on bad body', async () => {
    const res = await POST(new Request('http://localhost/api/jobs', {
      method: 'POST',
      headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ title: '' }),
    }));
    expect(res.status).toBe(400);
  });

  it('RATE_LIMITED at 31st create', async () => {
    for (let i = 0; i < 30; i++) {
      await POST(makeReq({ title: `t${i}`, /* ... */ }));
    }
    const res = await POST(makeReq({ title: 't31', /* ... */ }));
    expect(res.status).toBe(429);
  });

  it('rejects invalid category_id (FK violation → dbFail INTERNAL)', async () => {
    const res = await POST(makeReq({ title: 't', description: 'd', wage_won: 1,
      category_id: '00000000-0000-0000-0000-000000000999', location_address: 'S' }));
    expect([400, 500]).toContain(res.status);
  });
});
```

- [ ] **Step 2: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/jobs-create.test.ts`
Expected: PASS.

- [ ] **Step 3: Stage**

```bash
cd sharework-api && git add tests/integration/jobs-create.test.ts
```

---

### Task P4.6: API — POST /api/jobs/:id/photos/upload-url

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/photos/upload-url/route.ts`
- Create: `sharework-api/tests/integration/photos-upload-url.test.ts`

- [ ] **Step 1: Write failing test**

Create `sharework-api/tests/integration/photos-upload-url.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { POST } from '@/app/api/jobs/[id]/photos/upload-url/route';

describe('POST /api/jobs/:id/photos/upload-url', () => {
  it('401 without bearer', async () => {
    const res = await POST(new Request('http://localhost/.../upload-url', {
      method: 'POST', body: JSON.stringify({ mime_type: 'image/jpeg', file_size_bytes: 1 }),
    }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(401);
  });

  it('returns signed_url + photo_id + storage_path for valid request', async () => {
    const res = await POST(makeReq({ mime_type: 'image/jpeg', file_size_bytes: 100000 }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.photo_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(body.data.storage_path).toBe(`${jobId}/${body.data.photo_id}.jpg`);
    expect(body.data.upload_url).toMatch(/^https:\/\//);
    expect(body.data.expires_at).toBeGreaterThan(Date.now());
  });

  it('FORBIDDEN when caller is not owner', async () => {
    const res = await POST(makeReq({ mime_type: 'image/jpeg', file_size_bytes: 1 }, workerJwt), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(403);
  });

  it('VALIDATION on bad mime', async () => {
    const res = await POST(makeReq({ mime_type: 'image/gif', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(400);
  });

  it('PHOTO_LIMIT_EXCEEDED at 6th upload-url', async () => {
    // setup: 5 photos already inserted for job
    const res = await POST(makeReq({ mime_type: 'image/jpeg', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(409);
    expect((await res.json()).error.code).toBe('PHOTO_LIMIT_EXCEEDED');
  });

  it('RATE_LIMITED at 31st request', async () => {
    for (let i = 0; i < 30; i++) await POST(makeReq({ mime_type: 'image/jpeg', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) });
    const res = await POST(makeReq({ mime_type: 'image/jpeg', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(429);
  });
});
```

- [ ] **Step 2: Implement route**

Create `sharework-api/src/app/api/jobs/[id]/photos/upload-url/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobIdParamSchema, photoUploadUrlSchema } from '@/lib/schemas';
import { checkJobWriteLimit } from '@/lib/rate-limit';
import { createUploadUrl, buildStoragePath } from '@/lib/storage';

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const rawParams = await ctx.params;
    const paramRes = jobIdParamSchema.safeParse(rawParams);
    if (!paramRes.success) return fail(ErrorCode.VALIDATION, 'invalid job id');

    const raw = await req.json();
    const bodyRes = photoUploadUrlSchema.safeParse(raw);
    if (!bodyRes.success) return fail(ErrorCode.VALIDATION, 'invalid body');

    const supabase = getServiceRoleClient();
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .select('id, giver_id, status')
      .eq('id', paramRes.data.id)
      .maybeSingle();
    if (jobErr) return dbFail('photos.upload-url.job', jobErr);
    if (!job) return fail(ErrorCode.NOT_FOUND, 'job not found');
    if (job.giver_id !== userId) return fail(ErrorCode.FORBIDDEN, 'not owner');
    if (job.status === 'closed') return fail(ErrorCode.JOB_STATE_INVALID, 'closed job cannot upload photos');

    const { count, error: cntErr } = await supabase
      .from('job_photos')
      .select('id', { count: 'exact', head: true })
      .eq('job_id', job.id);
    if (cntErr) return dbFail('photos.upload-url.count', cntErr);
    if ((count ?? 0) >= 5) return fail(ErrorCode.PHOTO_LIMIT_EXCEEDED, 'photo limit (5)');

    const photoId = crypto.randomUUID();
    const path = buildStoragePath(job.id, photoId, bodyRes.data.mime_type);

    const { uploadUrl, expiresAtMs } = await createUploadUrl(path);

    return ok({
      photo_id: photoId,
      storage_path: path,
      upload_url: uploadUrl,
      expires_at: expiresAtMs,
    });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/photos-upload-url.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/\[id\]/photos/upload-url/route.ts tests/integration/photos-upload-url.test.ts
```

---

### Task P4.7: API — POST /api/jobs/:id/photos/confirm (B2 정정)

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/photos/confirm/route.ts`
- Create: `sharework-api/tests/integration/photos-confirm.test.ts`

- [ ] **Step 1: Write failing test**

Create `sharework-api/tests/integration/photos-confirm.test.ts`:

```typescript
describe('POST /api/jobs/:id/photos/confirm', () => {
  it('happy path: confirms uploaded photo (position=1 first)', async () => {
    // setup: upload-url 발급 → 클라이언트 PUT (Storage 직접) → confirm
    // 본 test는 PUT을 service role admin client로 모사
    const res = await POST(makeReq({
      storage_path: `${jobId}/${photoId}.jpg`,
      mime_type: 'image/jpeg',
      file_size_bytes: 100000,
    }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.position).toBe(1);
    expect(body.data.storage_path).toBe(`${jobId}/${photoId}.jpg`);
  });

  it('PHOTO_NOT_UPLOADED when Storage HEAD missing', async () => {
    const res = await POST(makeReq({
      storage_path: `${jobId}/${crypto.randomUUID()}.jpg`,
      mime_type: 'image/jpeg',
      file_size_bytes: 1,
    }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(422);
  });

  it('VALIDATION on storage_path prefix mismatch (path injection)', async () => {
    const otherJob = '00000000-0000-0000-0000-000000000999';
    const res = await POST(makeReq({
      storage_path: `${otherJob}/some.jpg`,
      mime_type: 'image/jpeg', file_size_bytes: 1,
    }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(400);
  });

  it('VALIDATION on mime <-> ext mismatch', async () => {
    const res = await POST(makeReq({
      storage_path: `${jobId}/${photoId}.png`,  // .png but mime jpeg
      mime_type: 'image/jpeg', file_size_bytes: 1,
    }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(400);
  });

  it('gap fill: DELETE pos 3 then confirm → position=3 (B1 verify)', async () => {
    // setup: insert 5 photos pos 1~5 → DELETE id=p3 → upload-url + confirm → 신규 pos=3
    const res = await POST(makeReq({ storage_path: `${jobId}/${newPhotoId}.jpg`, mime_type: 'image/jpeg', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) });
    const body = await res.json();
    expect(body.data.position).toBe(3);
  });

  it('PHOTO_LIMIT race: 5 concurrent confirms with 5 photos already → all reject with 5/6 fail', async () => {
    // setup: 5 photos already inserted, 5 upload-url 모두 발급된 상태에서 5개 confirm 동시
    // RPC FOR UPDATE 캡슐화로 한 번에 1개만 통과 (그러나 이미 5개 → 모두 PHOTO_LIMIT)
    const results = await Promise.all(Array.from({ length: 5 }, (_, i) =>
      POST(makeReq({ storage_path: `${jobId}/${uuids[i]}.jpg`, mime_type: 'image/jpeg', file_size_bytes: 1 }), { params: Promise.resolve({ id: jobId }) })
    ));
    expect(results.every(r => r.status === 409)).toBe(true);
  });

  it('FORBIDDEN when caller is not owner', async () => {
    const res = await POST(makeReq({ /* ... */ }, workerJwt), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 2: Implement route**

Create `sharework-api/src/app/api/jobs/[id]/photos/confirm/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobIdParamSchema, photoConfirmSchema } from '@/lib/schemas';
import { checkJobWriteLimit } from '@/lib/rate-limit';
import { headObject, removeObject } from '@/lib/storage';

const MIME_EXT: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const rawParams = await ctx.params;
    const paramRes = jobIdParamSchema.safeParse(rawParams);
    if (!paramRes.success) return fail(ErrorCode.VALIDATION, 'invalid job id');

    const raw = await req.json();
    const bodyRes = photoConfirmSchema.safeParse(raw);
    if (!bodyRes.success) return fail(ErrorCode.VALIDATION, 'invalid body');
    const { storage_path, mime_type, file_size_bytes, width, height } = bodyRes.data;

    // path prefix 검증 (job 간 path 주입 차단)
    const [pathJobId, fileName] = storage_path.split('/');
    if (pathJobId !== paramRes.data.id) {
      return fail(ErrorCode.VALIDATION, 'storage_path job mismatch');
    }

    // mime ↔ ext 정합 검증
    const expectedExt = MIME_EXT[mime_type];
    const actualExt = fileName.split('.').pop();
    if (expectedExt !== actualExt) {
      return fail(ErrorCode.VALIDATION, 'mime/extension mismatch');
    }

    // Storage HEAD
    const exists = await headObject(storage_path);
    if (!exists) return fail(ErrorCode.PHOTO_NOT_UPLOADED, 'object not found in storage');

    // RPC add_job_photo (FOR UPDATE + gap fill + insert atomic)
    // Plan 리뷰 SA/CR M2: P2.2 RPC가 p_user_id 명시 인자 받아 service role 환경에서 동작.
    // BFF가 JWT verify로 userId 확보 → RPC 신뢰 전달.
    const supabase = getServiceRoleClient();
    const { data, error } = await supabase.rpc('add_job_photo', {
      p_job_id: paramRes.data.id,
      p_user_id: userId,
      p_storage_path: storage_path,
      p_mime: mime_type,
      p_size: file_size_bytes,
      p_w: width ?? null,
      p_h: height ?? null,
    });

    if (error) {
      if (error.code === '42501') return fail(ErrorCode.FORBIDDEN, 'not owner');
      if (error.code === 'P0001') {
        // PHOTO_LIMIT — cleanup uploaded object
        await removeObject(storage_path);
        return fail(ErrorCode.PHOTO_LIMIT_EXCEEDED, 'photo limit (5)');
      }
      return dbFail('photos.confirm.rpc', error);
    }

    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

> **Plan 리뷰 SA/CR M2 정정 land**: P2.2 RPC `add_job_photo(p_job_id, p_user_id, ...)` + `reorder_job_photos(p_job_id, p_user_id, ...)` 시그니처가 본 plan에 lock-in됨. BFF가 service role로 RPC 호출 시 `p_user_id: userId`(JWT 검증 결과) 명시 전달. `auth.uid()` 의존 제거.
>
> **Plan 리뷰 CR S5 — Orphan trade-off 명시**: PHOTO_LIMIT_EXCEEDED 경로의 `removeObject(storage_path)`는 best-effort. cleanup remove 실패 시 Storage에 고아 객체 잔존 — DB job_photos에 미참조 상태. 베타 운영 빈도 추정: 5장 동시 confirm race × 일 50명 × 1% upload-cleanup race = 일 0.025건 (무시 가능). M3+ orphan storage cleanup cron 별도 운영 작업으로 분리 (spec §13 W4 명시). 본 plan M2 scope 외.

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/photos-confirm.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/\[id\]/photos/confirm/route.ts tests/integration/photos-confirm.test.ts
```

---

### Task P4.8: API — DELETE /api/jobs/:id/photos/:photoId

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/photos/[photoId]/route.ts`
- Create: `sharework-api/tests/integration/photos-delete.test.ts`

- [ ] **Step 1: Write failing test**

Create `sharework-api/tests/integration/photos-delete.test.ts`:

```typescript
describe('DELETE /api/jobs/:id/photos/:photoId', () => {
  it('owner can delete', async () => {
    const res = await DELETE(req, { params: Promise.resolve({ id: jobId, photoId: photoId }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.deleted).toBe(true);
  });

  it('FORBIDDEN for non-owner (RLS denies)', async () => {
    const res = await DELETE(reqAsWorker, { params: Promise.resolve({ id: jobId, photoId: photoId }) });
    // RLS 거부 → 행 미존재 → NOT_FOUND 또는 FORBIDDEN. 본 spec은 RLS-based deny로 NOT_FOUND fallback 허용
    expect([403, 404]).toContain(res.status);
  });

  it('NOT_FOUND for non-existent photo', async () => {
    const res = await DELETE(req, { params: Promise.resolve({ id: jobId, photoId: '00000000-0000-0000-0000-000000000999' }) });
    expect(res.status).toBe(404);
  });

  it('removes Storage object best-effort (verify via Storage HEAD)', async () => {
    // setup: confirm uploaded
    await DELETE(req, { params: Promise.resolve({ id: jobId, photoId }) });
    const exists = await headObjectInTest(`${jobId}/${photoId}.jpg`);
    expect(exists).toBe(false);
  });
});
```

- [ ] **Step 2: Implement route**

Create `sharework-api/src/app/api/jobs/[id]/photos/[photoId]/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { photoIdParamSchema } from '@/lib/schemas';
import { checkJobWriteLimit } from '@/lib/rate-limit';
import { removeObject } from '@/lib/storage';

export async function DELETE(req: Request, ctx: { params: Promise<{ id: string; photoId: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const rawParams = await ctx.params;
    const paramRes = photoIdParamSchema.safeParse(rawParams);
    if (!paramRes.success) return fail(ErrorCode.VALIDATION, 'invalid params');

    const supabase = getServiceRoleClient();

    // 1. 본인 소유 확인 + storage_path 조회
    const { data: photo, error: getErr } = await supabase
      .from('job_photos')
      .select('id, storage_path, job_id, jobs!inner(giver_id)')
      .eq('id', paramRes.data.photoId)
      .eq('job_id', paramRes.data.id)
      .maybeSingle();

    if (getErr) return dbFail('photos.DELETE.get', getErr);
    if (!photo) return fail(ErrorCode.NOT_FOUND, 'photo not found');
    if ((photo as any).jobs.giver_id !== userId) return fail(ErrorCode.FORBIDDEN, 'not owner');

    // 2. DB delete
    const { error: delErr } = await supabase
      .from('job_photos')
      .delete()
      .eq('id', paramRes.data.photoId);
    if (delErr) return dbFail('photos.DELETE', delErr);

    // 3. Storage best-effort cleanup
    await removeObject(photo.storage_path);

    return ok({ deleted: true });
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/photos-delete.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/\[id\]/photos/\[photoId\]/route.ts tests/integration/photos-delete.test.ts
```

---

### Task P4.9: API — PATCH /api/jobs/:id/photos/reorder

**Files:**
- Create: `sharework-api/src/app/api/jobs/[id]/photos/reorder/route.ts`
- Create: `sharework-api/tests/integration/photos-reorder.test.ts`

- [ ] **Step 1: Write failing test**

Create `sharework-api/tests/integration/photos-reorder.test.ts`:

```typescript
describe('PATCH /api/jobs/:id/photos/reorder', () => {
  it('reorders 3 photos [p3, p1, p2] → positions [1,2,3]', async () => {
    // setup: 3 photos p1(pos=1), p2(pos=2), p3(pos=3)
    const res = await PATCH(makeReq({ order: [p3, p1, p2] }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.map((p: any) => p.position)).toEqual([1, 2, 3]);
    expect(body.data[0].id).toBe(p3);
    expect(body.data[1].id).toBe(p1);
  });

  it('swap [p1, p2] → [p2, p1] (V1 verify — DEFERRABLE allows swap)', async () => {
    const res = await PATCH(makeReq({ order: [p2, p1] }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data[0].id).toBe(p2);
  });

  it('VALIDATION when order missing photo (count mismatch)', async () => {
    const res = await PATCH(makeReq({ order: [p1] }), { params: Promise.resolve({ id: jobId }) });
    // RPC raise 'order_mismatch' P0002 → 400
    expect(res.status).toBe(400);
  });

  it('FORBIDDEN for non-owner', async () => {
    const res = await PATCH(reqAsWorker({ order: [p1, p2, p3] }), { params: Promise.resolve({ id: jobId }) });
    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 2: Implement route**

Create `sharework-api/src/app/api/jobs/[id]/photos/reorder/route.ts`:

```typescript
import { ok, fail, dbFail, ErrorCode } from '@/lib/envelope';
import { verifyAccessToken, extractBearerToken } from '@/lib/jwt';
import { getServiceRoleClient } from '@/lib/supabase';
import { AppError } from '@/lib/errors';
import { jobIdParamSchema, photoReorderSchema } from '@/lib/schemas';
import { checkJobWriteLimit } from '@/lib/rate-limit';

export async function PATCH(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const token = extractBearerToken(req);
    const { userId } = await verifyAccessToken(token);

    const rl = await checkJobWriteLimit(userId);
    if (!rl.ok) return fail(ErrorCode.RATE_LIMITED, `retry after ${rl.retryAfterSec}s`);

    const rawParams = await ctx.params;
    const paramRes = jobIdParamSchema.safeParse(rawParams);
    if (!paramRes.success) return fail(ErrorCode.VALIDATION, 'invalid job id');

    const raw = await req.json();
    const bodyRes = photoReorderSchema.safeParse(raw);
    if (!bodyRes.success) return fail(ErrorCode.VALIDATION, 'invalid body');

    const supabase = getServiceRoleClient();
    // Plan 리뷰 M2 정정: P2.2 RPC 시그니처에 p_user_id land됨. BFF가 명시 전달.
    const { data, error } = await supabase.rpc('reorder_job_photos', {
      p_job_id: paramRes.data.id,
      p_user_id: userId,
      p_order: bodyRes.data.order,
    });

    if (error) {
      if (error.code === '42501') return fail(ErrorCode.FORBIDDEN, 'not owner');
      if (error.code === 'P0002') return fail(ErrorCode.VALIDATION, 'order mismatch');
      return dbFail('photos.reorder.rpc', error);
    }
    return ok(data);
  } catch (err) {
    if (err instanceof AppError) return fail(err.code, err.message);
    return fail(ErrorCode.INTERNAL, 'unexpected error');
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd sharework-api && npx vitest run tests/integration/photos-reorder.test.ts`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework-api && git add src/app/api/jobs/\[id\]/photos/reorder/route.ts tests/integration/photos-reorder.test.ts
```

---

## Sprint 1A — Flutter M1 Wire-up (A.1 ~ A.15)

> **참조 의무**: 각 Task의 step 상세는 **M1 plan** `../plans/2026-05-10-m1-auth-job-list.md`의 대응 Task를 SDD가 직접 read해서 그대로 따라간다. 본 plan은 (a) Task 정의 (b) M1 plan 대응 task 번호 (c) 본 plan에서 변경/추가된 부분만 명시 — Flutter wire-up은 spec의 §6.1 응답 schema 변경(giver+photos), B4 신규 모델(GiverPublic, JobPhoto), F1 정정(dioPlain 본 plan 도입)이 핵심 추가점.
>
> **commit 시점**: Sprint 1A 끝까지 staged 누적 → 단일 commit `feat(flutter): M1 wire-up — phone auth + worker home/list/detail + repository pattern`.

### Task A.1: pubspec 의존성 + build_runner

**Files:**
- Modify: `sharework/pubspec.yaml`

**M1 plan 참조**: Task 15 (M1 plan line 1678-1823).

**본 plan 변경/추가**:
- M2용 의존성 추가: `image_picker ^1.1.2`, `flutter_image_compress ^2.4.0` (Sprint 2 B5에서 사용하지만 Sprint 1A pubspec에 함께 등록 — 의존성 한 번에 land가 build_runner 회귀 비용 절감)
- F1 정정: `dio`는 dioAuth(인증 인터셉터) + dioPlain(Authorization 미부착) 두 인스턴스용 — pubspec 변경은 동일

- [ ] **Step 1: Update pubspec.yaml**

Edit `sharework/pubspec.yaml`:

```yaml
name: sharework_mockup
description: Sharework mockup app (Flutter rewrite, UI-only)
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ">=3.6.0 <4.0.0"
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  go_router: ^14.2.0
  intl: ^0.20.2
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8

  # M1 wire-up
  supabase_flutter: ^2.12.4
  dio: ^5.9.2
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.4
  flutter_dotenv: ^5.2.1

  # M2 photo upload
  image_picker: ^1.1.2
  flutter_image_compress: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 2: pub get**

```bash
cd sharework && flutter pub get
```

Expected: 의존성 resolved.

- [ ] **Step 3: Verify analyze passes (no breaking imports yet)**

```bash
cd sharework && flutter analyze
```

Expected: no issues (현재 코드가 신규 의존성을 사용하지 않음).

- [ ] **Step 4: Stage**

```bash
cd sharework && git add pubspec.yaml pubspec.lock
```

---

### Task A.2: Supabase 초기화 + .env + main.dart

**Files:**
- Create: `sharework/.env.example`
- Modify: `sharework/lib/main.dart`
- Create: `sharework/lib/data/env.dart`
- Modify: `sharework/.gitignore` (`.env` 추가)

**M1 plan 참조**: Task 15 Step 4-8 (M1 plan line 1750-1820).

**본 plan 변경/추가**:
- API_BASE_URL 기본값 = `https://sharework-api.vercel.app` (M1 production live, M2 sprint도 동일 사용)
- DEV 환경에서 `--dart-define API_BASE_URL=http://localhost:3000` 옵션 노출

- [ ] **Step 1: Create .env.example**

Write `sharework/.env.example`:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJ...
API_BASE_URL=https://sharework-api.vercel.app
```

- [ ] **Step 2: Update .gitignore**

Edit `sharework/.gitignore` — `.env` 라인 확인/추가.

- [ ] **Step 3: Create env.dart**

Write `sharework/lib/data/env.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get apiBaseUrl => _require('API_BASE_URL');

  static String _require(String key) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('missing env: $key');
    }
    return v;
  }
}
```

- [ ] **Step 4: Update main.dart**

Edit `sharework/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/env.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const ShareworkApp());
}

class ShareworkApp extends StatelessWidget {
  const ShareworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sharework',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.config,
    );
  }
}
```

> 기존 `main.dart` 구조 — SDD가 grep으로 현재 import + 위젯 트리 확인 후 차이 흡수. `AppTheme.light()`는 기존 호출 그대로 보존 (M1 plan Task 15와 동일).

- [ ] **Step 5: Run app boot smoke**

사용자 직접: 시뮬레이터에서 `flutter run`. SUPABASE_URL/ANON_KEY 미설정 시 StateError → 의도. 사용자가 `.env` 직접 생성 (Supabase dashboard에서 키 복붙) 후 재실행.

- [ ] **Step 6: Stage**

```bash
cd sharework && git add .env.example .gitignore lib/data/env.dart lib/main.dart
```

---

### Task A.3: ApiClient (dio + JWT 인터셉터 + dioPlain)

**Files:**
- Create: `sharework/lib/data/api_client.dart`
- Create: `sharework/lib/data/api_errors.dart`
- Create: `sharework/test/data/api_client_test.dart`

**M1 plan 참조**: Task 17 (M1 plan line 1960-2148).

**본 plan 변경/추가**:
- **F1 정정**: spec §8.3 `dioPlain` = "M1에서 도입한 인증 인터셉터 적용 안 한 별도 dio"는 **본 plan에서 도입**으로 정정. dioAuth + dioPlain 두 인스턴스 동시 land. dioPlain은 Sprint 2 photo_upload_service에서 signed URL PUT 시 사용 (Authorization 헤더 차단 의무).
- ErrorCode 명명: P1.4와 정렬 — `AUTH_REQUIRED, AUTH_INVALID, FORBIDDEN, NOT_FOUND, VALIDATION, INTERNAL, STORAGE_FAIL, RATE_LIMITED, PHOTO_LIMIT_EXCEEDED, PHOTO_FILE_INVALID, PHOTO_NOT_UPLOADED, JOB_STATE_INVALID`

- [ ] **Step 1: Write failing tests**

Create `sharework/test/data/api_client_test.dart` — M1 plan Task 17 Step 1-3 그대로 + 추가:

```dart
group('dioPlain', () {
  test('does NOT attach Authorization header even if session present', () async {
    // setup: mock Supabase session
    final plain = ApiClient.instance.plain;
    final adapter = DioAdapter(dio: plain);
    adapter.onPut('https://signed.example/upload', (server) => server.reply(204, null), data: Matchers.any);
    final res = await plain.put('https://signed.example/upload', data: [1, 2, 3], options: Options(headers: {'content-type': 'image/jpeg'}));
    // dioPlain doesn't have AuthInterceptor — verify no auth header
    expect(adapter.history.lastOptions?.headers['authorization'], isNull);
    expect(res.statusCode, 204);
  });
});

group('ApiError mapping', () {
  test('401 + code=AUTH_REQUIRED throws ApiError', () { /* ... */ });
  test('401 + code=AUTH_INVALID throws ApiError + redirects to /auth/phone', () { /* ... */ });
  test('429 + code=RATE_LIMITED parses retryAfter', () { /* ... */ });
});
```

- [ ] **Step 2: Implement api_errors.dart**

Create `sharework/lib/data/api_errors.dart`:

```dart
enum ApiErrorCode {
  authRequired,
  authInvalid,
  forbidden,
  notFound,
  validation,
  internal,
  storageFail,
  rateLimited,
  photoLimitExceeded,
  photoFileInvalid,
  photoNotUploaded,
  jobStateInvalid,
  unknown,
}

ApiErrorCode parseErrorCode(String? raw) {
  switch (raw) {
    case 'AUTH_REQUIRED': return ApiErrorCode.authRequired;
    case 'AUTH_INVALID': return ApiErrorCode.authInvalid;
    case 'FORBIDDEN': return ApiErrorCode.forbidden;
    case 'NOT_FOUND': return ApiErrorCode.notFound;
    case 'VALIDATION': return ApiErrorCode.validation;
    case 'INTERNAL': return ApiErrorCode.internal;
    case 'STORAGE_FAIL': return ApiErrorCode.storageFail;
    case 'RATE_LIMITED': return ApiErrorCode.rateLimited;
    case 'PHOTO_LIMIT_EXCEEDED': return ApiErrorCode.photoLimitExceeded;
    case 'PHOTO_FILE_INVALID': return ApiErrorCode.photoFileInvalid;
    case 'PHOTO_NOT_UPLOADED': return ApiErrorCode.photoNotUploaded;
    case 'JOB_STATE_INVALID': return ApiErrorCode.jobStateInvalid;
    default: return ApiErrorCode.unknown;
  }
}

class ApiError implements Exception {
  final int statusCode;
  final ApiErrorCode code;
  final String message;
  final int? retryAfterSec;

  ApiError({required this.statusCode, required this.code, required this.message, this.retryAfterSec});

  @override
  String toString() => 'ApiError($statusCode, $code, $message)';
}
```

- [ ] **Step 3: Implement api_client.dart**

Create `sharework/lib/data/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'api_errors.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio auth = _buildAuth();
  late final Dio plain = _buildPlain();

  Dio _buildAuth() {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'content-type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());
    return dio;
  }

  Dio _buildPlain() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),  // PUT upload는 길게
    ));
    // ⚠️ Authorization 인터셉터 등록 안 함 (F1: signed URL PUT 보호)
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token != null) options.headers['authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    if (res != null) {
      final body = res.data;
      String? rawCode;
      String message = err.message ?? 'unknown';
      if (body is Map && body['error'] is Map) {
        rawCode = body['error']['code'] as String?;
        message = (body['error']['message'] as String?) ?? message;
      }
      int? retryAfter;
      if (res.statusCode == 429) {
        retryAfter = int.tryParse(res.headers.value('retry-after') ?? '');
      }
      throw ApiError(
        statusCode: res.statusCode ?? 0,
        code: parseErrorCode(rawCode),
        message: message,
        retryAfterSec: retryAfter,
      );
    }
    handler.next(err);
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd sharework && flutter test test/data/api_client_test.dart`
Expected: PASS.

- [ ] **Step 5: Stage**

```bash
cd sharework && git add lib/data/api_client.dart lib/data/api_errors.dart test/data/api_client_test.dart
```

---

### Task A.4: freezed 모델 (Profile + Job + GiverPublic + JobPhoto + JobCategory)

**Files:**
- Create: `sharework/lib/models/api_models/profile.dart` + generated
- Create: `sharework/lib/models/api_models/giver_public.dart` + generated (B4 신규)
- Create: `sharework/lib/models/api_models/job_photo.dart` + generated (B4 신규)
- Create: `sharework/lib/models/api_models/job.dart` + generated
- Create: `sharework/lib/models/api_models/job_category.dart` + generated

**M1 plan 참조**: Task 16 (M1 plan line 1824-1958).

**본 plan 변경/추가 (B4)**:
- `GiverPublic` 신규: `{public_id: String, name: String}` — BFF 응답 변경(P4.3·P4.4) 그대로 수용
- `JobPhoto` 신규: `{id: String, position: int, signed_url: String}`
- `Job` 모델 변경: `giver_id`(String) 제거 → `giver: GiverPublic` 추가, `photos: List<JobPhoto>` 추가
- `Profile` 모델에 `public_id: String` 필드 추가

- [ ] **Step 1: Write Profile freezed**

Create `sharework/lib/models/api_models/profile.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String phone,
    required String name,
    required String role,
    @JsonKey(name: 'public_id') required String publicId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

- [ ] **Step 2: Write GiverPublic freezed (B4 신규)**

Create `sharework/lib/models/api_models/giver_public.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'giver_public.freezed.dart';
part 'giver_public.g.dart';

@freezed
class GiverPublic with _$GiverPublic {
  const factory GiverPublic({
    @JsonKey(name: 'public_id') required String publicId,
    required String name,
  }) = _GiverPublic;

  factory GiverPublic.fromJson(Map<String, dynamic> json) => _$GiverPublicFromJson(json);
}
```

- [ ] **Step 3: Write JobPhoto freezed (B4 신규)**

Create `sharework/lib/models/api_models/job_photo.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_photo.freezed.dart';
part 'job_photo.g.dart';

@freezed
class JobPhoto with _$JobPhoto {
  const factory JobPhoto({
    required String id,
    required int position,
    @JsonKey(name: 'signed_url') required String signedUrl,
  }) = _JobPhoto;

  factory JobPhoto.fromJson(Map<String, dynamic> json) => _$JobPhotoFromJson(json);
}
```

- [ ] **Step 4: Write Job freezed**

Create `sharework/lib/models/api_models/job.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'giver_public.dart';
import 'job_photo.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'wage_won') required int wageWon,
    @JsonKey(name: 'schedule_text') String? scheduleText,
    required String status,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'location_address') required String locationAddress,
    GiverPublic? giver,                              // /api/me/jobs는 giver 없음 (본인이므로)
    @Default(<JobPhoto>[]) List<JobPhoto> photos,    // Plan 리뷰 CR M3: nullable 회피 — UI .isNotEmpty 안전
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

- [ ] **Step 5: Write JobCategory freezed**

Create `sharework/lib/models/api_models/job_category.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_category.freezed.dart';
part 'job_category.g.dart';

@freezed
class JobCategory with _$JobCategory {
  const factory JobCategory({
    required String id,
    required String slug,
    required String name,
    String? emoji,
  }) = _JobCategory;

  factory JobCategory.fromJson(Map<String, dynamic> json) => _$JobCategoryFromJson(json);
}
```

- [ ] **Step 6: Run build_runner**

```bash
cd sharework && dart run build_runner build --delete-conflicting-outputs
```

Expected: `*.freezed.dart` + `*.g.dart` 생성.

- [ ] **Step 7: Run model tests (간단 round-trip)**

Write `sharework/test/models/api_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job.dart';
import 'package:sharework_mockup/models/api_models/giver_public.dart';

void main() {
  test('Job.fromJson with giver + photos', () {
    final json = {
      'id': 'j-1',
      'title': 't', 'description': 'd', 'wage_won': 1000, 'status': 'active',
      'category_id': 'c-1', 'location_address': 'S',
      'giver': {'public_id': 'gpid', 'name': 'gname'},
      'photos': [{'id': 'p1', 'position': 1, 'signed_url': 'https://...'}],
      'created_at': '2026-05-11T00:00:00Z', 'updated_at': '2026-05-11T00:00:00Z',
    };
    final job = Job.fromJson(json);
    expect(job.giver?.publicId, 'gpid');
    expect(job.photos[0].position, 1);
  });

  test('Job.fromJson without photos (legacy)', () {
    final json = {
      'id': 'j-1',
      'title': 't', 'description': 'd', 'wage_won': 1000, 'status': 'active',
      'category_id': 'c-1', 'location_address': 'S',
      'created_at': '2026-05-11T00:00:00Z', 'updated_at': '2026-05-11T00:00:00Z',
    };
    final job = Job.fromJson(json);
    expect(job.photos, isEmpty);
  });
}
```

Run: `cd sharework && flutter test test/models/`
Expected: PASS.

- [ ] **Step 8: Stage**

```bash
cd sharework && git add lib/models/api_models/ test/models/api_models_test.dart
```

---

### Task A.5: AuthRepository (Supabase SDK wrapper)

**Files:**
- Create: `sharework/lib/data/repositories/auth_repository.dart`
- Create: `sharework/test/data/auth_repository_test.dart`

**M1 plan 참조**: Task 18 (M1 plan line 2149-2294) — 본 plan에서 그대로 land. 변경/추가 없음.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 18 Steps 1-7 그대로 실행**

SDD가 `2026-05-10-m1-auth-job-list.md` 파일의 `### Task 18: Flutter — AuthRepository (Supabase SDK wrapper) (TDD)` 섹션을 직접 read하고 각 step의 code/command를 그대로 따라간다.

- [ ] **Step 2: Stage**

```bash
cd sharework && git add lib/data/repositories/auth_repository.dart test/data/auth_repository_test.dart
```

---

### Task A.6: MeRepository

**Files:**
- Create: `sharework/lib/data/repositories/me_repository.dart`
- Create: `sharework/test/data/me_repository_test.dart`

**M1 plan 참조**: Task 19 (M1 plan line 2295-2368).

**본 plan 변경/추가**:
- 응답 모델에 `public_id` 포함 (BFF P4.1 반영) — Profile freezed에 이미 land됨

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 19 그대로 실행, Profile 모델 import는 `lib/models/api_models/profile.dart`**

- [ ] **Step 2: Stage**

```bash
cd sharework && git add lib/data/repositories/me_repository.dart test/data/me_repository_test.dart
```

---

### Task A.7: JobRepository (M1 read) + CategoryRepository

**Files:**
- Create: `sharework/lib/data/repositories/job_repository.dart` (M1 read 메서드만, M2 write는 B.5에서 확장)
- Create: `sharework/lib/data/repositories/category_repository.dart`
- Create: `sharework/test/data/job_repository_test.dart`
- Create: `sharework/test/data/category_repository_test.dart`

**M1 plan 참조**: Task 20 (M1 plan line 2369-2512).

**본 plan 변경/추가**:
- Job 모델이 GiverPublic + JobPhoto 포함 — `fromJson` 처리는 freezed가 자동
- M2 write 메서드(createJob, updateJob, photo*)는 본 task에 *추가 안 함* — Sprint 2 B.5에서 확장 (R12 사전 정리 vs 본 작업 분리 정신 보존)

**M1 read 메서드 시그니처**:
```dart
class JobRepository {
  final Dio _dio;
  JobRepository(this._dio);
  factory JobRepository.fromApi() => JobRepository(ApiClient.instance.auth);

  Future<({List<Job> items, int total})> listJobs({String? category, String? q, int page = 1, int limit = 20});
  Future<Job> fetchJob(String id);
}
```

CategoryRepository:
```dart
class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);
  factory CategoryRepository.fromApi() => CategoryRepository(ApiClient.instance.auth);

  Future<List<JobCategory>> list();
}
```

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 20 Steps 1-6 그대로 실행 (read 메서드만)**

- [ ] **Step 2: Verify build_runner up to date**

```bash
cd sharework && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/data/job_repository_test.dart test/data/category_repository_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/data/repositories/job_repository.dart lib/data/repositories/category_repository.dart test/data/job_repository_test.dart test/data/category_repository_test.dart
```

---

### Task A.8: AuthGuard + splash redirect

**Files:**
- Modify: `sharework/lib/router/app_router.dart`
- Modify: `sharework/lib/screens/splash/splash_screen.dart`
- Create: `sharework/test/screens/splash_screen_test.dart`

**M1 plan 참조**: Task 21 (M1 plan line 2513-2597).

**본 plan 변경/추가**: 변경 없음 — M1 plan 그대로.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 21 그대로 실행** — `GoRouter.redirect` 콜백에서 Supabase session 확인 + 보호 라우트(`/worker`, `/giver`, `/me`) 가드.

- [ ] **Step 2: Stage**

```bash
cd sharework && git add lib/router/app_router.dart lib/screens/splash/splash_screen.dart test/screens/splash_screen_test.dart
```

---

### Task A.9: PhoneAuthScreen wire-up

**Files:**
- Modify: `sharework/lib/screens/auth/phone_auth_screen.dart`
- Create: `sharework/test/screens/phone_auth_screen_test.dart`

**M1 plan 참조**: Task 22 (M1 plan line 2598-2806).

**본 plan 변경/추가**: 변경 없음 — Mock OTP Test phone numbers 패턴 그대로.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 22 그대로 실행**

- [ ] **Step 2: Manual smoke (시뮬레이터)**

사용자 직접: `flutter run` → `/auth/phone` 진입 → Supabase Test phone number(`+821012345678`) 입력 → OTP `123456` 입력 → `/worker` 라우팅 확인.

- [ ] **Step 3: Stage**

```bash
cd sharework && git add lib/screens/auth/phone_auth_screen.dart test/screens/phone_auth_screen_test.dart
```

---

### Task A.10: WorkerHomeScreen wire-up (applied/hired pill 0/0)

**Files:**
- Modify: `sharework/lib/screens/worker/worker_main_screen.dart`
- (선택) Create: `sharework/lib/screens/worker/home/worker_home_content.dart` (worker_main_screen이 contained하는 list view 분리)
- Create: `sharework/test/screens/worker_main_screen_test.dart`

**M1 plan 참조**: Task 23 (M1 plan line 2807-3032).

**본 plan 변경/추가**:
- U3 lock-in: applied/hired pill = 0/0 하드코딩, 코멘트 `// M1: applications API 미존재, M3 연결`
- Job 모델이 GiverPublic + JobPhoto 포함 — UI에서 `job.giver?.name` 표시 (M1에서는 giver_name dummy 사용했으나 본 plan에서 실 API의 `giver.name` 사용)
- cover photo `job.photos.isNotEmpty ? job.photos[0].signedUrl : null` 표시 — placeholder fallback (M1 mockup이 fallback image 사용)

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 23 Steps 1-5 그대로 실행**

- [ ] **Step 2: 추가 — giver.name + cover photo 표시 (UI 변경)**

worker_main_screen.dart에서 list item rendering:

```dart
// 기존 dummy giver_name → job.giver?.name ?? '정보 없음'
// 기존 fallback image → cover photo signed_url 우선
Widget _buildJobTile(Job job) {
  final coverUrl = job.photos.isNotEmpty ? job.photos[0].signedUrl : null;
  return Card(
    child: ListTile(
      leading: coverUrl != null
        ? CachedNetworkImage(imageUrl: coverUrl, width: 56, height: 56, fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Icon(Icons.image_not_supported))
        : Container(width: 56, height: 56, color: Colors.grey.shade200, child: Icon(Icons.image)),
      title: Text(job.title),
      subtitle: Text('${job.giver?.name ?? "정보 없음"} · ${job.wageWon}원'),
      onTap: () => context.go('/job/${job.id}'),
    ),
  );
}
```

`cached_network_image` 패키지가 pubspec에 없으면 일반 `Image.network` 사용 (placeholder는 `FadeInImage.assetNetwork`).

- [ ] **Step 3: Run widget test**

Run: `cd sharework && flutter test test/screens/worker_main_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/screens/worker/worker_main_screen.dart test/screens/worker_main_screen_test.dart
```

---

### Task A.11: JobInfoScreen wire-up (사진 캐러셀 추가)

**Files:**
- Modify: `sharework/lib/screens/common/job_info_screen.dart`
- Create: `sharework/test/screens/job_info_screen_test.dart`

**M1 plan 참조**: Task 24 (M1 plan line 3033-3182).

**본 plan 변경/추가**:
- 사진 캐러셀 (PageView + 인디케이터) — `job.photos.length > 0` 시 표시. 0장이면 placeholder.
- giver.name 표시 (M1과 동일하게 GiverPublic.name 사용)

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 24 Steps 1-5 그대로 실행**

- [ ] **Step 2: 추가 — 사진 캐러셀**

```dart
Widget _buildPhotoCarousel(List<JobPhoto> photos) {
  if (photos.isEmpty) {
    return Container(height: 240, color: Colors.grey.shade200, child: Center(child: Icon(Icons.image, size: 64)));
  }
  return SizedBox(
    height: 240,
    child: PageView.builder(
      itemCount: photos.length,
      itemBuilder: (ctx, i) => Image.network(photos[i].signedUrl, fit: BoxFit.cover),
    ),
  );
}
```

- [ ] **Step 3: Widget test (사진 0/1/3장 케이스)**

```dart
testWidgets('renders placeholder when photos empty', (tester) async {
  await tester.pumpWidget(MaterialApp(home: JobInfoScreen(jobId: 'x')));
  await tester.pump();
  expect(find.byIcon(Icons.image), findsWidgets);
});

testWidgets('renders PageView when photos > 0', (tester) async {
  // mock JobRepository.fetchJob → returns job with 3 photos
  await tester.pumpWidget(...);
  expect(find.byType(PageView), findsOneWidget);
});
```

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/screens/common/job_info_screen.dart test/screens/job_info_screen_test.dart
```

---

### Task A.12: SearchScreen wire-up

**M1 plan 참조**: Task 25 (M1 plan line 3183-3326).

**본 plan 변경/추가**: 변경 없음 — `JobRepository.listJobs(q: keyword)` 호출 그대로.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 25 그대로 실행**

- [ ] **Step 2: Stage**

```bash
cd sharework && git add lib/screens/common/search_screen.dart test/screens/search_screen_test.dart
```

---

### Task A.13: CategoriesScreen + CategoryJobsScreen wire-up

**M1 plan 참조**: Task 26 (M1 plan line 3327-3591).

**본 plan 변경/추가**: 변경 없음.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 26 그대로 실행**

- [ ] **Step 2: Stage**

```bash
cd sharework && git add lib/screens/categories/categories_screen.dart lib/screens/categories/category_jobs_screen.dart test/screens/categories_screen_test.dart
```

---

### Task A.14: MyPageScreen wire-up

**M1 plan 참조**: Task 27 (M1 plan line 3592-3790).

**본 plan 변경/추가**:
- `Profile.publicId` 표시 (M2 P4.1 응답에 포함됨) — `// 본인 식별자 (외부 채팅 등에서 사용)` 코멘트

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 27 Steps 1-4 그대로 실행**

- [ ] **Step 2: 추가 — public_id 표시**

```dart
// MyPageScreen body에 추가
Text('ID: ${profile.publicId}', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
```

- [ ] **Step 3: Stage**

```bash
cd sharework && git add lib/screens/me/mypage_screen.dart test/screens/mypage_screen_test.dart
```

> M1 plan은 mypage_screen 경로를 `lib/screens/me/`로 두지 않을 수 있음 — SDD가 grep으로 mypage 실제 경로 확인.

---

### Task A.15: Integration test (m1_smoke)

**Files:**
- Create: `sharework/integration_test/m1_smoke_test.dart`

**M1 plan 참조**: Task 28 (M1 plan line 3791-3899).

**본 plan 변경/추가**:
- 시나리오: `/splash` → unauthenticated → `/auth/phone` → OTP `+821012345678` / `123456` → `/worker` (jobs 목록 표시 검증) → 첫 job tap → `/job/:id` → 사진 캐러셀 표시 확인 → MyPage → public_id 표시 검증.

> **SDD 의무 read (Plan 리뷰 SA N1)**: 본 plan §정정 이력 F1(dioPlain은 본 plan 도입 — M1 carry-over 아님) + F2(StatefulWidget setState 패턴 — Provider/Riverpod 미도입). M1 plan을 reference로 read하되 위 2가지는 본 plan 정의 우선.

- [ ] **Step 1: M1 plan Task 28 그대로 실행 + 사진 캐러셀 검증 추가**

- [ ] **Step 2: Run integration test**

```bash
cd sharework && flutter test integration_test/m1_smoke_test.dart
```

Expected: PASS (시뮬레이터에서).

- [ ] **Step 3: Stage + Sprint 1A 단일 commit + push**

```bash
cd sharework && git add integration_test/m1_smoke_test.dart
git status  # A.1~A.15 staged 누적 확인
git commit -m "feat(flutter): M1 wire-up — phone auth + worker 7 screens + repository pattern

- Sprint 1A: M1 Flutter 0-commit gap 해소
- A.1~A.4: pubspec(supabase_flutter/dio/freezed/secure_storage/dotenv) + .env + main.dart Supabase.initialize + freezed models(Profile/Job/GiverPublic/JobPhoto/JobCategory) + ApiClient(dioAuth + dioPlain F1 정정)
- A.5~A.7: AuthRepository + MeRepository + JobRepository(read) + CategoryRepository
- A.8: AuthGuard + splash redirect
- A.9~A.14: 7 화면 wire-up — PhoneAuth, WorkerHome(applied/hired pill 0/0 U3), JobInfo(사진 캐러셀), Search, Categories, CategoryJobs, MyPage(public_id 표시)
- A.15: m1_smoke integration test

M1 plan 참조: docs/superpowers/plans/2026-05-10-m1-auth-job-list.md (4107줄)
BFF: https://sharework-api.vercel.app (M1 land됨, P4.1·P4.3 응답 schema는 Sprint 2에서 변경)

R12 분리: Sprint 1A는 Sprint 1B(BFF carry-over hardening) + Sprint 2(M2 본 작업) 와 commit 별개.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin main
```

---

## Sprint 2 (Flutter 부분) — Giver M2 Wire-up (B.1 ~ B.11)

> Sprint 2 BFF(P2~P4)와 Flutter(B.1~B.11)를 **동일 commit**에 묶거나 분리 commit. 본 plan은 단일 commit 권장 (M2 feature 단위 atomic). 분리 시 BFF 먼저 push → Vercel 자동 배포 → Flutter는 production API 의존.

### Task B.1: JobRepository M2 확장 (write 메서드 추가)

**Files:**
- Modify: `sharework/lib/data/repositories/job_repository.dart`
- Modify: `sharework/test/data/job_repository_test.dart`

- [ ] **Step 1: Write failing tests**

Append to `sharework/test/data/job_repository_test.dart`:

```dart
group('JobRepository M2', () {
  test('listMine() returns own jobs across statuses', () async {
    // mock dio.get('/api/me/jobs') → 200 { data: { items: [...] } }
    final repo = JobRepository(mockDio);
    final items = await repo.listMine();
    expect(items, isA<List<Job>>());
  });

  test('createJob() POSTs to /api/jobs', () async {
    when(() => mockDio.post('/api/jobs', data: any())).thenAnswer((_) async => Response(/* job data */, requestOptions: RequestOptions(path: '')));
    final created = await repo.createJob(title: 't', description: 'd', wageWon: 1000, categoryId: 'c-1', locationAddress: 'S');
    expect(created.id, isNotEmpty);
  });

  test('updateJob() PATCHes /api/jobs/:id with status', () async {
    final updated = await repo.updateJob('j-1', status: 'paused');
    expect(updated.status, 'paused');
  });

  test('requestPhotoUploadUrl returns photo_id + storage_path + upload_url', () async {
    final res = await repo.requestPhotoUploadUrl('j-1', mimeType: 'image/jpeg', fileSizeBytes: 1000);
    expect(res.uploadUrl, startsWith('https://'));
  });

  test('confirmPhoto POSTs storage_path directly (B2)', () async {
    final photo = await repo.confirmPhoto('j-1', storagePath: 'j-1/p-1.jpg', mimeType: 'image/jpeg', fileSizeBytes: 1000);
    expect(photo.position, 1);
  });

  test('deletePhoto returns deleted=true', () async {
    expect(await repo.deletePhoto('j-1', 'p-1'), true);
  });

  test('reorderPhotos PATCHes new order', () async {
    final photos = await repo.reorderPhotos('j-1', ['p2', 'p1', 'p3']);
    expect(photos[0].id, 'p2');
  });
});
```

- [ ] **Step 2: Implement methods**

Append to `sharework/lib/data/repositories/job_repository.dart`:

```dart
class PhotoUploadInfo {
  final String photoId;
  final String storagePath;
  final String uploadUrl;
  final int expiresAtMs;
  PhotoUploadInfo({required this.photoId, required this.storagePath, required this.uploadUrl, required this.expiresAtMs});
}

extension JobRepositoryM2 on JobRepository {
  Future<List<Job>> listMine({String? status}) async {
    final res = await _dio.get('/api/me/jobs', queryParameters: { if (status != null) 'status': status });
    final items = (res.data['data']['items'] as List).cast<Map<String, dynamic>>();
    return items.map(Job.fromJson).toList();
  }

  Future<Job> createJob({
    required String title, required String description, required int wageWon,
    String? scheduleText, required String categoryId, required String locationAddress,
    double? locationLat, double? locationLng,
  }) async {
    final res = await _dio.post('/api/jobs', data: {
      'title': title, 'description': description, 'wage_won': wageWon,
      if (scheduleText != null) 'schedule_text': scheduleText,
      'category_id': categoryId, 'location_address': locationAddress,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
    });
    return Job.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<Job> updateJob(String jobId, {String? title, String? description, int? wageWon, String? scheduleText, String? categoryId, String? locationAddress, double? locationLat, double? locationLng, String? status}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (wageWon != null) body['wage_won'] = wageWon;
    if (scheduleText != null) body['schedule_text'] = scheduleText;
    if (categoryId != null) body['category_id'] = categoryId;
    if (locationAddress != null) body['location_address'] = locationAddress;
    if (locationLat != null) body['location_lat'] = locationLat;
    if (locationLng != null) body['location_lng'] = locationLng;
    if (status != null) body['status'] = status;
    final res = await _dio.patch('/api/jobs/$jobId', data: body);
    return Job.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<PhotoUploadInfo> requestPhotoUploadUrl(String jobId, {required String mimeType, required int fileSizeBytes}) async {
    final res = await _dio.post('/api/jobs/$jobId/photos/upload-url', data: {
      'mime_type': mimeType, 'file_size_bytes': fileSizeBytes,
    });
    final d = res.data['data'] as Map;
    return PhotoUploadInfo(
      photoId: d['photo_id'] as String,
      storagePath: d['storage_path'] as String,
      uploadUrl: d['upload_url'] as String,
      expiresAtMs: d['expires_at'] as int,
    );
  }

  Future<JobPhoto> confirmPhoto(String jobId, {required String storagePath, required String mimeType, required int fileSizeBytes, int? width, int? height}) async {
    final res = await _dio.post('/api/jobs/$jobId/photos/confirm', data: {
      'storage_path': storagePath, 'mime_type': mimeType, 'file_size_bytes': fileSizeBytes,
      if (width != null) 'width': width, if (height != null) 'height': height,
    });
    return JobPhoto.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<bool> deletePhoto(String jobId, String photoId) async {
    final res = await _dio.delete('/api/jobs/$jobId/photos/$photoId');
    return (res.data['data']['deleted'] as bool?) ?? false;
  }

  Future<List<JobPhoto>> reorderPhotos(String jobId, List<String> order) async {
    final res = await _dio.patch('/api/jobs/$jobId/photos/reorder', data: {'order': order});
    final items = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return items.map(JobPhoto.fromJson).toList();
  }
}
```

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/data/job_repository_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/data/repositories/job_repository.dart test/data/job_repository_test.dart
```

---

### Task B.2: photo_upload_service.dart

**Files:**
- Create: `sharework/lib/services/photo_upload_service.dart`
- Create: `sharework/test/services/photo_upload_service_test.dart`

- [ ] **Step 1: Write failing test**

Create `sharework/test/services/photo_upload_service_test.dart`:

```dart
group('PhotoUploadService', () {
  test('compresses image + requests upload-url + PUT to signed URL + confirms', () async {
    // mock JobRepository (requestPhotoUploadUrl, confirmPhoto)
    // mock dioPlain (PUT returns 204)
    // mock FlutterImageCompress (returns bytes)
    final service = PhotoUploadService(repo: mockRepo, dioPlain: mockDioPlain, compress: mockCompress);
    final photo = await service.uploadPhoto(jobId: 'j-1', picked: mockXFile);
    expect(photo.position, 1);
    // verify call order
    verifyInOrder([
      () => mockCompress.compress(any()),
      () => mockRepo.requestPhotoUploadUrl('j-1', mimeType: 'image/jpeg', fileSizeBytes: any(named: 'fileSizeBytes')),
      () => mockDioPlain.put(any(), data: any(named: 'data'), options: any(named: 'options')),
      () => mockRepo.confirmPhoto('j-1', storagePath: any(named: 'storagePath'), mimeType: 'image/jpeg', fileSizeBytes: any(named: 'fileSizeBytes')),
    ]);
  });

  test('V2: on signed URL PUT failure, retries with NEW upload-url (not reuses)', () async {
    when(() => mockDioPlain.put(any(), data: any(named: 'data'), options: any(named: 'options')))
      .thenThrow(DioException(requestOptions: RequestOptions(path: ''), response: Response(statusCode: 500, requestOptions: RequestOptions(path: ''))));
    // on retry, request new upload-url
    expect(() => service.uploadPhoto(jobId: 'j-1', picked: mockXFile), throwsA(isA<PhotoUploadException>()));
    // 즉시 throw — 자동 재시도는 UI layer 책임 (job_create_screen에서 명시 재시도 버튼)
  });

  test('rejects file > 10MB after compression', () async {
    when(() => mockCompress.compress(any())).thenAnswer((_) async => Uint8List(11 * 1024 * 1024));
    expect(() => service.uploadPhoto(jobId: 'j-1', picked: mockXFile), throwsA(isA<PhotoFileTooLargeException>()));
  });
});
```

- [ ] **Step 2: Implement service**

Create `sharework/lib/services/photo_upload_service.dart`:

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api_client.dart';
import '../data/repositories/job_repository.dart';
import '../models/api_models/job_photo.dart';

class PhotoUploadException implements Exception {
  final String message;
  final int? statusCode;
  PhotoUploadException(this.message, {this.statusCode});
  @override
  String toString() => 'PhotoUploadException($statusCode, $message)';
}

class PhotoFileTooLargeException implements Exception {
  final int sizeBytes;
  PhotoFileTooLargeException(this.sizeBytes);
}

class PhotoUploadService {
  final JobRepository _repo;
  final Dio _dioPlain;
  PhotoUploadService({JobRepository? repo, Dio? dioPlain})
    : _repo = repo ?? JobRepository.fromApi(),
      _dioPlain = dioPlain ?? ApiClient.instance.plain;

  Future<JobPhoto> uploadPhoto({required String jobId, required XFile picked}) async {
    // 1. 클라이언트 압축 (긴 변 1600px, quality 85, jpeg)
    final compressed = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      throw PhotoUploadException('compression failed');
    }
    final size = compressed.length;
    if (size > 10485760) {
      throw PhotoFileTooLargeException(size);
    }
    const mime = 'image/jpeg';

    // 2. signed URL 발급
    final info = await _repo.requestPhotoUploadUrl(jobId, mimeType: mime, fileSizeBytes: size);

    // 3. PUT signed URL (dioPlain — Authorization 미부착 F1)
    try {
      final res = await _dioPlain.put(
        info.uploadUrl,
        data: Stream.value(compressed),
        options: Options(headers: {'content-type': mime, 'x-upsert': 'false'}, contentType: mime),
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw PhotoUploadException('signed PUT non-2xx', statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      // V2: 동일 URL 재사용 X — caller가 신규 upload-url 발급 후 재시도
      throw PhotoUploadException('signed PUT failed: ${e.message}', statusCode: e.response?.statusCode);
    }

    // 4. confirm
    final photo = await _repo.confirmPhoto(
      jobId,
      storagePath: info.storagePath,
      mimeType: mime,
      fileSizeBytes: size,
    );
    return photo;
  }
}
```

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/services/photo_upload_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/services/photo_upload_service.dart test/services/photo_upload_service_test.dart
```

---

### Task B.3: photo_upload_grid widget

**Files:**
- Create: `sharework/lib/widgets/photo_upload_grid.dart`
- Create: `sharework/test/widgets/photo_upload_grid_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `sharework/test/widgets/photo_upload_grid_test.dart`:

```dart
testWidgets('renders 0~5 thumbnails + add button when < 5', (tester) async {
  final photos = [
    JobPhoto(id: 'p1', position: 1, signedUrl: 'https://1'),
    JobPhoto(id: 'p2', position: 2, signedUrl: 'https://2'),
  ];
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: PhotoUploadGrid(
    photos: photos, onAdd: () {}, onRemove: (_) {}, onReorder: (_) {},
  ))));
  expect(find.text('+ 사진 추가'), findsOneWidget);
});

testWidgets('hides add button at 5 photos', (tester) async {
  final photos = List.generate(5, (i) => JobPhoto(id: 'p$i', position: i+1, signedUrl: 'https://$i'));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: PhotoUploadGrid(
    photos: photos, onAdd: () {}, onRemove: (_) {}, onReorder: (_) {},
  ))));
  expect(find.text('+ 사진 추가'), findsNothing);
});

testWidgets('long-press initiates reorder mode (ReorderableListView)', (tester) async {
  // tap test 어렵 → renders ReorderableWrapper or similar
});

testWidgets('tap remove button calls onRemove with photo id', (tester) async {
  String? removed;
  final photos = [JobPhoto(id: 'p1', position: 1, signedUrl: 'https://1')];
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: PhotoUploadGrid(
    photos: photos, onAdd: () {}, onRemove: (id) => removed = id, onReorder: (_) {},
  ))));
  await tester.tap(find.byIcon(Icons.close).first);
  await tester.pump();
  expect(removed, 'p1');
});
```

- [ ] **Step 2: Implement widget**

Create `sharework/lib/widgets/photo_upload_grid.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/api_models/job_photo.dart';

class PhotoUploadGrid extends StatelessWidget {
  final List<JobPhoto> photos;
  final VoidCallback onAdd;
  final void Function(String photoId) onRemove;
  final void Function(List<String> newOrder) onReorder;

  const PhotoUploadGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('사진 ${photos.length}/5'),
        ),
        SizedBox(
          height: 100,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: photos.length,
            onReorder: (oldIdx, newIdx) {
              final list = photos.map((p) => p.id).toList();
              if (newIdx > oldIdx) newIdx -= 1;
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              onReorder(list);
            },
            itemBuilder: (ctx, i) {
              final p = photos[i];
              return Container(
                key: ValueKey(p.id),
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p.signedUrl, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: InkWell(
                        onTap: () => onRemove(p.id),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (photos.length < 5)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('+ 사진 추가'),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/widgets/photo_upload_grid_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/widgets/photo_upload_grid.dart test/widgets/photo_upload_grid_test.dart
```

---

### Task B.4: job_status_toggle widget

**Files:**
- Create: `sharework/lib/widgets/job_status_toggle.dart`
- Create: `sharework/test/widgets/job_status_toggle_test.dart`

- [ ] **Step 1: Write failing test**

Create `sharework/test/widgets/job_status_toggle_test.dart`:

```dart
testWidgets('active → paused: immediate callback (no dialog)', (tester) async {
  String? newStatus;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: JobStatusToggle(
    current: 'active',
    onChange: (s) => newStatus = s,
  ))));
  await tester.tap(find.text('Paused'));
  await tester.pumpAndSettle();
  expect(newStatus, 'paused');
});

testWidgets('paused → active: immediate callback', (tester) async {
  String? newStatus;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: JobStatusToggle(
    current: 'paused',
    onChange: (s) => newStatus = s,
  ))));
  await tester.tap(find.text('Active'));
  await tester.pumpAndSettle();
  expect(newStatus, 'active');
});

testWidgets('active → closed: shows confirm dialog, only fires on OK', (tester) async {
  String? newStatus;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: JobStatusToggle(
    current: 'active',
    onChange: (s) => newStatus = s,
  ))));
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  // dialog visible
  expect(find.text('마감 후 복구 불가'), findsOneWidget);
  // tap confirm
  await tester.tap(find.text('마감'));
  await tester.pumpAndSettle();
  expect(newStatus, 'closed');
});

testWidgets('cancel dialog: no callback', (tester) async {
  String? newStatus;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: JobStatusToggle(current: 'active', onChange: (s) => newStatus = s))));
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('취소'));
  await tester.pumpAndSettle();
  expect(newStatus, isNull);
});

testWidgets('closed: disables all toggles', (tester) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: JobStatusToggle(current: 'closed', onChange: (_) {}))));
  expect(tester.widget<SegmentedButton>(find.byType(SegmentedButton)).onSelectionChanged, isNull);
});
```

- [ ] **Step 2: Implement widget**

Create `sharework/lib/widgets/job_status_toggle.dart`:

```dart
import 'package:flutter/material.dart';

class JobStatusToggle extends StatelessWidget {
  final String current; // 'active' | 'paused' | 'closed'
  final void Function(String newStatus) onChange;

  const JobStatusToggle({super.key, required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final isClosed = current == 'closed';

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'active', label: Text('Active')),
        ButtonSegment(value: 'paused', label: Text('Paused')),
        ButtonSegment(value: 'closed', label: Text('Close')),
      ],
      selected: {current},
      onSelectionChanged: isClosed
        ? null
        : (sel) async {
            final next = sel.first;
            if (next == current) return;
            if (next == 'closed') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('공고 마감'),
                  content: const Text('마감 후 복구 불가'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('마감')),
                  ],
                ),
              );
              if (ok == true) onChange('closed');
            } else {
              onChange(next);
            }
          },
    );
  }
}
```

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/widgets/job_status_toggle_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/widgets/job_status_toggle.dart test/widgets/job_status_toggle_test.dart
```

---

### Task B.6: iOS Info.plist + AndroidManifest 권한 점검

**Files:**
- Modify (조건부): `sharework/ios/Runner/Info.plist`
- Modify (조건부): `sharework/android/app/src/main/AndroidManifest.xml`
- Create: `sharework/test/widgets/image_picker_permission_test.dart`

**Plan 리뷰 CR M4 (R5 grep을 step으로 박기)**: spec §8.5 권한이 self-review 체크리스트로만 있던 것을 정식 task로 land.

- [ ] **Step 0 (R5 grep 의무)**: 현재 권한 상태 확인

```bash
grep -A 2 NSPhotoLibraryUsageDescription /Users/sengmindavidhyun/Documents/David/projects/sharework/ios/Runner/Info.plist
grep "READ_MEDIA_IMAGES\|READ_EXTERNAL_STORAGE" /Users/sengmindavidhyun/Documents/David/projects/sharework/android/app/src/main/AndroidManifest.xml
```

S14 priming 흐름에서 land 가능성 — 결과에 따라 분기.

- [ ] **Step 1: iOS Info.plist — NSPhotoLibraryUsageDescription 없으면 추가**

Step 0 결과 없을 시 `<key>NSPhotoLibraryUsageDescription</key>` + `<string>공고 사진 등록을 위해 사진첩 접근이 필요합니다</string>` plist 추가. Info.plist 최상단 `<dict>` 내부에 land.

- [ ] **Step 2: Android Manifest — READ_MEDIA_IMAGES (API 33+)**

image_picker는 자동 처리하지만 명시 권장 — `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />` 누락 시 추가.

- [ ] **Step 3: Widget test — permission denied 경로**

Create `sharework/test/widgets/image_picker_permission_test.dart`:

```dart
testWidgets('shows guidance dialog when image_picker returns null (denied)', (tester) async {
  // mock ImagePicker.pickImage → null (denied/cancel 동일)
  final widget = JobCreateScreen();
  // ... addPhoto tap → _addPhoto handles null → 안내 dialog 또는 빈 op
});
```

> image_picker는 denied 시 `null` 반환. spec §9.2 권한 거부 처리는 안내 dialog 또는 silent no-op — 본 plan은 silent no-op (사용자가 다시 tap 가능).

- [ ] **Step 4: Manual smoke (시뮬레이터)**

`flutter run` → Giver → 공고 등록 → 사진 추가 → 권한 dialog → "허용" → 갤러리 표시 / "거부" → 빈 op 확인.

- [ ] **Step 5: Stage**

```bash
cd sharework && git add ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml test/widgets/image_picker_permission_test.dart
```

---

### Task B.7: GiverMainScreen wire-up (listMine + status 필터 탭)

**Files:**
- Modify: `sharework/lib/screens/giver/giver_main_screen.dart`
- Create: `sharework/test/screens/giver_main_screen_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
testWidgets('renders status tabs (전체/Active/Paused/Closed)', (tester) async {
  // mock JobRepository.listMine
  await tester.pumpWidget(MaterialApp(home: GiverMainScreen()));
  await tester.pumpAndSettle();
  expect(find.text('전체'), findsOneWidget);
  expect(find.text('Active'), findsOneWidget);
  expect(find.text('Paused'), findsOneWidget);
  expect(find.text('Closed'), findsOneWidget);
});

testWidgets('initial tab=전체 → listMine() without status', (tester) async {
  // verify mock called with no status filter
});

testWidgets('tap Paused tab → listMine(status:paused)', (tester) async {
  // verify mock called with status='paused'
});

testWidgets('FAB tap → navigates to /giver/job/create', (tester) async {
  // verify go_router push
});
```

- [ ] **Step 2: Implement screen**

Edit `sharework/lib/screens/giver/giver_main_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart';

class GiverMainScreen extends StatefulWidget {
  const GiverMainScreen({super.key});

  @override
  State<GiverMainScreen> createState() => _GiverMainScreenState();
}

class _GiverMainScreenState extends State<GiverMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _repo = JobRepository.fromApi();
  String? _statusFilter;
  late Future<List<Job>> _future;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChange);
    _future = _repo.listMine();
  }

  void _onTabChange() {
    if (!mounted) return;
    setState(() {
      switch (_tab.index) {
        case 0: _statusFilter = null; break;
        case 1: _statusFilter = 'active'; break;
        case 2: _statusFilter = 'paused'; break;
        case 3: _statusFilter = 'closed'; break;
      }
      _future = _repo.listMine(status: _statusFilter);
    });
  }

  @override
  void dispose() {
    // Plan 리뷰 CR M4: TabController + listener 누수 방지
    _tab.removeListener(_onTabChange);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 공고'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: '전체'), Tab(text: 'Active'), Tab(text: 'Paused'), Tab(text: 'Closed')],
        ),
      ),
      body: FutureBuilder<List<Job>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('오류: ${snap.error}'));
          final jobs = snap.data ?? [];
          if (jobs.isEmpty) return const Center(child: Text('등록한 공고가 없습니다'));
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (ctx, i) {
              final j = jobs[i];
              final coverUrl = j.photos.isNotEmpty ? j.photos[0].signedUrl : null;
              return ListTile(
                leading: coverUrl != null
                  ? Image.network(coverUrl, width: 56, height: 56, fit: BoxFit.cover)
                  : Container(width: 56, height: 56, color: Colors.grey.shade200),
                title: Text(j.title),
                subtitle: Text('${j.wageWon}원 · ${j.status}'),
                onTap: () => context.go('/giver/job/${j.id}/edit'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/giver/job/create'),
        icon: const Icon(Icons.add),
        label: const Text('공고 등록'),
      ),
    );
  }
}
```

> Router에 `/giver/job/:id/edit` route 추가 필요 — Sprint 1A A.8에서 라우터 변경 + 본 task에서 :id/edit GoRoute 추가.

- [ ] **Step 3: Stage**

```bash
cd sharework && git add lib/screens/giver/giver_main_screen.dart lib/router/app_router.dart test/screens/giver_main_screen_test.dart
```

---

### Task B.8: JobCreateScreen wire-up (form + photo upload)

**Files:**
- Modify: `sharework/lib/screens/giver/job_create/job_create_screen.dart`
- Create: `sharework/test/screens/job_create_screen_test.dart`

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('form validates title required', (tester) async {
  // tap submit without title → error visible
});

testWidgets('successful create → photo grid visible', (tester) async {
  // fill form + tap "다음" → JobRepository.createJob mock called → state moves to photo step
});

testWidgets('photo add tap → ImagePicker.pickImage → photo_upload_service.uploadPhoto → grid updates', (tester) async {
  // mock ImagePicker, PhotoUploadService
});

testWidgets('PHOTO_LIMIT error shows snackbar "최대 5장"', (tester) async {});
testWidgets('RATE_LIMITED error shows snackbar "잠시 후 재시도 (Xs)"', (tester) async {});
testWidgets('"완료" 버튼 tap → /giver 라우팅', (tester) async {});
```

- [ ] **Step 2: Implement screen (핵심 흐름만)**

Edit `sharework/lib/screens/giver/job_create/job_create_screen.dart` 핵심 구조:

```dart
class JobCreateScreen extends StatefulWidget {
  const JobCreateScreen({super.key});
  @override State<JobCreateScreen> createState() => _State();
}

class _State extends State<JobCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _wageC = TextEditingController();
  final _scheduleC = TextEditingController();
  final _addrC = TextEditingController();
  String? _categoryId;
  final _repo = JobRepository.fromApi();
  final _photoSvc = PhotoUploadService();

  bool _busy = false;
  Job? _createdJob;
  List<JobPhoto> _photos = [];

  @override
  void dispose() {
    // Plan 리뷰 CR M4: TextEditingController 5건 누수 방지
    _titleC.dispose();
    _descC.dispose();
    _wageC.dispose();
    _scheduleC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _busy = true);
    try {
      final job = await _repo.createJob(
        title: _titleC.text, description: _descC.text,
        wageWon: int.parse(_wageC.text), scheduleText: _scheduleC.text,
        categoryId: _categoryId!, locationAddress: _addrC.text,
      );
      setState(() => _createdJob = job);
    } on ApiError catch (e) {
      _showError(e);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto() async {
    if (_createdJob == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final photo = await _photoSvc.uploadPhoto(jobId: _createdJob!.id, picked: picked);
      setState(() => _photos = [..._photos, photo]);
    } on PhotoFileTooLargeException catch (e) {
      _showSnack('파일이 10MB를 초과합니다 (${(e.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB)');
    } on PhotoUploadException catch (e) {
      // Plan 리뷰 SA S2: V2 partial recovery — 사용자 명시 재시도 버튼
      _showSnackWithRetry('업로드 실패 (${e.statusCode ?? "network"}). 재시도', () => _addPhoto());
    } on ApiError catch (e) {
      _showError(e);
    } catch (e) {
      _showSnack('업로드 실패: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showSnackWithRetry(String msg, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      action: SnackBarAction(label: '재시도', onPressed: onRetry),
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _removePhoto(String photoId) async {
    if (_createdJob == null) return;
    try {
      await _repo.deletePhoto(_createdJob!.id, photoId);
      setState(() => _photos.removeWhere((p) => p.id == photoId));
    } on ApiError catch (e) { _showError(e); }
  }

  Future<void> _reorderPhotos(List<String> newOrder) async {
    if (_createdJob == null) return;
    try {
      final updated = await _repo.reorderPhotos(_createdJob!.id, newOrder);
      setState(() => _photos = updated);
    } on ApiError catch (e) { _showError(e); }
  }

  void _showError(ApiError e) {
    String msg;
    switch (e.code) {
      case ApiErrorCode.photoLimitExceeded: msg = '최대 5장'; break;
      case ApiErrorCode.rateLimited: msg = '잠시 후 재시도 (${e.retryAfterSec ?? "?"}s)'; break;
      case ApiErrorCode.jobStateInvalid: msg = '마감된 공고'; break;
      case ApiErrorCode.validation: msg = '입력값 확인'; break;
      default: msg = e.message;
    }
    _showSnack(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공고 등록')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_createdJob == null) _buildForm() else _buildPhotoStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(/* TextFormField 5개 + 카테고리 dropdown + 제출 버튼 */),
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text('공고가 등록되었습니다.\n사진을 추가하세요. (선택, 1~5장)')),
        PhotoUploadGrid(
          photos: _photos,
          onAdd: _addPhoto,
          onRemove: _removePhoto,
          onReorder: _reorderPhotos,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => context.go('/giver/job/preview', extra: {'job': _createdJob, 'photos': _photos}), child: const Text('미리보기'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => context.go('/giver'), child: const Text('완료'))),
            ],
          ),
        ),
      ],
    );
  }
}
```

> 핵심 분리: (a) 공고 생성 step (form) → (b) 사진 업로드 step (grid). 한 화면 내 2 state. spec §8.1 흐름 그대로.

- [ ] **Step 3: Run tests**

```bash
cd sharework && flutter test test/screens/job_create_screen_test.dart
```

Expected: PASS.

- [ ] **Step 4: Stage**

```bash
cd sharework && git add lib/screens/giver/job_create/job_create_screen.dart test/screens/job_create_screen_test.dart
```

---

### Task B.9: JobPreviewScreen wire-up

**Files:**
- Modify: `sharework/lib/screens/giver/job_create/job_preview_screen.dart`
- Create: `sharework/test/screens/job_preview_screen_test.dart`

- [ ] **Step 1: Write failing test**

```dart
testWidgets('renders job data from extra (no network call)', (tester) async {
  final job = Job(/* ... */);
  final photos = [JobPhoto(id: 'p1', position: 1, signedUrl: 'https://...')];
  await tester.pumpWidget(MaterialApp(home: JobPreviewScreen(job: job, photos: photos)));
  expect(find.text(job.title), findsOneWidget);
  expect(find.byType(PageView), findsOneWidget);  // photo carousel
});
```

- [ ] **Step 2: Implement screen**

Edit `sharework/lib/screens/giver/job_create/job_preview_screen.dart`:

```dart
class JobPreviewScreen extends StatelessWidget {
  final Job job;
  final List<JobPhoto> photos;
  const JobPreviewScreen({super.key, required this.job, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('미리보기')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty)
              SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) => Image.network(photos[i].signedUrl, fit: BoxFit.cover),
                ),
              )
            else
              Container(height: 240, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 64))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('${job.wageWon}원', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(job.description),
                  const SizedBox(height: 16),
                  Text('일정: ${job.scheduleText ?? "협의"}'),
                  Text('위치: ${job.locationAddress}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

router에서 GoRoute extra로 `{job: Job, photos: List<JobPhoto>}` 전달.

- [ ] **Step 3: Stage**

```bash
cd sharework && git add lib/screens/giver/job_create/job_preview_screen.dart test/screens/job_preview_screen_test.dart
```

---

### Task B.10: JobEditScreen wire-up (PATCH + status toggle)

**Files:**
- Modify: `sharework/lib/screens/giver/job_edit/job_edit_screen.dart`
- Create: `sharework/test/screens/job_edit_screen_test.dart`

- [ ] **Step 1: Write failing test**

```dart
testWidgets('loads existing job on init (GET /api/jobs/:id)', (tester) async {});
testWidgets('save button → PATCH /api/jobs/:id with modified fields', (tester) async {});
testWidgets('status toggle: active → paused → PATCH status', (tester) async {});
testWidgets('status toggle: active → closed → confirm dialog → PATCH status', (tester) async {});
testWidgets('JOB_STATE_INVALID after closed → snackbar', (tester) async {});
testWidgets('photo grid: add/remove/reorder updates server', (tester) async {});
```

- [ ] **Step 2: Implement screen**

Edit `sharework/lib/screens/giver/job_edit/job_edit_screen.dart`:

```dart
class JobEditScreen extends StatefulWidget {
  final String jobId;
  const JobEditScreen({super.key, required this.jobId});
  @override State<JobEditScreen> createState() => _State();
}

class _State extends State<JobEditScreen> {
  final _repo = JobRepository.fromApi();
  final _photoSvc = PhotoUploadService();
  Job? _job;
  bool _loading = true;
  bool _saving = false;

  // controllers
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _wageC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Plan 리뷰 CR M4: TextEditingController 3건 누수 방지
    _titleC.dispose();
    _descC.dispose();
    _wageC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final job = await _repo.fetchJob(widget.jobId);
      setState(() {
        _job = job;
        _titleC.text = job.title;
        _descC.text = job.description;
        _wageC.text = job.wageWon.toString();
        _loading = false;
      });
    } on ApiError catch (e) {
      _showError(e);
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _repo.updateJob(
        widget.jobId,
        title: _titleC.text != _job!.title ? _titleC.text : null,
        description: _descC.text != _job!.description ? _descC.text : null,
        wageWon: int.tryParse(_wageC.text) != _job!.wageWon ? int.parse(_wageC.text) : null,
      );
      setState(() => _job = updated);
      _showSnack('저장되었습니다');
    } on ApiError catch (e) {
      _showError(e);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _saving = true);
    try {
      final updated = await _repo.updateJob(widget.jobId, status: newStatus);
      setState(() => _job = updated);
    } on ApiError catch (e) { _showError(e); }
    finally { setState(() => _saving = false); }
  }

  // Plan 리뷰 CR S2: B.8 placeholder 제거 — 핵심 흐름 inline 명시 (_photoSvc는 위 _State 필드)
  Future<void> _addPhoto() async {
    if (_job == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final photo = await _photoSvc.uploadPhoto(jobId: _job!.id, picked: picked);
      setState(() => _job = _job!.copyWith(photos: [..._job!.photos, photo]));
    } on PhotoFileTooLargeException catch (e) {
      _showSnack('파일이 10MB를 초과합니다 (${(e.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB)');
    } on PhotoUploadException catch (e) {
      _showSnackWithRetry('업로드 실패 (${e.statusCode ?? "network"}). 재시도', () => _addPhoto());
    } on ApiError catch (e) {
      _showError(e);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _removePhoto(String photoId) async {
    if (_job == null) return;
    try {
      await _repo.deletePhoto(_job!.id, photoId);
      setState(() => _job = _job!.copyWith(photos: _job!.photos.where((p) => p.id != photoId).toList()));
    } on ApiError catch (e) { _showError(e); }
  }

  Future<void> _reorderPhotos(List<String> newOrder) async {
    if (_job == null) return;
    try {
      final updated = await _repo.reorderPhotos(_job!.id, newOrder);
      setState(() => _job = _job!.copyWith(photos: updated));
    } on ApiError catch (e) { _showError(e); }
  }

  void _showError(ApiError e) {
    String msg;
    switch (e.code) {
      case ApiErrorCode.photoLimitExceeded: msg = '최대 5장'; break;
      case ApiErrorCode.rateLimited: msg = '잠시 후 재시도 (${e.retryAfterSec ?? "?"}s)'; break;
      case ApiErrorCode.jobStateInvalid: msg = '마감된 공고는 수정할 수 없습니다'; break;
      case ApiErrorCode.validation: msg = '입력값 확인'; break;
      default: msg = e.message;
    }
    _showSnack(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSnackWithRetry(String msg, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      action: SnackBarAction(label: '재시도', onPressed: onRetry),
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_job == null) return const Scaffold(body: Center(child: Text('공고를 찾을 수 없습니다')));
    return Scaffold(
      appBar: AppBar(title: const Text('공고 수정')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: JobStatusToggle(current: _job!.status, onChange: _changeStatus),
              ),
              // 폼 (title, description, wage)
              Padding(/* ... TextField ... */),
              // 사진 그리드
              PhotoUploadGrid(
                photos: _job!.photos,
                onAdd: _addPhoto,
                onRemove: _removePhoto,
                onReorder: _reorderPhotos,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(onPressed: _save, child: const Text('저장')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Stage**

```bash
cd sharework && git add lib/screens/giver/job_edit/job_edit_screen.dart test/screens/job_edit_screen_test.dart
```

---

### Task B.11: M2 Giver Integration Smoke

**Files:**
- Create: `sharework/integration_test/m2_giver_smoke_test.dart`

- [ ] **Step 1: Write integration test**

```dart
testWidgets('Giver M2 end-to-end: OTP → create job → add photo → PATCH paused → close → cannot edit', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // OTP
  await _signIn(tester, phone: '+821012345678', otp: '123456');

  // Giver tab
  await tester.tap(find.text('등록자'));
  await tester.pumpAndSettle();

  // FAB → JobCreate
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Fill form
  await tester.enterText(find.byKey(const ValueKey('title')), '테스트 공고');
  await tester.enterText(find.byKey(const ValueKey('description')), '설명');
  await tester.enterText(find.byKey(const ValueKey('wage')), '15000');
  // category dropdown ...
  await tester.tap(find.text('등록'));
  await tester.pumpAndSettle();

  // Photo upload (mock ImagePicker)
  // ...

  // Done → Giver main
  await tester.tap(find.text('완료'));
  await tester.pumpAndSettle();

  // Tap newly created job → JobEdit
  await tester.tap(find.text('테스트 공고'));
  await tester.pumpAndSettle();

  // Status toggle: Active → Paused
  await tester.tap(find.text('Paused'));
  await tester.pumpAndSettle();
  expect(find.text('저장되었습니다'), findsOneWidget);

  // Status toggle: Paused → Closed (confirm dialog)
  await tester.tap(find.text('Close'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('마감'));
  await tester.pumpAndSettle();

  // Try edit title → JOB_STATE_INVALID
  await tester.enterText(find.byKey(const ValueKey('title')), '변경 시도');
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
  expect(find.textContaining('마감된 공고'), findsOneWidget);
});
```

- [ ] **Step 2: Run integration test**

```bash
cd sharework && flutter test integration_test/m2_giver_smoke_test.dart
```

Expected: PASS.

- [ ] **Step 3: Stage**

```bash
cd sharework && git add integration_test/m2_giver_smoke_test.dart
```

---

### Sprint 2 commit + push (BFF 먼저, Flutter 뒤)

> Plan 리뷰 CR S4: 다른 repo는 commit 분리 의무. Push 순서 — BFF 먼저 → Vercel 자동 배포 검증 → Flutter push.

- [ ] **Step 1: Verify all staged**

```bash
cd sharework-api && git status
cd /Users/sengmindavidhyun/Documents/David/projects/sharework && git status
```

- [ ] **Step 2: BFF commit + push 먼저**

```bash
# BFF
cd /Users/sengmindavidhyun/Documents/David/projects/sharework-api
git commit -m "feat(bff): M2 — job create/edit + photo upload (1~5장) + status transition

- P2.1~P2.3 마이그 3개 (profiles.public_id B3 / job_photos V1+B1 / storage bucket)
- P3.1~P3.5 lib (rate-limit Upstash sliding 30/min/user / errors M2 6개 / schemas 6개 / storage signed URL / photo-mapping)
- P4.1~P4.9 API endpoints — me(public_id), me/jobs, jobs POST+GET schema, jobs/:id GET+PATCH state machine, photos upload-url + confirm(B2) + delete + reorder
- ErrorCode M2 6개 + RPC add_job_photo(gap fill B1) + reorder_job_photos(DEFERRABLE V1)
- Rate limiting key=user:{profile_id} write 통합

Tests: BFF 60+ unit/integration + 3 e2e (M1 baseline)
R6 final 리뷰: Sprint 3에서 진행

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 3: Vercel 자동 배포 검증 (BFF push 직후)**

```bash
sleep 30 && vercel logs sharework-api --no-follow -x --since 2m
curl -s -o /dev/null -w "%{http_code}\n" https://sharework-api.vercel.app/api/categories  # 401 expected (no JWT)
```

state=Ready + 5xx 0건 확인 후 Flutter push.

- [ ] **Step 4: Flutter commit + push**

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
git commit -m "feat(flutter): M2 — Giver 공고 등록/수정/상태 전환 + 사진 업로드 (1~5장)

- B.1 JobRepository 확장 (createJob, updateJob, listMine, photo*)
- B.2 PhotoUploadService (compress + signed URL PUT via dioPlain F1 + confirm B2)
- B.3 PhotoUploadGrid widget (1~5 grid + reorder + remove)
- B.4 JobStatusToggle widget (active⇄paused + close confirm dialog)
- B.7 GiverMainScreen (listMine + status 필터 4 탭 + FAB)
- B.8 JobCreateScreen (form → POST /jobs → photo step → 완료)
- B.9 JobPreviewScreen (네트워크 X, 캐러셀 + 폼 데이터)
- B.10 JobEditScreen (GET → 편집 → PATCH + status toggle)
- B.11 m2_giver_smoke integration test

Sprint 1A wire-up 기반. Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin main
```

→ Sprint 3 (P7 E2E + P8 R6 + P9 production smoke) 진입.

---

## Sprint 3 — E2E + R6 멀티 에이전트 리뷰 + Production Smoke

### Task P7.1: BFF E2E (m2-giver-flow.test.ts)

**Files:**
- Create: `sharework-api/tests/e2e/m2-giver-flow.test.ts`

- [ ] **Step 1: Write E2E**

Create `sharework-api/tests/e2e/m2-giver-flow.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { createClient } from '@supabase/supabase-js';

const PROD = process.env.E2E_BASE_URL ?? 'https://sharework-api.vercel.app';
const SUPABASE_URL = process.env.SUPABASE_URL!;
const SUPABASE_ANON = process.env.SUPABASE_ANON_KEY!;

describe.skipIf(!process.env.RUN_E2E)('M2 Giver flow (production)', () => {
  let giverJwt: string;
  let jobId: string;
  let photoId: string;

  it('OTP login Test phone +821012345678 / 123456', async () => {
    const sb = createClient(SUPABASE_URL, SUPABASE_ANON);
    await sb.auth.signInWithOtp({ phone: '+821012345678' });
    const { data, error } = await sb.auth.verifyOtp({ phone: '+821012345678', token: '123456', type: 'sms' });
    expect(error).toBeNull();
    expect(data.session?.access_token).toBeDefined();
    giverJwt = data.session!.access_token;
  });

  it('GET /api/me returns public_id (P4.1)', async () => {
    const res = await fetch(`${PROD}/api/me`, { headers: { authorization: `Bearer ${giverJwt}` } });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.public_id).toMatch(/^.{22}$/);
  });

  it('POST /api/jobs creates job (P4.5)', async () => {
    // GET /api/categories → first id
    const catRes = await fetch(`${PROD}/api/categories`, { headers: { authorization: `Bearer ${giverJwt}` } });
    const catBody = await catRes.json();
    const categoryId = catBody.data[0].id;

    const res = await fetch(`${PROD}/api/jobs`, {
      method: 'POST',
      headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        title: `e2e-${Date.now()}`, description: 'e2e desc', wage_won: 10000,
        category_id: categoryId, location_address: '서울',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    jobId = body.data.id;
    expect(body.data.status).toBe('active');
  });

  it('POST /api/jobs/:id/photos/upload-url (P4.6)', async () => {
    const res = await fetch(`${PROD}/api/jobs/${jobId}/photos/upload-url`, {
      method: 'POST',
      headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ mime_type: 'image/jpeg', file_size_bytes: 100000 }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    photoId = body.data.photo_id;
    expect(body.data.upload_url).toMatch(/^https:\/\//);
    // Storage 직접 PUT — small bytes
    const putRes = await fetch(body.data.upload_url, {
      method: 'PUT',
      headers: { 'content-type': 'image/jpeg', 'x-upsert': 'false' },
      body: new Uint8Array(100),
    });
    expect([200, 204]).toContain(putRes.status);
  });

  it('POST /api/jobs/:id/photos/confirm (P4.7 B2)', async () => {
    const res = await fetch(`${PROD}/api/jobs/${jobId}/photos/confirm`, {
      method: 'POST',
      headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        storage_path: `${jobId}/${photoId}.jpg`,
        mime_type: 'image/jpeg', file_size_bytes: 100,
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.position).toBe(1);
  });

  it('GET /api/jobs/:id returns photos[] with signed_url (P4.4)', async () => {
    const res = await fetch(`${PROD}/api/jobs/${jobId}`, { headers: { authorization: `Bearer ${giverJwt}` } });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.photos).toHaveLength(1);
    expect(body.data.photos[0].signed_url).toMatch(/^https:\/\//);
    expect(body.data.giver.public_id).toBeDefined();
  });

  it('PATCH status: active → paused → active → closed (P4.4 state machine)', async () => {
    const pause = await fetch(`${PROD}/api/jobs/${jobId}`, {
      method: 'PATCH', headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'paused' }),
    });
    expect(pause.status).toBe(200);

    const active = await fetch(`${PROD}/api/jobs/${jobId}`, {
      method: 'PATCH', headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'active' }),
    });
    expect(active.status).toBe(200);

    const closed = await fetch(`${PROD}/api/jobs/${jobId}`, {
      method: 'PATCH', headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'closed' }),
    });
    expect(closed.status).toBe(200);

    // closed → active 시도 → 409
    const reactivate = await fetch(`${PROD}/api/jobs/${jobId}`, {
      method: 'PATCH', headers: { authorization: `Bearer ${giverJwt}`, 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'active' }),
    });
    expect(reactivate.status).toBe(409);
  });

  it('DELETE /api/jobs/:id/photos/:photoId (P4.8)', async () => {
    const res = await fetch(`${PROD}/api/jobs/${jobId}/photos/${photoId}`, {
      method: 'DELETE',
      headers: { authorization: `Bearer ${giverJwt}` },
    });
    expect(res.status).toBe(200);
  });
});
```

- [ ] **Step 2: Run E2E**

```bash
cd sharework-api && RUN_E2E=1 SUPABASE_URL=... SUPABASE_ANON_KEY=... npx vitest run tests/e2e/m2-giver-flow.test.ts
```

Expected: 모든 case PASS.

- [ ] **Step 3: Stage + commit**

```bash
cd sharework-api && git add tests/e2e/m2-giver-flow.test.ts
git commit -m "test(bff): M2 e2e — Giver flow OTP → create → photo → status transition → close → delete

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
git push origin main
```

---

### Task P7.2: Flutter Regression Check

**Files:**
- N/A — analyze + 전체 test suite 실행

- [ ] **Step 1: Run full Flutter test suite**

```bash
cd sharework && flutter analyze
flutter test
flutter test integration_test/
```

Expected:
- `flutter analyze`: 0 issues
- `flutter test`: 모든 unit/widget PASS (~50+ tests)
- `flutter test integration_test/`: m1_smoke + m2_giver_smoke PASS

- [ ] **Step 2: dart format**

```bash
cd sharework && dart format lib/ test/ integration_test/
```

- [ ] **Step 3: Build smoke (iOS + Android)**

```bash
cd sharework && flutter build ios --no-codesign --debug
cd sharework && flutter build apk --debug
```

Expected: 빌드 성공 (배포는 별도 운영 작업).

- [ ] **Step 4: Commit format diff if any**

```bash
cd sharework && git status
# format 변경만 있으면 staged + commit "style(flutter): dart format"
```

---

### Task P8.1: R6 멀티 에이전트 통합 리뷰 (Code Reviewer + Security Engineer + Database Optimizer 병렬)

**Files:**
- N/A — review dispatch only

- [ ] **Step 1: Dispatch 3 reviewers in parallel**

SDD 또는 메인 세션이 **동일 메시지에 3 Agent tool 호출**:

```
Agent(subagent_type=Code Reviewer, description="M2 sharework Code Review",
  prompt="sharework-api repo + sharework repo 모두 M2 changes 리뷰.
  - BFF: Sprint 1B (commit `<P1>`) + Sprint 2 (commit `<P2~P4>`) + E2E (`<P7.1>`)
  - Flutter: Sprint 1A (commit `<A.x>`) + Sprint 2 (commit `<B.x>`)
  - Spec: docs/superpowers/specs/2026-05-11-m2-job-create-edit-design.md (`0d2b0f0`)
  - Plan: docs/superpowers/plans/2026-05-11-m2-job-create-edit.md
  중점: (a) error handling 빠짐 (b) async race 위험 (c) test 누락 (d) zod schema gap (e) naming consistency (P1.4 ErrorCode rename 누락 위치) (f) Flutter dispose 누락 (g) freezed nullable 처리 (h) photo upload partial recovery V2 흐름.")

Agent(subagent_type=Security Engineer, description="M2 sharework Security Review",
  prompt="sharework-api M2 보안 audit.
  중점: (a) photo upload path injection — storage_path prefix 검증 강도 (b) signed URL TTL 누출 영향 (c) Rate limiting bypass — user:{profile_id} 키 분리 검증 (d) RLS coverage — job_photos giver_owner policy (e) NSPhotoLibraryUsageDescription presence (f) JWT verify ES256 pinning 유지 (g) Storage RLS backstop 정책 (h) dotenv 따옴표 strip 검증 (i) photo cleanup race — orphan storage object (j) Permissions-Policy + HSTS preload (k) public_id 22자 entropy + collision 가능성 (l) RPC SECURITY DEFINER + p_user_id 인자 추가 시 SQL injection 여부.")

Agent(subagent_type=Database Optimizer, description="M2 sharework DB Review",
  prompt="sharework-api M2 마이그 + 쿼리 audit.
  중점: (a) DEFERRABLE UNIQUE 동작 검증 — reorder swap이 statement 끝 검사로 통과 (b) gap fill RPC `generate_series` 인덱스 활용 (c) job_photos_job_position_idx 활용 — order_by position 쿼리에서 (d) profiles.public_id UNIQUE 인덱스 카디널리티 (e) jobs.giver_id FK + index 존재 여부 (M1 003에서 land됨) (f) jobs nested PostgREST select `profiles!jobs_giver_id_fkey` planner 비용 (g) RLS policy expense — EXISTS subquery 안에 job FK lookup × 사진 수 (h) storage_path TEXT UNIQUE — 보조 인덱스 비용 (i) updated_at trigger 적용 검증 — jobs/profiles 모두 trigger fire (j) RPC FOR UPDATE 캡슐화 lock escalation 위험.")
```

- [ ] **Step 2: 리뷰 결과 분류 + Important should_fix 즉시 land**

R6 룰 (Medium should_fix 본 세션 land 조건): "정량 명시 (retrofit 비용 vs 본 세션 land 비용)된 경우 한정". 5분 fix 또는 catastrophic risk only.

- [ ] **Step 3: Re-review (Code Reviewer 단독 재dispatch)**

R6 단일 1라운드 + 재리뷰 패턴 (sharework-api M1 PM4 lesson 재현).

- [ ] **Step 4: Approved 시 다음 sprint (P9) 진입**

---

### Task P9.1: Production Deploy + Smoke

**Files:**
- N/A

- [ ] **Step 1: Vercel deployment 상태 확인**

```bash
cd sharework-api && vercel ls 2>&1 | head -10
vercel logs sharework-api --no-follow -x --since 5m
```

Expected: state=Ready, error logs 0건.

- [ ] **Step 2: Production smoke — auth-required routes 401 검증**

```bash
for route in /api/me /api/me/jobs /api/jobs /api/jobs/00000000-0000-0000-0000-000000000001 /api/jobs/00000000-0000-0000-0000-000000000001/photos/upload-url; do
  curl -s -o /dev/null -w "%{http_code} %{url_effective}\n" "https://sharework-api.vercel.app${route}"
done
```

Expected: 모든 라우트 401 (Authorization 없음 → auth_required).

- [ ] **Step 3: Production smoke — 보안 헤더**

```bash
curl -I https://sharework-api.vercel.app/api/categories | grep -iE "strict-transport|x-frame|x-content-type|referrer-policy|permissions-policy"
```

Expected: 5 헤더 모두 표시.

- [ ] **Step 4: Production smoke — JWT 인증 + 핵심 flow (Test phone)**

P7.1 E2E를 `RUN_E2E=1` 환경변수로 production 대상 1회 실행:

```bash
cd sharework-api && RUN_E2E=1 SUPABASE_URL=... SUPABASE_ANON_KEY=... npx vitest run tests/e2e/m2-giver-flow.test.ts
```

Expected: 모든 case PASS.

- [ ] **Step 5: Flutter manual smoke (시뮬레이터)**

사용자 직접: iOS 시뮬레이터에서 `flutter run` → OTP login → Giver 탭 → 공고 등록 + 사진 1장 업로드 → status 변경 → MyPage public_id 표시 확인.

- [ ] **Step 6: Memory update**

`project_sharework.md` 업데이트:

- 메모리 기존: "sharework `0d2b0f0` (M2 spec 정정 7건 land)" + "sharework-api `c2266eb` (M1 외부 베타 live)"
- 메모리 갱신: "sharework `<final-commit>` (M2 Sprint 1A+2+3 land 2026-05-1X)" + "sharework-api `<final-commit>` (M2 외부 베타 live)"
- 본 plan 위치 + final 검증 결과 명시

- [ ] **Step 7: Lesson 등재**

`coding-lessons.md`에 본 M2 plan 진행에서 학습한 lesson 1~2건 등재:
- (a) advisor catch — Flutter M1 0-commit gap을 plan 작성 직전 발견 → R8 surface 후 옵션 2 mega-plan 채택 (사용자 결정 lock-in)
- (b) F1·F2 spec framing 정정 — plan 본문 §정정 이력으로 흡수 + spec commit 보존

---

## 결정 lock-in vs Plan 본문 차이 — F1·F2 처리

본 plan은 spec 본문(`docs/superpowers/specs/2026-05-11-m2-job-create-edit-design.md` `0d2b0f0`) 보존 + plan §정정 이력에서 framing 흡수 패턴. spec 본문에 직접 patch 안 함 — 사유:
- (a) spec commit `0d2b0f0`이 brainstorming 산출물의 timestamp 기록 가치 보존
- (b) plan이 항상 spec의 *최신 interpretation* 역할 (writing-plans skill 정신)
- (c) 본 plan §정정 이력 표가 verbatim grep 가능 — SDD agent가 spec read 후 plan 정정 흡수 가능

다만 SDD agent가 spec §8.3/§8.7을 그대로 인용해 dioPlain을 "M1 carry-over"로 잘못 framing할 risk 존재. 본 plan에서 명시적 차단:

> **SDD 진입 직전 의무 read**: 본 plan §정정 이력 (F1·F2). spec §8.3/§8.7 표현은 *본 plan 도입*으로 해석.

---

## Self-Review Checklist (Plan 작성 직후, 본 plan 작성자가 직접 수행)

### 1. Spec coverage

| Spec 섹션 | 본 plan 매핑 | 상태 |
|----------|-------------|------|
| §2 D1 (M2 scope) | Sprint 2 전체 + B.7~B.10 화면 | ✅ |
| §2 D2 (사진 흐름 A) | P4.6+P4.7 + B.2 photo_upload_service | ✅ |
| §2 D3 (profiles.public_id) | P2.1 마이그 + P4.1 응답 + A.4 Profile freezed | ✅ |
| §2 D4 (PATCH state machine) | P4.4 + B.10 + B.4 JobStatusToggle | ✅ |
| §2 D5 (사진 정책 1~5 / mime / 10MB / 1600px) | P3.3 schemas + B.2 service + P2.2 마이그 CHECK | ✅ |
| §2 D6 (Upstash 30/min/user) | P3.1 rate-limit.ts + 모든 write route에 checkJobWriteLimit | ✅ |
| §2 D7 (Incremental photo + 별도 테이블) | P2.2 job_photos + P4.6~P4.9 + B.3 grid | ✅ |
| §2 D8 (Flutter 4 화면 + image_picker + compress) | B.7~B.10 + B.2 + B.3 | ✅ |
| §2 D9 (M1 carry-over T_FIRST 3건) | Sprint 1B P1.1~P1.4 (Sec I-5 + Sec L-2 + dbFail nit + F4 ErrorCode align) | ✅ |
| §2 D10 (advisor 호출) | 본 plan 작성 단계에서 1회 호출됨 (Flutter M1 0-commit catch) | ✅ |
| §3 외부 의존성 (Storage + Upstash + Vercel env + pubspec) | Sprint 0 (사용자) + P0 (마이그 자동) + A.1 (SDD 자동) | ✅ |
| §4 아키텍처 + 보안 모델 5층 | P3.1+P3.4 + 마이그 RLS + P2.3 storage policy | ✅ |
| §5 Schema 변경 3 마이그 | P2.1~P2.3 | ✅ |
| §6 API 7 신규 + 3 변경 | P4.1~P4.9 | ✅ |
| §6.4 ErrorCode 확장 6 + M1 baseline | P3.2 + P1.4 (F4 align) | ✅ |
| §6.5 State machine | P4.4 + 검증 7 cases | ✅ |
| §7 Storage 흐름 + race 처리 | P3.4 + P4.7 RPC FOR UPDATE | ✅ |
| §8 Flutter Wire-up 4 화면 + 신규 파일 | B.7~B.10 + B.2 + B.3 + B.4 | ✅ |
| §8.1 home 변경 (Worker home) | A.10 (M1 wire-up 흡수 — F6 정정) | ✅ |
| §8.3 dioPlain | A.3 (F1 정정 — 본 plan 도입) | ✅ |
| §8.5 권한 (iOS Info.plist) | A.10 또는 SDD가 grep으로 S14 priming 흐름 land 확인 | ⚠️ SDD 진입 시 grep 의무 |
| §9 에러 처리 + Rate limiting | P3.1 + A.3 ApiError mapping + B.8 _showError | ✅ |
| §9.2 ErrorCode → UX 매핑 | B.8 _showError + B.10 _showError | ✅ |
| §9.3 Partial recovery V2 | B.2 PhotoUploadException + 캐리지 명시 | ✅ |
| §10 테스트 전략 (BFF 165+ / Flutter 280+) | P3~P4 unit/integration + P7.1 e2e + B 화면 widget + B.11 m2_smoke | ✅ |
| §11 M1 carry-over D9 | P1.1~P1.4 + P7.1 (CR S-5 phone normalize 자연 land) | ✅ |
| §12 R5/R11/R12 적용 | 본 plan §R5 lock-in + §R1 우회 위험 + P1.2 R11 + Sprint 단위 commit 분리 R12 | ✅ |
| §13 위험 W1~W10 | 본 plan §R1 우회 위험표 + 각 task 내 race 처리 명시 | ✅ |
| §14 SDD 분해 preview | 본 plan 51 task 분해 (preview를 actual로 land) | ✅ |

**Gap**: §8.5 iOS Info.plist는 SDD가 진입 시 `grep NSPhotoLibraryUsageDescription sharework/ios/Runner/Info.plist`로 확인. 없으면 A.10 또는 B.8 task에 추가 step 삽입.

### 2. Placeholder scan

본 plan에서 다음 안티패턴 확인:

| 패턴 | 발견 위치 | 처리 |
|------|----------|------|
| "TBD" / "TODO" | 없음 | ✅ |
| "implement later" | 없음 | ✅ |
| "add appropriate error handling" | 없음 | ✅ |
| "Similar to Task N" | A.5/A.6/A.7/A.8/A.9/A.12/A.13/A.14 — M1 plan reference 패턴 | ⚠️ 의도된 패턴 (사용자 결정 lock-in 옵션 2). SDD가 M1 plan 직접 read 의무 명시 |
| "Write tests for the above" (code 없음) | 없음 — 모든 test step에 code 명시 | ✅ |

**위험 완화**: M1 plan reference 패턴 task들은 본 plan §"참조 의무" 박스에서 "SDD가 M1 plan 직접 read 의무" 명시. 또한 본 plan에서 변경/추가 부분은 100% inline 명시 (`giver.name` 표시 / `public_id` 표시 등).

### 3. Type consistency

| 명명 | 위치 | 검증 |
|------|------|------|
| `ErrorCode.AUTH_REQUIRED` vs `UNAUTHORIZED` | P1.4 rename / A.3 ApiErrorCode.authRequired | ✅ 일치 |
| `JobPhoto.signedUrl` (camelCase) vs `signed_url` (BFF) | JSON serializable annotation `@JsonKey(name: 'signed_url')` | ✅ |
| `GiverPublic.publicId` vs `public_id` | 동일 패턴 | ✅ |
| `PhotoUploadInfo` (Dart) vs `{photo_id, storage_path, upload_url, expires_at}` (BFF) | B.1 manual 매핑 | ✅ |
| `add_job_photo` RPC signature | P2.2 정의 + P4.7 호출 + R5 SDD 확인 항목 (auth.uid() service role 동작) | ⚠️ SDD가 supabase-js docs grep 후 `p_user_id` 추가 결정 (마이그 추가 가능) |
| `reorder_job_photos` RPC | P2.2 정의 + P4.9 호출 | ⚠️ 동일 (p_user_id 추가 시 동기) |
| `dioPlain` vs `dioAuth` | A.3 정의 + B.2 dioPlain 사용 | ✅ |
| `BUCKET = 'job-photos'` | P3.4 storage.ts + P2.3 마이그 + B.2 비명시 (storage helper 추상화) | ✅ |

**SDD 진입 직전 R5 확인 의무 (type consistency 보호)**: supabase-js `rpc()` + service role 클라이언트에서 `auth.uid()` 동작. 결과에 따라 P2.2 마이그를 신규 마이그 `20260511000004_add_job_photo_user_id.sql`로 patch + RPC 시그니처에 `p_user_id` 추가. 본 plan은 옵션 명시, SDD가 결정.

### 4. 보강 항목

- [ ] **Plan Mode 리뷰 루프 의무**: 본 plan land 직후 Software Architect + Code Reviewer 병렬 dispatch 1회 (최소) → 피드백 흡수 → `✅ PLAN_REVIEWED` 체크포인트 → SDD 진입.

- [ ] **R5 SDD 진입 직전 의무 작업**:
  - `grep "auth.uid" sharework-api/node_modules/@supabase/supabase-js/dist/main/*.js`
  - `cat sharework/ios/Runner/Info.plist | grep -A 2 NSPhotoLibraryUsageDescription`
  - `cat sharework-api/node_modules/@upstash/ratelimit/README.md` (Ratelimit API 버전 lock-in 재확인)

- [ ] **R1 우회 4 조건 충족 (다음 세션 단일 압축 land 시점에)**:
  - (a) 사용자 명시 — 압축 land 결정 시 surface
  - (b) plan §위험표 + 완화안 본문 명시 — 완료 ✓
  - (c) lesson 등재 — 압축 land 결정 시 등재
  - (d) 멀티 에이전트 병렬 리뷰 — P8.1 R6 ✓

### 5. 본 plan vs 사용자 결정 일치

| 사용자 결정 | 반영 위치 | 검증 |
|------------|----------|------|
| U1: 옵션 2 mega-plan | 본 plan 51 task 분해 + Sprint 1A 흡수 | ✅ |
| U2: M1 Worker 화면 7개 그대로 | A.9~A.14 (7 화면 wire-up) | ✅ |
| U3: applied/hired pill 0/0 | A.10 명시 + 코멘트 | ✅ |
| U4: spec commit 보존 + plan에서 framing 정정 | 본 plan §정정 이력 + §결정 lock-in vs Plan 본문 차이 | ✅ |

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-11-m2-job-create-edit.md`.**

다음 단계 옵션:

**1. (권장) Plan 리뷰 루프 — Software Architect + Code Reviewer 병렬 dispatch (최소 1회 의무)**

본 plan은 mega-plan(51 task, ~3500줄)이므로 Plan Mode 리뷰 루프 의무 (CLAUDE.md). 본 plan land 직후:

```
Agent(subagent_type=Software Architect, description="M2 plan rev.1 SA review", ...)
Agent(subagent_type=Code Reviewer, description="M2 plan rev.1 CR review", ...)
```

(2 dispatch 동일 메시지에 병렬)

**2. (사용자 명시 시) SDD 진입 — superpowers:subagent-driven-development**

Plan 리뷰 통과 + 사용자 승인 후. Sprint 단위로 dispatch:
- Sprint 1A 단일 session
- Sprint 1B + Sprint 2 단일 session (또는 분할)
- Sprint 3 단일 session

**3. (사용자 명시 시) Inline Execution — superpowers:executing-plans**

본 세션에 plan 그대로 inline 실행 (R1 우회 압축 land). 4 조건 충족 의무 — 위 §R1 우회 위험표 + lesson 등재.

---

## 부록 — Sprint 단위 commit 메시지 템플릿

| Sprint | Repo | Commit 메시지 |
|--------|------|--------------|
| 1A | sharework | `feat(flutter): M1 wire-up — phone auth + worker home/list/detail + repository pattern` |
| 1B | sharework-api | `chore(bff): M1 carry-over hardening — security headers, env helper, ErrorCode align` |
| 2 BFF | sharework-api | `feat(bff): M2 — job create/edit + photo upload (1~5장) + status transition` |
| 2 Flutter | sharework | `feat(flutter): M2 — Giver 공고 등록/수정/상태 전환 + 사진 업로드 (1~5장)` |
| 3 E2E | sharework-api | `test(bff): M2 e2e — Giver flow OTP → create → photo → status transition → close → delete` |
| 3 R6 hardening | both | `fix: M2 R6 multi-agent review hardening — <items>` (해당 시) |

**Push 순서 의무** (R12 + Plan 리뷰 SA S1): **1B push → 1A push → 2 BFF push (Vercel 자동 배포 검증) → 2 Flutter push → 3 push**. BFF carry-over(ErrorCode rename) 선행 의무 — Flutter Sprint 1A integration test가 production HTTP error code parsing 의존.










