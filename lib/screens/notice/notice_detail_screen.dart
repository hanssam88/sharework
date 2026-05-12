import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class NoticeDetailScreen extends StatelessWidget {
  final int noticeId;
  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  Widget build(BuildContext context) {
    final notice = Dummy.notices.firstWhere(
      (n) => n.id == noticeId,
      orElse: () => Dummy.notices.first,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('공지')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (notice.pinned)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '📌 중요',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
          Text(
            notice.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            fmtDate(notice.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
          ),
          const SizedBox(height: 20),
          Text(
            notice.body,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
