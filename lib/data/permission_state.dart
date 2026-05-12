import 'package:flutter/foundation.dart';

/// 목업용 권한 상태 — SharedPreferences 대신 메모리에 보관.
/// 실 빌드에서는 permission_handler 등으로 교체.
enum PermissionStatus { notAsked, granted, denied, denied2, partial }

extension PermissionStatusX on PermissionStatus {
  String get label {
    switch (this) {
      case PermissionStatus.notAsked:
        return '미요청';
      case PermissionStatus.granted:
        return '허용됨';
      case PermissionStatus.partial:
        return '일부 허용';
      case PermissionStatus.denied:
        return '거부됨';
      case PermissionStatus.denied2:
        return '재차 거부 (시스템 설정 필요)';
    }
  }

  bool get isGranted =>
      this == PermissionStatus.granted || this == PermissionStatus.partial;

  bool get isDenied =>
      this == PermissionStatus.denied || this == PermissionStatus.denied2;
}

class PermissionStore extends ChangeNotifier {
  static final PermissionStore I = PermissionStore._();
  PermissionStore._();

  PermissionStatus location = PermissionStatus.notAsked;
  PermissionStatus notification = PermissionStatus.notAsked;
  PermissionStatus camera = PermissionStatus.notAsked;
  PermissionStatus gallery = PermissionStatus.notAsked;

  // priming 화면을 한 번이라도 봤는지 (다시 안 띄우기 위해)
  bool locationPrimed = false;
  bool notificationPrimed = false;
  bool cameraPrimed = false;
  bool galleryPrimed = false;

  // 거부 시 fallback 선택값
  String? manualAddress; // 위치 거부 시 입력한 주소
  bool emailFallback = false; // 알림 거부 시 이메일로 받기

  void set(PermissionKind kind, PermissionStatus status) {
    switch (kind) {
      case PermissionKind.location:
        location = status;
        break;
      case PermissionKind.notification:
        notification = status;
        break;
      case PermissionKind.camera:
        camera = status;
        break;
      case PermissionKind.gallery:
        gallery = status;
        break;
    }
    notifyListeners();
  }

  PermissionStatus get(PermissionKind kind) {
    switch (kind) {
      case PermissionKind.location:
        return location;
      case PermissionKind.notification:
        return notification;
      case PermissionKind.camera:
        return camera;
      case PermissionKind.gallery:
        return gallery;
    }
  }

  void markPrimed(PermissionKind kind) {
    switch (kind) {
      case PermissionKind.location:
        locationPrimed = true;
        break;
      case PermissionKind.notification:
        notificationPrimed = true;
        break;
      case PermissionKind.camera:
        cameraPrimed = true;
        break;
      case PermissionKind.gallery:
        galleryPrimed = true;
        break;
    }
    notifyListeners();
  }

  bool isPrimed(PermissionKind kind) {
    switch (kind) {
      case PermissionKind.location:
        return locationPrimed;
      case PermissionKind.notification:
        return notificationPrimed;
      case PermissionKind.camera:
        return cameraPrimed;
      case PermissionKind.gallery:
        return galleryPrimed;
    }
  }
}

enum PermissionKind { location, notification, camera, gallery }

extension PermissionKindX on PermissionKind {
  String get label {
    switch (this) {
      case PermissionKind.location:
        return '위치';
      case PermissionKind.notification:
        return '알림';
      case PermissionKind.camera:
        return '카메라';
      case PermissionKind.gallery:
        return '사진·갤러리';
    }
  }

  String get oneLineWhy {
    switch (this) {
      case PermissionKind.location:
        return '내 주변 일자리·거리 계산에 사용';
      case PermissionKind.notification:
        return '채용 확정·체크인 시간을 놓치지 않게';
      case PermissionKind.camera:
        return '본인인증·자격증·체크인 사진 촬영';
      case PermissionKind.gallery:
        return '포트폴리오·프로필 사진 등록';
    }
  }
}
