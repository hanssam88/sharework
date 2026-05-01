# Sharework — Flutter Mockup

Sharework 앱(긱워크 매칭 플랫폼)의 **UI-only 목업** 입니다. 비즈니스 로직·API·DB 없이 모든 화면을 더미 데이터로 구성한 정적 시안이며, 본 코딩에 들어가기 전 화면 구조 검토용입니다.

## 빠른 시작

이 디렉터리에는 `lib/`, `pubspec.yaml`, `analysis_options.yaml` 만 들어 있습니다. Flutter 플랫폼 폴더(`android/`, `ios/`)는 다음 명령으로 생성하세요.

```bash
# 1) 이 폴더로 이동
cd mockup_flutter

# 2) 플랫폼 폴더 스캐폴딩 (lib/ 는 보존됨)
flutter create . \
  --project-name sharework_mockup \
  --org kr.sharework \
  --platforms=android,ios

# 3) 의존성 설치 & 실행
flutter pub get
flutter run
```

> Flutter 3.19+ / Dart 3.3+ 필요. 안드로이드 에뮬레이터 또는 iOS 시뮬레이터에서 실행하세요.

## 화면 구성 (목표 사이트맵)

`[Sx]` 표시는 어느 세션에서 추가되는 화면인지를 의미합니다 (S1 = 현재 세션, 완료). 자세한 우선순위 기반 일정은 아래 [세션 로드맵](#세션-로드맵-p0--p1) 참고.

```
/splash                                   앱 진입 (브랜드 스플래시)
/auth/phone                               휴대폰 SMS 인증
/auth/signup                              회원가입 (이름·주민번호·이메일·약관·역할)
/auth/identity                            [S4] 신분증/본인인증

/worker                                   구직자 메인 (Bottom Nav 5탭)
  ├─ 홈        지도 + 일자리 BottomSheet + 즐겨찾기 / 검색바 → /search
  ├─ 지원내역  지원중·채용·완료·취소 4탭 [S1: 취소 탭 + 취소 액션]
  ├─ 채팅      대화방 목록 → 1:1 채팅
  ├─ 알림
  └─ 마이페이지

/giver                                    구인자 메인 (Bottom Nav 5탭)
  ├─ 홈        진행중·완료 2탭 (카드 더보기 → 지원자/수정/상세)
  ├─ 채팅
  ├─ 일감등록  중앙 탭 → /giver/job/create
  ├─ 알림
  └─ 마이페이지

# 공고
/giver/job/create                         공고 등록
/giver/job/:id/edit                       [S1] 공고 수정·마감·삭제
/giver/job/:id/applicants                 [S1] 지원자 관리 (대기·채용·거절 3탭)
/giver/job/:id/stats                      [S7] 통계 대시보드
/giver/job/:id/boost                      [S7] 끌어올리기/광고
/giver/job/templates                      [S7] 공고 템플릿/복제
/job/:id                                  공고 상세 (완료 시 리뷰 작성 CTA)
/job/:id/review/write                     [S1] 리뷰 작성 (별점 + 태그 + 사진)
/job/:id/checkin                          [S3] 출퇴근 (GPS·QR)
/job/:id/contract / /job/:id/contract/sign [S3] 전자근로계약서 + 서명

# 검색·매칭
/search                                   [S1] 공고 검색·필터·정렬
/recommended                              [S6] AI 추천 피드 (Worker)
/giver/workers / /giver/workers/:id       [S6] 워커 검색·스카웃
/giver/regulars                           [S6] 단골 워커 풀

# 프로필 / 마이페이지
/profile/:id                              사용자 프로필 (소개·리뷰)
/me/edit                                  내 프로필 수정
/me/identity                              [S4] 본인인증 상태
/me/credentials, /me/credentials/new      [S4] 자격증·서류
/me/resume, /me/portfolio                 [S5] 이력서·포트폴리오
/me/availability, /me/preferences         [S5] 가용 시간/희망 조건
/me/payments                              정산 내역
/me/payments/:id                          [S3] 정산 명세서 상세
/me/favorite-companies                    [S6] 즐겨찾는 업체
/me/blocklist                             [S2] 차단 목록
/me/notification-settings                 [S2] 푸시 설정
/me/invite, /me/coupons, /me/level        [S8] 초대·쿠폰·등급

# Giver 운영
/giver/business-verification              [S4] 사업자 인증
/giver/payment-methods                    [S3] 결제수단
/giver/escrow                             [S3] 에스크로 잔액·예치

# 신뢰·안전·지원
/report/:targetType/:targetId             [S2] 신고
/support, /support/faq                    [S2] 고객센터 / FAQ
/support/inquiry, /support/inquiry/new    [S2] 1:1 문의
/notice, /notice/:id                      [S2] 공지사항
/terms, /privacy, /guide                  [S2] 약관/개인정보/이용가이드
/events                                   [S8] 이벤트/미션
```

## 세션 로드맵 (P0 + P1)

경쟁사(당근알바·알바몬·급구·쑨·뉴워커·Instawork·Qwick) 비교 결과 도출한 누락 기능을 우선순위 기반 8개 세션으로 분할. 각 세션 = 라우트 등록 + UI-only 기본 화면 + 진입점 연결.

| 세션 | 우선순위 | 영역 | 주요 신규 화면 |
|---|---|---|---|
| **S1** ✅ | P0 | 운영 핵심 | `/search`, `/giver/job/:id/applicants`, `/giver/job/:id/edit`, `/job/:id/review/write`, 지원 취소 플로우 |
| **S2** ✅ | P0 | 신뢰·안전·지원 | `/report/...`, `/me/blocklist`, `/support/*`, `/notice/*`, `/terms·/privacy·/guide`, `/me/notification-settings`, 채팅·프로필 신고/차단 메뉴 |
| **S3** ✅ | P0 | 출퇴근·계약·정산 | `/job/:id/checkin` (GPS·QR), `/job/:id/contract(/sign)` (전자서명 캔버스), `/me/payments/:id` (수수료·세금 분해), `/giver/payment-methods`, `/giver/escrow` |
| **S4** ✅ | P0 | 인증·신원 | `/auth/identity` (4 step 플로우), `/me/identity`, `/me/credentials(/new)` (5종 서류·만료일·상태), `/giver/business-verification` (국세청 조회 placeholder), 프로필 인증 배지 |
| **S5** | P1 | 워커 프로필 강화 | `/me/resume`, `/me/portfolio`, `/me/availability`, `/me/preferences` |
| **S6** | P1 | 매칭·스카웃 | `/recommended`, `/giver/workers(/:id)`, `/giver/regulars`, `/me/favorite-companies` |
| **S7** | P1 | Giver 매출 도구 | `/giver/job/:id/stats`, `/giver/job/:id/boost`, `/giver/job/templates`, 정기/반복 공고 |
| **S8** | P1 | 리워드·채팅 향상 | `/me/invite`, `/me/coupons`, `/me/level`, `/events`, 채팅 첨부·신고·안심전화 |

> **백로그 (P2)**: 다국어(외국인 노동자), 다크모드, 응급콜, 단체채용, 커뮤니티 피드, 자동번역 — 본 코딩 진입 후 검토.

## 파일 구조

```
lib/
├─ main.dart
├─ theme/app_theme.dart       Material 3 + 브랜드 컬러(#64D8D1) + Noto Sans KR
├─ router/app_router.dart     go_router 설정
├─ models/models.dart         User / Job / Application / Review / Notification ...
├─ data/dummy_data.dart       모든 더미 데이터 (한국어)
├─ widgets/shared.dart        JobCard, ReviewCard, NotificationCard, TagChip ...
└─ screens/
   ├─ splash/
   ├─ auth/
   │  ├─ phone_auth_screen.dart
   │  ├─ signup_screen.dart
   │  └─ identity_screen.dart                   [S4]
   ├─ worker/
   │  ├─ worker_main_screen.dart
   │  ├─ home/worker_home_screen.dart
   │  ├─ history/history_screen.dart
   │  ├─ chat/chat_screen.dart
   │  ├─ notification/notification_screen.dart
   │  └─ mypage/mypage_screen.dart
   ├─ giver/
   │  ├─ giver_main_screen.dart
   │  ├─ home/giver_home_screen.dart
   │  └─ job_create/job_create_screen.dart
   ├─ giver/
   │  ├─ applicants/applicants_screen.dart      [S1]
   │  ├─ job_edit/job_edit_screen.dart          [S1]
   │  ├─ payment_methods_screen.dart            [S3]
   │  ├─ escrow_screen.dart                     [S3]
   │  └─ business_verification_screen.dart      [S4]
   ├─ job/                                      [S3]
   │  ├─ checkin_screen.dart
   │  ├─ contract_screen.dart
   │  └─ contract_sign_screen.dart
   └─ common/
      ├─ job_info_screen.dart
      ├─ profile_screen.dart
      ├─ user_info_update_screen.dart
      ├─ payment_history_screen.dart
      ├─ search_screen.dart                     [S1]
      ├─ review_write_screen.dart               [S1]
      └─ report_screen.dart                     [S2]
   ├─ me/
   │  ├─ blocklist_screen.dart                  [S2]
   │  ├─ notification_settings_screen.dart      [S2]
   │  ├─ payment_detail_screen.dart             [S3]
   │  ├─ identity_status_screen.dart            [S4]
   │  ├─ credentials_list_screen.dart           [S4]
   │  └─ credentials_new_screen.dart            [S4]
   ├─ support/                                  [S2]
   │  ├─ support_hub_screen.dart
   │  ├─ faq_screen.dart
   │  ├─ inquiry_list_screen.dart
   │  └─ inquiry_new_screen.dart
   ├─ notice/                                   [S2]
   │  ├─ notice_list_screen.dart
   │  └─ notice_detail_screen.dart
   └─ legal/legal_screen.dart                   [S2]
```

## 시연 흐름

1. 앱 실행 → 스플래시 → 휴대폰 인증 화면
2. 인증요청 클릭 → 인증번호 입력 → 확인
3. 회원가입 폼에서 역할(Worker/Giver) 선택 → 동의 후 시작
4. 또는 인증화면 하단의 **"테스트: 가입 건너뛰기"** 로 역할 직선택 가능
5. 마이페이지의 **"구인자/구직자 모드 전환"** 으로 두 플로우 자유롭게 비교

## 디자인 노트

- **브랜드 컬러**: 기존 Android 앱의 `mint(#64D8D1)` 를 계승
- **폰트**: `google_fonts` 의 Noto Sans KR (네트워크 접근이 어려운 환경에서는 `pubspec.yaml` 에 로컬 ttf 추가 권장)
- **지도**: 실제 SDK 연동 전이므로 그라디언트 + 마커 자리표시자로 대체
- **상태**: 모든 화면이 `StatefulWidget` 로컬 상태만 사용 (목업 단계라 글로벌 상태 매니저 미도입)

## 다음 단계 제안

| 단계 | 내용 |
|---|---|
| 1 | 이 목업으로 PM·디자인·이해관계자 화면 리뷰 |
| 2 | 디자인 시스템 정리 (Figma → 디자인 토큰 → Flutter Theme) |
| 3 | 라우팅·상태관리 본격화 (`riverpod` / `bloc`) |
| 4 | 백엔드 API 스펙 확정 후 `data/` 레이어를 `repository` 로 교체 |
| 5 | Google Maps Flutter 플러그인 + 실제 지오쿼리 연동 |
| 6 | Firebase Auth(SMS) + FCM + 채팅 백엔드(Stream/Firestore 등) |
