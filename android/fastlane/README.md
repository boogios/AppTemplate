# Android Fastlane

```sh
bundle exec fastlane android build_release
bundle exec fastlane android upload
```

업로드 전 `fastlane/.env`에 앱별 package name과 Google Play service account
JSON 경로를 입력합니다. 실제 키 파일은 저장소에 넣지 않습니다.
