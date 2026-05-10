# Sharework 실서비스 전환 마스터 플랜

본 문서는 Sharework UI Demo MVP를 단계적 베타 서비스로 전환하는 전체 로드맵이다. 각 마일스톤(M1~M8)은 별도 세션에서 brainstorming + Plan Mode + SDD로 구현한다. 본 문서는 전체 그림과 결정 lock-in만 다루며, 마일스톤별 상세 plan은 별도 문서로 분리한다.

## 배경

UI Demo MVP는 80개 화면 + 75개 라우트로 화면·흐름은 완비됐다(`main d3ee713`, 2026-05-09 기준). 이제 더미 데이터를 실 API로 교체하고, 실 사용자 10~50명 규모로 단계적 베타 검증을 거쳐 정식 출시로 진화시키는 단계로 넘어간다.

## 결정 lock-in (2026-05-10)

| 결정 | 값 | 근거 |
|------|---|------|
| 운영 성격 | 단계적 베타 (정식 출시 전 실 사용자 시험) | 사업자 등록·App Review 부담 우선 회피, 베타 검증 후 정식화 결정 |
| 베타 사용자 규모 | 10~50명 (TestFlight 정식 트랙) | Personal Team 사이드로드는 본 세션에 검증 완료, 다른 사람 배포는 TestFlight 필요 |
| 백엔드 스택 | Supabase + Next.js BFF | 다른 프로젝트(household-ledger·law-search·easy-travel-korea) 동일 패턴 → 러닝커브 최소 |
| Postgres·Auth·Storage·Realtime | Supabase 일괄 사용 | 단일 벤더로 운영 부담 최소 |
| BFF 위치 | 신규 레포 (`sharework-api`) — Next.js 16 + TypeScript + zod | easy-travel-korea-api 패턴 그대로 승계 |
| 첫 마일스톤(M1) | SMS 인증 + 공고 조회만 | 가장 단순한 양방향 흐름. 나머지 화면은 더미 데이터 유지 |

## 마일스톤 로드맵

| ID | 범위 | 외부 의존성 | 추정 세션 |
|----|------|-------------|-----------|
| **M1** | SMS 인증 + 공고 목록·상세 조회 (Worker 시점) | Supabase 프로젝트 생성, SMS 인증 라이선스(NHN Cloud / 카카오 알림톡 / Twilio Verify 중 택1) | 2~3 |
| **M2** | 공고 등록·수정 (Giver) + 사진 업로드 | Supabase Storage 버킷, Image picker 패키지 | 2 |
| **M3** | 공고 지원 + 지원자 관리 + 단순 채팅(폴링) | Supabase Realtime(channel) | 2 |
| **M4** | 실시간 채팅(WebSocket) + 푸시 알림(FCM/APNs) | Firebase 프로젝트(FCM), APNs 키 발급 | 2~3 |
| **M5** | 결제·에스크로 + 정산 | 토스 페이먼츠 또는 카카오 페이 PG 계약 | 2~3 |
| **M6** | 위치·지도 SDK + 실 권한 호출 + Info.plist 권한 설명 | 네이버 지도 SDK 키 또는 카카오 지도 SDK 키 | 2 |
| **M7** | 사업자 인증 + 신원 인증(KYC) + 신고/제재 | 사업자 인증 API 연동(국세청 또는 사업자등록번호 진위 확인 API) | 1~2 |
| **M8** | TestFlight 정식 트랙 진입 + 베타 사용자 모집 | Apple Developer Program $99/yr 가입 + ASC 등록 | 1 |

**총 추정**: 14~18 세션. M1~M3까지 진행 후 베타 첫 그룹에 배포할 가능성 높음(채팅·결제·지도 없이도 핵심 매칭 흐름은 시현 가능).

## M1 — 첫 마일스톤 inputs (다음 세션 brainstorming용)

다음 세션에 brainstorming을 시작할 때 결정해야 할 항목:

### 1. SMS 인증 공급자 선택

| 후보 | 장점 | 단점 |
|------|------|------|
| **NHN Cloud SMS** | 한국 가격 저렴, 발신 번호 등록 빠름 | API가 한국식, 영문 docs 부족 |
| **카카오 알림톡** | 사용자 도달률 높음 | 사업자 등록 + 카카오 비즈 채널 개설 필요 |
| **Twilio Verify** | 글로벌, docs 충실 | 가격 비쌈, 한국 SMS 별도 |
| **Supabase Phone Auth** | Supabase 일괄 통합 | 백엔드는 Twilio/MessageBird 등 외부 SMS 게이트웨이 필요 (Supabase는 발송만 중계) |

### 2. 데이터 모델 (M1 범위)

- `users` (id, phone, name, role: worker|giver, created_at)
- `auth_otp` (phone, code, expires_at, attempts) — Supabase Phone Auth 쓰면 Supabase가 관리
- `jobs` (id, giver_id, title, description, location, wage, schedule, status, created_at)
- `job_categories` (id, name, slug)
- `job_locations` (job_id, lat, lng, address) — M6에 본격 활용
- (이후 마일스톤): applications, reviews, payments, escrow, chats, notifications

### 3. BFF API 엔드포인트 (M1 범위)

- `POST /api/auth/send-otp` — 휴대폰 번호 입력 → SMS 발송
- `POST /api/auth/verify-otp` — OTP 인증 → 세션 토큰 발급
- `GET /api/jobs` — 공고 목록 (페이지네이션 + 카테고리 필터)
- `GET /api/jobs/:id` — 공고 상세
- `GET /api/me` — 본인 정보 조회 (인증 검증)

### 4. Flutter 클라이언트 변경 범위 (M1)

- 신규: `lib/data/api_client.dart` (HTTP 클라이언트, Bearer 토큰 인터셉터)
- 신규: `lib/data/repositories/auth_repository.dart`
- 신규: `lib/data/repositories/job_repository.dart`
- 변경: `lib/screens/auth/phone_auth_screen.dart` — 더미 OTP → 실 API 호출
- 변경: `lib/screens/worker/home/worker_home_screen.dart` — 더미 jobs → API 조회
- 변경: `lib/screens/job/job_info_screen.dart` — 더미 → API 조회
- 신규: `lib/data/auth_storage.dart` — flutter_secure_storage로 토큰 영속화
- 의존성 추가: `dio`, `flutter_secure_storage`, `freezed`(또는 `json_serializable`)

### 5. 보안 고려사항 (M1)

- BFF에서 휴대폰 번호 + OTP 코드 로깅 금지 (PII)
- OTP 시도 횟수 제한 (3회/번호/10분)
- 발신 번호 중복 발송 방지 (cooldown 60초)
- BFF에서 Supabase service role key는 절대 클라이언트 노출 금지
- 모바일에서 Supabase anon key + RLS 정책으로 보호

## 외부 의존성 처리 순서 (M1 시작 전)

본 세션 이후 사용자가 직접 처리해야 할 항목:

| 순서 | 항목 | 소요 |
|------|------|------|
| 1 | Supabase 프로젝트 생성 (https://supabase.com) — 무료 tier로 시작 | 5분 |
| 2 | Supabase 프로젝트 URL + anon key + service role key 발급 | 1분 |
| 3 | SMS 공급자 선택 + 가입 + 발신 번호 등록 (NHN Cloud 권장) | 1~3일 (발신 번호 등록 심사) |
| 4 | (선택) Vercel 계정 + GitHub 연동 (BFF 배포용) | 5분 |
| 5 | sharework-api 신규 레포 생성 | 5분 |

3번이 가장 시간 소요. M1 brainstorming은 1·2·5번까지만 끝나면 시작 가능 (SMS는 mock으로 시작 → 실제 SMS는 M1 후반에 통합).

## 다음 세션 진입점

**다음 세션에서 할 일**:

1. `/brainstorming` 스킬로 M1 의도·요구사항·설계 탐색
2. `/writing-plans` 스킬로 M1 상세 plan 작성 (docs/superpowers/plans/2026-MM-DD-m1-auth-job-list.md)
3. Plan 리뷰 루프 1~2회
4. 사용자 승인 시 SDD로 구현 진입

**다음 세션 진입 전 사용자 작업**:

- (필수) Supabase 프로젝트 생성 + 키 3개 메모
- (선택) SMS 공급자 결정·가입 (M1 후반에 필요, brainstorming은 미리 시작 가능)

## 변경하지 않는 것 (본 마일스톤 로드맵 외부)

- `lib/data/dummy_data.dart` — M1 범위 외 화면(Giver 흐름·채팅·결제 등)은 모두 더미 유지
- `docs/sideload-guide.md` — 별도 정정 작업 (본 세션 발견사항 반영, 사용자 요청 시)
- `docs/testflight-guide.md` — M8에서 활용
- iOS deployment target 14.0 — M6에서 권한 라이브러리 도입 시 재평가

## 참고

- Supabase docs: https://supabase.com/docs
- NHN Cloud SMS docs: https://www.toast.com/service/notification/sms
- easy-travel-korea-api 레포 (참고 아키텍처): 다른 프로젝트 메모리 참고
- Flutter dio + secure_storage 패턴: 일반화된 패턴, 다음 세션 brainstorming에서 결정
