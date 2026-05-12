import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CredentialsListScreen extends StatelessWidget {
  const CredentialsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Dummy.credentials;
    final verified =
        items.where((c) => c.status == CredentialStatus.verified).length;
    return Scaffold(
      appBar: AppBar(title: const Text('보유 자격증·서류')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.workspace_premium_outlined,
              message: '등록된 자격증/서류가 없어요',
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: AppColors.brandDark),
                      const SizedBox(width: 8),
                      Text(
                        '인증된 자격 $verified개 / 전체 ${items.length}개',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CredentialCard(c: items[i]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/me/credentials/new'),
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('서류 등록'),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final Credential c;
  const _CredentialCard({required this.c});

  Color get _statusColor {
    switch (c.status) {
      case CredentialStatus.verified:
        return AppColors.success;
      case CredentialStatus.pending:
        return AppColors.warning;
      case CredentialStatus.expired:
        return AppColors.danger;
      case CredentialStatus.rejected:
        return AppColors.danger;
    }
  }

  String get _statusLabel {
    switch (c.status) {
      case CredentialStatus.verified:
        return '인증 완료';
      case CredentialStatus.pending:
        return '검토 중';
      case CredentialStatus.expired:
        return '만료';
      case CredentialStatus.rejected:
        return '반려';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(c.kind.icon, color: AppColors.brandDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.kind.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    if (c.memo != null) ...[
                      const SizedBox(height: 2),
                      Text(c.memo!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '발급 ${fmtDate(c.issuedAt)}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (c.expiresAt != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.hourglass_bottom,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '만료 ${fmtDate(c.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.status == CredentialStatus.expired
                        ? AppColors.danger
                        : AppColors.textMuted,
                    fontWeight: c.status == CredentialStatus.expired
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
