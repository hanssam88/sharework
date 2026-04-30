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

## 화면 구성

```
/splash                       앱 진입 (브랜드 스플래시)
/auth/phone                   휴대폰 SMS 인증
/auth/signup                  회원가입 (이름·주민번호·이메일·약관·역할 선택)

/worker                       구직자 메인 (Bottom Nav 5탭)
  ├─ 홈        지도(자리표시) + 일자리 BottomSheet + 즐겨찾기 위치
  ├─ 지원내역  지원중·채용·완료 3탭
  ├─ 채팅      대화방 목록 → 1:1 채팅 화면
  ├─ 알림      카테고리별 알림 리스트
  └─ 마이페이지 프로필·계정·활동·고객센터

/giver                        구인자 메인 (Bottom Nav 5탭)
  ├─ 홈        진행중·완료 2탭
  ├─ 채팅      (Worker와 공유)
  ├─ 일감등록  중앙 탭 클릭 시 /giver/job/create 풀스크린
  ├─ 알림      (공유)
  └─ 마이페이지 (공유, 항목 일부 차이)

/giver/job/create             공고 등록 폼
/job/:id                      공고 상세 (지원 다이얼로그 포함)
/profile/:id                  사용자 프로필 (소개·리뷰)
/me/edit                      내 프로필 수정
/me/payments                  정산 내역
```

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
   │  └─ signup_screen.dart
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
   └─ common/
      ├─ job_info_screen.dart
      ├─ profile_screen.dart
      ├─ user_info_update_screen.dart
      └─ payment_history_screen.dart
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
