import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/api_errors.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../models/api_models/job.dart';
import '../../../models/api_models/job_photo.dart';
import '../../../services/photo_upload_service.dart';
import '../../../widgets/photo_upload_grid.dart';

/// M2 공고 등록 화면 (2-state):
///   State 1 (_createdJob == null): 폼 입력 + "다음"
///   State 2 (_createdJob != null): PhotoUploadGrid + "미리보기"/"완료"
///
/// M2 BFF 지원 필드만 노출 — title/description/wage/scheduleText/categoryId/
/// locationAddress. M1 rich UX(date/weekday/임시저장/시장가 등)는 M3+에서 재도입.
///
/// ApiError 캐치 패턴: Dio interceptor가 throw → DioException으로 재포장됨.
/// 직접 `on ApiError catch` 불가, 반드시 `on DioException` 후 `e.error is ApiError`
/// 로 unwrap (api_client.dart line 46-49 참조).
class JobCreateScreen extends StatefulWidget {
  final JobRepository? jobRepository;
  final PhotoUploadService? photoUploadService;
  final ImagePicker? imagePicker;

  const JobCreateScreen({
    super.key,
    this.jobRepository,
    this.photoUploadService,
    this.imagePicker,
  });

  @override
  State<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  // Lazy-initialized via getter — default constructors touch ApiClient /
  // Env / dotenv, which are unavailable in widget tests. Tests that exercise
  // a code path requiring a particular dependency must inject it via the
  // widget constructor.
  JobRepository? _repoOverride;
  PhotoUploadService? _photoSvcOverride;
  ImagePicker? _pickerOverride;

  JobRepository get _repo => _repoOverride ??= JobRepository.fromApi();
  PhotoUploadService get _photoSvc =>
      _photoSvcOverride ??= PhotoUploadService();
  ImagePicker get _picker => _pickerOverride ??= ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _wageC = TextEditingController();
  final _scheduleC = TextEditingController();
  final _addrC = TextEditingController();
  String? _categoryId;

  Job? _createdJob;
  List<JobPhoto> _photos = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repoOverride = widget.jobRepository;
    _photoSvcOverride = widget.photoUploadService;
    _pickerOverride = widget.imagePicker;
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

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) _showSnack('카테고리를 선택하세요');
      return;
    }
    setState(() => _busy = true);
    try {
      final job = await _repo.createJob(
        title: _titleC.text.trim(),
        description: _descC.text.trim(),
        wageWon: int.parse(_wageC.text.replaceAll(',', '')),
        scheduleText: _scheduleC.text.trim().isEmpty
            ? null
            : _scheduleC.text.trim(),
        categoryId: _categoryId!,
        locationAddress: _addrC.text.trim(),
      );
      if (!mounted) return;
      setState(() => _createdJob = job);
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
      _showSnack('등록에 실패했어요. 잠시 후 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto() async {
    if (_createdJob == null) return;
    // 권한 거부 또는 사용자 취소 시 pickImage가 null — silent no-op (spec §9.2).
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final photo = await _photoSvc.uploadPhoto(
        jobId: _createdJob!.id,
        picked: picked,
      );
      if (!mounted) return;
      setState(() => _photos = [..._photos, photo]);
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
    if (_createdJob == null) return;
    try {
      await _repo.deletePhoto(_createdJob!.id, photoId);
      if (!mounted) return;
      setState(
        () => _photos = _photos.where((p) => p.id != photoId).toList(),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiError) _showError(e.error as ApiError);
    }
  }

  Future<void> _reorderPhotos(List<String> newOrder) async {
    if (_createdJob == null) return;
    try {
      final updated = await _repo.reorderPhotos(_createdJob!.id, newOrder);
      if (!mounted) return;
      setState(() => _photos = updated);
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
        // F R6 CR-S3 + SE-S2: BFF 영문 message 직접 노출 차단 — 안전 한글
        // fallback. BFF 응답 보안성과 한국어 UX 양립.
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
    return Scaffold(
      appBar: AppBar(title: const Text('공고 등록')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _createdJob == null ? _buildForm() : _buildPhotoStep(),
              ),
            ),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('field-title'),
            controller: _titleC,
            decoration: const InputDecoration(labelText: '공고 제목 *'),
            maxLength: 50,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
          ),
          const SizedBox(height: 12),
          // TODO(M3): BFF /api/categories 연동 — 현재는 5개 매직 문자열 하드코딩.
          DropdownButtonFormField<String>(
            key: const Key('field-category'),
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: '카테고리 *'),
            items: const [
              DropdownMenuItem(value: 'cafe', child: Text('카페')),
              DropdownMenuItem(value: 'mart', child: Text('마트')),
              DropdownMenuItem(value: 'event', child: Text('행사')),
              DropdownMenuItem(value: 'office', child: Text('사무')),
              DropdownMenuItem(value: 'etc', child: Text('기타')),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? '카테고리를 선택하세요' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-wage'),
            controller: _wageC,
            decoration: const InputDecoration(labelText: '시급 (원) *'),
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
            decoration: const InputDecoration(
              labelText: '일정 (선택, 예: 주3일 9-17시)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-address'),
            controller: _addrC,
            decoration: const InputDecoration(labelText: '근무 주소 *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '주소를 입력하세요' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-desc'),
            controller: _descC,
            decoration: const InputDecoration(labelText: '상세 설명 *'),
            maxLines: 5,
            maxLength: 500,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '상세 설명을 입력하세요' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('btn-submit'),
            onPressed: _submitJob,
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('공고가 등록되었습니다.\n사진을 추가하세요. (선택, 최대 5장)'),
        ),
        PhotoUploadGrid(
          photos: _photos,
          onAdd: _addPhoto,
          onRemove: _removePhoto,
          onReorder: _reorderPhotos,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(
                  '/giver/job/preview',
                  extra: {'job': _createdJob, 'photos': _photos},
                ),
                child: const Text('미리보기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                // F R6 CR-M1: context.pop() — GiverHome의 push().then(refresh)
                // 사이클로 자동 refresh. context.go(stack replace)는 then()
                // 후속 callback이 불가능해 stale data 회피 패턴과 호환 안 됨.
                onPressed: () => context.pop(),
                child: const Text('완료'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
