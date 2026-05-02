# 내부 테스트 배포 런북

이 문서는 **Sharework 목업을 Google Play 내부 테스트 트랙·Apple TestFlight 에 올리기 위한 단계별 명령서**입니다. 정식 출시(프로덕션 트랙) 절차는 [`DEPLOYMENT.md`](./DEPLOYMENT.md) 참고.

> ⚠️ 이 저장소는 README에 명시된 대로 **UI-only 목업**입니다. 내부 테스트(자체 팀 시연)는 가능하지만, 외부 공개 출시는 백엔드 연동·심사 가이드 충족 이후에 진행하세요.

---

## 사전 체크

| 항목 | 확인 |
|---|---|
| Flutter SDK 3.27+ 설치 (`flutter --version`) | □ |
| Android Studio + Android SDK 설치 | □ |
| **iOS 빌드용 macOS + Xcode** (필요 시) | □ |
| Apple Developer Program 등록 ($99/년) | □ (iOS만) |
| Google Play Console 등록 ($25 1회) | □ (Android만) |
| App Store Connect에 앱 미리 생성 (Bundle ID 예약) | □ (iOS만) |
| Play Console에 앱 미리 생성 (Application ID 예약) | □ (Android만) |

---

## Step 0 — 플랫폼 폴더 스캐폴딩 (1회만)

```bash
# 저장소 루트에서
flutter create . \
  --project-name sharework_mockup \
  --org kr.sharework \
  --platforms=android,ios

flutter pub get
```

생성되는 식별자 (수정 가능, 단 **출시 후엔 변경 불가**):

- Android `applicationId` = `kr.sharework.sharework_mockup`
- iOS `Bundle Identifier` = `kr.sharework.shareworkMockup`

> 🔧 식별자를 바꾸려면: `android/app/build.gradle` 의 `applicationId`, Xcode (`open ios/Runner.xcworkspace`) 의 General → Bundle Identifier 를 동시에 수정.

빌드 동작 확인:
```bash
flutter run            # 디버그
flutter analyze        # 린트
```

---

## Step 1 — Android 내부 테스트 배포

### 1-A. 업로드 키스토어 생성 (1회, 영구 보관)

```bash
keytool -genkey -v \
  -keystore ~/sharework-upload.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

> 🔐 **`sharework-upload.jks` 파일 + 비밀번호는 절대 분실 금지.** 분실 시 동일 앱 업데이트가 영구 불가능합니다. 1Password·iCloud 등 안전한 곳에 백업.

### 1-B. 서명 설정 파일 작성

`android/key.properties` 생성 (이 파일은 `.gitignore` 에 이미 등록돼 있음):

```properties
storePassword=<키스토어 비밀번호>
keyPassword=<키 비밀번호>
keyAlias=upload
storeFile=/Users/<사용자>/sharework-upload.jks
```

템플릿: [`deploy/android/key.properties.template`](./deploy/android/key.properties.template)

### 1-C. `android/app/build.gradle` 에 서명 설정 추가

[`deploy/android/signing-snippet.gradle`](./deploy/android/signing-snippet.gradle) 의 내용을 그대로 붙여넣기. 핵심:

- `android` 블록 위에 `key.properties` 로드
- `signingConfigs.release` 추가
- `buildTypes.release.signingConfig = signingConfigs.release` 로 교체

### 1-D. 버전 올리기

`pubspec.yaml`:
```yaml
version: 1.0.0+1   # 표시버전 + 빌드번호. 매 업로드마다 빌드번호 +1
```

### 1-E. AAB 빌드

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### 1-F. Play Console 업로드

1. <https://play.google.com/console> → 앱 선택
2. **테스트 → 내부 테스트** 메뉴
3. **새 버전 만들기** → `app-release.aab` 드래그 업로드
4. 출시 노트(한국어 1줄 가능) 입력 → **저장 → 검토 → 출시**
5. **테스터 → 이메일 목록 만들기** → 팀원 Gmail 등록
6. 공유받은 옵트인 URL 을 테스터에게 전달 → 약 5~10분 후 Play 스토어에서 설치 가능

> 📌 첫 빌드 업로드 시 Play의 자동 검수가 1~24시간 걸릴 수 있습니다. 이후 업로드는 즉시 반영.

---

## Step 2 — iOS TestFlight 배포 (macOS 필수)

### 2-A. CocoaPods 설치 (1회)

```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
```

### 2-B. Xcode 서명 설정

```bash
open ios/Runner.xcworkspace
```

Xcode에서:
1. 좌측 트리 **Runner** 선택 → **Signing & Capabilities** 탭
2. **Team** 드롭다운에서 본인 Apple Developer 팀 선택
3. **Automatically manage signing** 체크 → 인증서·Provisioning Profile 자동 생성
4. **Bundle Identifier** 가 App Store Connect에 등록한 값과 일치하는지 확인

### 2-C. App Store Connect 준비

1. <https://appstoreconnect.apple.com> → **나의 앱 → +** → 새 앱 생성
2. Bundle ID, SKU(아무 문자열), 기본 언어(한국어) 입력
3. (TestFlight는 스토어 메타데이터 없이도 가능 — 정식 출시 시점에 입력)

### 2-D. IPA 빌드 & 업로드

```bash
flutter build ipa --release
# → build/ios/ipa/sharework_mockup.ipa
```

업로드 방법 두 가지 (둘 중 하나):

**A. Transporter 앱** (권장, Mac App Store 무료):
- 앱 실행 → IPA 드래그 → **Deliver**

**B. Xcode Organizer**:
- Xcode → **Product → Archive**
- Organizer 창에서 **Distribute App → App Store Connect → Upload**

### 2-E. TestFlight 테스터 초대

업로드 후 약 10~30분 → App Store Connect → **TestFlight** 탭에 빌드 노출.

1. 빌드 클릭 → **수출 규정 준수** 질문 답변(보통 "아니오" 선택, 표준 암호화만 사용)
2. **내부 테스터** 그룹 → 팀원 Apple ID 추가 (즉시, 최대 100명)
3. 또는 **외부 테스터** 그룹 → Apple TestFlight 베타 검토(보통 1일 내 통과, 최대 1만명)
4. 테스터는 TestFlight 앱(앱스토어에서 무료) 으로 설치

---

## Step 3 — 다음 빌드부터의 짧은 사이클

```bash
# 1) 버전 올리기 (pubspec.yaml 의 +N 부분만 +1 해도 됨)
# 2) 빌드
flutter build appbundle --release    # Android
flutter build ipa --release          # iOS

# 3) 업로드
#    - Android: Play Console 내부 테스트 → 새 버전 만들기 → AAB 드래그
#    - iOS:    Transporter 로 IPA 전송 → TestFlight 자동 노출
```

---

## 자주 막히는 곳

| 증상 | 원인·해결 |
|---|---|
| Play Console: "이미 사용된 버전 코드입니다" | `pubspec.yaml` 의 `+N` 빌드번호 안 올림 → 증가시키기 |
| Play Console: "서명 키가 일치하지 않습니다" | 다른 키스토어로 빌드함 → Step 1-A 의 키스토어 사용 확인 |
| Xcode: "No signing certificate iOS Distribution" | Apple Developer 계정 활성 상태 확인, Xcode → Settings → Accounts 재로그인 |
| TestFlight 빌드 안 보임 | 업로드 후 10~30분 처리 대기. 메일에 "Invalid Binary" 오면 수정 후 재업로드 |
| `flutter build ipa` 실패 (Linux/Windows) | iOS 빌드는 macOS 전용. Codemagic 같은 클라우드 CI 또는 macOS 머신 필요 |
| CocoaPods "No such module" | `cd ios && pod install` 재실행. M1/M2 Mac은 `arch -x86_64 pod install` 시도 |

---

## 정식 출시 전 추가 필요 작업

내부 테스트 통과 후 프로덕션 트랙에 올리려면 [`DEPLOYMENT.md`](./DEPLOYMENT.md) 의 추가 항목을 충족해야 합니다:

- 백엔드 API 연동 (목업 → 실 데이터)
- 앱 아이콘·스플래시(`flutter_launcher_icons`, `flutter_native_splash`)
- 스토어용 스크린샷 (Android: 폰 1080×1920 2~8장 / iOS: 6.7인치 + 6.5인치 시뮬레이터 캡처)
- 앱 설명·키워드·카테고리
- 개인정보 처리방침 외부 호스팅 URL
- iOS Info.plist 권한 사용 사유 문구
- 콘텐츠 등급 설문 (Play) / Age Rating (App Store)
