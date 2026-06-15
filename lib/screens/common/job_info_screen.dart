import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/api_errors.dart';
import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;
import '../../models/api_models/job_photo.dart' as api;
import '../../theme/app_theme.dart';

class JobInfoScreen extends StatefulWidget {
  final String jobId;
  final JobRepository? jobRepository;
  const JobInfoScreen({super.key, required this.jobId, this.jobRepository});

  @override
  State<JobInfoScreen> createState() => _JobInfoScreenState();
}

class _JobInfoScreenState extends State<JobInfoScreen> {
  late final JobRepository _repo;
  late Future<api.Job> _future;
  bool _applying = false;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.fetchJob(widget.jobId);
  }

  void _retry() {
    setState(() => _future = _repo.fetchJob(widget.jobId));
  }

  Future<void> _openApplyDialog(api.Job job) async {
    if (_applying || _applied) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('지원하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              '간단한 메시지 (선택)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 3,
              // BFF zod schema enforces 200 chars; clamp client-side so user
              // doesn't type past the limit only to hit VALIDATION on submit.
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '경험·가능 시간 등 자기소개를 적어주세요',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('지원'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _applying = true);
    try {
      await _repo.applyToJob(widget.jobId, coverNote: controller.text.trim());
      if (!mounted) return;
      setState(() {
        _applied = true;
        _applying = false;
      });
      _snack('지원이 접수되었어요');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      final err = e.error;
      _snack(err is ApiError ? _friendlyError(err) : '네트워크 오류가 발생했어요');
    }
  }

  String _friendlyError(ApiError err) {
    // Prefer raw BFF code (contractually stable) over message substring.
    switch (err.rawCode) {
      case 'LIFETIME_CAP_EXCEEDED':
        return '이 공고에는 이미 2번 지원했어요. 더 이상 지원할 수 없습니다';
      case 'REAPPLY_REJECTED':
        return '이전에 거절된 공고는 다시 지원할 수 없어요';
      case 'JOB_NOT_ACCEPTING':
        return '이 공고는 지원을 받지 않고 있어요';
      case 'ALREADY_APPLIED':
        return '이미 지원한 공고예요';
      case 'JOB_NOT_FOUND':
        return '공고를 찾을 수 없어요';
      case 'SELF_APPLY_FORBIDDEN':
        return '본인이 등록한 공고에는 지원할 수 없어요';
    }
    switch (err.code) {
      case ApiErrorCode.authRequired:
      case ApiErrorCode.authInvalid:
        return '로그인이 만료되었어요. 다시 로그인 해주세요';
      case ApiErrorCode.rateLimited:
        return '너무 자주 지원했어요. 잠시 후 다시 시도해주세요';
      case ApiErrorCode.notFound:
        return '공고를 찾을 수 없어요';
      default:
        return '문제가 발생했어요 (${err.message})';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공고 상세')),
      body: FutureBuilder<api.Job>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('연결이 불안정합니다'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _retry, child: const Text('다시 시도')),
                ],
              ),
            );
          }
          final job = snap.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _PhotoCarousel(photos: job.photos),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${job.wageWon}원 · ${job.locationAddress}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (job.giver != null)
                      Text('공고 등록자: ${job.giver!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (job.scheduleText != null) ...[
                      const SizedBox(height: 8),
                      Text('일정: ${job.scheduleText}'),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(job.description,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<api.Job>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done ||
              snap.data == null) {
            return const SizedBox.shrink();
          }
          final job = snap.data!;
          // BFF에서 status가 'active'인 공고만 지원 가능.
          final canApply = job.status == 'active' && !_applied;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: !canApply || _applying
                    ? null
                    : () => _openApplyDialog(job),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _applying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_applied
                        ? '지원 완료'
                        : (job.status == 'active' ? '지원하기' : '지원 불가')),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  final List<api.JobPhoto> photos;
  const _PhotoCarousel({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        key: const Key('photo-placeholder'),
        height: 240,
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.image, size: 64, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Image.network(
          photos[i].signedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      ),
    );
  }
}
