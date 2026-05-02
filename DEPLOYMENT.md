# Sharework — iOS / Android 배포 가이드

Flutter는 **단일 코드베이스로 iOS와 Android 양쪽 스토어에 동시 배포**할 수 있습니다. `lib/` 의 Dart 코드를 그대로 두고, 플랫폼별 빌드 산출물(AAB·IPA)만 따로 생성해 각 스토어에 올리면 끝입니다.

```
[lib/ Dart 코드]
       │
       ├──flutter build appbundle ──▶ app-release.aab ─▶ Google Play Console
       │
       └──flutter build ipa ───────▶ Runner.ipa ──────▶ App Store Connect
```

> ⚠️ **iOS 배포에는 macOS + Xcode가 반드시 필요합니다.** Apple의 코드 서명·아카이브 도구가 macOS 전용이기 때문입니다. macOS 머신이 없다면 Codemagic, Bitrise 같은 클라우드 CI가 우회 옵션입니다(아래 [CI/CD](#7-cicd-우회-옵션) 참고).

---

## 1. 사전 준비

### 공통

| 항목 | 비고 |
|---|---|
| Flutter SDK 3.19+ / Dart 3.3+ | `flutter --version` 으로 확인 |
| 플랫폼 폴더 스캐폴딩 | 본 저장소는 `lib/` 만 들어 있음 — [README "빠른 시작"](./README.md#빠른-시작)의 `flutter create .` 명령으로 `android/`, `ios/` 생성 |
| 앱 아이콘·스플래시 | `flutter_launcher_icons`, `flutter_native_splash` 패키지 권장 |
| 버전 표기 | `pubspec.yaml` 의 `version: 1.0.0+1` 형식 — 앞은 표시 버전, `+` 뒤는 빌드 번호 |

### Android 전용

| 항목 | 비고 |
|---|---|
| JDK 17 + Android Studio | Android SDK·플랫폼 도구 포함 설치 |
| 키스토어(서명 키) | `keytool` 로 1회 생성 후 안전하게 백업 — 분실 시 동일 앱 업데이트 불가 |
| Google Play Console 계정 | $25 1회 등록 |

### iOS 전용

| 항목 | 비고 |
|---|---|
| **macOS + Xcode (최신 버전)** | 필수. CocoaPods(`sudo gem install cocoapods`)도 필요 |
| Apple Developer Program | $99/년 |
| 서명 인증서 + Provisioning Profile | Xcode가 "Automatic signing" 으로 대부분 자동 처리 |
| App Store Connect 앱 등록 | Bundle ID·앱 이름·카테고리 사전 등록 |

---

## 2. Android 배포 핵심 단계

1. **앱 식별자·버전 확인**
   - `android/app/build.gradle` 의 `applicationId` (예: `kr.sharework.app`) — 한 번 정하면 사실상 변경 불가
   - `pubspec.yaml` 의 `version` 을 올림 (예: `1.0.0+1` → `1.0.1+2`)

2. **서명 설정**
   - `android/key.properties` 에 키스토어 경로·비밀번호 기재(이 파일은 `.gitignore` 에 추가)
   - `android/app/build.gradle` 의 `signingConfigs.release` 가 `key.properties` 를 읽도록 설정

3. **릴리스 빌드**
   ```bash
   flutter build appbundle --release
   # 산출물: build/app/outputs/bundle/release/app-release.aab
   ```
   > Google Play는 2021년부터 AAB(App Bundle)를 요구합니다. APK는 사내 배포용으로만 사용.

4. **Play Console 업로드**
   - **내부 테스트** 트랙에 AAB 업로드 → 테스터 이메일 등록 → 즉시 설치 링크 공유
   - 검증 후 **비공개 → 공개 테스트 → 프로덕션** 트랙으로 승격

5. **출시 심사**
   - 첫 출시는 보통 **1~3일** 소요(이후 업데이트는 수 시간~1일)

---

## 3. iOS 배포 핵심 단계

1. **Xcode 프로젝트 설정** (`open ios/Runner.xcworkspace`)
   - **Bundle Identifier** (예: `kr.sharework.app`) 확인
   - **Team** 선택, **Automatically manage signing** 체크
   - `pubspec.yaml` 의 `version` 이 Xcode의 Version·Build로 자동 반영됨

2. **릴리스 빌드**
   ```bash
   flutter build ipa --release
   # 산출물: build/ios/ipa/Runner.ipa
   ```
   또는 Xcode → **Product ▸ Archive** 로 동일 결과.

3. **App Store Connect 업로드**
   - **Transporter** 앱 (Mac App Store 무료) 으로 `.ipa` 드래그 업로드
   - 또는 Xcode **Organizer ▸ Distribute App**

4. **TestFlight 테스트**
   - 업로드된 빌드는 자동으로 TestFlight에 노출 (10~30분 처리 대기)
   - **내부 테스트**(팀원 100명, 즉시) → **외부 테스트**(최대 1만명, Apple 간단 검토 1일 내)

5. **App Store 심사 제출**
   - App Store Connect에서 빌드 선택 → 스크린샷·설명·심사용 계정 입력 → 제출
   - 심사 보통 **1~2일** (거절 시 사유 메시지 보고 수정 후 재제출)

---

## 4. 흔한 함정 체크리스트

- ❌ **버전 충돌** — 스토어는 동일·낮은 `versionCode`/`build number`를 거부합니다. 매 업로드마다 빌드 번호 증가 필수.
- ❌ **iOS 권한 문구 누락** — 카메라·위치·마이크 등은 `ios/Runner/Info.plist` 에 `NSCameraUsageDescription` 같은 사용 목적 문구가 없으면 심사 거절.
- ❌ **Bundle ID / Package name 변경 시도** — 한 번 출시하면 사실상 변경 불가. 새 앱으로 등록해야 함.
- ❌ **Android 키스토어 분실** — 동일 앱 업데이트 영구 불가. 클라우드 보관 + 비밀번호 별도 보관.
- ❌ **개인정보 처리방침 URL** — 양 스토어 모두 필수. 본 프로젝트는 `/privacy` 라우트가 있으니 호스팅 후 URL 등록.

---

## 5. 배포 전 빠른 체크리스트

```
□ pubspec.yaml version 올림
□ 앱 아이콘·스플래시 적용 확인 (flutter_launcher_icons / flutter_native_splash)
□ Android: key.properties 존재 + .gitignore 등록
□ iOS: Bundle ID·Team·Signing 정상 + Info.plist 권한 문구
□ 디버그 코드·console 로그 제거
□ flutter build appbundle --release 성공
□ flutter build ipa --release 성공 (macOS 필요)
□ Play Console 내부 테스트 통과
□ TestFlight 내부 테스트 통과
□ 스크린샷·앱 설명·개인정보 URL 준비
```

---

## 6. 명령어 한눈에

```bash
# 첫 1회: 플랫폼 폴더 스캐폴딩
flutter create . --project-name sharework_mockup --org kr.sharework --platforms=android,ios

# 의존성
flutter pub get

# Android 릴리스 빌드 (Play Store용)
flutter build appbundle --release

# Android APK (사내 배포용, Play Store 업로드 X)
flutter build apk --release

# iOS 릴리스 빌드 (App Store용, macOS 필요)
flutter build ipa --release
```

---

## 7. CI/CD 우회 옵션

| 도구 | 특징 |
|---|---|
| **Codemagic** | Flutter 전용. macOS 빌드 머신 제공 → macOS 없이 iOS 배포 가능. 무료 500분/월. |
| **GitHub Actions** | `macos-latest` 러너로 iOS 빌드. 공개 저장소 무료. Fastlane 조합이 일반적. |
| **Fastlane** | 서명·업로드·스크린샷 자동화. `fastlane match` 로 인증서 팀 공유. |

각 도구 모두 "Git push → 자동 빌드 → TestFlight·Play 내부 테스트 자동 업로드" 파이프라인을 표준 패턴으로 제공합니다.

---

## 참고

- Flutter 공식 배포 가이드: <https://docs.flutter.dev/deployment/android>, <https://docs.flutter.dev/deployment/ios>
- Google Play Console: <https://play.google.com/console>
- App Store Connect: <https://appstoreconnect.apple.com>
