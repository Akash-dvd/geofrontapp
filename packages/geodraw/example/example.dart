import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

/// Example demonstrating the basic usage of the GeoDraw package
void main() {
  runApp(const GeoDrawExample());
}

class GeoDrawExample extends StatelessWidget {
  const GeoDrawExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoDraw Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GeoDrawDemo(),
    );
  }
}

class GeoDrawDemo extends StatefulWidget {
  const GeoDrawDemo({super.key});

  @override
  State<GeoDrawDemo> createState() => _GeoDrawDemoState();
}

class _GeoDrawDemoState extends State<GeoDrawDemo> {
  late DAGManager dagManager;

  @override
  void initState() {
    super.initState();
    dagManager = DAGManager();
    _createInitialConstruction();
  }

  void _createInitialConstruction() {
    // Create three free points
    final p1 = GeoPointer(
      id: 'p1',
      label: 'A',
      x: 100,
      y: 100,
      color: Colors.red,
    );
    final p2 = GeoPointer(
      id: 'p2',
      label: 'B',
      x: 300,
      y: 100,
      color: Colors.red,
    );
    final p3 = GeoPointer(
      id: 'p3',
      label: 'C',
      x: 200,
      y: 250,
      color: Colors.red,
    );

    dagManager.addObject(p1, []);
    dagManager.addObject(p2, []);
    dagManager.addObject(p3, []);

    // Create lines connecting the points
    final line1 = GeoLine2P.fromPoints(
      id: 'l1',
      label: 'AB',
      p1: p1,
      p2: p2,
      color: Colors.blue,
    );
    final line2 = GeoLine2P.fromPoints(
      id: 'l2',
      label: 'BC',
      p1: p2,
      p2: p3,
      color: Colors.blue,
    );
    final line3 = GeoLine2P.fromPoints(
      id: 'l3',
      label: 'CA',
      p1: p3,
      p2: p1,
      color: Colors.blue,
    );

    dagManager.addObject(line1, ['p1', 'p2']);
    dagManager.addObject(line2, ['p2', 'p3']);
    dagManager.addObject(line3, ['p3', 'p1']);

    // Create a circle through the three points (circumcircle)
    final circle = GeoCircle3P.fromPoints(
      id: 'c1',
      label: 'Circumcircle',
      p1: p1,
      p2: p2,
      p3: p3,
      color: Colors.green,
    );

    if (circle != null) {
      dagManager.addObject(circle, ['p1', 'p2', 'p3']);
    }

    // Create midpoints
    final m1 = GeoMidpoint.fromPoints(
      id: 'm1',
      label: 'M_AB',
      p1: p1,
      p2: p2,
      color: Colors.orange,
    );
    final m2 = GeoMidpoint.fromPoints(
      id: 'm2',
      label: 'M_BC',
      p1: p2,
      p2: p3,
      color: Colors.orange,
    );
    final m3 = GeoMidpoint.fromPoints(
      id: 'm3',
      label: 'M_CA',
      p1: p3,
      p2: p1,
      color: Colors.orange,
    );

    dagManager.addObject(m1, ['p1', 'p2']);
    dagManager.addObject(m2, ['p2', 'p3']);
    dagManager.addObject(m3, ['p3', 'p1']);

    dagManager.propagateUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoDraw Package Demo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: SimpleGeoDrawPainter(dagManager),
              child: Container(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Construction Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Total objects: ${dagManager.nodeCount}'),
                Text(
                  'Objects: ${dagManager.nodes.values.map((n) => n.object.label).join(", ")}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'This demo shows:\n'
                  '• 3 free points (A, B, C)\n'
                  '• 3 lines forming a triangle\n'
                  '• 1 circumcircle through all 3 points\n'
                  '• 3 midpoints of the triangle sides',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple painter that renders the DAG objects
class SimpleGeoDrawPainter extends CustomPainter {
  final DAGManager dagManager;

  SimpleGeoDrawPainter(this.dagManager);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Sort objects by depth to draw in correct order
    final sortedNodes = dagManager.topologicalSort();

    // Draw all objects
    for (final node in sortedNodes) {
      if (node.object.visible) {
        final paint = Paint()
          ..color = node.object.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        node.object.draw(canvas, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SimpleGeoDrawPainter oldDelegate) {
    return oldDelegate.dagManager != dagManager;
  }
}
