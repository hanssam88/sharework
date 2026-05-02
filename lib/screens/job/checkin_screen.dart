import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CheckinScreen extends StatefulWidget {
  final int jobId;
  const CheckinScreen({super.key, required this.jobId});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  DateTime? _checkinAt;
  DateTime? _checkoutAt;

  // 목업: 임의 거리값 (실제로는 GPS 거리)
  double get _distanceMeters => 12.4;
  bool get _withinRange => _distanceMeters < 100;

  void _checkin() {
    setState(() => _checkinAt = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출근 체크인 완료 (목업)')),
    );
  }

  void _checkout() {
    setState(() => _checkoutAt = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('퇴근 체크아웃 완료 (목업)')),
    );
  }

  void _scanQr() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR 코드 스캔'),
        content: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner,
                  size: 80, color: AppColors.brandDark),
              SizedBox(height: 12),
              Text('카메라 권한 필요\n(목업 placeholder)',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final canCheckin = _checkinAt == null;
    final canCheckout = _checkinAt != null && _checkoutAt == null;
    final done = _checkoutAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('출퇴근 체크'),
        actions: [
          IconButton(
            onPressed: _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline,
                        color: AppColors.brandDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(job.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16, color: AppColors.brandDark),
                    const SizedBox(width: 4),
                    Text(
                      '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // GPS 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _withinRange
                          ? Icons.gps_fixed
                          : Icons.gps_not_fixed,
                      color: _withinRange
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _withinRange ? '근무지 100m 이내' : '근무지 100m 이상 떨어져 있어요',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _withinRange
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 위치 → 근무지: ${_distanceMeters.toStringAsFixed(1)}m',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 140,
                    color: const Color(0xFFE3F2F5),
                    alignment: Alignment.center,
                    child: const Icon(Icons.location_pin,
                        size: 40, color: AppColors.brandDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TimeCard(
            label: '출근',
            time: _checkinAt,
            placeholder: '출근 전',
          ),
          const SizedBox(height: 8),
          _TimeCard(
            label: '퇴근',
            time: _checkoutAt,
            placeholder: '퇴근 전',
          ),
          if (done) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF1F8E48)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '근무 완료. 정산 처리가 시작됩니다.',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F8E48)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/me/payments'),
                    child: const Text('정산 보기'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: canCheckin
                ? (_withinRange ? _checkin : null)
                : canCheckout
                    ? _checkout
                    : null,
            child: Text(
              canCheckin
                  ? (_withinRange ? '출근 체크인' : '근무지 근처에서 다시 시도해주세요')
                  : canCheckout
                      ? '퇴근 체크아웃'
                      : '근무 완료',
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final DateTime? time;
  final String placeholder;
  const _TimeCard({
    required this.label,
    required this.time,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final filled = time != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: filled ? AppColors.brandSoft : AppColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              label == '출근' ? Icons.login : Icons.logout,
              color: filled ? AppColors.brandDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  filled ? fmtTime(time!) : placeholder,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: filled ? AppColors.text : AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          if (filled)
            const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }
}
