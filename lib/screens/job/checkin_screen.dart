import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

enum _CheckMethod { gps, qr, pin, approval }

extension _CheckMethodX on _CheckMethod {
  String get label {
    switch (this) {
      case _CheckMethod.gps:
        return 'GPS';
      case _CheckMethod.qr:
        return 'QR 코드';
      case _CheckMethod.pin:
        return 'PIN';
      case _CheckMethod.approval:
        return '사장님 승인';
    }
  }

  IconData get icon {
    switch (this) {
      case _CheckMethod.gps:
        return Icons.gps_fixed;
      case _CheckMethod.qr:
        return Icons.qr_code_scanner;
      case _CheckMethod.pin:
        return Icons.dialpad;
      case _CheckMethod.approval:
        return Icons.how_to_reg_outlined;
    }
  }
}

enum _Phase { before, working, onBreak, done }

class CheckinScreen extends StatefulWidget {
  final int jobId;
  const CheckinScreen({super.key, required this.jobId});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  _CheckMethod _method = _CheckMethod.gps;
  DateTime? _checkinAt;
  DateTime? _checkoutAt;
  DateTime? _breakStartAt;
  Duration _accumulatedBreak = Duration.zero;
  bool _photoVerified = false;
  String? _lateReason;
  String? _earlyLeaveReason;
  String _memo = '';

  Timer? _ticker;

  // 목업: 임의 거리값 (실제로는 GPS 거리)
  double get _distanceMeters => 12.4;
  bool get _withinRange => _distanceMeters < 100;

  _Phase get _phase {
    if (_checkoutAt != null) return _Phase.done;
    if (_breakStartAt != null) return _Phase.onBreak;
    if (_checkinAt != null) return _Phase.working;
    return _Phase.before;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase != _Phase.before && _phase != _Phase.done) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _workedSinceCheckin() {
    if (_checkinAt == null) return Duration.zero;
    final end = _checkoutAt ?? DateTime.now();
    final raw = end.difference(_checkinAt!);
    final breakDur = _accumulatedBreak +
        (_breakStartAt != null
            ? DateTime.now().difference(_breakStartAt!)
            : Duration.zero);
    final net = raw - breakDur;
    return net.isNegative ? Duration.zero : net;
  }

  void _doCheckin() {
    if (!_canCheckin()) return;
    final now = DateTime.now();
    final job = Dummy.jobById(widget.jobId);
    final isLate = now.isAfter(job.startAt.add(const Duration(minutes: 5)));

    if (isLate && _lateReason == null) {
      _showReasonSheet(
        title: '지각 사유',
        reasons: const [
          '대중교통 지연',
          '도로 정체',
          '몸이 안 좋음',
          '길을 헤맸음',
          '기타',
        ],
        onPick: (r) {
          setState(() {
            _lateReason = r;
            _checkinAt = now;
          });
          _snack('출근 체크인 완료 · 지각 사유: $r');
        },
      );
      return;
    }

    setState(() => _checkinAt = now);
    _snack('출근 체크인 완료 (목업)');
  }

  void _doCheckout() {
    if (_phase != _Phase.working) return;
    final job = Dummy.jobById(widget.jobId);
    final now = DateTime.now();
    final isEarly = now.isBefore(job.endAt.subtract(const Duration(minutes: 5)));

    if (isEarly && _earlyLeaveReason == null) {
      _showReasonSheet(
        title: '조퇴 사유',
        reasons: const [
          '몸이 안 좋음',
          '개인 일정',
          '업무 조기 종료',
          '사장님 협의',
          '기타',
        ],
        onPick: (r) {
          setState(() {
            _earlyLeaveReason = r;
            _checkoutAt = now;
          });
          _snack('퇴근 체크아웃 완료 · 조퇴 사유: $r');
        },
      );
      return;
    }

    setState(() => _checkoutAt = now);
    _snack('퇴근 체크아웃 완료 (목업)');
  }

  void _toggleBreak() {
    if (_phase == _Phase.working) {
      setState(() => _breakStartAt = DateTime.now());
      _snack('휴식 시작');
    } else if (_phase == _Phase.onBreak) {
      final dur = DateTime.now().difference(_breakStartAt!);
      setState(() {
        _accumulatedBreak += dur;
        _breakStartAt = null;
      });
      _snack('휴식 종료 · 이번 휴식 ${_fmtDuration(dur)}');
    }
  }

  bool _canCheckin() {
    if (_checkinAt != null) return false;
    switch (_method) {
      case _CheckMethod.gps:
        return _withinRange;
      case _CheckMethod.qr:
      case _CheckMethod.pin:
        return false;
      case _CheckMethod.approval:
        return true;
    }
  }

  String _primaryButtonLabel() {
    switch (_phase) {
      case _Phase.before:
        switch (_method) {
          case _CheckMethod.gps:
            return _withinRange ? '출근 체크인' : '근무지 100m 이내에서 다시 시도';
          case _CheckMethod.qr:
            return 'QR 스캔';
          case _CheckMethod.pin:
            return 'PIN 입력';
          case _CheckMethod.approval:
            return '사장님께 승인 요청';
        }
      case _Phase.working:
        return '퇴근 체크아웃';
      case _Phase.onBreak:
        return '휴식 종료';
      case _Phase.done:
        return '근무 완료';
    }
  }

  void _onPrimary() {
    switch (_phase) {
      case _Phase.before:
        switch (_method) {
          case _CheckMethod.gps:
            _doCheckin();
            break;
          case _CheckMethod.qr:
            _openQrSheet();
            break;
          case _CheckMethod.pin:
            _openPinSheet();
            break;
          case _CheckMethod.approval:
            _openApprovalSheet();
            break;
        }
        break;
      case _Phase.working:
        _doCheckout();
        break;
      case _Phase.onBreak:
        _toggleBreak();
        break;
      case _Phase.done:
        break;
    }
  }

  void _openQrSheet() {
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
            children: [
              const Text('근무지 QR 코드 스캔',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Stack(
                  children: [
                    Center(
                      child: Icon(Icons.qr_code_scanner,
                          size: 80, color: AppColors.brandDark),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.fromBorderSide(
                                BorderSide(
                                    color: AppColors.brandDark, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('매장에 비치된 QR 코드를 사각형 안에 맞춰주세요.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _checkinAt = DateTime.now());
                  _snack('QR 인증 출근 완료 (목업)');
                },
                child: const Text('스캔 성공 (목업)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPinSheet() {
    final ctrl = TextEditingController();
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
                const Text('근무지 PIN 입력',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '사장님이 매일 알려주는 4자리 PIN을 입력하세요. (목업: 아무 4자리)',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 12),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    counterText: '',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().length != 4) {
                      _snack('4자리를 입력해주세요');
                      return;
                    }
                    Navigator.pop(sheetCtx);
                    setState(() => _checkinAt = DateTime.now());
                    _snack('PIN 인증 출근 완료 (목업)');
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openApprovalSheet() {
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
              const Text('사장님 승인 요청',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'GPS·QR·PIN 모두 사용이 어려울 때 사장님께 직접 출근 승인을 요청해요. 채팅방에 자동으로 메시지가 전송됩니다.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.brandDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '승인 받기 전까지는 출근으로 인정되지 않아요. 평균 응답 시간 5분.',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _checkinAt = DateTime.now());
                  _snack('사장님 승인 요청 전송 → 자동 출근 처리 (목업)');
                },
                child: const Text('승인 요청 보내기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReasonSheet({
    required String title,
    required List<String> reasons,
    required ValueChanged<String> onPick,
  }) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ...reasons.map((r) => ListTile(
                  title: Text(r),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onPick(r);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _openPhotoSheet() {
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
              const Text('근무지 인증샷',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                '근무지 입구나 본인 사진을 1장 업로드해주세요. 분쟁 발생 시 증빙 자료로 사용돼요.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        setState(() => _photoVerified = true);
                        _snack('사진 업로드 완료 (목업)');
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('카메라'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        setState(() => _photoVerified = true);
                        _snack('갤러리에서 첨부 완료 (목업)');
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('갤러리'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMemoSheet() {
    final ctrl = TextEditingController(text: _memo);
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
                const Text('근무 메모·인수인계',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  '추가 업무·이슈·다음 근무자에게 전할 내용을 적어주세요.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '예) 18시쯤 손님 많았음 / 우유 재고 부족',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _memo = ctrl.text);
                    _snack('메모 저장 (목업)');
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openContactSheet() {
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
              title: const Text('안심번호 통화'),
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
              leading: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.brandDark),
              title: const Text('채팅방 열기'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('채팅방 진입 (목업)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency_outlined,
                  color: AppColors.danger),
              title: const Text('SOS 도움 요청'),
              subtitle: const Text(
                '등록된 긴급연락처에 위치·상황 즉시 전송',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _snack('SOS 발동 (목업)');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareReceipt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('근무 확인서 공유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('아래 정보가 포함된 PDF를 생성합니다.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            const Text('• 근무 일시·장소·시간\n• 출퇴근 GPS 좌표\n• 인증샷·메모\n• 정산 금액',
                style: TextStyle(fontSize: 12, height: 1.6)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            onPressed: () {
              Navigator.pop(context);
              _snack('PDF 생성 → 공유 시트 (목업)');
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final job = Dummy.jobById(widget.jobId);
    final worked = _workedSinceCheckin();
    final hourlyRate = job.payType == '시급' ? job.pay : (job.pay / 8).round();
    final accruedPay =
        (worked.inSeconds * hourlyRate / 3600).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('출퇴근 체크'),
        actions: [
          IconButton(
            tooltip: '인증샷',
            icon: Icon(
              _photoVerified
                  ? Icons.image_outlined
                  : Icons.add_a_photo_outlined,
              color: _photoVerified ? AppColors.brandDark : null,
            ),
            onPressed: _openPhotoSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Job header
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
                    _PhaseBadge(phase: _phase),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16, color: AppColors.brandDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)} ~ ${fmtTime(job.endAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live working ticker
          if (_phase == _Phase.working || _phase == _Phase.onBreak)
            _LiveCard(
              worked: worked,
              accruedPay: accruedPay,
              breakDur: _accumulatedBreak +
                  (_breakStartAt != null
                      ? DateTime.now().difference(_breakStartAt!)
                      : Duration.zero),
              onBreak: _phase == _Phase.onBreak,
            ),

          // Method picker (출근 전 only)
          if (_phase == _Phase.before) ...[
            const Text('체크인 방식',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: Row(
                children: _CheckMethod.values.map((m) {
                  final on = _method == m;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _method = m),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: on ? AppColors.brandSoft : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: on
                                  ? AppColors.brandDark
                                  : AppColors.divider,
                              width: on ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(m.icon,
                                  color: on
                                      ? AppColors.brandDark
                                      : AppColors.textMuted,
                                  size: 22),
                              const SizedBox(height: 4),
                              Text(m.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: on
                                          ? AppColors.brandDark
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // GPS card (only when method = gps)
          if (_method == _CheckMethod.gps && _phase == _Phase.before)
            _GpsCard(
              withinRange: _withinRange,
              distanceMeters: _distanceMeters,
              onApprovalRequest: _openApprovalSheet,
            ),
          if (_method == _CheckMethod.gps && _phase == _Phase.before)
            const SizedBox(height: 16),

          // Quick action grid (after check-in)
          if (_phase == _Phase.working || _phase == _Phase.onBreak) ...[
            const Text('빠른 작업',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
              children: [
                _ActionTile(
                  icon: _phase == _Phase.onBreak
                      ? Icons.play_arrow
                      : Icons.coffee_outlined,
                  label: _phase == _Phase.onBreak ? '휴식 종료' : '휴식 시작',
                  highlight: _phase == _Phase.onBreak,
                  onTap: _toggleBreak,
                ),
                _ActionTile(
                  icon: _photoVerified
                      ? Icons.check_circle_outline
                      : Icons.photo_camera_outlined,
                  label: _photoVerified ? '인증완료' : '인증샷',
                  highlight: _photoVerified,
                  onTap: _openPhotoSheet,
                ),
                _ActionTile(
                  icon: Icons.note_alt_outlined,
                  label: _memo.isEmpty ? '메모' : '메모 ✓',
                  onTap: _openMemoSheet,
                ),
                _ActionTile(
                  icon: Icons.support_agent,
                  label: '사장님',
                  onTap: _openContactSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Time cards
          _TimeCard(
            label: '출근',
            time: _checkinAt,
            placeholder: '출근 전',
            badge: _lateReason == null ? null : '지각: $_lateReason',
          ),
          const SizedBox(height: 8),
          _TimeCard(
            label: '퇴근',
            time: _checkoutAt,
            placeholder: '퇴근 전',
            badge:
                _earlyLeaveReason == null ? null : '조퇴: $_earlyLeaveReason',
          ),

          // Done summary
          if (_phase == _Phase.done) ...[
            const SizedBox(height: 16),
            _DoneCard(
              workedHours: worked.inSeconds / 3600,
              breakDur: _accumulatedBreak,
              estimatedPay: accruedPay,
              onShare: _shareReceipt,
              onViewPay: () => context.push('/me/payments'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _phase == _Phase.done ||
                    (_phase == _Phase.before &&
                        _method == _CheckMethod.gps &&
                        !_withinRange)
                ? null
                : _onPrimary,
            child: Text(_primaryButtonLabel()),
          ),
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final _Phase phase;
  const _PhaseBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color bg;
    late Color fg;
    switch (phase) {
      case _Phase.before:
        text = '출근 전';
        bg = AppColors.chipBg;
        fg = AppColors.textMuted;
        break;
      case _Phase.working:
        text = '근무 중';
        bg = AppColors.brandSoft;
        fg = AppColors.brandDark;
        break;
      case _Phase.onBreak:
        text = '휴식 중';
        bg = const Color(0xFFFFF6E5);
        fg = const Color(0xFFB45309);
        break;
      case _Phase.done:
        text = '근무 완료';
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF1F8E48);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final Duration worked;
  final int accruedPay;
  final Duration breakDur;
  final bool onBreak;
  const _LiveCard({
    required this.worked,
    required this.accruedPay,
    required this.breakDur,
    required this.onBreak,
  });

  String _hms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = onBreak ? const Color(0xFFB45309) : AppColors.brandDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                onBreak ? Icons.coffee_outlined : Icons.timer_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(onBreak ? '휴식 중' : '근무 중',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (breakDur.inSeconds > 0)
                Text('휴식 누적 ${breakDur.inMinutes}분',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_hms(worked),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1,
              )),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('현재까지 적립 ${fmtMoney(accruedPay)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  final bool withinRange;
  final double distanceMeters;
  final VoidCallback onApprovalRequest;
  const _GpsCard({
    required this.withinRange,
    required this.distanceMeters,
    required this.onApprovalRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                withinRange ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: withinRange ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  withinRange
                      ? '근무지 100m 이내'
                      : '근무지 100m 이상 떨어져 있어요',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: withinRange
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '현재 위치 → 근무지: ${distanceMeters.toStringAsFixed(1)}m',
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
          if (!withinRange) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onApprovalRequest,
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: const Text('사장님께 승인 요청하기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.brandDark : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: highlight ? AppColors.brandSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.brandDark : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final DateTime? time;
  final String placeholder;
  final String? badge;
  const _TimeCard({
    required this.label,
    required this.time,
    required this.placeholder,
    this.badge,
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
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge!,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
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

class _DoneCard extends StatelessWidget {
  final double workedHours;
  final Duration breakDur;
  final int estimatedPay;
  final VoidCallback onShare;
  final VoidCallback onViewPay;
  const _DoneCard({
    required this.workedHours,
    required this.breakDur,
    required this.estimatedPay,
    required this.onShare,
    required this.onViewPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF1F8E48)),
              SizedBox(width: 8),
              Text('근무 완료',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F8E48))),
            ],
          ),
          const SizedBox(height: 12),
          _row('정산 대상 시간', '${workedHours.toStringAsFixed(2)}h'),
          _row('휴식 차감', '- ${breakDur.inMinutes}분', muted: true),
          const Divider(height: 16, color: AppColors.divider),
          _row('예상 수입', fmtMoney(estimatedPay), highlight: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('확인서 공유'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onViewPay,
                  child: const Text('정산 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v,
      {bool muted = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(k,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          Text(v,
              style: TextStyle(
                fontSize: highlight ? 16 : 13,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? const Color(0xFF1F8E48)
                    : muted
                        ? AppColors.textMuted
                        : AppColors.text,
              )),
        ],
      ),
    );
  }
}
