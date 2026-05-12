import 'package:flutter/material.dart';

import '../../data/repositories/job_repository.dart';
import '../../models/api_models/job.dart' as api;
import '../../models/api_models/job_photo.dart' as api;

class JobInfoScreen extends StatefulWidget {
  final String jobId;
  final JobRepository? jobRepository;
  const JobInfoScreen({super.key, required this.jobId, this.jobRepository});

  @override
  State<JobInfoScreen> createState() => _JobInfoScreenState();
}

class _JobInfoScreenState extends State<JobInfoScreen> {
  late final JobRepository _repo;
  late Future<api.Job> _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.jobRepository ?? JobRepository.fromApi();
    _future = _repo.fetchJob(widget.jobId);
  }

  void _retry() {
    setState(() => _future = _repo.fetchJob(widget.jobId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공고 상세')),
      body: FutureBuilder<api.Job>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('연결이 불안정합니다'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _retry, child: const Text('다시 시도')),
                ],
              ),
            );
          }
          final job = snap.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _PhotoCarousel(photos: job.photos),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${job.wageWon}원 · ${job.locationAddress}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 16),
                    if (job.giver != null)
                      Text('공고 등록자: ${job.giver!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (job.scheduleText != null) ...[
                      const SizedBox(height: 8),
                      Text('일정: ${job.scheduleText}'),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(job.description,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  final List<api.JobPhoto> photos;
  const _PhotoCarousel({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        key: const Key('photo-placeholder'),
        height: 240,
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.image, size: 64, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Image.network(
          photos[i].signedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      ),
    );
  }
}
