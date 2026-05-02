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

class _ChatRoomScreen extends StatefulWidget {
  final String otherName;
  const _ChatRoomScreen({required this.otherName});

  @override
  State<_ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<_ChatRoomScreen> {
  late List<ChatMessage> _messages;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _showQuickReply = true;

  @override
  void initState() {
    super.initState();
    _messages = List.of(Dummy.demoChatMessages);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addMessage({
    required ChatMessageKind kind,
    required String body,
    String? attachment,
    bool mine = true,
  }) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        kind: kind,
        body: body,
        attachment: attachment,
        mine: mine,
        createdAt: DateTime.now(),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _addMessage(kind: ChatMessageKind.text, body: text);
    _ctrl.clear();
    setState(() => _showQuickReply = false);
  }

  void _showMore() {
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
                _snack('050-xxxx-xxxx 로 연결합니다 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('대화 내용 검색'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('대화 검색 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('주고받은 사진·파일'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('미디어 갤러리 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('알림 끄기 (24시간)'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('이 채팅의 알림을 24시간 동안 꺼요');
              },
            ),
            const Divider(),
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
                _snack('차단 후 나갔어요 (목업)');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        Widget tile(IconData icon, String label, VoidCallback onTap) =>
            InkWell(
              onTap: () {
                Navigator.pop(sheetCtx);
                onTap();
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
                    Text(label, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: [
                tile(Icons.image_outlined, '사진', _pickPhoto),
                tile(Icons.location_on_outlined, '위치', _pickLocation),
                tile(Icons.work_outline, '일감 카드', _pickJob),
                tile(Icons.description_outlined, '계약서', _pickContract),
                tile(Icons.payments_outlined, '결제 요청', _pickPayment),
                tile(Icons.check_circle_outline, '체크인 요청', _requestCheckin),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickPhoto() {
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
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.brandDark),
              title: const Text('카메라'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _addMessage(
                    kind: ChatMessageKind.image,
                    body: '사진을 보냈어요',
                    attachment: 'cam-${_messages.length}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined,
                  color: AppColors.brandDark),
              title: const Text('갤러리'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _addMessage(
                    kind: ChatMessageKind.image,
                    body: '사진을 보냈어요',
                    attachment: 'gal-${_messages.length}');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickLocation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('위치 공유',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.location_pin,
                    size: 36, color: AppColors.brandDark),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.my_location,
                    color: AppColors.brandDark),
                title: const Text('현재 위치 공유'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _addMessage(
                      kind: ChatMessageKind.location,
                      body: '서울 강남구 테헤란로 123',
                      attachment: '37.5,127.0');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.search,
                    color: AppColors.brandDark),
                title: const Text('주소 검색해서 공유'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _addMessage(
                      kind: ChatMessageKind.location,
                      body: '잠실역 2번 출구',
                      attachment: '37.5145,127.1');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickJob() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetCtx).size.height * 0.6,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('공유할 일감 선택',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: Dummy.jobs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final j = Dummy.jobs[i];
                    return ListTile(
                      leading: const Icon(Icons.work_outline,
                          color: AppColors.brandDark),
                      title: Text(j.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${j.giverName} · ${fmtMoney(j.pay)}',
                          style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _addMessage(
                            kind: ChatMessageKind.jobCard,
                            body: j.title,
                            attachment: '${j.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickContract() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('전자근로계약서 보내기'),
        content: const Text('현재 진행 중인 일감의 계약서를 채팅으로 발송합니다. 상대방이 서명하면 자동으로 채용 확정돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _addMessage(
                  kind: ChatMessageKind.contract,
                  body: '근로계약서 발송',
                  attachment: '1002');
            },
            child: const Text('발송'),
          ),
        ],
      ),
    );
  }

  void _pickPayment() {
    final ctrl = TextEditingController(text: '50000');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('결제 요청',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '금액',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final amt = int.tryParse(
                            ctrl.text.replaceAll(',', '').trim()) ??
                        0;
                    if (amt < 1000) {
                      _snack('금액을 정확히 입력해주세요');
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    _addMessage(
                        kind: ChatMessageKind.paymentCard,
                        body: '${fmtMoney(amt)} 결제 요청',
                        attachment: '$amt');
                  },
                  child: const Text('결제 요청 발송'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _requestCheckin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('출퇴근 체크 요청'),
        content: const Text('상대방이 근무 시작·종료 시점에 체크인을 누르도록 알림을 보냅니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _addMessage(
                  kind: ChatMessageKind.system,
                  body: '체크인 요청을 보냈어요. 근무 시작/종료 시점에 알림이 발송됩니다.',
                  mine: false);
            },
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }

  void _onMessageLongPress(ChatMessage m) {
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
              leading: const Icon(Icons.copy),
              title: const Text('복사'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('메시지가 복사되었어요');
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('답장'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _ctrl.text = '> ${m.body}\n';
              },
            ),
            if (m.mine)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _messages.removeWhere((x) => x.id == m.id));
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag_outlined,
                    color: AppColors.danger),
                title: const Text('이 메시지 신고'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/report/chat/${m.id}');
                },
              ),
          ],
        ),
      ),
    );
  }

  static const _quickReplies = [
    '네, 가능합니다',
    '확인했습니다',
    '잠시만요',
    '시간 변경 가능할까요?',
    '네 감사합니다 :)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.otherName,
                style: const TextStyle(fontSize: 16)),
            const Text('● 응답 평균 5분',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: '안심번호 통화',
            onPressed: () => _snack('050-xxxx-xxxx 연결 (목업)'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMore,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => GestureDetector(
                onLongPress: () => _onMessageLongPress(_messages[i]),
                child: _Msg(message: _messages[i]),
              ),
            ),
          ),
          if (_showQuickReply)
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt,
                                size: 14, color: AppColors.brandDark),
                            SizedBox(width: 4),
                            Text('빠른 답장',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    ..._quickReplies.map((r) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            label: Text(r,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _addMessage(
                                  kind: ChatMessageKind.text, body: r);
                              setState(() => _showQuickReply = false);
                            },
                          ),
                        )),
                  ],
                ),
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
                  onPressed: _openAttachmentSheet,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                    ),
                    onSubmitted: (_) => _send(),
                    onTap: () => setState(() => _showQuickReply = false),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.brandDark),
                  onPressed: _send,
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
