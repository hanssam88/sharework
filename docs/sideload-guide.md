# Sharework 본인 iPhone 사이드로드 가이드 (무료 Personal Team)

본 문서는 Apple Developer Program(연 $99) 가입 없이 **본인 Apple ID(무료 Personal Team)** 로 본인 iPhone에 Sharework 베타 빌드를 직접 설치하는 절차다. 다른 사람 iPhone 배포가 필요해지면 [`testflight-guide.md`](./testflight-guide.md)로 전환한다.

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
- iPhone 1대 + Lightning/USB-C 케이블
- iPhone iOS 14.0 이상 (Sharework deployment target과 일치)

### 환경 보정 (이미 완료됨)

- iOS deployment target 14.0 — Podfile + project.pbxproj 통일
- Bundle ID `kr.sharework.app`
- 앱 버전 `0.1.0+1`
- DEVELOPMENT_TEAM 미설정 (Step 2에서 Xcode가 자동 채움)
- Info.plist 권한 사용 설명 미설정 (UI Demo MVP — 의도된 상태)

## Step 0. iPhone iOS 버전 확인

iPhone에서 **설정 > 일반 > 정보 > iOS 버전** 14.0 이상인지 확인. 13.x 이하라면 iPhone iOS 업데이트 또는 deployment target 13.0으로 낮추는 추가 작업 필요(본 가이드 범위 밖).

## Step 1. Xcode에 본인 Apple ID 등록

1. Xcode 실행 > 메뉴 `Xcode > Settings...` (⌘,) > **Accounts** 탭
2. 좌측 하단 `+` > **Apple ID** 선택 > 본인 Apple ID 로그인 (결제 정보 없는 무료 Apple ID도 가능)
3. 로그인 완료 후 우측 패널에 **Personal Team**(이름: "Your Name (Personal Team)")이 보이는지 확인
   - Personal Team이 보이지 않고 "No teams"만 표시되면 Apple ID 약관 미동의 상태일 수 있음. https://appleid.apple.com 로그인 후 약관 동의 알림 처리.

## Step 2. Runner Signing & Capabilities 설정

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

## Step 3. iPhone USB 연결 + Trust 승인

1. iPhone과 Mac을 USB 케이블로 연결
2. 처음 연결 시 iPhone 화면에 **"이 컴퓨터를 신뢰하시겠습니까?"** 다이얼로그 표시 → **신뢰** 탭
3. iPhone 잠금 해제 상태 유지
4. Xcode 상단 destination 선택기에서 본인 iPhone 모델명이 보이는지 확인 (예: `iPhone 13 - hanssam`)

(선택) wireless 디버깅 활성화: Xcode 메뉴 `Window > Devices and Simulators` > 본인 iPhone 선택 > **Connect via network** 체크. 다음 세션부터 USB 없이 같은 Wi-Fi에서 실행 가능.

## Step 4. 사전 검증

빌드 직전 환경 정합 재확인:

```bash
cd /Users/sengmindavidhyun/Documents/David/projects/sharework
flutter pub get
cd ios && pod install && cd ..
flutter test
flutter analyze --no-fatal-infos
flutter build ios --release --no-codesign
```

성공 게이트:

- `pod install` — deployment target mismatch 없이 통과
- `flutter test` — 모든 테스트 통과 (현재 2/2)
- `flutter analyze --no-fatal-infos` — error/warning 0
- `flutter build ios --release --no-codesign` — 성공

## Step 5. iPhone에 설치 + 실행

방법 A — Flutter CLI (간편):

```bash
flutter devices         # 본인 iPhone이 목록에 보이는지 확인
flutter run --release -d <iPhone-id>
```

`<iPhone-id>`는 `flutter devices` 출력의 첫 번째 컬럼 값이다. release 모드는 사이드로드 후 데모 시연 안정성에 유리(debug보다 빠르고 7일 만료 정책상 동일).

방법 B — Xcode UI:

1. Xcode 상단 destination 선택기에서 본인 iPhone 선택
2. Scheme이 `Runner`인지 확인 후 `Product > Scheme > Edit Scheme...`에서 Build Configuration을 **Release**로 변경 (선택)
3. ▶ 버튼 클릭 또는 ⌘R

빌드 + 설치 진행 (수 분 소요). 완료 시 iPhone 홈스크린에 **Sharework** 아이콘 표시.

## Step 6. iPhone에서 개발자 신뢰

처음 설치 직후 iPhone에서 앱 실행 시 **"신뢰할 수 없는 개발자"** 알림이 뜬다. 한 번만 다음 절차로 신뢰:

1. iPhone **설정** 앱 > **일반** > **VPN 및 기기 관리** (iOS 16+) 또는 **기기 관리** (iOS 14~15)
2. 본인 Apple ID가 **개발자 앱** 카테고리에 표시됨 → 탭
3. **"<Apple ID> 신뢰"** 탭 > **신뢰** 확인
4. 홈스크린으로 돌아가 Sharework 아이콘 탭 → 정상 실행

이 단계는 같은 Apple ID로 같은 iPhone에 설치하는 한 1회만 필요.

## Step 7. 7일 만료 후 재설치

무료 Personal Team 빌드는 약 7일 후 실행 시 "이 앱을 더 이상 사용할 수 없습니다" 메시지로 만료된다. 재설치 절차:

1. iPhone과 Mac을 USB 연결 (처음과 동일)
2. 다음 명령 실행:
   ```bash
   cd /Users/sengmindavidhyun/Documents/David/projects/sharework
   flutter run --release -d <iPhone-id>
   ```
3. 기존 앱은 자동으로 새 빌드로 교체됨 (홈스크린 아이콘 위치 유지)
4. Step 6 신뢰 절차는 같은 Apple ID라면 재실행 불필요

데모 직전 1회 재설치를 권장(만료 임박 빌드로 시연하다 갑자기 안 열리는 사고 회피).

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| Step 2에서 Bundle ID 충돌 빨간 에러 | `kr.sharework.app`이 다른 Apple Developer 계정에 이미 등록됨 | `project.pbxproj`의 `PRODUCT_BUNDLE_IDENTIFIER`를 임시로 `kr.sharework.app.dev` 등으로 변경 후 재시도 (커밋하지 말고 본인 로컬에서만) |
| iPhone에서 앱 아이콘 탭 시 "신뢰할 수 없는 개발자" | 개발자 신뢰 미설정 | Step 6 절차 진행 |
| `flutter devices`에 iPhone 미표시 | USB 케이블 데이터 미지원 또는 Trust 미승인 | 다른 USB 케이블 시도 + iPhone 재연결 후 "신뢰" 다이얼로그 확인 |
| 7일 안 됐는데 갑자기 만료 메시지 | iPhone 시간/Apple ID 토큰 동기화 이슈 | 재설치(Step 7) 진행 |
| `pod install` deployment target mismatch | Podfile과 pbxproj 불일치 | 둘 다 `14.0`인지 grep 재확인 |
| Personal Team에서 Push Notifications capability 빨간 에러 | Personal Team은 일부 paid capability 사용 불가 | 본 MVP는 push 미사용 — Capability 추가하지 말 것 |
| wireless debug 페어링 실패 | Wi-Fi 다른 네트워크 또는 firewall | 같은 Wi-Fi 확인 + 첫 페어링은 USB로 |
| Xcode "No accounts" 메시지 | Xcode 계정 미등록 | Step 1 재진행 |

## 정식 베타로 전환할 때

다른 사람 iPhone에 배포하거나 7일 만료 없이 설치하려면 Apple Developer Program ($99/yr) 가입 후 [`testflight-guide.md`](./testflight-guide.md) 8단계로 전환한다. 본 가이드와 testflight 가이드는 독립적이며 어느 쪽이든 다시 사용 가능.

## 참고

- Apple 공식 Personal Team Capability 표: https://developer.apple.com/help/account/reference/supported-capabilities-ios/
- Flutter iOS 배포 가이드: https://docs.flutter.dev/deployment/ios
- Xcode Signing 공식 도움말: https://developer.apple.com/help/account/manage-identifiers/register-an-app-id/
