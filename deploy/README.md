# Sharework — iOS + Android 동시 배포 가이드

GitHub Actions(`A`) + Fastlane(`B`) 조합으로 태그 푸시 1번에 양 스토어 동시 업로드.

```
git tag v0.1.0 && git push origin v0.1.0
   │
   ├─► ubuntu-latest  : flutter build appbundle  ──► fastlane android deploy_internal  ──► Play Console (internal)
   └─► macos-14       : flutter build ipa        ──► fastlane ios beta                 ──► TestFlight
```

수동 트리거(`workflow_dispatch`)에선 트랙(`internal`/`beta`/`production`)과 iOS 레인(`beta`/`release`)을 골라서 실행 가능.

---

## 0. 사전 준비 (1회)

목업 단계라 `android/`, `ios/` 가 git 에 없습니다. CI 가 매번 `flutter create` 로 생성합니다. **단, 정식 배포 전 아래는 사람이 직접 한 번씩 해 줘야** 합니다.

### Apple

1. App Store Connect 에 앱 ID `kr.sharework.sharework-mockup` 로 새 앱 등록.
2. Apple Developer Portal 에서 **Distribution Certificate(.p12)** 발급, **Provisioning Profile (App Store)** 생성.
3. App Store Connect → Users and Access → **API Keys** 에서 발급(.p8). Issuer ID, Key ID 메모.
4. **첫 빌드는 Xcode 에서 수동 업로드** — App Store Connect 가 빌드를 받아본 적 없으면 fastlane 업로드가 거부됩니다.

### Google

1. Play Console 에 앱 등록(패키지명 `kr.sharework.sharework_mockup`). **첫 AAB 는 수동 업로드** (내부 테스트 트랙).
2. Google Cloud Console → Service Accounts → JSON 키 발급 → Play Console 에서 권한 위임.
3. Android 업로드 키스토어 생성:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

---

## 1. GitHub Secrets

저장소 → Settings → Secrets and variables → Actions 에 등록.

### Android (5개)

| Secret | 내용 |
|---|---|
| `GOOGLE_PLAY_JSON_KEY` | Play Console 서비스 계정 JSON 전체 내용 |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks` 결과 |
| `ANDROID_KEYSTORE_PASSWORD` | 키스토어 비번 |
| `ANDROID_KEY_PASSWORD` | 키 비번 |
| `ANDROID_KEY_ALIAS` | `upload` (또는 본인이 만든 alias) |

### iOS (9개)

| Secret | 내용 |
|---|---|
| `APPLE_ID` | Apple 계정 이메일 |
| `APPLE_TEAM_ID` | Developer Portal Team ID (10자) |
| `APPLE_ITC_TEAM_ID` | App Store Connect Team ID (숫자) |
| `APP_STORE_CONNECT_KEY_ID` | API 키 ID (10자) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (UUID) |
| `APP_STORE_CONNECT_KEY_CONTENT` | `.p8` 파일을 `base64 -i AuthKey.p8` 한 결과 |
| `IOS_DIST_CERT_P12_BASE64` | `base64 -i dist_cert.p12` 결과 |
| `IOS_DIST_CERT_PASSWORD` | .p12 export 시 설정한 비번 |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i profile.mobileprovision` 결과 |
| `IOS_PROVISIONING_PROFILE_NAME` | 프로비저닝 프로파일 이름 (예: `Sharework App Store`) |

> macOS 에서 `base64 -i` 는 줄바꿈을 넣습니다. 시크릿에 그대로 붙여 넣어도 GitHub 가 처리합니다. 의심되면 `base64 -i file | tr -d '\n'`.

---

## 2. 트리거

### 자동 (태그 푸시)

```bash
# pubspec.yaml 의 version 라인은 CI 가 태그값으로 덮어씁니다
git tag v0.1.0
git push origin v0.1.0
```

→ Android 는 **internal** 트랙, iOS 는 **TestFlight** 로 동시 업로드.

### 수동

GitHub → Actions → "Release — iOS + Android" → **Run workflow** → 트랙/레인 선택.

```
android_track: internal | beta | production
ios_lane:      beta     | release
```

---

## 3. 버전 관리

- `pubspec.yaml` 의 `version: 0.1.0+1` 한 줄을 양 플랫폼이 공유.
- 태그 푸시 시 CI 가 자동으로 `version: <태그>+<github.run_number>` 로 덮어씀 (커밋되지 않고 빌드 중에만).
- 수동 디스패치 시엔 pubspec 의 값을 그대로 사용. 매번 직접 올리는 게 안전.

---

## 4. 디렉토리 구조

```
deploy/
├─ Gemfile                   # fastlane + cocoapods
├─ scripts/
│  └─ patch_android_gradle.py  # CI 가 build.gradle 에 release signing 블록 주입
├─ android/
│  ├─ Fastfile               # lanes: deploy_internal / deploy_beta / deploy_production
│  └─ Appfile                # package_name + json_key_file
├─ ios/
│  ├─ Fastfile               # lanes: beta (TestFlight) / release (App Store)
│  ├─ Appfile                # app_identifier + apple/team id
│  └─ ExportOptions.plist    # app-store + manual signing
└─ README.md                 # (이 문서)

.github/workflows/release.yml  # 트리거 + 병렬 잡 + 시크릿 주입
```

CI 는 `flutter create` 후 위 fastlane 파일을 `android/fastlane/`, `ios/fastlane/` 로 복사해서 사용합니다.

---

## 5. 트러블슈팅

| 증상 | 원인/해결 |
|---|---|
| `Authentication failed` (Play Console) | 서비스 계정에 Play Console 권한 미위임. Play Console → Users and Permissions → Invite users |
| `No suitable application records were found` | App Store Connect 에 앱 첫 등록 안 됐거나, 처음 fastlane 만으로 업로드 시도 — Xcode 로 1회 수동 업로드 |
| `Code signing error` | Provisioning profile 의 Bundle ID 가 `kr.sharework.sharework-mockup` 와 불일치 |
| iOS 빌드만 30분+ | macOS 러너는 가용량 적음, `concurrency` 그룹으로 중복 트리거 방지 권장 |
| Android `keytool` 알 수 없음 | `actions/setup-java@v4` 잡 안에서만 사용 가능 |

---

## 6. 안전 장치

- 양 lane 모두 **`release_status: draft` / `submit_for_review: false`** — CI 는 업로드만 하고, 실제 출시(rollout)는 사람이 콘솔에서 누름.
- 프로덕션 트랙 rollout 은 `0.1` (10%) — 단계적 롤아웃 기본값.
- iOS `release` 레인도 자동 제출 안 함 (`submit_for_review: false`).

문제 생기면 콘솔에서 draft/build 삭제하면 끝, 사용자에게 영향 없음.
