import 'package:flutter/material.dart';

import '../models/api_models/job_photo.dart';

/// 사진 0~5장 그리드 위젯.
///
/// - 부모가 photos 리스트를 관리 (StatelessWidget)
/// - 0~5장 ReorderableListView (가로) + 5장 미만 시 추가 버튼 노출
/// - X 버튼 → onRemove(photoId)
/// - 드래그 reorder → onReorder(새 순서의 photoId 리스트)
class PhotoUploadGrid extends StatelessWidget {
  final List<JobPhoto> photos;
  final VoidCallback onAdd;
  final void Function(String photoId) onRemove;
  final void Function(List<String> newOrder) onReorder;

  const PhotoUploadGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('사진 ${photos.length}/5'),
        ),
        SizedBox(
          height: 100,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: photos.length,
            onReorder: (oldIdx, newIdx) {
              final list = photos.map((p) => p.id).toList();
              if (newIdx > oldIdx) newIdx -= 1;
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              onReorder(list);
            },
            itemBuilder: (ctx, i) {
              final p = photos[i];
              return Container(
                key: ValueKey(p.id),
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.signedUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => onRemove(p.id),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (photos.length < 5)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('+ 사진 추가'),
            ),
          ),
      ],
    );
  }
}
