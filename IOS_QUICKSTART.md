# iOS 빠른 실행 가이드 — 무료 Apple ID + 실 iPhone

**대상**: 유료 Apple Developer 계정($99/년) 없이, macOS + Xcode + 본인 iPhone 만으로 Sharework 목업을 실 디바이스에서 돌려보고 싶은 경우.

**제약**:
- 앱이 **7일** 후 만료 → Xcode 에서 재실행하면 자동 갱신
- 1 Apple ID 당 동시 설치 **3개** 까지
- 실 디바이스에서만 가능 (시뮬레이터로 실행하려면 Apple ID 도 불필요 — `flutter run -d <simulator>` 만 하면 됨)

---

## 사전 준비 (1회)

| 항목 | 확인 명령 / 방법 |
|---|---|
| macOS 13(Ventura)+ | `sw_vers` |
| Xcode 15+ (App Store 최신) | `xcodebuild -version` |
| Xcode Command Line Tools | `xcode-select --install` |
| Flutter SDK 3.27+ | `flutter --version` |
| CocoaPods | `sudo gem install cocoapods` 또는 `brew install cocoapods` |
| 본인 Apple ID (App Store 로그인용 그대로 OK, 무료) | — |
| iPhone + Lightning/USB-C 케이블 | — |
| `flutter doctor` 모두 ✓ | `flutter doctor` |

---

## Step 1 — iOS 플랫폼 폴더 생성 (저장소 처음 1회)

```bash
cd /path/to/sharework

# android 와 ios 동시 생성. 이미 했다면 건너뛰기.
flutter create . \
  --project-name sharework_mockup \
  --org kr.sharework \
  --platforms=android,ios

cd ios && pod install && cd ..
```

> 💡 M1/M2/M3 Mac 에서 `pod install` 실패 시: `cd ios && arch -x86_64 pod install`

---

## Step 2 — Xcode 서명 설정

```bash
open ios/Runner.xcworkspace
```

> ⚠️ `Runner.xcodeproj` 가 아니라 **`.xcworkspace`** 를 열어야 합니다 (CocoaPods 통합 때문).

Xcode 좌측 트리에서:

1. **Runner** (파란 아이콘, 최상단) 클릭
2. 가운데 패널 상단 **Signing & Capabilities** 탭
3. **Team** 드롭다운 → **Add an Account...** → 본인 Apple ID 로그인
4. 로그인 후 Team 드롭다운에 `<본인이름> (Personal Team)` 표시 → 선택
5. **Bundle Identifier** 변경:
   - 기본값 `kr.sharework.shareworkMockup` 은 **이미 다른 사람이 등록했을 확률이 높아 거부**됩니다
   - 본인만의 고유값으로 바꾸기. 예시: `kr.sharework.shareworkMockup.{본인영문이니셜}{4자리숫자}`
   - 좋은 패턴: `kr.sharework.shareworkMockup.kim8421`
6. **Automatically manage signing** 체크박스 ON 유지 → 인증서·Provisioning Profile 자동 생성
7. 빨간 에러 메시지 사라질 때까지 1~10초 대기

> 🔧 "Failed to register bundle identifier" 에러가 계속 뜨면 Bundle ID 끝부분 숫자를 다른 값으로 바꿔서 재시도. 무료 Apple ID 는 같은 ID 가 이미 다른 사람이 사용 중이면 거부됩니다.

---

## Step 3 — iPhone 준비

### 3-A. Mac에 처음 연결할 때

1. iPhone 을 USB 로 Mac 에 연결
2. iPhone 화면 잠금 해제 → **"이 컴퓨터를 신뢰하시겠습니까?"** → **신뢰**
3. Mac 의 Finder 좌측 사이드바에 iPhone 아이콘 등장 확인

### 3-B. iOS 16+ 개발자 모드 켜기 (1회)

iOS 16 이상에서는 명시적으로 켜야 합니다.

1. iPhone → **설정 → 개인정보 보호 및 보안**
2. 맨 아래 **개발자 모드** → **켜기** → 재부팅
3. 재부팅 후 잠금 해제 시 한 번 더 확인 팝업 → **켜기**

> 📌 **개발자 모드** 메뉴가 안 보이면, 한 번 Mac 에서 iPhone 으로 앱을 빌드 시도해야 메뉴가 나타납니다 (Step 4 한 번 실행 후 다시 설정으로).

---

## Step 4 — 빌드 & 설치

### 4-A. Xcode 에서 실행 (가장 안정적)

1. Xcode 상단 중앙의 디바이스 선택 메뉴에서 본인 iPhone 이름 선택
2. 좌측 상단 ▶︎ (Run) 버튼 → 빌드 시작 (첫 빌드 약 3~10분, 이후 1~2분)
3. **첫 실행 시** "Could not launch... Untrusted Developer" 에러 → 정상. Step 4-C 진행

### 4-B. 또는 Flutter CLI 에서

Xcode 서명 설정이 끝났다면 터미널에서도 가능:
```bash
flutter devices                           # 연결된 iPhone 확인
flutter run -d <device-id>                # 또는 -d 빼고 자동 선택
```

### 4-C. iPhone 에서 개발자 신뢰 (Apple ID 별 1회)

첫 빌드 후 iPhone 에서:

1. **설정 → 일반 → VPN 및 기기 관리** (또는 일부 버전: **프로파일 및 기기 관리**)
2. **개발자 앱** 섹션에 본인 Apple ID 표시 → 탭
3. **"<Apple ID> 신뢰"** → 다시 **신뢰**
4. Xcode 로 돌아가서 ▶︎ Run 다시 → 이번엔 정상 설치·실행

---

## Step 5 — 일상 사용

코드 변경 후:

```bash
flutter run -d <device-id>   # 핫 리로드 자동 활성화
# r: 핫 리로드  R: 핫 리스타트  q: 종료
```

또는 Xcode 에서 ▶︎ Run.

**7일 만료 시**: 앱 아이콘 탭하면 "이 앱을 더 이상 사용할 수 없습니다" → Xcode 에서 한 번 더 ▶︎ Run 하면 갱신됨.

---

## 자주 막히는 곳

| 증상 | 해결 |
|---|---|
| `pod install` 이 한참 멈춤 / `CDN: trunk URL couldn't be downloaded` | `pod repo update` 후 재시도. M-series Mac 은 `arch -x86_64 pod install` |
| Xcode: `No signing certificate "iOS Development" found` | Team 미설정. Step 2-3 다시 확인 |
| Xcode: `Failed to register bundle identifier` | Bundle ID 가 다른 사람과 충돌. Step 2-5 처럼 끝에 본인 식별자 추가 |
| iPhone: `Could not launch ... Security` 또는 `Untrusted Developer` | Step 4-C 의 개발자 신뢰 안 함 |
| Xcode: `iOS Deployment Target ... is below ... required` | `ios/Podfile` 첫 줄 `platform :ios, '12.0'` 주석 해제 + 값 `13.0` 으로 상향 → `cd ios && pod install` |
| `flutter run` 에서 디바이스 안 보임 | iPhone 잠금 해제 + Mac 신뢰 + USB 케이블 데이터 라인 지원 (충전전용 케이블이면 안 됨) |
| 빌드 성공인데 앱이 7일 전 만료 | Xcode 에서 다시 ▶︎ Run 하면 자동 재서명·재설치 |
| Xcode 빌드 매우 느림 (15분+) | Xcode → Settings → Locations → Derived Data → Delete (캐시 초기화). M1/M2 Mac 은 Rosetta 모드 끄기 |

---

## 참고

- 시뮬레이터로만 충분하면 Step 2 의 Apple ID·Team 설정 자체가 불필요 (서명 없이 동작). `flutter emulators --launch apple_ios_simulator` 후 `flutter run`.
- 공식 출시(TestFlight·App Store)로 가려면 Apple Developer Program($99/년) 가입 후 [`INTERNAL_TEST.md`](./INTERNAL_TEST.md) Step 2 진행.
- 실 디바이스에서만 발생하는 권한·카메라·GPS 동작 검증이 끝나면, 키스토어 생성과 Play Console 등록 등 정식 출시 사전 작업으로 넘어갈 수 있습니다.
