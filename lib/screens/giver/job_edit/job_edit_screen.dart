import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dummy_data.dart';
import '../../../theme/app_theme.dart';

class JobEditScreen extends StatefulWidget {
  final int jobId;
  const JobEditScreen({super.key, required this.jobId});

  @override
  State<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends State<JobEditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _personnelCtrl;
  late TextEditingController _payCtrl;
  late bool _sameDayPay;
  late bool _foodProvided;
  late bool _extraPay;

  @override
  void initState() {
    super.initState();
    final job = Dummy.jobById(widget.jobId);
    _titleCtrl = TextEditingController(text: job.title);
    _addressCtrl = TextEditingController(text: job.address);
    _descCtrl = TextEditingController(text: job.description);
    _personnelCtrl = TextEditingController(text: '${job.personnel}');
    _payCtrl = TextEditingController(text: '${job.pay}');
    _sameDayPay = job.sameDayPayment;
    _foodProvided = job.foodProvided;
    _extraPay = job.extraPay;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _personnelCtrl.dispose();
    _payCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공고가 수정되었습니다 (목업)')),
    );
    context.pop();
  }

  void _close() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('공고 마감'),
        content: const Text('공고를 마감하면 더 이상 지원을 받을 수 없어요. 마감하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공고가 마감되었습니다 (목업)')),
              );
              context.pop();
            },
            child: const Text('마감하기'),
          ),
        ],
      ),
    );
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('공고 삭제'),
        content: const Text('삭제한 공고는 복구할 수 없습니다. 정말 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공고가 삭제되었습니다 (목업)')),
              );
              context.pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공고 수정'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'close') _close();
              if (v == 'delete') _delete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'close', child: Text('공고 마감')),
              PopupMenuItem(
                value: 'delete',
                child: Text('공고 삭제',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const _Label('공고 제목'),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '제목을 입력해주세요'),
          ),
          const SizedBox(height: 16),
          const _Label('일할 장소'),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(hintText: '주소'),
          ),
          const SizedBox(height: 16),
          const _Label('필요한 인원'),
          TextField(
            controller: _personnelCtrl,
            decoration: const InputDecoration(suffixText: '명'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const _Label('임금'),
          TextField(
            controller: _payCtrl,
            decoration: const InputDecoration(suffixText: '원'),
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sameDayPay,
            onChanged: (v) => setState(() => _sameDayPay = v),
            title: const Text('당일지급', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.brandDark,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _foodProvided,
            onChanged: (v) => setState(() => _foodProvided = v),
            title: const Text('식사제공', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.brandDark,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _extraPay,
            onChanged: (v) => setState(() => _extraPay = v),
            title: const Text('교통비지원', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.brandDark,
          ),
          const SizedBox(height: 16),
          const _Label('상세 설명'),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(hintText: '업무 내용을 자세히 적어주세요'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('수정 완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
