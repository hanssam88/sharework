import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/api_errors.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../models/api_models/job.dart';
import '../../../services/photo_upload_service.dart';
import '../../../widgets/job_status_toggle.dart';
import '../../../widgets/photo_upload_grid.dart';

/// M2 공고 수정 화면:
///   GET /api/jobs/:id → 폼 prefill
///   PATCH /api/jobs/:id (modified fields only) → 저장
///   JobStatusToggle → status PATCH (active/paused/closed)
///   PhotoUploadGrid → 사진 add/remove/reorder
///
/// M2 BFF 지원 필드만 노출 — title/description/wage/scheduleText/
/// locationAddress + status. M1 mockup의 personnel/sameDayPay/foodProvided/
/// extraPay 등 풍부한 UX는 M3+에서 재도입.
///
/// ApiError 캐치 패턴: Dio interceptor가 throw → DioException으로 재포장됨.
/// 직접 `on ApiError catch` 불가, 반드시 `on DioException` 후 `e.error is ApiError`
/// 로 unwrap (api_client.dart line 46-49 참조).
class JobEditScreen extends StatefulWidget {
  final String jobId;
  final JobRepository? jobRepository;
  final PhotoUploadService? photoUploadService;
  final ImagePicker? imagePicker;

  const JobEditScreen({
    super.key,
    required this.jobId,
    this.jobRepository,
    this.photoUploadService,
    this.imagePicker,
  });

  @override
  State<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends State<JobEditScreen> {
  // Lazy-initialized via getter — default constructors touch ApiClient /
  // Env / dotenv, which are unavailable in widget tests. Tests must inject
  // overrides via constructor (B.8 pattern).
  JobRepository? _repoOverride;
  PhotoUploadService? _photoSvcOverride;
  ImagePicker? _pickerOverride;

  JobRepository get _repo => _repoOverride ??= JobRepository.fromApi();
  PhotoUploadService get _photoSvc =>
      _photoSvcOverride ??= PhotoUploadService();
  ImagePicker get _picker => _pickerOverride ??= ImagePicker();

  Job? _job;
  bool _loading = true;
  bool _busy = false;

  // Form validator key (F R6 UX-M2): TextFormField + validator 회복으로
  // submit-time '필수 입력 누락' UX 일관성을 JobCreate와 맞춤. M3+에서
  // autovalidateMode.onUserInteraction 도입 검토 (현재는 학습 비용 최소화).
  final _formKey = GlobalKey<FormState>();

  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _wageC = TextEditingController();
  final _scheduleC = TextEditingController();
  final _addrC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repoOverride = widget.jobRepository;
    _photoSvcOverride = widget.photoUploadService;
    _pickerOverride = widget.imagePicker;
    _load();
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _wageC.dispose();
    _scheduleC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final job = await _repo.fetchJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _titleC.text = job.title;
        _descC.text = job.description;
        _wageC.text = job.wageWon.toString();
        _scheduleC.text = job.scheduleText ?? '';
        _addrC.text = job.locationAddress;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) {
        _showError(e.error as ApiError);
      } else {
        // F R6 UX-S2: raw e.message 노출 제거 → 한글 안전 fallback.
        _showSnack('연결이 불안정합니다. 잠시 후 다시 시도해주세요');
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      // F R6 UX-S2: raw exception 노출 제거 → 한글 안전 fallback.
      _showSnack('로드에 실패했어요. 잠시 후 다시 시도해주세요');
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_job == null) return;
    // F R6 UX-M2: Form validator 우선 — 필수 필드 빈 값 차단 (JobCreate 동일 패턴).
    if (!_formKey.currentState!.validate()) return;
    // F R6 CR-S1: wage silent drop guard — int 파싱 실패 또는 0 이하 시 PATCH
    // 누락(silent drop) 대신 명시 알림 후 중단. 빈 입력은 validator가 차단.
    final wageInt = int.tryParse(_wageC.text.replaceAll(',', ''));
    if (wageInt == null || wageInt <= 0) {
      _showSnack('올바른 시급을 입력해주세요 (양수)');
      return;
    }
    setState(() => _busy = true);
    try {
      // F R6 CR-S2: scheduleText 빈 문자열 → null 보장 (BFF에 '' 저장 회피).
      final scheduleTrimmed = _scheduleC.text.trim();
      final updated = await _repo.updateJob(
        widget.jobId,
        title: _titleC.text != _job!.title ? _titleC.text : null,
        description: _descC.text != _job!.description ? _descC.text : null,
        wageWon: wageInt != _job!.wageWon ? wageInt : null,
        scheduleText: _scheduleC.text != (_job!.scheduleText ?? '')
            ? (scheduleTrimmed.isEmpty ? null : scheduleTrimmed)
            : null,
        locationAddress:
            _addrC.text != _job!.locationAddress ? _addrC.text : null,
      );
      if (!mounted) return;
      setState(() => _job = updated);
      _showSnack('저장되었습니다');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) {
        _showError(e.error as ApiError);
      } else {
        _showSnack('네트워크 오류가 발생했어요');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('저장에 실패했어요. 잠시 후 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_job == null) return;
    setState(() => _busy = true);
    try {
      final updated = await _repo.updateJob(widget.jobId, status: newStatus);
      if (!mounted) return;
      setState(() => _job = updated);
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) _showError(e.error as ApiError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto() async {
    if (_job == null) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final photo = await _photoSvc.uploadPhoto(
        jobId: widget.jobId,
        picked: picked,
      );
      if (!mounted) return;
      setState(
        () => _job = _job!.copyWith(photos: [..._job!.photos, photo]),
      );
    } on PhotoFileTooLargeException catch (e) {
      if (!mounted) return;
      _showSnack(
        '파일이 10MB를 초과합니다 '
        '(${(e.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
    } on PhotoUploadException catch (e) {
      if (!mounted) return;
      // V2: 동일 URL 재시도 금지 — 재시도 시 새 upload-url 발급 후 진행.
      _showSnackWithRetry(
        '업로드 실패 (${e.statusCode ?? "network"})',
        () => _addPhoto(),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) {
        _showError(e.error as ApiError);
      } else {
        // F R6 UX-S2: raw e.message 노출 제거 → 한글 안전 fallback.
        _showSnack('네트워크 오류가 발생했어요');
      }
    } catch (e) {
      if (!mounted) return;
      // F R6 UX-S2: raw exception 노출 제거 → 한글 안전 fallback.
      _showSnack('업로드에 실패했어요. 잠시 후 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto(String photoId) async {
    if (_job == null) return;
    try {
      await _repo.deletePhoto(widget.jobId, photoId);
      if (!mounted) return;
      setState(
        () => _job = _job!.copyWith(
          photos: _job!.photos.where((p) => p.id != photoId).toList(),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) _showError(e.error as ApiError);
    }
  }

  Future<void> _reorderPhotos(List<String> newOrder) async {
    if (_job == null) return;
    try {
      final updated = await _repo.reorderPhotos(widget.jobId, newOrder);
      if (!mounted) return;
      setState(() => _job = _job!.copyWith(photos: updated));
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) _showError(e.error as ApiError);
    }
  }

  void _showError(ApiError e) {
    final String msg;
    switch (e.code) {
      case ApiErrorCode.photoLimitExceeded:
        msg = '최대 5장까지 등록할 수 있어요';
        break;
      case ApiErrorCode.rateLimited:
        msg = '잠시 후 다시 시도해주세요 (${e.retryAfterSec ?? "?"}초)';
        break;
      case ApiErrorCode.jobStateInvalid:
        msg = '마감된 공고는 수정할 수 없어요';
        break;
      case ApiErrorCode.validation:
        msg = '입력값을 확인해주세요';
        break;
      case ApiErrorCode.photoFileInvalid:
        msg = '파일 형식이 올바르지 않아요';
        break;
      case ApiErrorCode.storageFail:
        msg = '저장 실패. 다시 시도해주세요';
        break;
      default:
        // F R6 CR-S3 + SE-S2: BFF 영문 message가 사용자에게 직접 노출되는 것
        // 차단 — 안전 한글 fallback. BFF 응답 보안성과 한국어 UX 양립.
        msg = '일시적인 오류가 발생했어요. 잠시 후 다시 시도해주세요';
    }
    _showSnack(msg);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showSnackWithRetry(String msg, VoidCallback onRetry) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(label: '재시도', onPressed: onRetry),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('공고 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('공고 수정')),
        body: const Center(child: Text('공고를 찾을 수 없습니다')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('공고 수정')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    JobStatusToggle(
                      current: _job!.status,
                      onChange: _changeStatus,
                    ),
                    const SizedBox(height: 24),
                    PhotoUploadGrid(
                      photos: _job!.photos,
                      onAdd: _addPhoto,
                      onRemove: _removePhoto,
                      onReorder: _reorderPhotos,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('field-title'),
                      controller: _titleC,
                      decoration: const InputDecoration(labelText: '제목'),
                      maxLength: 50,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '제목을 입력하세요'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('field-wage'),
                      controller: _wageC,
                      decoration: const InputDecoration(labelText: '시급 (원)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '시급을 입력하세요';
                        final n = int.tryParse(v.replaceAll(',', ''));
                        if (n == null || n <= 0) return '올바른 숫자를 입력하세요';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('field-schedule'),
                      controller: _scheduleC,
                      decoration: const InputDecoration(labelText: '일정 (선택)'),
                      // optional: validator 없음
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('field-address'),
                      controller: _addrC,
                      decoration: const InputDecoration(labelText: '주소'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '주소를 입력하세요'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('field-desc'),
                      controller: _descC,
                      decoration: const InputDecoration(labelText: '상세 설명'),
                      maxLines: 5,
                      maxLength: 500,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '상세 설명을 입력하세요'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('btn-save'),
                      onPressed: _save,
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
