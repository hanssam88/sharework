import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final String docType; // terms / privacy / guide
  const LegalScreen({super.key, required this.docType});

  String get _title {
    switch (docType) {
      case 'terms':
        return '이용약관';
      case 'privacy':
        return '개인정보 처리방침';
      case 'guide':
        return '이용가이드';
      default:
        return '문서';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Dummy.legalContents[docType] ?? '문서를 불러올 수 없어요.';
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            body,
            style: const TextStyle(
                fontSize: 14, height: 1.7, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}
