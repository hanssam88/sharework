import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

String fmtMoney(int won) {
  final formatter = NumberFormat('#,###');
  return '${formatter.format(won)}원';
}

String fmtDate(DateTime dt) => DateFormat('M월 d일 (E)', 'ko_KR').format(dt);
String fmtTime(DateTime dt) => DateFormat('a h:mm', 'ko_KR').format(dt);
String fmtRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return DateFormat('M월 d일').format(dt);
}

class TagChip extends StatelessWidget {
  final String label;
  final bool primary;
  const TagChip(this.label, {super.key, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary ? AppColors.brandSoft : AppColors.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: primary ? AppColors.brandDark : AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  final double? distanceKm;
  const JobCard({super.key, required this.job, this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (job.sameDayPayment) const TagChip('당일지급', primary: true),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      job.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  if (distanceKm != null)
                    Text(
                      '${distanceKm!.toStringAsFixed(1)}km',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textFaint),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${fmtDate(job.startAt)} · ${fmtTime(job.startAt)}~${fmtTime(job.endAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${job.payType} ${fmtMoney(job.pay)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${job.hiredCount}/${job.personnel}명',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              if (job.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: job.tags.map((t) => TagChip('#$t')).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.chipBg,
                  child:
                      Icon(Icons.person, size: 16, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  review.fromUserName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  fmtRelative(review.createdAt),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textFaint),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: _stars(review.rating)),
            const SizedBox(height: 6),
            Text(
              review.jobTitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(review.content,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }

  List<Widget> _stars(double rating) {
    return List.generate(5, (i) {
      final filled = i < rating.round();
      return Icon(
        filled ? Icons.star : Icons.star_border,
        size: 14,
        color: filled ? const Color(0xFFFFC400) : AppColors.textFaint,
      );
    });
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification noti;
  final VoidCallback? onTap;
  const NotificationCard({super.key, required this.noti, this.onTap});

  IconData get _icon {
    switch (noti.kind) {
      case NotificationKind.hire:
        return Icons.celebration_outlined;
      case NotificationKind.application:
        return Icons.send_outlined;
      case NotificationKind.complete:
        return Icons.check_circle_outline;
      case NotificationKind.review:
        return Icons.rate_review_outlined;
      case NotificationKind.system:
        return Icons.campaign_outlined;
    }
  }

  Color get _iconBg {
    switch (noti.kind) {
      case NotificationKind.hire:
        return AppColors.brandSoft;
      case NotificationKind.application:
        return const Color(0xFFEEF4FF);
      case NotificationKind.complete:
        return const Color(0xFFE8F8EE);
      case NotificationKind.review:
        return const Color(0xFFFFF6E5);
      case NotificationKind.system:
        return AppColors.chipBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: noti.isRead ? null : AppColors.brandSoft.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 20, color: AppColors.brandDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          noti.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        fmtRelative(noti.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.body,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textFaint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
