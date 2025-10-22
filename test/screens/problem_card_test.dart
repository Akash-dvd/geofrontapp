import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geoapp/models/problem.dart';
import 'package:geoapp/screens/problem_management_screen.dart';

void main() {
  group('ProblemCard', () {
    testWidgets('uses Supabase public URL when thumbnailId is a storage path', (tester) async {
      final problem = Problem(
        id: 'p1',
        title: 'With Image',
        description: 'Desc',
        difficulty: ProblemDifficulty.beginner,
        category: ProblemCategory.geometry,
        thumbnailId: 'user123/thumbnails/p1.png',
        createdAt: DateTime(2025, 10, 4, 10),
        updatedAt: DateTime(2025, 10, 4, 11),
      );

      var tapped = false;
      var edited = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProblemCard(
              problem: problem,
              onTap: () => tapped = true,
              onEdit: () => edited = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // There should be a NetworkImage with a Supabase public URL prefix.
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final provider = imageWidget.image as NetworkImage;
      expect(provider.url, contains('/storage/v1/object/public/problem-images/'));
      expect(provider.url, contains('user123/thumbnails/p1.png'));

      // Buttons exist and callbacks are wired
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.tap(find.text('Delete'));

      expect(edited, isTrue);
      expect(deleted, isTrue);
    });
  });
}
