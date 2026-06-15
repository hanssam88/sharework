import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api_errors.dart';
import '../../../data/repositories/me_repository.dart';
import '../../../models/api_models/application.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

/// Worker: 본인 지원 내역.
/// BFF: GET /api/me/applications  (cursor pagination, safe view, no counts)
///      PATCH /api/me/applications/:id  (status: withdrawn, only from 'applied')
class MyApplicationsScreen extends StatefulWidget {
  final MeRepository? repository;

  const MyApplicationsScreen({super.key, this.repository});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late final MeRepository _repo;
  List<Application> _items = [];
  bool _loading = true;
  bool _hasMore = false;
  Object? _error;
  final Set<String> _withdrawing = {};

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MeRepository.fromApi();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.listMyApplications(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _withdraw(Application app) async {
    if (_withdrawing.contains(app.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('지원 철회'),
        content: const Text('이 지원을 철회할까요? 철회 후에는 다시 지원할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('철회'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _withdrawing.add(app.id));
    try {
      await _repo.withdrawApplication(app.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((a) =>
                a.id == app.id ? a.copyWith(status: 'withdrawn') : a)
            .toList();
      });
      _snack('지원이 철회되었어요');
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiError) {
        _snack(_friendlyError(err));
        // INVALID_TRANSITION = Giver가 이미 처리한 row → list 동기화로 정정.
        if (err.rawCode == 'INVALID_TRANSITION') {
          unawaited(_load());
        }
      } else {
        _snack('네트워크 오류가 발생했어요');
      }
    } finally {
      if (mounted) setState(() => _withdrawing.remove(app.id));
    }
  }

  String _friendlyError(ApiError err) {
    switch (err.rawCode) {
      case 'INVALID_TRANSITION':
        return '이미 처리되어 철회할 수 없어요';
      case 'APPLICATION_NOT_FOUND':
        return '지원 내역을 찾을 수 없어요';
    }
    switch (err.code) {
      case ApiErrorCode.authRequired:
      case ApiErrorCode.authInvalid:
        return '로그인이 만료되었어요. 다시 로그인 해주세요';
      case ApiErrorCode.rateLimited:
        return '요청이 너무 많아요. 잠시 후 다시 시도해주세요';
      case ApiErrorCode.notFound:
        return '지원 내역을 찾을 수 없어요';
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
      appBar: AppBar(
        title: const Text('내 지원내역'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final err = _error;
      final msg = err is DioException && err.error is ApiError
          ? _friendlyError(err.error as ApiError)
          : '지원 내역을 불러올 수 없었어요';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: AppColors.textFaint,
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: AppColors.textFaint),
              SizedBox(height: 12),
              Text(
                '아직 지원한 공고가 없어요',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_hasMore)
          Container(
            width: double.infinity,
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '일부 지원 내역만 표시되고 있어요. 새로고침을 눌러 최신 상태를 확인하세요.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: _load,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('새로고침'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _card(_items[i]),
          ),
        ),
      ],
    );
  }

  Widget _card(Application a) {
    final isApplied = a.status == 'applied';
    final isBusy = _withdrawing.contains(a.id);
    return Card(
      child: InkWell(
        onTap: () => context.push('/job/${a.jobId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Job #${a.jobId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusChip(a.status),
              ],
            ),
            if ((a.coverNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.coverNote!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              _appliedAtLabel(a.appliedAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textFaint,
              ),
            ),
            if (isApplied) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => _withdraw(a),
                  child: isBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('지원 철회'),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'applied' => ('지원중', AppColors.brandDark),
      'hired' => ('채용', Colors.green.shade700),
      'rejected' => ('거절', AppColors.danger),
      'withdrawn' => ('철회', AppColors.textMuted),
      _ => (status, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _appliedAtLabel(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '지원';
  return '지원 ${fmtRelative(dt)}';
}
