# 네이티브 템플릿 공통 기반 1.0.0

기본 기능을 모두 포함한 SwiftUI·Kotlin/Compose 템플릿을 유지한다. 생성된 앱은 독립 소스이며 공통 패키지에 의존하지 않는다. 기존 제품에는 자동 적용하지 않는다. RN은 이 기준의 대상이 아니다.

## 수정 위치와 책임

| 책임 | iOS | Android |
|---|---|---|
| 앱 수명과 구성 | `Infrastructure/AppDependencies.swift`, `AppCoordinator` | `core/foundation/AppDependencies.kt`, Application |
| 저장·읽기 오류 | `PreferencesClient`, `Store/SettingsStore`, `Store/OnboardingStore` | `PreferenceRepository`, `data/settings` |
| 구매 SDK 어댑터 | `Infrastructure/PurchaseClient.swift` | `data/premium/BillingGateway.kt` |
| 구매 권한과 화면 상태 | `Store/PremiumStore.swift` | `data/premium/PremiumStore.kt` |
| 보상 완료와 중복 방지 | `View/Common/AdMob/RewardedAdSheetView.swift` | `core/admob/RewardedAdService.kt` |
| 분석·권한 대체 | `AnalyticsClient`, `PermissionClient`, `AdvertisingClient` | `AnalyticsClient`, `NotificationClient`, `AdvertisingClient` |
| 오류·로딩·재시도 UI | `AsyncStatusView`, `FoundationL10n` | `AsyncStatus`, `foundation_*` 문자열 |

각 앱의 기존 저장 키, 지원 OS, 언어, 설정 탭과 시스템 테마를 유지한다. iOS는 앱 소유 객체를 `@StateObject`로 보유한다. Android 서비스는 Application에 보관하고 Activity는 호출 시 전달한다. 초기 저장값을 읽기 전에는 온보딩을 확정하지 않는다. 읽기 실패는 빈 값으로 덮어쓰지 않고 재시도를 제공한다.

iOS UserDefaults의 쓰기 완료는 프로세스 내 반영 기준이다. 운영체제의 디스크 기록 실패를 검출하는 API로 간주하지 않는다. Android는 DataStore 쓰기 반환 후 완료를 알린다. 더 강한 영속성 요구는 제품 저장소에서 해결한다.

## 동작 계약

- 구매 권한: 확인 전 → 확인 중 → 무료/유료/확인 실패. 실패 시 마지막 완전한 조회 결과와 시각을 보존한다. iOS는 알려진 만료 시각도 적용한다. Android는 SUBS와 INAPP을 함께 기다린 뒤 합산한다. 실패한 유형의 기존 권한은 보존하고, 성공한 유형에서 확인된 만료·취소는 반영한다. 두 유형이 모두 성공한 시각과 유형별 성공 시각을 별도로 기록한다. Google 응답에 만료 시간이 없으므로 로컬에서 시간을 추정하지 않는다.
- 마지막 권한은 프로세스 메모리 내에서 보존한다. 재실행 시 스토어가 보관한 구매 내역을 다시 조회한다. 검증되지 않은 디스크 플래그로 유료 권한을 만들지 않는다.
- 상품 로딩과 권한 조회는 별개다. 상품 미등록·연결 오류에서 재시도가 가능하며 가격은 스토어 응답만 사용한다.
- 구매 결과: 성공/보류/사용자 취소/실패. 보류·취소는 구매 오류로 표시하지 않는다. Google 구매 승인은 최대 3회 재시도하며 다음 조회에서도 미승인 구매를 처리한다.
- 광고 결과: 보상 획득/보상 없이 닫힘/실패. 보상 이벤트에서는 표시만 기록하고 닫힘 콜백에서 최종 결과를 한 번 전달한다. 표시·로딩 중 추가 요청은 기존 요청을 교체하지 않고 실패로 끝낸다. 이전 광고의 지연 콜백이 새 요청을 완료시키지 않는다.
- 동의와 알림 요청 중 반복 호출은 같은 진행 중 요청을 기다린다. 거부·동의 실패도 온보딩을 진행할 수 있다.
- 프리뷰·테스트는 외부 광고, 분석, 결제 SDK를 비활성화한다. StoreKit 로컬 테스트만 명시적으로 로컬 스토어 어댑터를 사용한다. 실제 동의창·광고 송출·스토어 계정 결제는 별도 기기 QA 항목이다.
- 서버에서 유료 콘텐츠를 제공하는 제품은 서버 구매 검증과 계정 연결을 추가해야 한다. 이 템플릿의 로컬 권한 판정만으로 서버 접근을 허용하지 않는다.

## 분석 이벤트

기존 이름을 유지하고 양쪽에 같은 이벤트를 추가했다. 공통 속성은 `platform`, `app_version`, `build_number`이며 기존 플랫폼 값 iOS/Android를 유지한다. 사용자 닉네임은 기존 프로필 `$name`에만 설정한다. 오류 안내·예외 메시지에는 닉네임·구매 토큰·서버 원문을 넣지 않는다.

| 이벤트 | 발생 시점 |
|---|---|
| `onboarding_completed` | 저장 성공 뒤 |
| `onboarding_replayed` | 다시 보기 시작 |
| `premium_viewed` | 페이월 열기 |
| `purchase_started` | 구매 실행 직전 |
| `purchase_completed/pending/cancelled/failed` | 구매 결과 확정; 성공은 권한 재확인 후 |
| `purchase_restored` | 복원 조회 성공 뒤; 유료가 없을 수도 있음 |
| `rewarded_ad_requested` | 광고 표시 요청마다 |
| `rewarded_ad_completed/dismissed/failed` | 각 요청의 최종 결과, 최대 1회 |

## 생성과 검사

기존 명령 형식을 유지한다. 첫 인자는 코드 식별자이고 사용자 표시 이름은 별도 인자다.

```sh
./scripts/new-ios-app.sh NewApp com.example.newapp 'A & B "한글"' Utilities
./scripts/new-android-app.sh NewApp com.example.newapp 'A & B "한글"'
python3 scripts/test_native_template.py
python3 scripts/check-native-template.py ios --mode local
python3 scripts/check-native-template.py android --mode local
./scripts/audit-template-drift.sh --all
```

- 생성 결과 `template-manifest.json`의 템플릿·기능별 버전은 1.0.0부터 기록한다. 앱 스토어 버전과 별개다.
- 템플릿 전체를 임시 폴더에 복사하고 형식을 검증한 뒤 최종 경로를 만든다. 충돌 경로는 덮어쓰지 않는다.
- 실제 설정·서명 키·SDK 서비스 설정·Git·외부 라이브러리·캐시·산출물·심볼릭 링크는 복사하지 않는다. 예제에서 앱별 설정 파일을 새로 만든다.
- `local`: 구조·번역·파일 형식·식별자·기본 기능 검사. placeholder를 허용한다.
- `release`: local에 더해 예제 URL, 기본 ID, 미완성 아이콘·스토어 ID 등을 보고한다. 서명, 서버 운영 상태, 실제 구매와 동의, 스토어 등록·개인정보 답변은 별도로 검증한다. 검사 성공은 제출 또는 공개의 증거가 아니다.
- iOS 번들에 PrivacyInfo.xcprivacy와 실제 폰트 등록을 단위 테스트로 확인한다. UserDefaults 사유 CA92.1을 선언하며 다른 기본 API나 수집 데이터가 추가되면 선언을 함께 검토한다.
- 영어 지역 변형은 기본 영어로 대체할 수 있다. 다른 언어의 키와 치환 인자는 일치해야 한다. iOS Home의 미완성 번역도 채웠다.
- 차이 검사에서 버전 기록 없는 기존 앱은 적용 후보로 표시한다. 개별 구조 차이를 제품 오류로 간주하지 않는다. 내부 검사 앱은 `scripts/template-audit-policy.json`에서 제외한다.

## 앞으로의 앱 개발 순서

1. 템플릿에서 생성하고 앱별 이름·ID·아이콘·키·링크·상품을 설정한다. manifest 원본 버전을 유지한다.
2. 기존 기본 기능의 회귀 테스트를 먼저 실행한 뒤 제품 고유 화면과 데이터 흐름을 만든다. 네이티브별 UI와 제품 차별성은 앱 내부에서 설계한다.
3. 실패·취소·재시도 동작을 먼저 정하고 작은 어댑터를 주입해 테스트한다. 화면에 SDK와 저장 규칙을 직접 섞지 않는다.
4. 단위 테스트 → 생성 앱 빌드 → UI 테스트 → 큰 글씨·긴 번역·다크 모드 → 실제 기기·서비스 순서로 검증한다.
5. 여러 앱에 유용한 수정은 재현 테스트와 함께 템플릿으로 되돌린다. 양쪽 결과 상태·이벤트를 맞추고 기능 버전과 변경 기록을 올린다. 다시 생성한 임시 앱까지 검증한다.
6. 기존 앱 적용은 해당 앱의 저장 키·구매 상품·SDK 버전을 비교한 개별 변경으로 진행한다. 전체 덮어쓰기를 하지 않는다. 업로드·제출·출시는 앱별 별도 단계다.

## 기존 앱 후속 적용 후보

| 참고 앱 | 가져온 기준 | 후속 확인할 항목 |
|---|---|---|
| Mindset | 초기 권한 조회, 결과 상태, 번역·폰트 검사 | 재실행·복귀 조회와 실패 시 기존 권한 보존 |
| DadaCut | 광고 실패와 회귀 테스트 | 보상 후 닫힘 기준 완료, 중복 요청·콜백 방지 |
| Loopin | 의존성 연결과 대체 구현 테스트 | 앱 소유 수명과 저장 실패 주입 |
| 기존 템플릿 생성 앱 | 설정·테마·온보딩 기본 흐름 | 폰트 번들 경로, 저장 후 완료, 버전 기록 |

이 문서와 이번 구현은 위 제품 앱을 수정하지 않는다. Android Billing만 승인된 9.1.0으로 변경하며 다른 운영 SDK를 일괄 갱신하지 않는다. 테스트용 kotlinx-coroutines-test는 비동기 조회·저장 실패 회귀 테스트에만 사용한다. Fastlane 업로드·심사·자동 출시 기본값은 유지한다.

공식 참고: [Google Billing 지원 기한](https://developer.android.com/google/play/billing/deprecation-faq), [릴리스 노트](https://developer.android.com/google/play/billing/release-notes), [Apple StoreKit 로컬 테스트](https://developer.apple.com/documentation/storekittest/sktestsession)

## 플랫폼별 검증 명령

앱 루트에서 실행한다. 임시 생성 앱은 해당 이름으로 프로젝트와 scheme을 바꾼다.

```sh
# iOS: 일반 실행 scheme은 실제 스토어 구성을 유지한다.
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -list -project AppTemplate.xcodeproj
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project AppTemplate.xcodeproj -scheme AppTemplate -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test CODE_SIGNING_ALLOWED=NO
# StoreKit 로컬 시나리오는 별도 scheme에서 직렬 실행한다.
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project AppTemplate.xcodeproj -scheme AppTemplateLocalTests -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
# Android: 설치된 JDK/SDK와 실행 중인 에뮬레이터를 사용한다.
./gradlew :app:testDebugUnitTest :app:assembleDebug :app:connectedDebugAndroidTest
```

시뮬레이터 이름은 로컬에 설치된 기기에 맞게 바꾼다. StoreKit 로컬 설정의 ID는 새 앱 생성 시 앱 식별자별로 분리된다. 기본 scheme과 배포 빌드에는 로컬 구매 설정을 활성화하지 않는다. 일반 앱 실행에 테스트 상품을 섞지 않기 위한 구분이다.


## 스토어 자산 기능 1.0.0 (템플릿 1.1.0)

Fastlane 2.241.2와 앱 내부 검사·순차 업로드 도구를 포함한다. iOS 기본 출력은 1206×2622와 Duo 바깥/안쪽이며, 두 Duo 화면 합계 최대 10장이다. Android는 지원하는 Play 기기 분류로만 제출한다. 상세 규격·검증·재개 규칙은 템플릿의 `fastlane/STORE_SCREENSHOTS.md`를 따른다. 실제 업로드·심사 제출은 앱별 승인 범위에서 별도로 실행한다.
