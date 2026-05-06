# Sharework TestFlight 업로드 가이드

본 문서는 Sharework iOS UI Demo MVP를 TestFlight 내부 테스트에 배포하는 전체 절차를 단계별로 정리한다. 이 가이드를 처음부터 끝까지 따라가면 다른 사람의 iPhone에 베타 빌드를 배포할 수 있다.

## 사전 조건

- macOS + 최신 Xcode 설치 완료
- Flutter SDK + CocoaPods 설치 완료
- 본 저장소가 로컬에 클론되어 있고 `flutter pub get`이 정상 동작
- 현재 환경 보정 상태:
  - iOS deployment target 14.0 (Podfile + project.pbxproj 통일)
  - Bundle ID: `kr.sharework.app`
  - 앱 버전: `0.1.0+1`
  - DEVELOPMENT_TEAM: 미설정 (Step 3에서 발급 + Xcode 자동 서명)
  - Info.plist 권한 사용 설명 미설정 (UI Demo MVP 범위 — 의도된 상태)

## Step 1. Apple Developer Program 가입

- 가입 URL: https://developer.apple.com/programs/
- 비용: $99/yr (2026년 5월 기준)
- 승인 소요: 보통 24~48시간 (개인 가입 기준, 결제 검토 + 신원 확인)
- 결제 완료 후 Apple ID에 Team이 발급됨 → 이때부터 Team ID 확인 가능 (https://developer.apple.com/account 접속 후 "Membership" 탭)
- **개인 vs 조직**: 개인 가입은 빠름. 조직 가입은 D-U-N-S 번호 필요(추가 1~2주). 본 MVP는 개인 가입 권장.

## Step 2. App Store Connect 앱 레코드 생성

가입 + Team 발급 완료 후:

1. https://appstoreconnect.apple.com 접속
2. "내 앱" > "+" > "신규 앱" 클릭
3. 다음 정보 입력:
   - **플랫폼**: iOS
   - **이름**: `Sharework`
   - **기본 언어**: 한국어
   - **Bundle ID**: `kr.sharework.app` 선택 (목록에 없으면 https://developer.apple.com/account/resources/identifiers 에서 먼저 등록)
   - **SKU**: 임의 식별자 (예: `sharework-ios-001`)
   - **사용자 액세스**: 전체 액세스 또는 제한 (본인만 사용 시 전체)
4. "생성" 클릭

## Step 3. Xcode 계정 + Team 설정

1. Xcode 실행 > Settings (⌘,) > Accounts 탭
2. 좌측 하단 "+" > "Apple ID" > 본인 Apple ID 로그인
3. 로그인 완료 후 "Team" 컬럼에 Step 1에서 발급받은 Team이 보이는지 확인
4. `ios/Runner.xcworkspace` 열기 (Xcode에서 File > Open)
5. 좌측 프로젝트 네비게이터에서 `Runner` 선택 > 우측 패널 "Signing & Capabilities" 탭
6. "Automatically manage signing" 체크되어 있는지 확인
7. "Team" 드롭다운에서 발급받은 Team 선택 → `project.pbxproj`의 `DEVELOPMENT_TEAM` 자동 채워짐

## Step 4. 사전 검증

빌드 직전 다음 명령으로 환경 정합 확인:

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
- `flutter test` — 모든 테스트 통과
- `flutter analyze --no-fatal-infos` — error/warning 0개 (info는 README상 허용)
- `flutter build ios --release --no-codesign` — 성공

## Step 5. Archive

1. Xcode에서 `ios/Runner.xcworkspace` 열기 (워크스페이스 ≠ 프로젝트, 반드시 .xcworkspace 사용)
2. 상단 scheme 선택기에서 `Runner` 확인
3. Destination을 **"Any iOS Device (arm64)"** 로 선택 (시뮬레이터 destination 금지)
4. 메뉴 `Product > Archive`
5. 빌드 진행 (수 분 소요) → 완료 시 자동으로 Organizer 창이 열림
6. Organizer의 "Archives" 탭에 방금 만든 archive가 보이는지 확인 (Sharework + 날짜 + 버전 0.1.0)

## Step 6. Validate + Upload

Organizer 창에서:

1. 방금 만든 archive 선택 > 우측 "Validate App" 클릭
2. 옵션: "Upload your app's symbols..." 체크 (크래시 리포트 디버깅용)
3. "Validate" 진행 → 모든 검증 통과 확인 (실패 시 메시지를 그대로 캡처해 troubleshoot)
4. 검증 통과 후 "Distribute App" > "App Store Connect" > "Upload" 선택
5. "Strip Swift symbols", "Upload your app's symbols", "Manage Version and Build Number" 옵션 기본값 유지
6. Apple ID 로그인 + 업로드 진행 (수 분~수십 분 소요, 네트워크 속도 의존)
7. 업로드 완료 메시지 확인

업로드 후 ASC가 빌드를 처리하기까지 5~30분 추가 대기 (메일로 처리 결과 통보).

## Step 7. TestFlight 베타 앱 정보 입력

빌드 처리 완료 후 https://appstoreconnect.apple.com > 내 앱 > Sharework > "TestFlight" 탭:

1. "iOS" 빌드 목록에서 방금 업로드한 0.1.0 (1) 빌드 선택
2. 베타 앱 설명에 다음 템플릿 입력:

> Sharework는 주변 단기 일자리 매칭을 보여주는 UI Demo MVP입니다. 본 베타 빌드는 실제 API/SMS 인증/결제/지도 SDK가 포함되지 않은 더미 데이터 기반 화면 흐름 시연용입니다. 위치/알림/카메라/갤러리 권한은 향후 도입 예정인 흐름의 사전 동의 화면을 보여주는 용도이며, 현재 빌드에서는 실제 권한 호출이 발생하지 않습니다.

3. 개인정보 처리방침 URL: 없으면 "더미 데이터 기반이라 개인정보 수집 없음" 라인 입력 또는 임시 페이지 URL
4. 베타 앱 검토 정보(연락처, 데모 계정) 입력 — 외부 테스트 시에만 필요. 내부 테스트만 한다면 스킵 가능
5. 수출 규정 준수 여부 확인 (암호화 미사용 — 더미 데이터 MVP)

## Step 8. 내부 테스터 그룹 + 초대

내부 테스트 그룹은 Apple App Review 없이 즉시 배포 가능 (최대 100명).

1. ASC > Sharework > TestFlight > 좌측 "내부 테스트" 그룹 또는 "+" 로 신규 그룹 생성 (예: "Sharework Internal")
2. 그룹 > "테스터" 탭 > "+" > 이메일로 초대 (테스터는 ASC에 사용자로 먼저 등록되어 있어야 함 — Users and Access 메뉴에서)
3. 그룹 > "빌드" 탭 > "+" > 0.1.0 (1) 빌드 추가
4. 빌드 추가 완료 시 테스터에게 자동으로 초대 메일 발송
5. 테스터는 메일 링크로 TestFlight 앱을 통해 Sharework 베타 설치 가능

## 사전 체크리스트 (업로드 전 확인)

- [ ] Apple Developer Program 가입 완료 + Team ID 발급
- [ ] App Store Connect에 Sharework 앱 레코드 등록 (Bundle ID `kr.sharework.app` 일치)
- [ ] Xcode > Settings > Accounts에 Apple ID 추가 + Team 보임
- [ ] Xcode Runner 타깃 Signing에 Team 선택됨 (project.pbxproj `DEVELOPMENT_TEAM` 채워짐)
- [ ] Bundle ID `kr.sharework.app`이 ASC 앱 레코드의 Bundle ID와 정확히 일치
- [ ] iOS deployment target 14.0 (Podfile + project.pbxproj 3곳 일치)
- [ ] AppIcon 1024x1024 마케팅 아이콘이 Assets.xcassets에 포함됨 (이미 완비)
- [ ] LaunchScreen.storyboard 정상 (이미 완비)
- [ ] `flutter test` 통과
- [ ] `flutter analyze --no-fatal-infos` warning/error 0
- [ ] `flutter build ios --release --no-codesign` 통과

## 빌드 번호 관리

`pubspec.yaml`의 `version: 0.1.0+1` 형식은 `<버전>+<빌드 번호>`. ASC는 동일 빌드 번호 재업로드를 거부한다.

- 첫 archive: `0.1.0+1` 그대로 OK
- 같은 0.1.0에 대해 재업로드 필요 시: `0.1.0+2`, `0.1.0+3` 으로 빌드 번호만 bump
- 새 버전 출시: `0.2.0+1` 처럼 버전 + 빌드 번호 모두 새로 시작

## 자주 발생하는 문제

| 증상 | 원인 | 해결 |
|------|------|------|
| `pod install` 시 deployment target mismatch | Podfile과 pbxproj 불일치 | 둘 다 14.0인지 grep 재확인 |
| Validate App 시 "No accounts with iTunes Connect access" | Xcode에 Apple ID 미등록 | Step 3 재확인 |
| Validate App 시 "Bundle ID mismatch" | ASC 앱 레코드 Bundle ID와 Xcode Bundle ID 불일치 | ASC와 `project.pbxproj` 모두 `kr.sharework.app`인지 확인 |
| Upload 시 "Build number already exists" | 같은 빌드 번호 재업로드 | `pubspec.yaml`에서 빌드 번호 bump |
| TestFlight에서 "처리 중" 상태가 1시간 넘게 지속 | ASC 처리 지연 (가끔 발생) | 메일 통보 대기, 24시간 후에도 진행 없으면 Apple Support |

## 참고

- Apple Developer 공식 문서: https://developer.apple.com/distribute/
- TestFlight 공식 가이드: https://developer.apple.com/testflight/
- App Store Connect 도움말: https://help.apple.com/app-store-connect/
