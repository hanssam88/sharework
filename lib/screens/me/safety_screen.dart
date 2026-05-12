import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  late List<EmergencyContact> _contacts;
  bool _sosEnabled = true;
  bool _shareLocation = true;
  bool _autoCheckin = true;
  bool _shareItinerary = false;

  @override
  void initState() {
    super.initState();
    _contacts = List.of(Dummy.emergencyContacts);
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relation = '가족';
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
        child: StatefulBuilder(
          builder: (_, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('긴급연락처 추가',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: '이름'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '휴대폰 번호'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['가족', '친구', '동료', '기타'].map((r) {
                      final on = relation == r;
                      return ChoiceChip(
                        label: Text(r),
                        selected: on,
                        showCheckmark: false,
                        selectedColor: AppColors.brandDark,
                        labelStyle: TextStyle(
                          color: on ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setSheet(() => relation = r),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이름과 번호를 입력해주세요')),
                        );
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      setState(() {
                        _contacts.add(EmergencyContact(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: nameCtrl.text.trim(),
                          relation: relation,
                          phone: phoneCtrl.text.trim(),
                        ));
                      });
                    },
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeContact(int id) {
    setState(() => _contacts.removeWhere((c) => c.id == id));
  }

  void _testSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emergency_outlined, color: AppColors.danger),
            SizedBox(width: 8),
            Text('SOS 테스트'),
          ],
        ),
        content: Text(
          '실제로 누르면 등록된 ${_contacts.length}명에게 위치·상황을 즉시 전송하고 112에 자동 신고돼요. 지금은 테스트만 진행됩니다.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('테스트 SOS 발송 완료 (목업)')),
              );
            },
            child: const Text('테스트 발송'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('안전·SOS')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.danger.withOpacity(0.15),
                        AppColors.danger.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.emergency_outlined,
                              color: Colors.white, size: 36),
                          onPressed: _testSOS,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('SOS 테스트',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                        '실제 사용 시 길게 눌러 5초 카운트다운 후 발송',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          const SectionHeader(title: 'SOS 설정'),
          SwitchListTile(
            value: _sosEnabled,
            activeColor: AppColors.brandDark,
            title: const Text('SOS 사용'),
            subtitle: const Text('홈 화면 + 채팅방에서 SOS 버튼 표시',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _sosEnabled = v),
          ),
          SwitchListTile(
            value: _shareLocation,
            activeColor: AppColors.brandDark,
            title: const Text('실시간 위치 공유'),
            subtitle: const Text('SOS 발동 시 등록된 연락처에 위치 60분간 공유',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _shareLocation = v),
          ),
          SwitchListTile(
            value: _autoCheckin,
            activeColor: AppColors.brandDark,
            title: const Text('근무 종료 자동 체크'),
            subtitle: const Text('예정 종료 시간 30분 후까지 체크아웃 없으면 자동 알림',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _autoCheckin = v),
          ),
          SwitchListTile(
            value: _shareItinerary,
            activeColor: AppColors.brandDark,
            title: const Text('근무 일정 자동 공유'),
            subtitle: const Text('채용 확정 시 매번 등록된 연락처에 일정·위치 자동 전송',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onChanged: (v) => setState(() => _shareItinerary = v),
          ),
          const Divider(thickness: 8, color: AppColors.bg),
          SectionHeader(
            title: '긴급연락처 (${_contacts.length}/3)',
            trailing: TextButton.icon(
              onPressed: _contacts.length >= 3 ? null : _addContact,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가'),
            ),
          ),
          if (_contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text('등록된 연락처가 없어요',
                  style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ..._contacts.map((c) => ListTile(
                  leading: const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(Icons.person, color: AppColors.brandDark),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${c.relation} · ${c.phone}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textFaint),
                    onPressed: () => _removeContact(c.id),
                  ),
                )),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '※ SOS 신고는 한국 112·119와 연동되며, 무분별한 사용은 처벌 대상이 될 수 있어요. 실제 위급 상황에서만 사용해주세요.',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
