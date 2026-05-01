import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = Dummy.chatRooms;
    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: rooms.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              message: '아직 대화방이 없어요',
            )
          : ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) {
                final r = rooms[i];
                return InkWell(
                  onTap: () => _openChatRoom(context, r.otherUserName),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.brandSoft,
                          child: Icon(Icons.business,
                              color: AppColors.brandDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.otherUserName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.chipBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.jobTitle,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    fmtRelative(r.lastMessageAt),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textFaint),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted),
                                    ),
                                  ),
                                  if (r.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.brandDark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${r.unreadCount}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openChatRoom(BuildContext context, String name) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ChatRoomScreen(otherName: name),
    ));
  }
}

class _ChatRoomScreen extends StatelessWidget {
  final String otherName;
  const _ChatRoomScreen({required this.otherName});

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_outlined,
                  color: AppColors.brandDark),
              title: const Text('안심번호로 통화'),
              subtitle: const Text(
                '050으로 시작하는 가상번호로 연결돼요',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('050-xxxx-xxxx 로 연결합니다 (목업)')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppColors.danger),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                context.push('/report/chat/0');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.danger),
              title: const Text('차단 후 나가기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('차단 후 나갔어요 (목업)')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = [
      _Msg('안녕하세요, 지원해주셔서 감사합니다.', mine: false, ago: '오후 2:30'),
      _Msg('네 안녕하세요! 잘 부탁드립니다.', mine: true, ago: '오후 2:31'),
      _Msg('내일 8시까지 잠실역 2번 출구에서 뵐게요.', mine: false, ago: '오후 2:32'),
      _Msg('네 알겠습니다 :)', mine: true, ago: '오후 2:33'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(otherName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMore(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => messages[i],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: AppColors.textMuted),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.brandDark),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg extends StatelessWidget {
  final String text;
  final bool mine;
  final String ago;
  const _Msg(this.text, {required this.mine, required this.ago});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (mine) Text(ago, style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
          if (mine) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.brandDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: mine
                    ? null
                    : Border.all(color: AppColors.divider),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.text,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (!mine) const SizedBox(width: 4),
          if (!mine) Text(ago, style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
