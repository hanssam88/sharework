# Sharework 본인 iPhone 사이드로드 가이드 (무료 Personal Team)

본 문서는 Apple Developer Program(연 $99) 가입 없이 **본인 Apple ID(무료 Personal Team)** 로 본인 iPhone에 Sharework 베타 빌드를 직접 설치하는 절차다. 다른 사람 iPhone 배포가 필요해지면 [`testflight-guide.md`](./testflight-guide.md)로 전환한다.

본 가이드는 **iPhone 15 Pro + macOS 26 + Xcode 26 + Flutter 3.41.6** 환경에서 2026-05-10 실 검증을 거쳤다.

## 이 가이드의 적용 범위

- 테스터: 본인 1명, 본인 iPhone 한 대
- 비용: 0원 (Apple ID만 필요)
- 데모 확인용 1회성 설치 — 빌드는 일정 기간 후 만료되어 재설치가 필요함

## 알려진 한도 (Apple 공식 미명시, 커뮤니티 정설)

Apple 공식 docs는 무료 Personal Team의 정확한 수치 한도를 명시하지 않는다. 아래는 개발자 커뮤니티상 일반적으로 알려진 값으로, 실제 수치는 Apple 정책 변경에 따라 달라질 수 있다.

- 빌드 유효기간: 약 7일
- 동시 설치 가능 앱 수: 약 3개 (한 Apple ID 기준)
- App Store / TestFlight 배포 불가 (개발용 사이드로드 한정)
- 일부 capability 제한 (Push Notifications 등 Paid Program 전용 기능 사용 불가, 본 MVP는 해당 없음)

## 사전 조건

- macOS + 최신 Xcode 설치
- Flutter SDK + CocoaPods 설치
- 본 저장소 로컬 클론 + `flutter pub get` 정상
- 본인 Apple ID (무료, 결제 정보 등록 불필요)
- iPhone 1대 + 데이터 통신 가능한 Lightning/USB-C 케이블 (충전 전용 케이블 불가)
- iPhone iOS 14.0 이상 (iOS 17+ 권장 — 검증된 환경)

### 환경 보정 (이미 완료됨)

- iOS deployment target 14.0 — Podfile + project.pbxproj 통일
- Bundle ID `kr.sharework.app`
- 앱 버전 `0.1.0+1`
- DEVELOPMENT_TEAM 미설정 (Step 3에서 Xcode가 자동 채움)
- Info.plist 권한 사용 설명 미설정 (UI Demo MVP — 의도된 상태)

---

## Step 0. iPhone iOS 버전 확인

iPhone에서 **설정 > 일반 > 정보 > iOS 버전** 14.0 이상인지 확인. 13.x 이하라면 iPhone iOS 업데이트 또는 deployment target 13.0으로 낮추는 추가 작업 필요(본 가이드 범위 밖).

---

## Step 1. Xcode에 본인 Apple ID 등록

1. Xcode 실행 > 메뉴 `Xcode > Settings...` (⌘,) > **Accounts** 탭
2. 좌측 하단 `+` > **Apple ID** 선택 > 본인 Apple ID 로그인 (결제 정보 없는 무료 Apple ID도 가능)
3. 로그인 완료 후 우측 패널에 **Personal Team**(이름: "Your Name (Personal Team)")이 보이는지 확인
   - Personal Team이 보이지 않고 "No teams"만 표시되면 Apple ID 약관 미동의 상태일 수 있음. https://appleid.apple.com 로그인 후 약관 동의 알림 처리.

---

## Step 2. iPhone USB 연결 + 페어링 (Signing 전에 반드시 선행)

> **이 Step 2를 Step 3 Signing보다 먼저 끝내야 한다.** Personal Team은 디바이스가 Mac에 연결돼 있어야 Apple Developer 계정에 자동 등록 + provisioning profile 생성이 가능하다. 디바이스가 등록 안 된 상태에서 Signing 화면을 열면 "Communication with Apple failed / No profiles for 'kr.sharework.app'" 노란 경고가 뜬다.

### 2-1. 케이블 연결 + Trust 다이얼로그

1. iPhone과 Mac을 USB 케이블로 연결 (충전 전용 케이블 금지 — 데이터 통신 가능 케이블 사용)
2. **iPhone 잠금 해제** (Face ID 또는 암호) — 잠금 상태에선 다이얼로그가 뜨지 않음
3. iPhone 화면 켜진 상태 유지
4. iPhone에 **"이 컴퓨터를 신뢰하시겠습니까?"** 다이얼로그 표시 → **신뢰** 탭
5. **이어서 잠금 암호 6자리(또는 4자리) 입력** ← 이 단계가 누락되면 페어링 미완료
6. Mac에 권한 다이얼로그가 뜨면 **허용**

### 2-2. 페어링 완료 확인

Xcode 메뉴 `Window > Devices and Simulators` (`⌘⇧2`) > **Devices** 탭

- 좌측에 본인 iPhone이 **검정 정상 글씨**로 표시되면 성공
- 흐릿한 회색 글씨 + "Xcode has already started pairing with iPhone. Follow the instructions on iPhone to complete pairing." 메시지가 뜨면 → iPhone 화면을 다시 보고 다이얼로그 처리
- "Preparing iPhone for development..." 메시지가 1~3분 표시될 수 있음 → 사라질 때까지 대기

터미널에서:
```bash
xcrun devicectl list devices
```
본인 iPhone이 **State: connected** 또는 **available**로 출력되면 OK. UUID(예: `C228416D-...`) 메모해 두면 Step 5에서 활용.

### 2-3. (선택) Wireless 디버깅 활성화

Xcode `Window > Devices and Simulators` > 본인 iPhone 선택 > **Connect via network** 체크. 첫 페어링은 USB로 끝내고, 다음 세션부터 USB 없이 같은 Wi-Fi에서 실행 가능.

---

## Step 3. Runner Signing & Capabilities 설정

Step 2 페어링 완료 후 진행해야 자동 등록·provisioning이 동작한다.

1. 터미널에서:
   ```bash
   cd /Users/sengmindavidhyun/Documents/David/projects/sharework
   open ios/Runner.xcworkspace
   ```
   (반드시 `.xcworkspace` 사용. `.xcodeproj` 직접 열기 금지)
2. Xcode 좌측 프로젝트 네비게이터에서 **Runner** 선택 > 우측 상단 **TARGETS > Runner** 선택
3. **Signing & Capabilities** 탭
4. `Automatically manage signing` 체크 ON
5. **Team** 드롭다운에서 Step 1에서 등록한 **Personal Team** 선택
   - 선택 즉시 `project.pbxproj`의 `DEVELOPMENT_TEAM`이 자동으로 채워진다.
   - Bundle ID `kr.sharework.app`이 다른 Apple Developer 계정에 이미 등록되어 있으면 빨간 에러가 표시될 수 있다 → 트러블슈팅 표 참고.
6. 노란 경고("Communication with Apple failed" 등)가 보이면 **Try Again** 버튼 클릭 → 5~15초 후 사라짐 확인

---

## Step 4. 사전 검증

빌드 직전 환경 정합 재확인:

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter pub get
cd ios && pod install && cd ..
flutter test
flutter analyze --no-fatal-infos
```

성공 게이트:

- `pod install` — deployment target mismatch 없이 통과
- `flutter test` — 모든 테스트 통과 (현재 2/2)
- `flutter analyze --no-fatal-infos` — error/warning 0

---

## Step 5. iPhone에 설치 + 실행

> **권장 순서**: 방법 A (Xcode UI) → 막히면 방법 B (CLI 우회). 방법 C (`flutter run`)는 Xcode 26 + iOS 17+ 환경에서 lockdown 페어링 단계에서 자주 막힌다.

### 방법 A — Xcode UI에서 ▶ (가장 안정적, 첫 실행 권장)

1. Xcode 메인 창 상단 가운데 destination 드롭다운에서 본인 iPhone 선택 (예: `iPhone — iOS 17.x`)
2. (선택) `Product > Scheme > Edit Scheme...` (`⌘<`) > Run 좌측 메뉴 > Info 탭 > **Build Configuration: Release** 변경
3. 상단 좌측 ▶ 버튼 클릭 (또는 `⌘R`)

빌드 + 설치 + 실행이 한 번에 진행된다 (3~7분, 첫 빌드). Xcode가 Apple Developer 자격증·페어링·provisioning 모두 자동 처리한다.

### 방법 B — CLI 우회 (Flutter build + devicectl install + launch)

방법 A로 한 번 빌드를 끝낸 후 같은 환경에서 재설치하거나, Xcode UI를 사용하지 않고 자동화하려면:

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter build ios --release
xcrun devicectl device install app --device <iPhone-UUID> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <iPhone-UUID> kr.sharework.app
```

`<iPhone-UUID>`는 Step 2-2의 `xcrun devicectl list devices` 출력에서 메모한 값. 본인 iPhone 한정 고정값이라 한 번 메모하면 영구 사용 가능.

이 방법은 Xcode 26 + iOS 17+ 환경에서 검증된 패턴이다 (2026-05-10 검증). `flutter run`이 lockdown 페어링 단계에서 막힐 때 우회 가능.

### 방법 C — `flutter run` (Xcode 26 + iOS 17+에선 비추천)

```bash
flutter devices
flutter run --release -d <iPhone-id>
```

Xcode 26 + macOS 26 + iOS 17+ 조합에선 `flutter run`이 lockdown 페어링을 못 잡고 `iPhone is not available because it is unpaired (code -29)` 에러로 막히는 사례가 보고됐다. 이 경우 방법 A 또는 B 사용.

성공 시 iPhone 홈스크린에 **Sharework** 아이콘 표시.

---

## Step 6. iOS 17+ 개발자 모드 활성화 (iPhone)

iOS 17 이상은 사이드로드 앱 실행 전에 **개발자 모드**를 명시 활성화해야 한다. 이 메뉴는 사이드로드 앱이 한 번이라도 설치 시도된 후에야 등장한다(Step 5 진행 후).

1. iPhone **설정 > 개인정보 보호 및 보안** 진입
2. 맨 아래까지 스크롤 → **개발자 모드** 항목 확인
3. 탭 → 토글 **ON**
4. **"재시동"** 알림 → iPhone 재시작
5. 부팅 후 잠금 화면에 **"개발자 모드 켜기?"** 다이얼로그 → **켜기** 탭
6. 잠금 암호 입력 → 활성화 완료

iOS 16 이하라면 이 Step은 건너뛰어도 된다.

---

## Step 7. iPhone에서 개발자 신뢰 (한 번만)

Step 6 활성화 후, iPhone 홈에서 Sharework 아이콘을 처음 탭하면 **"신뢰할 수 없는 개발자"** 또는 **"profile has not been explicitly trusted by the user"** 메시지가 뜬다.

1. iPhone **설정 > 일반 > VPN 및 기기 관리** (iOS 16+) 또는 **기기 관리** (iOS 14~15)
2. 본인 Apple ID가 **개발자 앱** 카테고리에 표시됨 → 탭
3. **"<Apple ID> 신뢰"** 탭 > **신뢰** 확인 + 잠금 암호 입력
4. 홈스크린으로 돌아가 Sharework 아이콘 탭 → 정상 실행

이 단계는 같은 Apple ID로 같은 iPhone에 설치하는 한 1회만 필요.

---

## Step 8. 7일 만료 후 재설치 (CLI 3줄)

무료 Personal Team 빌드는 약 7일 후 실행 시 "이 앱을 더 이상 사용할 수 없습니다" 메시지로 만료된다. 한 번 페어링·신뢰가 자리잡았으니 다음번부턴 CLI 3줄로 1~3분에 끝난다:

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter build ios --release
xcrun devicectl device install app --device <iPhone-UUID> build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device <iPhone-UUID> kr.sharework.app
```

처리 흐름:
- iPhone과 Mac을 USB 연결 + iPhone 잠금 해제
- 위 3줄 실행 → 기존 앱은 자동으로 새 빌드로 교체 (홈스크린 아이콘 위치 유지)
- Step 6·7 (개발자 모드 + 신뢰)은 같은 Apple ID라면 재실행 불필요

데모 직전 1회 재설치를 권장(만료 임박 빌드로 시연하다 갑자기 안 열리는 사고 회피).

---

## 트러블슈팅

### 페어링·인증 단계 (Step 2~3)

| 증상 | 원인 | 해결 |
|------|------|------|
| Step 3에서 "Communication with Apple failed" + "No profiles for 'kr.sharework.app'" 노란 경고 | Step 2 페어링 미완료 상태에서 Step 3 진입 | Step 2 (USB 연결 + Trust + 잠금 암호)부터 다시 진행 후 Signing 화면에서 **Try Again** |
| `flutter doctor` 또는 `flutter devices`에 `iPhone is not available because it is unpaired (code -29)` | Xcode 26 + Flutter CLI lockdown 호환성 | 방법 A (Xcode UI ▶)로 한 번 빌드 → Xcode가 lockdown 페어링 자동 처리. 그 후엔 Flutter CLI도 정상 |
| `Xcode has already started pairing with iPhone. Follow the instructions on iPhone to complete pairing.` | Trust 다이얼로그 + 잠금 암호 입력 미완료 | iPhone 잠금 해제 + 다이얼로그 신뢰 + 잠금 암호 입력 둘 다 필요 |
| `xcrun devicectl list devices`에 iPhone 미표시 | USB 통신 끊김 (sleep 또는 케이블 꼬임) | 케이블 분리 → 5초 대기 → iPhone 잠금 해제 → 재연결 |
| Step 3에서 Bundle ID 충돌 빨간 에러 | `kr.sharework.app`이 다른 Apple Developer 계정에 이미 등록됨 | `project.pbxproj`의 `PRODUCT_BUNDLE_IDENTIFIER`를 임시로 `kr.sharework.app.dev` 등으로 변경 후 재시도 (커밋하지 말고 본인 로컬에서만) |
| Xcode "No accounts" 메시지 | Xcode 계정 미등록 | Step 1 재진행 |

### 빌드·설치 단계 (Step 4~5)

| 증상 | 원인 | 해결 |
|------|------|------|
| `pod install` deployment target mismatch | Podfile과 pbxproj 불일치 | 둘 다 `14.0`인지 grep 재확인 |
| Personal Team에서 Push Notifications capability 빨간 에러 | Personal Team은 일부 paid capability 사용 불가 | 본 MVP는 push 미사용 — Capability 추가하지 말 것 |
| `xcrun devicectl device install app` 실패 시 `The device must be paired before it can be connected` | Step 2 페어링 자체가 미완료 | 케이블 재연결 + 잠금 해제 후 다시 시도. Mac 재부팅으로 usbmuxd 리셋이 가장 확실 |
| `flutter build ios --release` 시 codesign 에러 | Step 3 Signing 미설정 또는 Personal Team 인증서 캐시 부재 | 방법 A (Xcode UI ▶)로 한 번 빌드 → 자동 캐시 후 CLI도 정상 |

### 실행 단계 (Step 6~7)

| 증상 | 원인 | 해결 |
|------|------|------|
| iPhone에서 앱 아이콘 탭 시 "신뢰할 수 없는 개발자" 또는 `profile has not been explicitly trusted` | Step 7 개발자 신뢰 미설정 | Step 7 절차 진행 |
| iPhone에서 앱 시작 시 "이 앱을 시작하려면 개발자 모드가 필요" | iOS 17+ 개발자 모드 비활성화 | Step 6 절차 진행 |
| 7일 안 됐는데 갑자기 만료 메시지 | iPhone 시간/Apple ID 토큰 동기화 이슈 | 재설치(Step 8) 진행 |
| wireless debug 페어링 실패 | Wi-Fi 다른 네트워크 또는 firewall | 같은 Wi-Fi 확인 + 첫 페어링은 USB로 |

---

## 정식 베타로 전환할 때

다른 사람 iPhone에 배포하거나 7일 만료 없이 설치하려면 Apple Developer Program ($99/yr) 가입 후 [`testflight-guide.md`](./testflight-guide.md) 8단계로 전환한다. 본 가이드와 testflight 가이드는 독립적이며 어느 쪽이든 다시 사용 가능.

## 검증 환경 (2026-05-10)

| 항목 | 값 |
|------|---|
| iPhone | iPhone 15 Pro (iPhone16,1) iOS 17.x |
| Mac | macOS 26.3 darwin-arm64 |
| Xcode | 26.4.1 |
| Flutter | 3.41.6 stable |
| Personal Team ID | `B79XF7LBS2` (사용자별 고유) |
| 빌드 시간 | 첫 빌드 약 60초, 재빌드 약 30초 |
| 빌드 산출물 | `build/ios/iphoneos/Runner.app` 약 20.1MB |

## 참고

- Apple 공식 Personal Team Capability 표: https://developer.apple.com/help/account/reference/supported-capabilities-ios/
- Flutter iOS 배포 가이드: https://docs.flutter.dev/deployment/ios
- Xcode Signing 공식 도움말: https://developer.apple.com/help/account/manage-identifiers/register-an-app-id/
- iOS 17 Developer Mode 공식 안내: https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device
