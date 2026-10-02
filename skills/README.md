# Boogios 작업 스킬

이 폴더에는 Boogios 앱을 스토어용 이미지로 준비하고, TestFlight와 Google
Play 출시를 반복 가능하게 만드는 Codex 작업 지침이 들어 있습니다.

## 포함된 스킬

| 스킬 | 용도 | 주요 산출물 |
| --- | --- | --- |
| `screenshot-ios` | iOS 실제 시뮬레이터 화면 캡처와 App Store 이미지 구성 | 실제 UI 캡처, HTML/CSS 프레임, 다국어 스크린샷 |
| `screenshot-android` | Android 에뮬레이터 화면 캡처와 Google Play 이미지 구성 | 실제 UI 캡처, Play용 이미지, 크기·비율 검증 |
| `ios-fastlane-release` | iOS 빌드·메타데이터·스크린샷·TestFlight/App Store 출시 | Fastlane 검사와 업로드/제출 절차 |
| `android-fastlane-release` | Android 빌드·서명·메타데이터·Google Play 출시 | Fastlane 검사와 트랙 업로드/검토 절차 |

각 스킬은 `SKILL.md`를 중심으로 사용합니다. `agents/openai.yaml`은 Codex에서
스킬을 검색하고 호출할 때 사용하는 설명이며, `assets/`, `references/`,
`scripts/`에는 스킬이 실제로 재사용하는 템플릿과 검증 도구가 있습니다.

## 추천 사용 순서

1. 앱의 실제 화면과 제품 문구를 먼저 완성합니다.
2. `screenshot-ios` 또는 `screenshot-android`로 실제 기기 화면을 캡처합니다.
3. 캡처 이미지를 확인한 뒤 해당 플랫폼의 출시 스킬을 사용합니다.
4. Fastlane의 사전 점검을 통과시킵니다.
5. 업로드·검토 제출·공개 상태를 각각 확인합니다.

스크린샷 스킬은 HTML/CSS를 사용해 장식 프레임을 만들 수 있지만, 앱 화면
자체를 가짜로 만들지는 않습니다. 제품 화면은 실제 Simulator 또는
에뮬레이터에서 캡처해야 합니다.

## 키와 개인정보

스킬에 적힌 경로는 예시 또는 이 컴퓨터에서 사용하는 기본 경로일 수 있습니다.
실제 App Store Connect API 키, Google Play 서비스 계정 JSON, 업로드 키스토어,
Fastlane `.env`, 개인정보가 담긴 스토어 자료는 이 저장소에 넣지 않습니다.

- iOS API 키: `fastlane/.env`와 로컬 `.p8` 파일로 관리합니다.
- Android 서비스 계정: 로컬 JSON 파일 경로를 환경 변수로 지정합니다.
- Android 업로드 키: 로컬 키스토어 경로와 비밀번호를 환경 변수로 지정합니다.
- 스크린샷·스토어 문구에는 테스트용 개인정보나 내부 메모를 남기지 않습니다.

스킬을 다른 컴퓨터에서 사용할 때는 각 `SKILL.md`의 경로, Bundle ID,
Application ID, 스킴, 패키지명, 저장소 위치를 현재 앱에 맞게 확인하세요.
