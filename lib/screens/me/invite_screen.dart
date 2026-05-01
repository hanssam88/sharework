import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  static const _code = 'KIMALBA-7H4K2';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구초대')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandDark, AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('친구를 초대하면\n양쪽 모두 5,000원',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    )),
                SizedBox(height: 8),
                Text(
                  '추천코드로 가입한 친구의 첫 근무 완료 시\n양쪽 모두에게 즉시 쿠폰이 지급돼요.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('내 추천코드',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code,
                    color: AppColors.brandDark, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.brandDark,
                      )),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('추천코드가 복사되었어요')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카카오톡 공유 (목업)')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('카카오톡'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS 보내기 (목업)')),
                    );
                  },
                  icon: const Icon(Icons.sms_outlined, size: 16),
                  label: const Text('문자'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('링크 공유 (목업)')),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('공유'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('초대 현황',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _StatCard(label: '초대 완료', value: '3')),
              SizedBox(width: 8),
              Expanded(
                  child: _StatCard(label: '받은 쿠폰', value: '15,000원')),
              SizedBox(width: 8),
              Expanded(child: _StatCard(label: '랭킹', value: 'TOP 12%')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('안내',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...const [
            _BulletRow('친구가 추천코드 입력 후 가입해야 인정돼요.'),
            _BulletRow('첫 근무 완료(또는 첫 정산 완료) 시 쿠폰 즉시 발급.'),
            _BulletRow('어뷰징 의심 시 보상이 회수될 수 있어요.'),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

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
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDark,
              )),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child:
                Icon(Icons.circle, size: 5, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
