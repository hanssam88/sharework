import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({super.key});

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen> {
  late List<BlockedUser> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(Dummy.blocked);
  }

  void _unblock(BlockedUser u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('차단 해제'),
        content: Text('${u.name} 님의 차단을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.removeWhere((b) => b.userId == u.userId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('차단이 해제되었습니다')),
              );
            },
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.block,
              message: '차단한 사용자가 없어요',
            )
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final u = _items[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.chipBg,
                    child: Icon(Icons.person, color: AppColors.textMuted),
                  ),
                  title: Text(u.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${fmtRelative(u.blockedAt)} 차단',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _unblock(u),
                    child: const Text('해제'),
                  ),
                );
              },
            ),
    );
  }
}
