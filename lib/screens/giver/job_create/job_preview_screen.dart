import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/api_models/job.dart';
import '../../../models/api_models/job_photo.dart';

class JobPreviewScreen extends StatelessWidget {
  final Job job;
  final List<JobPhoto> photos;
  const JobPreviewScreen({
    super.key,
    required this.job,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미리보기'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('편집으로'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty)
              SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) => Image.network(
                    photos[i].signedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 240,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 64),
                ),
              ),
            Container(
              color: const Color(0xFFFFF6E5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 18, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '워커에게 보일 화면 미리보기예요. 등록 전에는 지원·문의가 진행되지 않아요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    '${job.wageWon.toString()}원',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(job.description),
                  const SizedBox(height: 16),
                  Text('일정: ${job.scheduleText ?? "협의"}'),
                  const SizedBox(height: 4),
                  Text('위치: ${job.locationAddress}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
