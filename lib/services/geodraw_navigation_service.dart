import 'package:flutter/material.dart';

import '../models/problem.dart';

/// Service for navigating to GeoDraw functionality
/// Follows constitutional requirement for clear API boundaries
class GeoDrawNavigationService {
  /// Navigate to GeoDraw for creating a new problem
  static Future<Map<String, dynamic>?> navigateToCreate(
    BuildContext context,
  ) async {
    return await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const GeoDrawCreateScreen(),
      ),
    );
  }

  /// Navigate to GeoDraw for editing an existing problem
  static Future<Map<String, dynamic>?> navigateToEdit(
    BuildContext context,
    Problem problem,
  ) async {
    return await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => GeoDrawEditScreen(problem: problem),
      ),
    );
  }

  /// Navigate to GeoDraw for viewing a problem (read-only)
  static Future<void> navigateToView(
    BuildContext context,
    Problem problem,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeoDrawViewScreen(problem: problem),
      ),
    );
  }
}

/// Placeholder screen for GeoDraw creation functionality
/// This would be replaced with actual geodraw package integration
class GeoDrawCreateScreen extends StatelessWidget {
  const GeoDrawCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw - Create'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Mock geometry data - this would come from actual GeoDraw
              final mockGeometryData = {
                'type': 'construction',
                'objects': [
                  {
                    'id': 'point1',
                    'type': 'point',
                    'coordinates': {'x': 100, 'y': 100},
                    'label': 'A',
                  },
                  {
                    'id': 'point2',
                    'type': 'point',
                    'coordinates': {'x': 200, 'y': 100},
                    'label': 'B',
                  },
                  {
                    'id': 'line1',
                    'type': 'line',
                    'points': ['point1', 'point2'],
                    'label': 'AB',
                  },
                ],
                'constraints': [],
                'created_at': DateTime.now().toIso8601String(),
              };
              Navigator.of(context).pop(mockGeometryData);
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.draw,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'GeoDraw Create Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This is a placeholder for the geodraw package integration.\nUse the save button to return mock geometry data.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mock Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Point creation and manipulation'),
                    Text('• Line and shape drawing'),
                    Text('• Geometric constraints'),
                    Text('• Construction export'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for GeoDraw editing functionality
class GeoDrawEditScreen extends StatelessWidget {
  const GeoDrawEditScreen({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw - Edit'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Mock updated geometry data
              final updatedGeometryData = {
                ...?problem.geometryData,
                'modified_at': DateTime.now().toIso8601String(),
                'version': (problem.geometryData?['version'] ?? 0) + 1,
              };
              Navigator.of(context).pop(updatedGeometryData);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'GeoDraw Edit Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Editing: ${problem.title}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Geometry Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      problem.geometryData != null
                          ? 'Objects: ${problem.geometryData!.keys.length} properties'
                          : 'No geometry data available',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for GeoDraw viewing functionality
class GeoDrawViewScreen extends StatelessWidget {
  const GeoDrawViewScreen({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw - View'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.visibility,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'GeoDraw View Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Viewing: ${problem.title}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Problem Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Read-Only',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Difficulty: ${problem.difficulty.displayName}'),
                    Text('Category: ${problem.category.displayName}'),
                    const SizedBox(height: 8),
                    Text(
                      problem.geometryData != null
                          ? 'Geometry: ${problem.geometryData!.keys.length} properties'
                          : 'No geometry data available',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}