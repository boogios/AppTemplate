# AppTemplateAndroid

Boogios 네이티브 Android 스타터 템플릿입니다. iOS `AppTemplate`의 기본
구조를 Jetpack Compose와 Kotlin으로 대응시켰습니다.

## 처음 시작하는 분들을 위한 안내

이 폴더는 Android 앱을 만들기 위한 템플릿입니다. 화면은 Kotlin과 Jetpack
Compose로 작성하고, 설정값은 `local.properties`에 저장합니다. 완성된 하나의
서비스가 아니라 새로운 앱을 시작하는 기본 프로젝트이므로, 먼저 예제 앱을
실행해 본 뒤 제품 기능을 추가하세요.

### 준비물

- Android Studio
- Android SDK와 Android 12 이상 에뮬레이터 또는 테스트 기기
- JDK: Android Studio에 포함된 JBR 사용 권장
- 인터넷 연결: Gradle 의존성을 처음 내려받을 때 필요

### 5분 안에 실행하기

Android Studio에서 저장소의 `android` 폴더를 엽니다. 터미널을 사용하는 경우:

```sh
cd android
cp local.properties.example local.properties
```

`local.properties`를 열어 `sdk.dir`을 본인 컴퓨터의 Android SDK 경로로
바꿉니다. Android Studio에서 에뮬레이터를 실행하고 Run 버튼을 누르거나,
다음 명령으로 APK를 빌드합니다.

```sh
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:assembleDebug --console=plain
```

빌드가 끝나면 Android Studio에서 Run을 눌러 앱을 설치할 수 있습니다.
예제 키는 placeholder이므로 광고·분석·결제는 연결되지 않지만, 홈·설정·
온보딩 화면은 정상적으로 확인할 수 있습니다.

### 처음 수정할 파일 순서

1. `core/config/AppConfig.kt`에서 앱 이름, 색상, URL, 상품 ID를 확인합니다.
2. `features/home/HomeScreen.kt`에서 기본 홈 화면을 제품에 맞게 바꿉니다.
3. `features/settings/SettingsScreen.kt`에서 설정 메뉴와 이동을 확인합니다.
4. 새 문구는 `app/src/main/res/values*/strings.xml`에 추가합니다.
5. 색상·간격·폰트는 `core/ui/theme/Theme.kt`와 `DESIGN.md`를 확인합니다.
6. 새 기능은 `features/<Feature>` 패키지로 분리합니다.

### Android Studio에서 자주 보는 폴더

- `core`: 여러 화면이 함께 사용하는 기반 코드
- `data`: 설정 저장, 온보딩 상태, 결제 상태
- `features`: 실제 제품 화면
- `navigation`: 온보딩·홈·설정·페이월 연결
- `res/values*`: 언어별 화면 문구와 테마 리소스

`ui`라는 하나의 폴더에 모든 화면을 넣지 않는 것이 이 템플릿의 중요한
원칙입니다. 화면이 늘어나면 기능별 패키지로 분리해야 나중에 수정하기 쉽습니다.

## 포함된 기본 구성

- 홈 / 설정 하단 탭
- 첫 실행 온보딩: 소개 2페이지, 필수 닉네임, 알림 안내, 광고 개인정보 안내
- 설정에서 소개 페이지만 다시 보기
- 시스템·라이트·다크 테마 선택 및 저장
- Preferences DataStore 기반 설정 저장 및 기존 SharedPreferences 마이그레이션
- 시스템 기본, 한국어, 영어 US·UK·Canada·Australia, 일본어, 독일어,
  프랑스어, 브라질 포르투갈어, 베트남어 10개 로케일
- 언어·테마·필요 시 광고 개인정보 선택·개발자의 다른 앱·앱 리뷰·문의·약관·개인정보·버전 설정
- 설정 화면 핵심 이동을 확인하는 Compose UI smoke test
- iOS `AppTemplate`와 대응하는 Compose 색상·타이포그래피·간격·모서리 토큰
- `BoogiosCard`·`BoogiosPrimaryButton`·`BoogiosTextField`·`SettingRow` 공통 컴포넌트
- AdMob Banner·Native·Rewarded 공통 컴포넌트와 초기화 관리자
- AdMob UMP 동의 요청, 광고 요청 가능 상태 확인, 개인정보 선택 진입점
- 설정 상단 프리미엄 구독 카드와 Google Play Billing 기반 페이월
- 월간·연간·평생 상품 ID placeholder, 상품 조회·구매·구매 복원·권한 상태 반영
- Google Play In-App Review 기반 시스템 리뷰 요청
- Android 13 이상 알림 권한 요청과 UMP 요청은 상태·설정에 따라 조건부 실행
- Mixpanel 초기화·사용자 식별·속성·이벤트·flush 관리자
- Supabase 설정 자리
- Android 12 스플래시와 둥근 앱 아이콘
- 단위 테스트와 Fastlane Android 기본 구조

## 새 앱 만들기

workspace 루트에서 실행합니다.

```sh
./scripts/new-android-app.sh MyNewApp com.example.mynewapp "My New App"
```

생성 후 `local.properties.example`을 `local.properties`로 복사하고 앱별
키를 입력합니다. 실제 키와 `local.properties`는 Git에 넣지 않습니다.

프리미엄 상품은 `AppConfig.kt`의 `premium*ProductId`를 Google Play Console에
등록한 상품 ID로 바꿔서 사용합니다. 상품을 등록하기 전에는 페이월에 임의의
가격을 보여주지 않고 준비 중 안내만 표시합니다.

## 아키텍처

템플릿은 화면을 한 패키지에 몰아넣지 않고 공통 기반, 데이터, 기능, 탐색
계층으로 나눕니다.

```text
app/src/main/
├── java/com/boogios/template/
│   ├── core/
│   │   ├── config/       # 앱 이름, 색상, URL, 상품 ID, placeholder 판정
│   │   ├── admob/        # UMP 동의, Banner·Native·Rewarded 광고
│   │   ├── analytics/    # Mixpanel 초기화, 사용자 속성, 이벤트
│   │   ├── review/       # Google Play In-App Review 요청
│   │   └── ui/
│   │       ├── components/ # 카드, 버튼, 입력창, 설정 행, 광고 UI
│   │       └── theme/      # 색상, Typography, 간격, 모서리
│   ├── data/
│   │   ├── settings/     # Preferences DataStore, 언어·테마·온보딩 상태
│   │   └── premium/      # Play Billing 상품·구매·복원·권한
│   ├── features/
│   │   ├── home/         # 홈 화면
│   │   ├── onboarding/   # 첫 실행 온보딩
│   │   ├── premium/      # 프리미엄 페이월
│   │   └── settings/     # 설정 화면
│   ├── navigation/       # 탭과 루트 화면 연결
│   ├── MainActivity.kt   # Compose 진입점
│   └── AppTemplateAndroidApplication.kt # 앱 전역 초기화
├── res/values*/strings.xml # 로케일별 사용자 노출 문구
└── res/xml/locales_config.xml # 앱 언어 선택 목록
```

`core`는 여러 기능에서 재사용하는 기반 코드만 둡니다. 제품 기능이 커지면
`features/<Feature>`에 화면, ViewModel, Repository를 함께 두고, 설정 저장이나
결제 같은 앱 전역 상태는 `data` 계층을 통해 접근합니다. 새 화면에서 고정
색상이나 임의의 여백을 만들지 않고 `DESIGN.md`의 토큰과 공통 컴포넌트를
우선 사용합니다.

## 빌드

```sh
cp local.properties.example local.properties
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:assembleDebug --console=plain
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:testDebugUnitTest --console=plain
```

## 구조

- `app/src/main/java/.../core/config`: 앱 설정과 외부 링크
- `app/src/main/java/.../core/ui/theme`: iOS 기준 Boogios 색상·테마·타이포그래피·간격·모서리
- `app/src/main/java/.../core/ui/components`: 카드·버튼·텍스트 필드·설정 행 공통 Compose 컴포넌트
- `app/src/main/java/.../core/admob`: AdMob 초기화·배너·네이티브·보상형 광고
- `app/src/main/java/.../core/analytics`: Mixpanel 공통 관리자
- `app/src/main/java/.../core/review`: Google Play 리뷰 요청 관리자
- `app/src/main/java/.../data/settings`: 언어, 테마, 온보딩 상태 저장
- `app/src/main/java/.../data/premium`: Play Billing 상품·구매·복원·권한 상태
- `app/src/main/java/.../features/home`: 홈 화면
- `app/src/main/java/.../features/onboarding`: 온보딩 화면
- `app/src/main/java/.../features/premium`: 프리미엄 페이월 UI
- `app/src/main/java/.../features/settings`: 설정 화면
- `app/src/main/java/.../navigation`: 탭과 앱 루트 화면 연결
- `app/src/main/java/.../AppTemplateAndroidApplication.kt`: SDK 초기화 진입점
- `app/src/main/res/values*/strings.xml`: 10개 로케일 사용자 노출 문자열
- `app/src/main/res/xml/locales_config.xml`: Android 앱별 언어 목록
- `fastlane/`: Google Play 빌드·업로드 lane

제품 기능이 커지면 `features/<Feature>` 패키지를 추가하고 화면 상태는
ViewModel과 앱별 Repository로 분리합니다. 상세한 색상·간격·컴포넌트 규칙은
`DESIGN.md`를 따릅니다.

## 기본 사용자 흐름

### 첫 실행 온보딩

앱 루트가 `OnboardingStore`의 완료 상태를 확인하고, 미완료 상태면 다음
단계를 보여줍니다.

1. 소개 페이지 2개
2. 공백을 제거한 닉네임 입력과 1-20자 검증
3. Android 13 이상 알림 권한 안내와 조건부 요청
4. 광고 개인정보 안내와 조건부 UMP 동의 요청
5. 홈 화면 진입

권한을 거부해도 앱 진입은 막히지 않습니다. AdMob 설정이 placeholder이면
UMP와 광고 요청을 건너뛰고, 설정의 온보딩 다시 보기는 소개 2페이지만
표시합니다. 닉네임과 온보딩 완료 상태는 Preferences DataStore에 저장합니다.
Mixpanel이 설정된 경우에만 닉네임 속성과 온보딩 이벤트를 기록합니다.

### 설정

설정 화면은 다음 순서의 표면을 유지합니다.

1. 프리미엄 구독 카드
2. 언어·테마·필요한 경우 개인정보 선택
3. 온보딩 다시 보기·개발자의 다른 앱·앱 리뷰·문의·약관·개인정보
4. 앱 버전

개발자 앱과 문서 메뉴는 외부 링크를 열고, 리뷰 메뉴는 Google Play의 시스템
In-App Review API를 사용합니다. 알림 설정은 기본 템플릿 메뉴에 넣지 않고,
제품에 알림 기능이 있을 때 해당 기능에서 추가합니다.

### 프리미엄

`PremiumStore`가 상품 조회, 구매, 구매 복원, 결제 상태 갱신을 담당하고
`PremiumPaywallDialog`가 페이월을 표시합니다. 월간·연간·평생 상품 ID는 placeholder로
제공되며, 실제 상품이 등록되기 전에는 임의의 가격을 표시하지 않습니다.

## 설정값과 보안

앱별 키는 `local.properties`에만 저장하고 Git에 커밋하지 않습니다.
`local.properties.example`에는 placeholder만 둡니다.

- `AppConfig.kt`: 앱 이름, 브랜드 색상, 외부 링크, 상품 ID
- `AdMobManager`: UMP 동의 상태 확인 후 AdMob 초기화
- `MixpanelManager`: 토큰이 있을 때만 초기화와 이벤트 전송
- `SettingsStore`: Preferences DataStore 기반 설정 저장
- `OnboardingStore`: 온보딩 완료 상태와 닉네임 저장
- `PremiumStore`: Google Play Billing 상태 관리
- `Supabase`: URL·publishable key·redirect URL 설정 자리만 제공

placeholder 상태에서는 SDK 초기화, 광고 요청, 분석 전송, 외부 요청이
실행되지 않도록 유지합니다.

## 검증

템플릿 변경 후 기본 검증은 다음과 같습니다.

```sh
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:testDebugUnitTest :app:assembleDebug \
  :app:compileDebugAndroidTestKotlin --console=plain
```

Compose UI smoke test는 전체 온보딩 흐름과 설정의 온보딩 다시 보기,
설정 메뉴 이동을 확인합니다. 실제 기기 또는 에뮬레이터에서 실행할 때는
다음 명령으로 연결된 테스트를 실행할 수 있습니다.

```sh
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  ./gradlew :app:connectedDebugAndroidTest --console=plain
```
