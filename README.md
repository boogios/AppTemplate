# Boogios App Templates

Boogios 스타일의 네이티브 iOS·Android 앱을 빠르게 시작하기 위한 공통
템플릿 저장소입니다. 두 플랫폼은 각각 독립적으로 빌드되지만, 온보딩·설정·
프리미엄·광고·분석·다국어·리뷰 요청의 기본 제품 경험은 최대한 대응되도록
구성되어 있습니다.

## 이 저장소를 처음 보는 분께

이 저장소는 완성된 하나의 앱이 아니라, 새로운 앱을 만들 때 반복해서 쓰는
출발점입니다. 이미 홈 화면, 설정 화면, 온보딩, 다국어, 구독 화면, 광고와
분석 SDK 연결 자리, 테스트 구조가 들어 있습니다. 따라서 새 앱을 만들 때마다
로그인·테마·설정·권한 화면을 처음부터 다시 만들 필요가 없습니다.

다만 이 템플릿만 복사한다고 바로 출시할 수 있는 것은 아닙니다. 앱 이름,
아이콘, Bundle ID 또는 Application ID, 개인정보 처리방침 URL, 광고·분석 키,
스토어 상품 ID처럼 앱마다 달라지는 값을 먼저 바꿔야 합니다. 실제 서비스
기능과 스토어 심사 정보도 제품별로 추가해야 합니다.

### 먼저 알아두면 좋은 단어

| 단어 | 쉬운 설명 |
| --- | --- |
| 템플릿 | 새 앱을 시작할 때 복사해서 쓰는 기본 프로젝트 |
| Bundle ID | iOS에서 앱을 구별하는 고유 주소 |
| Application ID | Android에서 앱을 구별하는 고유 주소 |
| XcodeGen | iOS 설정 파일로 Xcode 프로젝트를 다시 만드는 도구 |
| Compose | Android 화면을 Kotlin 코드로 작성하는 UI 방식 |
| placeholder | 아직 실제 값을 넣지 않은 예시 값 |
| StoreKit / Play Billing | 각각 Apple·Google의 결제 기능 |
| UMP | 광고를 보여주기 전 개인정보 동의를 처리하는 Google 도구 |
| smoke test | 앱의 가장 중요한 화면 이동이 작동하는지 빠르게 확인하는 테스트 |

## 초보자용 시작 순서

1. 아래의 `ios` 또는 `android` 중 만들 플랫폼 하나를 선택합니다.
2. 해당 폴더의 README를 처음부터 읽습니다.
3. 예제 설정 파일을 복사하고 앱별 기본 정보를 입력합니다.
4. 앱을 먼저 빌드해서 템플릿이 정상 실행되는지 확인합니다.
5. 홈 화면이나 기능을 바꾸기 전에 설정·온보딩·다국어 구조를 유지합니다.

처음부터 광고, 결제, 로그인 키를 넣을 필요는 없습니다. placeholder 상태로
앱을 실행한 뒤 화면 구조를 이해하고, 실제 서비스 준비가 끝났을 때 키를
추가하는 것이 안전합니다.

## 가장 쉬운 확인 방법

### iOS만 확인하기

```sh
git clone https://github.com/boogios/AppTemplate.git
cd AppTemplate/ios
cp Configs/AppSecrets.xcconfig.example Configs/AppSecrets.xcconfig
xcodegen generate
open AppTemplate.xcodeproj
```

Xcode가 열리면 `AppTemplate` 스킴과 iPhone Simulator를 선택한 뒤 실행 버튼을
누릅니다. 처음 실행하면 온보딩이 나오고, 닉네임을 입력하면 홈 화면으로
이동합니다.

### Android만 확인하기

```sh
cd AppTemplate/android
cp local.properties.example local.properties
```

그다음 `local.properties`의 `sdk.dir`을 본인 컴퓨터의 Android SDK 위치로
바꾸고 Android Studio에서 `android` 폴더를 엽니다. 에뮬레이터를 실행한 뒤
Run 버튼을 누르거나 다음 명령을 사용합니다.

```sh
./gradlew :app:assembleDebug --console=plain
```

## 새 앱을 만들 때의 추천 순서

앱 이름과 식별자를 정한 뒤 저장소 루트에서 생성기를 실행합니다.

```sh
./scripts/new-ios-app.sh MyNewApp com.example.mynewapp "My New App" Utilities
./scripts/new-android-app.sh MyNewApp com.example.mynewapp "My New App"
```

생성된 앱은 기본적으로 이 저장소의 형제 폴더에 만들어집니다. 다른 위치에
만들고 싶으면 `BOOGIOS_WORKSPACE_DIR` 환경 변수를 지정할 수 있습니다. iOS
생성에는 XcodeGen이 필요하고, Android 생성에는 Android SDK와 JDK가 필요합니다.

## 문제가 생겼을 때 먼저 확인할 것

- `SDK location not found`: Android `local.properties`의 `sdk.dir` 확인
- iOS `base configuration` 오류: `Configs/AppSecrets.xcconfig` 생성 여부 확인
- 광고가 안 보임: 정상일 수 있습니다. 실제 AdMob ID와 UMP 동의가 필요합니다.
- 결제 상품이 안 보임: App Store Connect 또는 Play Console 상품 등록 전에는
  준비 중 화면이 표시됩니다.
- 화면 문구가 이상함: 코드가 아니라 해당 플랫폼의 `strings.xml` 또는
  `*L10n.swift`를 수정해야 합니다.
- Xcode 프로젝트가 오래된 것 같음: iOS `project.yml` 수정 후
  `xcodegen generate`를 다시 실행합니다.

## 저장소 구조

```text
.
├── ios/                  # SwiftUI + XcodeGen iOS 템플릿
├── android/              # Kotlin + Jetpack Compose Android 템플릿
├── scripts/
│   ├── new-ios-app.sh    # iOS 새 앱 생성기
│   └── new-android-app.sh # Android 새 앱 생성기
└── README.md
```

각 플랫폼 폴더는 독립 프로젝트입니다. 플랫폼별 상세 구조와 실행 방법은
[iOS README](ios/README.md)와 [Android README](android/README.md)를 확인하세요.
화면 디자인 규칙은 각 폴더의 `DESIGN.md`, 작업·검증 규칙은 `AGENTS.md`에
정리되어 있습니다.

## 공통 기본 기능

- 첫 실행 온보딩: 소개 2페이지, 필수 닉네임, 권한 안내
- 설정에서 소개 페이지만 다시 보기
- 시스템·라이트·다크 테마
- 언어 선택과 다국어 리소스
- 설정 상단 프리미엄 구독 카드와 페이월
- 개발자의 다른 앱, 문의, 약관, 개인정보 링크
- 시스템 리뷰 요청
- AdMob·개인정보 동의·Mixpanel·Supabase 설정 자리
- placeholder 설정에서 잘못된 외부 요청을 하지 않는 안전한 기본 동작
- 단위 테스트와 UI smoke test 기본 구조

## 새 앱 생성

### iOS

```sh
./scripts/new-ios-app.sh MyNewApp com.example.mynewapp "My New App" Utilities
```

필요 조건은 XcodeGen과 Xcode입니다. 생성기는 앱 이름·Bundle ID·표시 이름·
App Store 카테고리를 반영하고, Xcode 프로젝트를 다시 생성합니다.

### Android

```sh
./scripts/new-android-app.sh MyNewApp com.example.mynewapp "My New App"
```

필요 조건은 Android SDK와 JDK입니다. 생성기는 Kotlin 패키지와 테스트 패키지,
앱 표시 이름을 변경합니다.

## 보안 및 설정

실제 키는 저장소에 넣지 않습니다.

- iOS: `ios/Configs/AppSecrets.xcconfig.example`을 복사해
  `AppSecrets.xcconfig`로 만들고 앱별 키를 입력합니다.
- Android: `android/local.properties.example`을 복사해
  `local.properties`로 만들고 앱별 키를 입력합니다.
- Fastlane `.env`, App Store Connect `.p8`, 서명 파일, 빌드 결과물은 커밋하지
  않습니다.

## 플랫폼별 방향

### iOS

SwiftUI와 StoreKit 2를 기반으로 합니다. `Global`에 공통 토큰·Manager·
다국어를 두고, `Store`가 온보딩·설정·프리미엄 상태를 관리하며, `View`와
`Features`가 화면을 담당합니다. `project.yml`이 Xcode 프로젝트의 원본이고,
변경 후 `xcodegen generate`를 실행합니다.

### Android

Kotlin과 Jetpack Compose를 기반으로 합니다. `core`에 공통 UI·SDK·설정을
두고, `data`에 DataStore와 Play Billing 상태를 두며, `features`에 화면별
구현을 분리합니다. 설정값은 `local.properties`에만 저장하고, Gradle로
빌드·단위 테스트·Compose 테스트를 실행합니다.

## 검증 명령

```sh
# iOS
cd ios
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project AppTemplate.xcodeproj -scheme AppTemplate \
  -destination 'generic/platform=iOS Simulator' build

# Android
cd ../android
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:testDebugUnitTest :app:assembleDebug \
  :app:compileDebugAndroidTestKotlin --console=plain
```

출시 전에는 각 플랫폼의 README와 Fastlane 설정을 확인하고, 제품별 Bundle
ID·Application ID·스토어 상품·키·개인정보 URL을 반드시 교체하세요.
