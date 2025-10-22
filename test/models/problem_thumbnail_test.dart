import 'package:flutter_test/flutter_test.dart';
import 'package:geoapp/models/problem.dart';

void main() {
  group('Problem thumbnail parsing', () {
    test('prefers Directus thumbnail object id when present', () {
      final data = {
        'id': '1',
        'title': 't',
        'description': 'd',
        'difficulty': 'beginner',
        'category': 'geometry',
        'thumbnail': {'id': 'file_abc'},
        'date_created': '2025-10-04T10:00:00.000Z',
        'date_updated': '2025-10-04T10:00:00.000Z',
      };
      final p = Problem.fromJson(data);
      expect(p.thumbnailId, 'file_abc');
    });

    test('uses Supabase storage path when thumbnail_id provided', () {
      final data = {
        'id': '1',
        'title': 't',
        'description': 'd',
        'difficulty': 'beginner',
        'category': 'geometry',
        'thumbnail_id': 'user1/thumbnails/a.png',
        'created_at': '2025-10-04T10:00:00.000Z',
        'updated_at': '2025-10-04T10:00:00.000Z',
      };
      final p = Problem.fromJson(data);
      expect(p.thumbnailId, 'user1/thumbnails/a.png');
    });
  });
}
