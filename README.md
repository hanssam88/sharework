# Sharework iOS UI Demo MVP

Sharework는 주변 단기 일자리 매칭을 보여주는 Flutter 기반 iOS UI Demo MVP입니다. 현재 목표는 백엔드 없이 로컬 iOS 시뮬레이터에서 Worker와 Giver 양쪽 핵심 흐름을 안정적으로 시연하는 것입니다.

## MVP Scope

- Worker: 온보딩, 권한 안내, 휴대폰 인증 목업, 일자리 탐색, 공고 상세, 지원내역, 채팅, 알림, 마이페이지
- Giver: 공고 등록, 공고 미리보기, 지원자 관리, 공고 수정, 통계, 끌어올리기, 결제수단, 에스크로, 사업자 인증 목업
- 공통: 검색, 카테고리, 프로필, 리뷰 작성, 신고, 고객센터, 공지, 약관, 권한 센터
- 데이터: `lib/data/dummy_data.dart`의 더미 데이터를 사용하며 실제 API, DB, 결제, 지도 SDK, SMS 인증은 포함하지 않습니다.

## Run

```bash
flutter pub get
flutter devices
flutter run -d <ios-simulator-id>
```

`flutter devices`에 iOS Simulator가 보이지 않으면 Xcode에서 iOS Simulator를 설치하고 부팅한 뒤 다시 확인하세요.

iOS 시뮬레이터 빌드만 확인하려면:

```bash
flutter build ios --simulator
```

## Verification

```bash
flutter test
flutter analyze --no-fatal-infos
flutter build ios --simulator
flutter build ios --release --no-codesign
```

`flutter analyze`의 info 항목에는 `const` 권고와 Flutter 최신 API deprecation 안내가 남아 있을 수 있습니다. MVP 품질 게이트는 warning/error 없이 동작하는 것을 기준으로 합니다.

## iOS TestFlight

- 배포 대상: TestFlight 내부 테스트
- Bundle ID: `kr.sharework.app`
- 앱 버전: `0.1.0+1`
- 서명 방식: Xcode 자동 서명

TestFlight 업로드 전 Xcode에서 `ios/Runner.xcworkspace`를 열고 Runner 타깃의 Team을 Apple Developer 계정의 배포 팀으로 선택하세요. 이 앱은 더미 데이터 기반 UI Demo MVP이므로 App Store Connect의 베타 앱 설명에는 실제 API, SMS 인증, 결제, 지도 SDK가 포함되지 않았다는 점을 명시합니다.

권장 업로드 흐름:

1. `flutter test`, `flutter analyze --no-fatal-infos`, `flutter build ios --release --no-codesign` 확인
2. Xcode에서 `Runner` scheme과 `Any iOS Device` destination 선택
3. `Product > Archive`
4. Organizer에서 `Validate App` 후 `Distribute App > App Store Connect > Upload`
5. App Store Connect TestFlight에서 내부 테스트 그룹에 빌드 추가

## Demo Flow

1. 앱 실행 후 스플래시에서 온보딩으로 이동
2. 권한 안내를 지나 휴대폰 인증 화면 진입
3. `테스트: 가입 건너뛰기`로 Worker 또는 Giver 선택
4. Worker 흐름: 홈 지도형 리스트, 검색, 공고 상세, 지원내역, 채팅, 마이페이지 확인
5. Giver 흐름: 홈, 공고 등록/미리보기, 지원자 관리, 결제/에스크로, 마이페이지 확인

## Project Notes

- 앱 이름은 iOS에서 `Sharework`로 표시됩니다.
- iPhone/iPad 시연은 세로 방향을 기준으로 합니다.
- 권한 상태는 `PermissionStore` 메모리 상태로만 관리합니다.
- 실제 서비스 전환 시 `data/` 레이어를 repository/API 레이어로 교체하고 인증, 저장소, 푸시, 결제, 지도 SDK를 단계적으로 연결합니다.
