# AppTemplateAndroid Agent Guide

이 폴더는 Boogios 네이티브 Android 앱의 공통 시작점입니다. iOS
`AppTemplate`의 설정, 다국어, 광고, 분석 구조와 대응되는 기본 표면을
유지합니다.

- UI는 Jetpack Compose로 작성합니다.
- 사용자 노출 문구는 `res/values/strings.xml`과 locale 리소스에 둡니다.
- 색상·간격·타이포그래피·모서리는 `core/ui/theme`의 `Boogios*` 토큰을 우선 사용합니다.
- 카드·주요 버튼·입력 필드는 `BoogiosCard`, `BoogiosPrimaryButton`, `BoogiosTextField`를 먼저 확인합니다.
- 다크 모드 화면에서는 고정 색상값 대신 `MaterialTheme.colorScheme`의 동적 표면·텍스트 토큰을 사용합니다.
- 기본 10개 로케일과 `AppLanguageManager`를 유지합니다.
- 제품별 키는 `local.properties`에만 저장하고 예제 파일에는 placeholder만 둡니다.
- AdMob 공통 컴포넌트와 `AdMobManager`, Mixpanel `MixpanelManager`를 재사용합니다.
- AdMob 광고 요청 전 UMP 동의 상태를 확인하고, 필요한 경우 개인정보 선택 메뉴를 노출합니다.
- 설정값은 `SettingsStore`와 Preferences DataStore로 저장하며 기존 설정 키를 마이그레이션합니다.
- 앱별 기능은 `ui`에 계속 몰아넣지 말고 `features/<Feature>`로 분리합니다.
- `SettingsScreen`과 시스템·라이트·다크 테마 진입점은 생성 앱에서도 유지합니다.
- 설정의 언어, 테마, 개발자의 다른 앱, 외부 링크 동작을 placeholder로 되돌리지 않습니다.
- 변경 후 `:app:assembleDebug`, `:app:testDebugUnitTest`,
  `:app:compileDebugAndroidTestKotlin`을 실행합니다.
