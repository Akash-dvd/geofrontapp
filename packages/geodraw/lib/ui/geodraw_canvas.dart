import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/dag/dag_manager.dart' hide Viewport;
import '../core/dag/dag_manager.dart' as dag show Viewport;
import '../core/dag/dag_node.dart';
import '../models/canvas_object.dart';
import '../models/canvas_style.dart';
import '../models/geometry_object.dart';
import '../models/simple/geo_point.dart';
import '../models/simple/geo_line.dart';
import '../models/simple/geo_circle.dart';
import '../tools/tool_manager.dart';
import '../tools/tool.dart';
import 'object_toolbar.dart';
import 'object_browser.dart' show SettingsPanelOverlay;

// Conditional import for web
import 'context_menu_handler_stub.dart'
    if (dart.library.html) 'context_menu_handler_web.dart' as context_menu_handler;

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
  final GlobalKey _canvasKey = GlobalKey();
  bool _showGrid = true;
  bool _showAxes = true;

  @override
  void initState() {
    super.initState();
    _viewport =
        widget.dagManager.viewport ??
        dag.Viewport(
          center: Offset.zero,
          zoom: 1.0,
          gridVisible: widget.showGrid,
          axesVisible: true,
          canvasSize: const Size(800, 600),
        );
    widget.dagManager.viewport = _viewport;
    _showGrid = widget.showGrid;
    _showAxes = _viewport!.axesVisible;
    
    // Prevent browser context menu on web (only in canvas area)
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preventBrowserContextMenu();
      });
    }
  }

  void _preventBrowserContextMenu() {
    // Use platform-specific code to prevent browser context menu only in canvas area
    if (kIsWeb) {
      context_menu_handler.preventBrowserContextMenuInCanvas(_canvasKey);
    }
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
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTopRightControls(context),
                      // Toolbar for selected objects (only when select tool is active)
                      if (widget.toolManager.activeToolType == ToolType.select &&
                          widget.selectedIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildObjectToolbar(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBottomRightControls(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvasContent() {
    return Listener(
      key: _canvasKey,
      onPointerDown: _handlePointerDown,
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onSecondaryTapDown: _handleSecondaryTapDown,
        onLongPress: _handleLongPress,
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
                showGrid: _showGrid,
                showAxes: _showAxes,
                backgroundColor: widget.backgroundColor,
                gridColor: widget.gridColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Prevent browser context menu on right-click (secondary button)
    if (event.buttons == kSecondaryButton) {
      // The event is already handled by onSecondaryTapDown in GestureDetector
      // This Listener ensures we capture it first to prevent browser default
      // In web, we need to use platform-specific code to fully prevent default
      // For now, showing our menu quickly will override the browser menu
    }
  }

  Widget _buildHistoryControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
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

    if (nearby.isEmpty) {
      // No objects nearby - forward to tool
      final pointerEvent = PointerDownEvent(
        position: worldPos,
      );
      widget.toolManager.handleInput(pointerEvent);
      setState(() {});
      return;
    }

    // Multiple objects at intersection - show dropdown if no point exists
    if (nearby.length > 1) {
      final hasPoint = nearby.any((obj) => obj is GeoPoint);
      if (!hasPoint) {
        // Show dropdown with all intersecting elements
        _showIntersectionMenu(details.globalPosition, nearby);
        return;
      }
      // Point exists - select it (already prioritized in proximitySearch)
    }

    // Select innermost element (first in list, which is prioritized)
    final selectedObject = nearby.first;

    if (widget.toolManager.activeToolType == ToolType.select) {
      // Direct selection mode
      final newSelection = {selectedObject.id};
      final objectName = selectedObject.label.isNotEmpty
          ? selectedObject.label
          : selectedObject.id;
      final objectType = selectedObject.runtimeType.toString();
      debugPrint('Selected object - Label: $objectName, Type: $objectType');
      widget.onSelectionChanged?.call(newSelection);
      setState(() {});
    } else {
      // Forward event to active tool with world coordinates
      // The tool will manage selection highlighting via onObjectSelected callback
      final pointerEvent = PointerDownEvent(
        position: worldPos, // Use world coordinates for tool
      );
      widget.toolManager.handleInput(pointerEvent);
      setState(() {});
    }
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    final worldPos = _viewport!.screenToWorld(details.localPosition);
    final nearby = widget.dagManager.proximitySearch(worldPos, threshold: 10);

    if (nearby.isEmpty) {
      return;
    }

    // Right-click: show hierarchy menu
    final selectedElement = nearby.first;
    _showHierarchyMenu(details.globalPosition, selectedElement);
  }

  void _handleLongPress() {
    // Long-press: same as right-click for touch devices
    // Note: We need the position, but long-press doesn't provide it directly
    // This will be handled via onLongPressStart if needed
  }

  void _showIntersectionMenu(Offset position, List<GeometryObject> objects) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: objects.map((obj) {
        final label = obj.label.isNotEmpty ? obj.label : obj.id;
        final type = obj.runtimeType.toString().replaceAll('Geo', '');
        return PopupMenuItem<GeometryObject>(
          value: obj,
          child: Text('$type: $label'),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        if (widget.toolManager.activeToolType == ToolType.select) {
          widget.onSelectionChanged?.call({selected.id});
        } else {
          // Forward to tool
          final pointerEvent = PointerDownEvent(
            position: _viewport!.screenToWorld(position),
          );
          widget.toolManager.handleInput(pointerEvent);
        }
        setState(() {});
      }
    });
  }

  void _showHierarchyMenu(Offset position, GeometryObject element) {
    // Find all containers containing this element
    final containers = widget.dagManager.findContainers(element);

    // Build hierarchy list: element first, then containers (innermost to outermost)
    final hierarchy = <GeometryObject>[element, ...containers];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: hierarchy.map((obj) {
        final label = obj.label.isNotEmpty ? obj.label : obj.id;
        final type = obj.runtimeType.toString().replaceAll('Geo', '');
        final isElement = obj == element;
        return PopupMenuItem<GeometryObject>(
          value: obj,
          child: Row(
            children: [
              if (isElement) const Icon(Icons.circle, size: 8),
              if (!isElement) const Icon(Icons.folder, size: 16),
              const SizedBox(width: 8),
              Text('$type: $label'),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        if (widget.toolManager.activeToolType == ToolType.select) {
          widget.onSelectionChanged?.call({selected.id});
        } else {
          // For tools, we need to pass the selected object
          // This might require tool API changes
          widget.onSelectionChanged?.call({selected.id});
        }
        setState(() {});
      }
    });
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

  Widget _buildTopRightControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: _showGrid ? 'Hide Grid' : 'Show Grid',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: ValueKey(_showGrid),
                    icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
                    onPressed: () {
                      setState(() {
                        _showGrid = !_showGrid;
                        _viewport?.gridVisible = _showGrid;
                      });
                    },
                  ),
                ),
              ),
              Tooltip(
                message: _showAxes ? 'Hide Axes' : 'Show Axes',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: ValueKey(_showAxes),
                    icon: Icon(_showAxes ? Icons.linear_scale : Icons.linear_scale_outlined),
                    onPressed: () {
                      setState(() {
                        _showAxes = !_showAxes;
                        _viewport?.axesVisible = _showAxes;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRightControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: () {
                  setState(() {
                    _viewport?.zoomIn();
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildFloatingButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: () {
                  setState(() {
                    _viewport?.zoomOut();
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildFloatingButton(
                icon: Icons.home,
                tooltip: 'Reset View',
                onPressed: () {
                  setState(() {
                    _viewport?.resetView();
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildFloatingButton(
                icon: Icons.pan_tool,
                tooltip: 'Pan Tool',
                isActive: widget.toolManager.activeToolType == ToolType.pan,
                onPressed: () {
                  widget.toolManager.selectTool(ToolType.pan);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          elevation: isActive ? 4 : 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$isActive'),
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectToolbar() {
    final selectedObjects = widget.selectedIds
        .map((id) => widget.dagManager.getObject(id))
        .whereType<GeometryObject>()
        .toList();

    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    return ObjectToolbar(
      selectedObjects: selectedObjects,
      dagManager: widget.dagManager,
      settingsPanelOpen: false, // Not used anymore, kept for compatibility
      onSettingsToggle: () {
        if (selectedObjects.length == 1) {
          // Check if settings panel is already open by checking the route stack
          final navigator = Navigator.of(context);
          final currentRoute = ModalRoute.of(context);
          if (currentRoute?.settings.name == 'settings_panel') {
            return; // Already showing settings panel
          }
          
          // Show settings panel as full-screen overlay
          navigator.push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black.withOpacity(0.3),
              settings: const RouteSettings(name: 'settings_panel'),
              pageBuilder: (context, animation, secondaryAnimation) {
                return SettingsPanelOverlay(
                  object: selectedObjects.first,
                  dagManager: widget.dagManager,
                  onObjectUpdated: (updatedObject) {
                    widget.dagManager.updateObject(
                      updatedObject.id,
                      updatedObject,
                    );
                    setState(() {});
                  },
                );
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
            ),
          );
        }
      },
      onObjectUpdated: (updatedObject) {
        widget.dagManager.updateObject(updatedObject.id, updatedObject);
        setState(() {});
      },
    );
  }

  // Settings panel is now shown via Navigator overlay, not built here
}

/// Custom painter for rendering the geometric construction
class GeoDrawCanvasPainter extends CustomPainter {
  final DAGManager dagManager;
  final dag.Viewport viewport;
  final Set<String> selectedIds;
  final bool showGrid;
  final bool showAxes;
  final Color backgroundColor;
  final Color gridColor;

  GeoDrawCanvasPainter({
    required this.dagManager,
    required this.viewport,
    required this.selectedIds,
    required this.showGrid,
    required this.showAxes,
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

    // Draw axes and labels
    if (showAxes && viewport.axesVisible) {
      _drawAxes(canvas, size);
    }

    // Apply viewport transformation
    canvas.save();
    _applyViewportTransform(canvas, size);

    // Draw all objects in topological order
    // First draw non-GeoPoint objects, then GeoPoint objects (so points appear on top)
    final sortedNodes = dagManager.topologicalSort();
    final nonPointNodes = <DAGNode>[];
    final pointNodes = <DAGNode>[];

    for (final node in sortedNodes) {
      if (!node.object.visible) continue;
      if (node.object is GeoPoint) {
        pointNodes.add(node);
      } else {
        nonPointNodes.add(node);
      }
    }

    // Collect labels to draw in screen space
    final labelsToDraw = <_LabelInfo>[];

    // Draw non-point objects first (with zoom-invariant stroke width)
    // Draw objects WITHOUT their labels, then collect labels for zoom-invariant rendering
    for (final node in nonPointNodes) {
      final isSelected = _isNodeOrElementSelected(node);
      final paint = _getPaintForObject(node.object, isSelected);
      
      // Draw object without label (create copy with empty label to prevent label drawing)
      if (node.object is GeometryObject) {
        final geomObj = node.object as GeometryObject;
        final originalLabel = geomObj.label;
        
        // Create a temporary copy with empty label to prevent label drawing
        final objWithoutLabel = geomObj.copyWith(label: '');
        objWithoutLabel.draw(canvas, paint);
        
        // Collect label for redrawing in screen space (zoom-invariant)
        // For elements: object.id == object.label (display label)
        // For containers: object.label is the container label (e.g., SL1, SL2)
        if (originalLabel.isNotEmpty) {
          final worldPos = _getLabelPosition(geomObj, size);
          if (worldPos != null) {
            labelsToDraw.add(_LabelInfo(
              text: originalLabel, // Display label (same as ID for elements)
              worldPosition: worldPos,
              style: geomObj.style,
              isHighlighted: isSelected,
              isPoint: geomObj is GeoPoint,
              isCircle: geomObj is GeoCircle,
              object: geomObj,
            ));
          }
        }
      } else {
        // Fallback for non-GeometryObject (shouldn't happen, but be safe)
      node.object.draw(canvas, paint);
      }
    }

    // Draw points on top with zoom-invariant radius
    // We need to draw them in screen space, so temporarily restore transform
    canvas.restore(); // Restore to screen space
    
    for (final node in pointNodes) {
      final isSelected = _isNodeOrElementSelected(node);
      _drawPointZoomInvariant(canvas, size, node.object as GeoPoint, isSelected, labelsToDraw);
    }
    
    // Re-apply transform for selected elements drawing
    canvas.save();
    _applyViewportTransform(canvas, size);
    
    // Also draw selected elements that are within containers
    // Elements use display labels as IDs (e.g., "A", "B", "a", "b") and are tracked in elementToContainer map
    for (final id in selectedIds) {
      final obj = dagManager.getObject(id);
      if (obj == null) continue;
      if (obj is! GeometryObject) continue;
      if (!obj.visible) continue;
      
      // Check if this is an element (not a direct DAG node) that's not already drawn
      final node = dagManager.getNode(id);
      if (node == null) {
        // This is an element within a container, draw it with selection highlighting
        final paint = _getPaintForObject(obj, true);
        
        // Draw object without label (create copy with empty label to prevent label drawing)
        final originalLabel = obj.label;
        final objWithoutLabel = obj.copyWith(label: '');
        objWithoutLabel.draw(canvas, paint);
        
        // Collect label for this element (element ID is the display label)
        // In new system: element.id == element.label (display label)
        if (originalLabel.isNotEmpty) {
          final worldPos = _getLabelPosition(obj, size);
          if (worldPos != null) {
            labelsToDraw.add(_LabelInfo(
              text: originalLabel, // This is the element's ID (which is the display label)
              worldPosition: worldPos,
              style: obj.style,
              isHighlighted: true,
              isPoint: obj is GeoPoint,
              isCircle: obj is GeoCircle,
              object: obj,
            ));
          }
        }
      }
    }

    canvas.restore();

    // Cover zoom-dependent labels with background rectangles, then draw zoom-invariant labels
    for (final labelInfo in labelsToDraw) {
      // First, cover the zoom-dependent label area with background color
      _coverZoomDependentLabel(canvas, size, labelInfo);
      // Then draw the zoom-invariant label
      _drawLabelInScreenSpace(canvas, size, labelInfo);
    }

    // Draw selection indicators
    _drawSelectionIndicators(canvas, size);
  }


  /// Get the label position for an object in world coordinates
  /// Returns the position and object type info for accurate label covering
  Offset? _getLabelPosition(GeometryObject object, Size? canvasSize) {
    if (object is GeoPoint) {
      return Offset(object.x, object.y);
    } else if (object is GeoLine) {
      // Calculate midpoint of the visible portion of the line
      // Find where the line intersects the visible viewport bounds
      final a = object.a;
      final b = object.b;
      final c = object.c;
      
      // Get visible world bounds
      final size = canvasSize ?? viewport.canvasSize;
      final topLeft = viewport.screenToWorld(Offset(0, 0));
      final bottomRight = viewport.screenToWorld(Offset(size.width, size.height));
      
      final left = topLeft.dx;
      final right = bottomRight.dx;
      final top = topLeft.dy;
      final bottom = bottomRight.dy;
      
      // Find intersections with viewport bounds
      final intersections = <Offset>[];
      const tolerance = 0.001;
      
      // Intersection with left edge (x = left)
      if (b.abs() > tolerance) {
        final y = -(a * left + c) / b;
        if (y >= top && y <= bottom) {
          intersections.add(Offset(left, y));
        }
      }
      
      // Intersection with right edge (x = right)
      if (b.abs() > tolerance) {
        final y = -(a * right + c) / b;
        if (y >= top && y <= bottom) {
          intersections.add(Offset(right, y));
        }
      }
      
      // Intersection with top edge (y = top)
      if (a.abs() > tolerance) {
        final x = -(b * top + c) / a;
        if (x >= left && x <= right) {
          intersections.add(Offset(x, top));
        }
      }
      
      // Intersection with bottom edge (y = bottom)
      if (a.abs() > tolerance) {
        final x = -(b * bottom + c) / a;
        if (x >= left && x <= right) {
          intersections.add(Offset(x, bottom));
        }
      }
      
      // Remove duplicates
      final uniqueIntersections = <Offset>[];
      for (final intersection in intersections) {
        bool isDuplicate = false;
        for (final existing in uniqueIntersections) {
          if ((intersection - existing).distance < tolerance) {
            isDuplicate = true;
            break;
          }
        }
        if (!isDuplicate) {
          uniqueIntersections.add(intersection);
        }
      }
      
      if (uniqueIntersections.length >= 2) {
        // Use midpoint of the two intersection points
        final mid = (uniqueIntersections[0] + uniqueIntersections[1]) / 2;
        return mid;
      } else if (uniqueIntersections.length == 1) {
        // Only one intersection (line goes through corner)
        return uniqueIntersections[0];
      } else {
        // Fallback: use viewport center projected onto line
        final viewportCenter = viewport.center;
        if (b.abs() > tolerance) {
          // Non-vertical line: use viewport center x, calculate y
          final x = viewportCenter.dx;
          final y = -(a * x + c) / b;
          return Offset(x, y);
        } else if (a.abs() > tolerance) {
          // Vertical line: use viewport center y, calculate x
          final x = -c / a;
          final y = viewportCenter.dy;
          return Offset(x, y);
        } else {
          // Degenerate line (both a and b are ~0)
          return null;
        }
      }
    } else if (object is GeoCircle) {
      // Place label on the circumference, at the right side of the circle
      // This matches the original GeoCircle.draw() behavior: center + Offset(radius + 5, -textPainter.height / 2)
      final centerX = object.centerX;
      final centerY = object.centerY;
      final radius = object.radius;
      
      // Place at the rightmost point on the circumference (0 degrees)
      // This ensures the label is always visible and consistent
      return Offset(centerX + radius, centerY);
    }
    // For other objects, use bounds center
    final bounds = object.getBounds();
    return bounds.center;
  }
  

  /// Draw a point with zoom-invariant radius (assumes canvas is in screen space)
  void _drawPointZoomInvariant(
    Canvas canvas,
    Size size,
    GeoPoint point,
    bool isHighlighted,
    List<_LabelInfo> labelsToDraw,
  ) {
    if (!point.visible) return;

    // Convert world position to screen position
    final screenPos = viewport.worldToScreen(Offset(point.x, point.y));
    
    // Draw in screen space with constant radius
    final effectiveStyle = point.style;
    final radius = effectiveStyle.pointRadius; // Constant in screen space
    
    // Check if highlighted
    final isHighlightedActual = isHighlighted || selectedIds.contains(point.id);
    
    // Draw glow effect if highlighted
    if (isHighlightedActual && effectiveStyle.highlightUseGlow && effectiveStyle.highlightGlowRadius > 0) {
      final glowPaint = Paint()
        ..color = effectiveStyle.getEffectiveFillColor(true).withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, effectiveStyle.highlightGlowRadius);
      canvas.drawCircle(screenPos, radius + effectiveStyle.highlightGlowRadius, glowPaint);
    }

    if (effectiveStyle.filled) {
      final fillColor = isHighlightedActual && effectiveStyle.highlightFillColor != null
          ? effectiveStyle.highlightFillColor!
          : effectiveStyle.fillColor;
      final strokeColor = isHighlightedActual && effectiveStyle.highlightStrokeColor != null
          ? effectiveStyle.highlightStrokeColor!
          : effectiveStyle.strokeColor;
      final strokeWidth = effectiveStyle.strokeWidth; // Constant in screen space
      
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(screenPos, radius, fillPaint);

      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(screenPos, radius, strokePaint);
    } else {
      final strokeColor = isHighlightedActual && effectiveStyle.highlightStrokeColor != null
          ? effectiveStyle.highlightStrokeColor!
          : effectiveStyle.strokeColor;
      final strokeWidth = effectiveStyle.strokeWidth; // Constant in screen space
      
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(screenPos, radius, strokePaint);
    }

    // Collect label for later drawing
    if (point.label.isNotEmpty) {
      labelsToDraw.add(_LabelInfo(
        text: point.label,
        worldPosition: Offset(point.x, point.y),
        style: effectiveStyle,
        isHighlighted: isHighlightedActual,
        isPoint: true,
        isCircle: false,
        object: point,
      ));
    }
  }

  /// Cover the zoom-dependent label area with background color
  /// This covers both the text and the white background that objects draw
  void _coverZoomDependentLabel(Canvas canvas, Size size, _LabelInfo labelInfo) {
    // The zoom-dependent label was drawn in transformed space
    // Its font size was labelFontSize (in world space), which appears as labelFontSize * zoom in screen space
    final zoomDependentFontSize = labelInfo.style.labelFontSize * viewport.zoom;
    
    // Create a TextPainter with the exact same settings as objects use to get accurate dimensions
    final labelColor = labelInfo.style.labelColor;
    final hasBackground = !labelInfo.isPoint; // Lines and circles have white backgrounds
    
    final tempTextPainter = TextPainter(
      text: TextSpan(
        text: labelInfo.text,
        style: TextStyle(
          color: labelColor,
          fontSize: zoomDependentFontSize, // Use zoom-dependent size for accurate measurement
          fontWeight: labelInfo.isPoint ? FontWeight.bold : FontWeight.normal,
          backgroundColor: hasBackground ? Colors.white.withOpacity(0.7) : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tempTextPainter.layout();
    
    // Get exact label dimensions
    final labelWidth = tempTextPainter.width;
    final labelHeight = tempTextPainter.height;
    
    // Convert world position to screen position (base position)
    final baseScreenPos = viewport.worldToScreen(labelInfo.worldPosition);
    
    // Calculate the offset used by objects (in world space, so it scales with zoom)
    // These offsets match exactly what the objects use in their draw() methods
    double worldOffsetX;
    double worldOffsetY;
    
    if (labelInfo.isPoint) {
      // GeoPoint: Offset(x + radius + 2, y - textPainter.height / 2)
      final pointRadius = labelInfo.style.pointRadius;
      worldOffsetX = pointRadius + 2;
      // Use actual textPainter height in world space
      worldOffsetY = -(labelInfo.style.labelFontSize * 1.2) / 2;
    } else if (labelInfo.isCircle && labelInfo.object is GeoCircle) {
      // GeoCircle: label position is already on circumference at (centerX + radius, centerY)
      // So offset is just Offset(5, -textPainter.height / 2) from the circumference point
      worldOffsetX = 5.0;
      worldOffsetY = -(labelInfo.style.labelFontSize * 1.2) / 2;
    } else {
      // GeoLine: mid + Offset(5, -textPainter.height - 5)
      worldOffsetX = 5.0;
      worldOffsetY = -(labelInfo.style.labelFontSize * 1.2) - 5.0;
    }
    
    // Convert world space offset to screen space (it scales with zoom)
    final screenOffsetX = worldOffsetX * viewport.zoom;
    final screenOffsetY = worldOffsetY * viewport.zoom;
    
    // Draw a background rectangle to cover the zoom-dependent label
    // Use exact dimensions from TextPainter plus padding for the white background
    final padding = hasBackground ? 4.0 : 2.0; // Extra padding for white background
    final coverRect = Rect.fromLTWH(
      baseScreenPos.dx + screenOffsetX - padding,
      baseScreenPos.dy + screenOffsetY - padding,
      labelWidth + padding * 2,
      labelHeight + padding * 2,
    );
    
    final coverPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(coverRect, coverPaint);
  }

  /// Draw a label in screen space with constant font size
  void _drawLabelInScreenSpace(Canvas canvas, Size size, _LabelInfo labelInfo) {
    // Convert world position to screen position
    final screenPos = viewport.worldToScreen(labelInfo.worldPosition);
    
    // Don't draw if off-screen
    if (screenPos.dx < -50 || screenPos.dx > size.width + 50 ||
        screenPos.dy < -50 || screenPos.dy > size.height + 50) {
      return;
    }

    final labelColor = labelInfo.style.labelColor;
    final labelFontSize = labelInfo.style.labelFontSize; // Constant size
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelInfo.text,
        style: TextStyle(
          color: labelColor,
          fontSize: labelFontSize,
          fontWeight: FontWeight.bold,
          // No background color - labels should be transparent
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Position label offset from point/object
    Offset offset;
    if (labelInfo.isPoint) {
      offset = Offset(8, -textPainter.height / 2);
    } else if (labelInfo.isCircle) {
      // Circle label is at circumference, offset slightly to the right and center vertically
      offset = Offset(5, -textPainter.height / 2);
    } else {
      // Line label
      offset = Offset(5, -textPainter.height - 5);
    }
    textPainter.paint(canvas, screenPos + offset);
  }

  /// Check if a node or any of its elements are selected
  /// Returns true only if the node itself is selected, not if its elements are selected
  /// (Elements are drawn separately and will get their own highlighting)
  bool _isNodeOrElementSelected(DAGNode node) {
    // Only check if the node itself is selected
    // Don't check elements - they're drawn separately and will get their own highlighting
    return selectedIds.contains(node.id);
  }

  void _drawGrid(Canvas canvas, Size size) {
    // Grid spacing in world coordinates
    final majorSpacing = 50.0;
    final minorSpacing = 10.0;

    // Calculate zoom-based visibility threshold for minor grid lines
    // Minor lines appear when zoom > 0.5, fade out when zoom < 0.3
    final minorLineOpacity = ((viewport.zoom - 0.3) / 0.2).clamp(0.0, 1.0);

    // Find the range of world coordinates visible on screen
    final leftWorldX = viewport.screenToWorld(Offset(0, 0)).dx;
    final rightWorldX = viewport.screenToWorld(Offset(size.width, 0)).dx;
    final topWorldY = viewport.screenToWorld(Offset(0, 0)).dy;
    final bottomWorldY = viewport.screenToWorld(Offset(0, size.height)).dy;

    // Draw minor grid lines (if zoomed in enough)
    if (minorLineOpacity > 0) {
      final minorPaint = Paint()
        ..color = gridColor.withOpacity(0.15 * minorLineOpacity)
        ..strokeWidth = 0.5;

      final firstMinorWorldX = (leftWorldX / minorSpacing).floor() * minorSpacing;
      final firstMinorWorldY = (topWorldY / minorSpacing).floor() * minorSpacing;

      // Draw minor vertical lines
      for (double worldX = firstMinorWorldX; worldX <= rightWorldX; worldX += minorSpacing) {
        // Skip if this is a major grid line
        if ((worldX % majorSpacing).abs() < 0.001) continue;

        final screenX = (worldX - viewport.center.dx) * viewport.zoom + size.width / 2;
        if (screenX >= -10 && screenX <= size.width + 10) {
          canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), minorPaint);
        }
      }

      // Draw minor horizontal lines
      for (double worldY = firstMinorWorldY; worldY <= bottomWorldY; worldY += minorSpacing) {
        // Skip if this is a major grid line
        if ((worldY % majorSpacing).abs() < 0.001) continue;

        final screenY = (worldY - viewport.center.dy) * viewport.zoom + size.height / 2;
        if (screenY >= -10 && screenY <= size.height + 10) {
          canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), minorPaint);
        }
      }
    }

    // Draw major grid lines
    final majorPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1;

    final firstMajorWorldX = (leftWorldX / majorSpacing).floor() * majorSpacing;
    final firstMajorWorldY = (topWorldY / majorSpacing).floor() * majorSpacing;

    // Draw major vertical lines
    for (double worldX = firstMajorWorldX; worldX <= rightWorldX; worldX += majorSpacing) {
      final screenX = (worldX - viewport.center.dx) * viewport.zoom + size.width / 2;
      if (screenX >= -10 && screenX <= size.width + 10) {
        canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), majorPaint);
      }
    }

    // Draw major horizontal lines
    for (double worldY = firstMajorWorldY; worldY <= bottomWorldY; worldY += majorSpacing) {
      final screenY = (worldY - viewport.center.dy) * viewport.zoom + size.height / 2;
      if (screenY >= -10 && screenY <= size.height + 10) {
        canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), majorPaint);
    }
    }
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = gridColor.withOpacity(0.8)
      ..strokeWidth = 2;

    final centerX = size.width / 2 - viewport.center.dx * viewport.zoom;
    final centerY = size.height / 2 - viewport.center.dy * viewport.zoom;

    // Draw Y-axis (vertical)
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      axisPaint,
    );

    // Draw X-axis (horizontal)
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);

    // Draw axis labels with coordinate values
    _drawAxisLabels(canvas, size, centerX, centerY);
  }

  void _drawAxisLabels(Canvas canvas, Size size, double centerX, double centerY) {
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final labelStyle = TextStyle(
      color: gridColor.withOpacity(0.7),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final axisLabelStyle = TextStyle(
      color: gridColor.withOpacity(0.8),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Spacing for coordinate labels (every 50 units)
    final labelSpacing = 50.0;
    final labelOffset = 8.0; // Distance from axis

    // Find visible range
    final leftWorldX = viewport.screenToWorld(Offset(0, 0)).dx;
    final rightWorldX = viewport.screenToWorld(Offset(size.width, 0)).dx;
    final topWorldY = viewport.screenToWorld(Offset(0, 0)).dy;
    final bottomWorldY = viewport.screenToWorld(Offset(0, size.height)).dy;

    // Draw X-axis labels (below the axis)
    final firstLabelX = (leftWorldX / labelSpacing).floor() * labelSpacing;
    for (double worldX = firstLabelX; worldX <= rightWorldX; worldX += labelSpacing) {
      final screenX = (worldX - viewport.center.dx) * viewport.zoom + size.width / 2;
      if (screenX >= 20 && screenX <= size.width - 20 && worldX != 0) {
        labelPaint.text = TextSpan(
          text: _formatCoordinate(worldX),
          style: labelStyle,
        );
        labelPaint.layout();
        labelPaint.paint(
          canvas,
          Offset(screenX - labelPaint.width / 2, centerY + labelOffset),
        );
      }
    }

    // Draw Y-axis labels (to the left of the axis)
    final firstLabelY = (topWorldY / labelSpacing).floor() * labelSpacing;
    for (double worldY = firstLabelY; worldY <= bottomWorldY; worldY += labelSpacing) {
      final screenY = (worldY - viewport.center.dy) * viewport.zoom + size.height / 2;
      if (screenY >= 20 && screenY <= size.height - 20 && worldY != 0) {
        labelPaint.text = TextSpan(
          text: _formatCoordinate(worldY),
          style: labelStyle,
        );
        labelPaint.layout();
        labelPaint.paint(
          canvas,
          Offset(centerX - labelPaint.width - labelOffset, screenY - labelPaint.height / 2),
        );
      }
    }

    // Draw "x" label near positive end of X-axis
    if (centerY >= 0 && centerY <= size.height) {
      final xLabelX = size.width - 30;
      if (xLabelX > centerX + 20) {
        labelPaint.text = TextSpan(
          text: 'x',
          style: axisLabelStyle,
        );
        labelPaint.layout();
        labelPaint.paint(
          canvas,
          Offset(xLabelX, centerY - labelPaint.height - labelOffset),
        );
      }
    }

    // Draw "y" label near positive end of Y-axis
    if (centerX >= 0 && centerX <= size.width) {
      final yLabelY = 20.0;
      if (yLabelY < centerY - 20) {
        labelPaint.text = TextSpan(
          text: 'y',
          style: axisLabelStyle,
        );
        labelPaint.layout();
        labelPaint.paint(
          canvas,
          Offset(centerX + labelOffset, yLabelY),
        );
      }
    }
  }

  String _formatCoordinate(double value) {
    // Format coordinate values nicely
    if (value.abs() < 0.001) return '0';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _applyViewportTransform(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(viewport.zoom);
    canvas.translate(-viewport.center.dx, -viewport.center.dy);
  }

  Paint _getPaintForObject(CanvasObject object, bool isHighlighted) {
    final baseStyle = object.style;
    
    // Use highlight styles if highlighted, otherwise use base style
    final strokeColor = baseStyle.getEffectiveStrokeColor(isHighlighted);
    final strokeWidth = baseStyle.getEffectiveStrokeWidth(isHighlighted);

    // Make stroke width zoom-invariant by dividing by zoom
    // When canvas is scaled by zoom, the effective stroke width stays constant
    final zoomInvariantStrokeWidth = strokeWidth / viewport.zoom;

    return Paint()
      ..color = strokeColor
      ..strokeWidth = zoomInvariantStrokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _drawSelectionIndicators(Canvas canvas, Size size) {
    for (final id in selectedIds) {
      // Use getObject() instead of getNode() to handle pattern IDs (like intersection_0)
      final obj = dagManager.getObject(id);
      if (obj == null) continue;

      final bounds = obj.getBounds();
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
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showAxes != showAxes;
  }
}

/// Information about a label to be drawn in screen space
class _LabelInfo {
  final String text;
  final Offset worldPosition;
  final CanvasStyle style;
  final bool isHighlighted;
  final bool isPoint;
  final bool isCircle;
  final GeometryObject? object; // Store object reference for circle radius

  _LabelInfo({
    required this.text,
    required this.worldPosition,
    required this.style,
    this.isHighlighted = false,
    this.isPoint = false,
    this.isCircle = false,
    this.object,
  });
}
