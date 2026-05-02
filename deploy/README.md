# deploy/ — 배포 템플릿

`flutter create .` 로 `android/`, `ios/` 폴더가 생성된 뒤 그대로 복사·붙여넣기 할 수 있는 설정 템플릿 모음입니다.

자세한 사용 흐름은 저장소 루트의 [`INTERNAL_TEST.md`](../INTERNAL_TEST.md) 참고.

```
deploy/
├─ android/
│  ├─ key.properties.template    → android/key.properties 로 복사 후 비밀번호 채우기
│  └─ signing-snippet.gradle     → android/app/build.gradle 에 병합
└─ ios/
   └─ Info.plist.permissions.snippet.xml  → ios/Runner/Info.plist 의 <dict> 안에 병합
```

이 디렉터리의 파일은 **참고용**이며 빌드에 직접 사용되지 않습니다. 실제로는 사용자가 위치를 옮겨야 적용됩니다.
