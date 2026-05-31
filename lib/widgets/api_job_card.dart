import 'package:flutter/material.dart';

import '../models/api_models/job.dart' as api;
import '../theme/app_theme.dart';
import 'shared.dart' show fmtMoney;

/// Renders an [api.Job] in the mockup JobCard layout.
///
/// Per restoration policy (a), fields the backend does not expose are omitted
/// (no `sameDayPayment` chip, no distance, no `payType` prefix, no
/// headcount, no tags). Structured start/end times are replaced by the free
/// `scheduleText` line, shown only when present.
class ApiJobCard extends StatelessWidget {
  final api.Job job;
  final VoidCallback? onTap;
  const ApiJobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final schedule = job.scheduleText?.trim() ?? '';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      job.locationAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              if (schedule.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                fmtMoney(job.wageWon),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
