# Boogios App Templates

Boogios 스타일의 네이티브 iOS·Android 앱을 빠르게 시작하기 위한 공통
템플릿 저장소입니다. 두 플랫폼은 각각 독립적으로 빌드되지만, 온보딩·설정·
프리미엄·광고·분석·다국어·리뷰 요청의 기본 제품 경험은 최대한 대응되도록
구성되어 있습니다.

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
