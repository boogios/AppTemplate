# AppTemplateAndroid Design Guide

이 문서는 iOS `AppTemplate/DESIGN.md`와 대응하는 Android 구현 체크리스트입니다.
새 화면은 이 규칙을 기본값으로 사용하고, 제품별 차이는 생성된 앱 안에서만
정의합니다.

## Provided Tokens

### Color

`core/ui/theme/Theme.kt`의 토큰을 우선 사용합니다. 이 계층은 iOS
`AppTemplate/AppTemplate/Global/Extension/Color+.swift`의 Android 대응
구현이며, 제품별 색상은 생성된 앱에서만 조정합니다.

- `BoogiosMain`: 주요 액션, 선택 상태, 활성 아이콘
- `BoogiosMainSoft`: 선택 배경과 약한 브랜드 표면
- `BoogiosMainSofter`: 빈 상태와 부드러운 강조
- `BoogiosWhite`: 밝은 카드 표면의 기준색
- `BoogiosGray1`: 기본 화면 배경
- `BoogiosGray2` / `BoogiosGray3`: 구분선과 테두리
- `BoogiosGray4` / `BoogiosGray5`: 비활성 요소와 약한 보조 정보
- `BoogiosGray6` / `BoogiosGray7`: 보조 텍스트
- `BoogiosGray8` / `BoogiosGray9` / `BoogiosGray10`: 강조도 높은 텍스트

Material 3의 `colorScheme`은 이 토큰을 기준으로 라이트·다크 테마를 구성합니다.
화면에서는 다크 모드 대응을 위해 `MaterialTheme.colorScheme.surface`,
`onSurface`, `onSurfaceVariant`, `primary`, `primaryContainer`를 우선
사용합니다. 화면 안에 고정된 색상값을 새로 만들지 않습니다.

### Spacing And Shapes

`BoogiosSpacing`과 `BoogiosShapes`로 iOS의 기본 치수를 맞춥니다.

- 화면 좌우 여백: `BoogiosSpacing.screen` 20dp
- 카드 내부 여백: `BoogiosSpacing.card` 20dp
- 주요 섹션 간격: `BoogiosSpacing.section` 16dp
- 카드 모서리: `BoogiosShapes.card` 16dp
- 입력·버튼 모서리: `BoogiosShapes.control` 14dp
- 실용적인 최소 터치 영역: `BoogiosSpacing.touchTarget` 44dp

### Typography

모든 기본 텍스트는 앱에 포함된 Pretendard를 사용하고, Material 3 Typography를
통해 iOS `Font+`의 역할별 크기와 굵기를 적용합니다. 시스템 sans로 돌아가지
않도록 새 화면에서도 별도 요청이 없는 한 `PretendardFontFamily`를 유지합니다.

| iOS 토큰 | Android 역할 | 크기·굵기 |
| --- | --- | --- |
| `headline1` | `headlineLarge` | 22sp Bold |
| `headline2` | `headlineMedium` | 20sp Bold |
| `headline3` | `headlineSmall` | 18sp Bold |
| `subtitle1` | `titleLarge` | 18sp SemiBold |
| `subtitle2` | `titleMedium` | 16sp SemiBold |
| `subtitle3` | `titleSmall` | 14sp SemiBold |
| `body1` | `bodyLarge` | 16sp, line height 24sp |
| `body2` | `bodyMedium` | 14sp, line height 21sp |
| `caption1` | `labelMedium` | 12sp Medium |
| `caption2` | `labelSmall` | 12sp Light |

글꼴 파일과 굵기 연결은 `core/ui/theme/Theme.kt`의 `PretendardFontFamily`를
기준으로 관리합니다.

## New Screen Defaults

- 내용이 길어질 수 있으면 `verticalScroll`을 사용합니다.
- 기본 좌우 여백은 20dp입니다.
- 기본 화면 배경은 `BoogiosGray1`입니다.
- 카드는 `BoogiosCard`를 사용합니다. 모서리 반경은 16dp, 내부 여백은 기본
  20dp로 두며 제품 화면에서도 16~20dp 범위를 유지합니다.
- 카드 간격은 16~20dp를 유지합니다.
- 표준 화면은 iOS처럼 콘텐츠 위에 가운데 정렬된 inline 타이틀을 둡니다.
- 표준 설정 화면은 프리미엄 카드 다음에 환경설정·링크·버전의 3개 카드로
  나누고, 각 행은 제목과 선택적 trailing 값·chevron을 한 줄에 배치합니다.
  행 사이에는 divider를 넣지 않고 28dp 간격을 사용합니다.
- 터치 영역은 최소 44dp 이상으로 둡니다.
- 사용자 노출 문구는 Kotlin 코드에 하드코딩하지 않고 `strings.xml`에 둡니다.

### Primary Button

주요 동작에는 `BoogiosPrimaryButton`을 사용합니다.

- 배경은 `BoogiosMain`, 글자는 `BoogiosWhite`에 해당하는 테마 표면색으로 둡니다.
- 글꼴은 Pretendard SemiBold 15sp를 사용합니다.
- 모서리 반경은 14dp, 세로 안쪽 여백은 15dp로 둡니다.
- 버튼은 기본적으로 화면 너비를 채우고, 실제 터치 높이는 최소 44dp를
  유지합니다.

### Onboarding Defaults

온보딩은 소개 2페이지, 필수 닉네임 입력, 알림 안내, 광고 개인정보 안내로
구성합니다. 실제 알림 권한과 UMP 팝업은 OS 권한 상태와 AdMob 설정에 따라
조건부로 요청하며, 거부해도 앱 진입을 막지 않습니다. 제품별 문구는
`res/values*/strings.xml`에서 관리하고, 설정의 다시 보기는 소개 2페이지만
표시합니다.

## Common Components First

기존 공통 컴포넌트를 먼저 확인합니다.

- `core/ui/components/Components.kt`의 `BoogiosCard`: 카드 표면과 기본 내부 여백
- `BoogiosPrimaryButton`: Boogios 기본 색상·글꼴·모서리 기준을 적용한 주요 버튼
- `BoogiosTextField`: iOS `BoogiosTextField`에 대응하는 입력 필드
- `SettingRow`: 설정 목록 행
- `BannerAdView`: 적응형 배너 광고
- `NativeAdLoader` / `NativeAdCard`: 네이티브 광고 로드와 표시
- `RewardedAdService` / `RewardedAdButton`: 보상형 광고 사전 로드와 표시

광고 컴포넌트는 실제 ID가 설정되지 않았거나 UMP 동의가 완료되지 않았을 때
아무 UI도 표시하지 않아 placeholder 키와 동의 전 광고 요청을 막습니다.

## Settings And Localization

생성 앱에서도 다음 설정 표면을 유지합니다.

- 언어: 시스템 기본, 한국어, 영어 US·UK·Canada·Australia, 일본어, 독일어,
  프랑스어, 브라질 포르투갈어, 베트남어
- 테마: 시스템·라이트·다크
- 개발자의 다른 앱: Boogios Studio 외부 링크 열기
- 문의하기, 이용약관, 개인정보 처리방침: 외부 URL 열기
- 앱 버전 표시

언어 변경은 `AppCompatDelegate`의 앱별 언어 API를 사용하며, 리소스 폴더와
`res/xml/locales_config.xml`을 함께 갱신합니다.

## SDK And Configuration

앱별 설정은 무시되는 `local.properties`에만 저장합니다.

- `AppConfig`: 설정값, placeholder 판정, 외부 링크
- `AdMobManager`: UMP 동의 갱신, 개인정보 선택, 동의 후 AdMob 초기화
- `MixpanelManager`: 초기화, 사용자 식별, 속성, 이벤트, flush
- `data/settings/SettingsStore`: Preferences DataStore 기반 테마 설정 저장
- `data/settings/OnboardingStore`: 온보딩 완료 상태와 닉네임을 Preferences DataStore에 저장
- Supabase: URL·publishable key·redirect URL 설정 자리만 제공하며 실제 SDK와
  인증·DB 구현은 제품별로 추가

## Growth Path

화면이 커지면 `ui`에 계속 파일을 추가하지 말고 다음처럼 분리합니다.

```text
features/<Feature>/
    <Feature>Screen.kt
    <Feature>ViewModel.kt
    <Feature>Repository.kt
```

상태와 비즈니스 로직은 ViewModel과 Repository로 옮기고, 앱 전역 설정은
`SettingsStore`를 통해 유지합니다.
