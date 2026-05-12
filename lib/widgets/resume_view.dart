import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// 이력서 본문 — 프로필 탭과 마이페이지/이력서 화면에서 공유.
class ResumeView extends StatelessWidget {
  final Resume resume;
  final List<String>? userTags; // 프로필 화면에서 user.tags 표시용
  const ResumeView({super.key, required this.resume, this.userTags});

  @override
  Widget build(BuildContext context) {
    final empty = resume.headline.isEmpty &&
        resume.summary.isEmpty &&
        resume.careers.isEmpty &&
        resume.educations.isEmpty &&
        resume.skills.isEmpty;
    if (empty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('아직 이력서가 등록되지 않았어요',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (resume.headline.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, color: AppColors.brandDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resume.headline,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (resume.summary.isNotEmpty) ...[
          const _SectionTitle('자기소개'),
          const SizedBox(height: 8),
          Text(resume.summary,
              style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
        ],
        if (resume.careers.isNotEmpty) ...[
          const _SectionTitle('경력'),
          const SizedBox(height: 12),
          ...resume.careers.map((c) => _CareerCard(c: c)),
          const SizedBox(height: 16),
        ],
        if (resume.educations.isNotEmpty) ...[
          const _SectionTitle('학력'),
          const SizedBox(height: 8),
          ...resume.educations.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.school} · ${e.degree}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(e.period,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (resume.skills.isNotEmpty) ...[
          const _SectionTitle('스킬'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: resume.skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (userTags != null && userTags!.isNotEmpty) ...[
          const _SectionTitle('받은 태그'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: userTags!
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$t',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700));
  }
}

class _CareerCard extends StatelessWidget {
  final CareerEntry c;
  const _CareerCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.company,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Text(c.period,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textFaint)),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.role,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.brandDark,
                  fontWeight: FontWeight.w600)),
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(c.description,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
