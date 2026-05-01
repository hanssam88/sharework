import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
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

  void _openAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        Widget tile(IconData icon, String label, String snack) => InkWell(
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(snack)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.brandDark),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 12),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: [
                tile(Icons.image_outlined, '사진', '사진 첨부 (목업)'),
                tile(Icons.location_on_outlined, '위치',
                    '위치 공유 (목업)'),
                tile(Icons.work_outline, '일감 카드',
                    '일감 카드 첨부 (목업)'),
                tile(Icons.description_outlined, '계약서',
                    '계약서 카드 (목업)'),
                tile(Icons.payments_outlined, '결제',
                    '결제 카드 (목업)'),
                tile(Icons.check_circle_outline, '체크인 요청',
                    '출퇴근 체크 요청 (목업)'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = Dummy.demoChatMessages;
    return Scaffold(
      appBar: AppBar(
        title: Text(otherName),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: '안심번호 통화',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('050-xxxx-xxxx 로 연결합니다 (목업)')),
              );
            },
          ),
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
              itemBuilder: (_, i) => _Msg(message: messages[i]),
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
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.textMuted),
                  onPressed: () => _openAttachmentSheet(context),
                ),
                const SizedBox(width: 4),
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
  final ChatMessage message;
  const _Msg({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.body,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final mine = message.mine;
    final ago = fmtTime(message.createdAt);
    final bubble = _bubbleContent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (mine)
            Text(ago,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textFaint)),
          if (mine) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: bubble,
          ),
          if (!mine) const SizedBox(width: 4),
          if (!mine)
            Text(ago,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textFaint)),
        ],
      ),
    );
  }

  Widget _bubbleContent(BuildContext context) {
    final mine = message.mine;
    switch (message.kind) {
      case ChatMessageKind.text:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.brandDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: mine ? null : Border.all(color: AppColors.divider),
          ),
          child: Text(
            message.body,
            style: TextStyle(
              color: mine ? Colors.white : AppColors.text,
              fontSize: 14,
            ),
          ),
        );
      case ChatMessageKind.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            height: 140,
            color: AppColors.brandSoft,
            alignment: Alignment.center,
            child: const Icon(Icons.image,
                size: 40, color: AppColors.brandDark),
          ),
        );
      case ChatMessageKind.location:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.location_pin,
                    size: 32, color: AppColors.brandDark),
              ),
              const SizedBox(height: 8),
              Text(message.body,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              if (message.attachment != null)
                Text(message.attachment!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        );
      case ChatMessageKind.jobCard:
        final jobId = int.tryParse(message.attachment ?? '') ?? 0;
        return InkWell(
          onTap: () => context.push('/job/$jobId'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.work_outline,
                        color: AppColors.brandDark, size: 16),
                    SizedBox(width: 4),
                    Text('일감 카드',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message.body,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('탭해서 공고 보기',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
      case ChatMessageKind.contract:
        final jobId = int.tryParse(message.attachment ?? '') ?? 0;
        return InkWell(
          onTap: () => context.push('/job/$jobId/contract'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            width: 240,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description,
                        color: AppColors.brandDark, size: 16),
                    SizedBox(width: 4),
                    Text('전자근로계약서',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message.body,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('탭해서 계약서 확인 / 서명',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.brandDark)),
              ],
            ),
          ),
        );
      case ChatMessageKind.paymentCard:
        return Container(
          padding: const EdgeInsets.all(12),
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.payments_outlined,
                      color: AppColors.brandDark, size: 16),
                  SizedBox(width: 4),
                  Text('결제 카드',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark)),
                ],
              ),
              const SizedBox(height: 6),
              Text(message.body,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        );
      case ChatMessageKind.system:
        return const SizedBox.shrink();
    }
  }
}
