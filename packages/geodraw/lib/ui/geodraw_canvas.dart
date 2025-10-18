import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/dag/dag_manager.dart' hide Viewport;
import '../core/dag/dag_manager.dart' as dag show Viewport;
import '../models/canvas_object.dart';
import '../models/simple/geo_point.dart';
import '../tools/tool_manager.dart';
import '../tools/tool.dart';

/// Main canvas widget for rendering and interacting with geometric constructions
class GeoDrawCanvas extends StatefulWidget {
  final DAGManager dagManager;
  final ToolManager toolManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final bool showGrid;
  final Color backgroundColor;
  final Color gridColor;

  const GeoDrawCanvas({
    super.key,
    required this.dagManager,
    required this.toolManager,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.showGrid = true,
    this.backgroundColor = Colors.white,
    this.gridColor = Colors.grey,
  });

  @override
  State<GeoDrawCanvas> createState() => _GeoDrawCanvasState();
}

class _GeoDrawCanvasState extends State<GeoDrawCanvas> {
  dag.Viewport? _viewport;
  Offset? _lastPanPosition;
  String? _draggedObjectId;

  @override
  void initState() {
    super.initState();
    _viewport =
        widget.dagManager.viewport ??
        dag.Viewport(
          center: Offset.zero,
          zoom: 1.0,
          gridVisible: widget.showGrid,
          canvasSize: const Size(800, 600),
        );
    widget.dagManager.viewport = _viewport;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport?.canvasSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          children: [
            Positioned.fill(child: _buildCanvasContent()),
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildHistoryControls(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvasContent() {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: ClipRect(
          child: CustomPaint(
            painter: GeoDrawCanvasPainter(
              dagManager: widget.dagManager,
              viewport: _viewport!,
              selectedIds: widget.selectedIds,
              showGrid: widget.showGrid,
              backgroundColor: widget.backgroundColor,
              gridColor: widget.gridColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceVariant.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Undo',
              child: IconButton(
                icon: const Icon(Icons.undo),
                onPressed: widget.dagManager.canUndo ? _handleUndo : null,
              ),
            ),
            Tooltip(
              message: 'Redo',
              child: IconButton(
                icon: const Icon(Icons.redo),
                onPressed: widget.dagManager.canRedo ? _handleRedo : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUndo() {
    if (!widget.dagManager.canUndo) return;
    final changed = widget.dagManager.undo();
    if (changed) {
      setState(() {
        _viewport = widget.dagManager.viewport ?? _viewport;
      });
    }
  }

  void _handleRedo() {
    if (!widget.dagManager.canRedo) return;
    final changed = widget.dagManager.redo();
    if (changed) {
      setState(() {
        _viewport = widget.dagManager.viewport ?? _viewport;
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final worldPos = _viewport!.screenToWorld(details.localPosition);

    // Check if we're clicking on an existing object
    final nearby = widget.dagManager.proximitySearch(worldPos, threshold: 10);

    if (nearby.isNotEmpty &&
        widget.toolManager.activeToolType == ToolType.select) {
      // Select object
      final newSelection = {nearby.first.id};
      widget.onSelectionChanged?.call(newSelection);
      setState(() {});
    } else {
      // Forward event to active tool with world coordinates
      final pointerEvent = PointerDownEvent(
        position: worldPos, // Use world coordinates for tool
      );
      widget.toolManager.handleInput(pointerEvent);
      widget.onSelectionChanged?.call({});
      setState(() {});
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final worldPos = _viewport!.screenToWorld(details.localPosition);

    if (widget.toolManager.activeToolType == ToolType.pan) {
      _lastPanPosition = details.localPosition;
    } else if (widget.toolManager.activeToolType == ToolType.select) {
      // Check if we're dragging a selected object
      final nearby = widget.dagManager.proximitySearch(worldPos, threshold: 10);
      if (nearby.isNotEmpty && widget.selectedIds.contains(nearby.first.id)) {
        _draggedObjectId = nearby.first.id;
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.toolManager.activeToolType == ToolType.pan &&
        _lastPanPosition != null) {
      // Pan the viewport
      final delta = details.localPosition - _lastPanPosition!;
      _viewport!.pan(-delta);
      _lastPanPosition = details.localPosition;
      setState(() {});
    } else if (_draggedObjectId != null) {
      // Drag object (only free points can be dragged)
      final node = widget.dagManager.getNode(_draggedObjectId!);
      if (node != null && node.isFree && node.object is GeoPointer) {
        // Convert screen position to world coordinates
        final worldPos = _viewport!.screenToWorld(details.localPosition);

        // Update the point position
        final point = node.object as GeoPointer;
        final updatedPoint = point.copyWith(x: worldPos.dx, y: worldPos.dy);
        widget.dagManager.updateObject(_draggedObjectId!, updatedPoint);

        // Propagate updates to dependent objects (lines, circles, etc.)
        widget.dagManager.propagateUpdates();

        setState(() {});
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
    _draggedObjectId = null;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Zoom with mouse wheel
      final zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      _viewport!.zoomAt(event.localPosition, zoomFactor);
      setState(() {});
    }
  }
}

/// Custom painter for rendering the geometric construction
class GeoDrawCanvasPainter extends CustomPainter {
  final DAGManager dagManager;
  final dag.Viewport viewport;
  final Set<String> selectedIds;
  final bool showGrid;
  final Color backgroundColor;
  final Color gridColor;

  GeoDrawCanvasPainter({
    required this.dagManager,
    required this.viewport,
    required this.selectedIds,
    required this.showGrid,
    required this.backgroundColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Draw grid
    if (showGrid && viewport.gridVisible) {
      _drawGrid(canvas, size);
    }

    // Apply viewport transformation
    canvas.save();
    _applyViewportTransform(canvas, size);

    // Draw all objects in topological order
    final sortedNodes = dagManager.topologicalSort();
    for (final node in sortedNodes) {
      if (!node.object.visible) continue;

      final isSelected = selectedIds.contains(node.id);
      final paint = _getPaintForObject(node.object, isSelected);

      node.object.draw(canvas, paint);
    }

    canvas.restore();

    // Draw selection indicators
    _drawSelectionIndicators(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1;

    // Calculate grid spacing based on zoom
    final baseSpacing = 50.0;
    final spacing = baseSpacing * viewport.zoom;

    // Calculate grid offset
    final offsetX = (viewport.center.dx * viewport.zoom) % spacing;
    final offsetY = (viewport.center.dy * viewport.zoom) % spacing;

    // Draw vertical lines
    for (
      double x = size.width / 2 + offsetX % spacing;
      x < size.width;
      x += spacing
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double x = size.width / 2 + offsetX % spacing; x > 0; x -= spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (
      double y = size.height / 2 + offsetY % spacing;
      y < size.height;
      y += spacing
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double y = size.height / 2 + offsetY % spacing; y > 0; y -= spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 2;

    final centerX = size.width / 2 - viewport.center.dx * viewport.zoom;
    final centerY = size.height / 2 - viewport.center.dy * viewport.zoom;

    // Y-axis
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      axisPaint,
    );

    // X-axis
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
  }

  void _applyViewportTransform(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(viewport.zoom);
    canvas.translate(-viewport.center.dx, -viewport.center.dy);
  }

  Paint _getPaintForObject(CanvasObject object, bool isSelected) {
    final baseStyle = object.style;
    final strokeColor = isSelected ? Colors.orange : baseStyle.strokeColor;
    final strokeWidth = isSelected
        ? (baseStyle.strokeWidth + 1.0)
        : baseStyle.strokeWidth;

    return Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _drawSelectionIndicators(Canvas canvas, Size size) {
    for (final id in selectedIds) {
      final node = dagManager.getNode(id);
      if (node == null) continue;

      final bounds = node.object.getBounds();
      final topLeft = viewport.worldToScreen(bounds.topLeft);
      final bottomRight = viewport.worldToScreen(bounds.bottomRight);

      final selectionRect = Rect.fromPoints(topLeft, bottomRight);

      final paint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(selectionRect, paint);
    }
  }

  @override
  bool shouldRepaint(GeoDrawCanvasPainter oldDelegate) {
    return oldDelegate.dagManager != dagManager ||
        oldDelegate.viewport != viewport ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.showGrid != showGrid;
  }
}
