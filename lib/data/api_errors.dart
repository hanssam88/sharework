// 12 BFF ErrorCodes + `unknown` fallback. Codes beyond Sprint 1B BFF
// (STORAGE_FAIL, RATE_LIMITED, PHOTO_*, JOB_STATE_INVALID) are defined ahead
// of Sprint 2 BFF land — until then, unmatched payloads map to `unknown`.
enum ApiErrorCode {
  authRequired,
  authInvalid,
  forbidden,
  notFound,
  validation,
  internal,
  storageFail,
  rateLimited,
  photoLimitExceeded,
  photoFileInvalid,
  photoNotUploaded,
  jobStateInvalid,
  unknown,
}

ApiErrorCode parseErrorCode(String? raw) {
  switch (raw) {
    case 'AUTH_REQUIRED':
      return ApiErrorCode.authRequired;
    case 'AUTH_INVALID':
      return ApiErrorCode.authInvalid;
    case 'FORBIDDEN':
      return ApiErrorCode.forbidden;
    case 'NOT_FOUND':
      return ApiErrorCode.notFound;
    case 'VALIDATION':
      return ApiErrorCode.validation;
    case 'INTERNAL':
      return ApiErrorCode.internal;
    case 'STORAGE_FAIL':
      return ApiErrorCode.storageFail;
    case 'RATE_LIMITED':
      return ApiErrorCode.rateLimited;
    case 'PHOTO_LIMIT_EXCEEDED':
      return ApiErrorCode.photoLimitExceeded;
    case 'PHOTO_FILE_INVALID':
      return ApiErrorCode.photoFileInvalid;
    case 'PHOTO_NOT_UPLOADED':
      return ApiErrorCode.photoNotUploaded;
    case 'JOB_STATE_INVALID':
      return ApiErrorCode.jobStateInvalid;
    default:
      return ApiErrorCode.unknown;
  }
}

class ApiError implements Exception {
  final int statusCode;
  final ApiErrorCode code;
  final String message;
  final int? retryAfterSec;

  ApiError({
    required this.statusCode,
    required this.code,
    required this.message,
    this.retryAfterSec,
  });

  @override
  String toString() => 'ApiError($statusCode, $code, $message)';
}
