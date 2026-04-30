import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = Dummy.notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('모두 읽음', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none, message: '새 알림이 없어요')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => NotificationCard(
                noti: list[i],
                onTap: () {
                  if (list[i].jobId != null) {
                    context.push('/job/${list[i].jobId}');
                  }
                },
              ),
            ),
    );
  }
}
