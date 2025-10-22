import 'package:flutter_test/flutter_test.dart';
import 'package:geoapp/services/directus_file_service.dart';
import 'package:geoapp/services/supabase_file_service.dart';

void main() {
  group('DirectusFileService.getFileUrl', () {
    test('builds base URL without params', () {
      final svc = DirectusFileService(baseUrl: 'http://localhost:8055');
      final url = svc.getFileUrl('abc123');
      expect(url, 'http://localhost:8055/assets/abc123');
    });

    test('builds URL with params', () {
      final svc = DirectusFileService(baseUrl: 'http://localhost:8055');
      final url = svc.getFileUrl('abc123', width: 300, height: 200, fit: 'cover', quality: 80);
      expect(url, 'http://localhost:8055/assets/abc123?width=300&height=200&fit=cover&quality=80');
    });
  });

  group('SupabaseFileService.getPublicUrl', () {
    test('returns public URL', () {
      final svc = SupabaseFileService(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
      );
      final url = svc.getPublicUrl('user1/thumbnails/p.png');
      expect(
        url,
        'https://example.supabase.co/storage/v1/object/public/problem-images/user1/thumbnails/p.png',
      );
    });
  });
}
