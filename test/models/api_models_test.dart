import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/models/api_models/job.dart';
import 'package:sharework_mockup/models/api_models/profile.dart';
import 'package:sharework_mockup/models/api_models/job_category.dart';

void main() {
  group('Profile', () {
    test('fromJson includes public_id', () {
      final json = {
        'id': 'p-1',
        'phone': '+821012345678',
        'name': 'Hong',
        'role': 'worker',
        'public_id': 'PUB123',
        'created_at': '2026-05-11T00:00:00Z',
        'updated_at': '2026-05-11T00:00:00Z',
      };
      final p = Profile.fromJson(json);
      expect(p.publicId, 'PUB123');
      expect(p.role, 'worker');
    });
  });

  group('Job', () {
    test('fromJson with giver + photos', () {
      final json = {
        'id': 'j-1',
        'title': 't',
        'description': 'd',
        'wage_won': 1000,
        'status': 'active',
        'category_id': 'c-1',
        'location_address': 'Seoul',
        'giver': {'public_id': 'gpid', 'name': 'gname'},
        'photos': [
          {'id': 'p1', 'position': 1, 'signed_url': 'https://example/sig'}
        ],
        'created_at': '2026-05-11T00:00:00Z',
        'updated_at': '2026-05-11T00:00:00Z',
      };
      final job = Job.fromJson(json);
      expect(job.giver?.publicId, 'gpid');
      expect(job.photos[0].position, 1);
      expect(job.photos[0].signedUrl, 'https://example/sig');
    });

    test('fromJson without photos defaults to empty list (M3 정정)', () {
      final json = {
        'id': 'j-1',
        'title': 't',
        'description': 'd',
        'wage_won': 1000,
        'status': 'active',
        'category_id': 'c-1',
        'location_address': 'Seoul',
        'created_at': '2026-05-11T00:00:00Z',
        'updated_at': '2026-05-11T00:00:00Z',
      };
      final job = Job.fromJson(json);
      expect(job.photos, isEmpty);
      expect(job.giver, isNull);
    });
  });

  group('JobCategory', () {
    test('fromJson with emoji', () {
      final json = {
        'id': 'c-1',
        'slug': 'restaurant',
        'name': '식당',
        'emoji': '🍽'
      };
      final c = JobCategory.fromJson(json);
      expect(c.emoji, '🍽');
    });

    test('fromJson without emoji is null', () {
      final json = {'id': 'c-1', 'slug': 'restaurant', 'name': '식당'};
      final c = JobCategory.fromJson(json);
      expect(c.emoji, isNull);
    });
  });
}
