import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter/rendering.dart';
import 'package:geodraw/geodraw.dart';

/// Utility class for capturing canvas as image
class CanvasCapture {
  /// Capture the GeoDraw canvas as PNG image bytes
  ///
  /// [dagManager] - The DAG manager containing the geometry
  /// [width] - Image width in pixels (default: 800)
  /// [height] - Image height in pixels (default: 600)
  /// [backgroundColor] - Background color (default: white)
  /// [showGrid] - Whether to show grid (default: false for cleaner thumbnails)
  ///
  /// Returns PNG image bytes or null on failure
  static Future<Uint8List?> captureAsPng({
    required DAGManager dagManager,
    int width = 800,
    int height = 600,
    Color backgroundColor = Colors.white,
    bool showGrid = false,
  }) async {
    try {
      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(width.toDouble(), height.toDouble());

      // Create viewport for the capture
      final viewport = Viewport(
        center: Offset.zero,
        zoom: 1.0,
        gridVisible: showGrid,
        canvasSize: size,
      );

      // Draw background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );

      // Draw grid if enabled
      if (showGrid) {
        _drawGrid(canvas, size, viewport);
      }

      // Apply viewport transformation
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(viewport.zoom);
      canvas.translate(-viewport.center.dx, -viewport.center.dy);

      // Set clip bounds in transformed coordinate space (required for GeoLine._getLinePoints())
      // After transformation, objects are drawn in world coordinates
      // Calculate the world coordinate bounds that correspond to the screen bounds
      final worldLeft = viewport.center.dx - size.width / (2 * viewport.zoom);
      final worldTop = viewport.center.dy - size.height / (2 * viewport.zoom);
      final worldWidth = size.width / viewport.zoom;
      final worldHeight = size.height / viewport.zoom;
      canvas.clipRect(Rect.fromLTWH(worldLeft, worldTop, worldWidth, worldHeight));

      // Draw all objects in topological order
      final sortedNodes = dagManager.topologicalSort();
      for (final node in sortedNodes) {
        final object = node.object;
        if (!object.visible) continue;

        final paint = Paint();
        final style = object.style;
        paint
          ..color = style.filled ? style.fillColor : style.strokeColor
          ..strokeWidth = style.strokeWidth
          ..style = style.filled ? PaintingStyle.fill : PaintingStyle.stroke;

        object.draw(canvas, paint);
      }

      canvas.restore();

      // End recording and convert to image
      debugPrint('DEBUG: Recording picture...');
      final picture = recorder.endRecording();

      debugPrint('DEBUG: Converting to image...');
      final image = await picture.toImage(width, height);

      // Convert to PNG bytes
      debugPrint('DEBUG: Encoding to PNG...');
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('ERROR: PNG encoding returned null');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      debugPrint('DEBUG: Canvas capture complete, ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      debugPrint('ERROR: Exception capturing canvas: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Capture canvas from a GlobalKey (for capturing actual widget)
  ///
  /// [key] - GlobalKey attached to RepaintBoundary wrapping the canvas
  ///
  /// Returns PNG image bytes or null on failure
  static Future<Uint8List?> captureFromKey(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('Could not find RenderRepaintBoundary');
        return null;
      }

      // Capture the boundary as an image
      final image = await boundary.toImage(pixelRatio: 2.0);

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing from key: $e');
      return null;
    }
  }

  /// Helper method to draw grid
  static void _drawGrid(Canvas canvas, Size size, Viewport viewport) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final baseSpacing = 50.0;
    final spacing = baseSpacing * viewport.zoom;

    final offsetX = (viewport.center.dx * viewport.zoom) % spacing;
    final offsetY = (viewport.center.dy * viewport.zoom) % spacing;

    // Draw vertical lines
    for (double x = size.width / 2 + offsetX % spacing;
        x < size.width;
        x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double x = size.width / 2 + offsetX % spacing; x > 0; x -= spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = size.height / 2 + offsetY % spacing;
        y < size.height;
        y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double y = size.height / 2 + offsetY % spacing; y > 0; y -= spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }
}
