import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/geometry_object.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_circle.dart';
import 'dag_node.dart';
import '../command/command_registry.dart';

/// Manages the Directed Acyclic Graph (DAG) of geometry objects
/// Handles dependency tracking, update propagation, undo/redo, and object lifecycle
class DAGManager {
  final Map<String, DAGNode> _nodes = {};
  int _idCounter = 0;

  Viewport? viewport;
  List<dynamic> constraints = [];
  Map<String, dynamic> metadata = {};

  final CommandRegistry commandRegistry;
  final DagHistory history;

  DAGManager({CommandRegistry? commandRegistry, DagHistory? history})
    : commandRegistry = commandRegistry ?? CommandRegistry.standard,
      history = history ?? DagHistory() {
    this.history.attach(snapshot: _snapshot, restore: _restore);
  }

  Map<String, DAGNode> get nodes => UnmodifiableMapView(_nodes);

  DAGNode? getNode(String id) => _nodes[id];

  GeometryObject? getObject(String id) => _nodes[id]?.object;

  String addObject(GeometryObject object, List<String> dependencies) {
    history.record();

    for (final depId in dependencies) {
      if (!_nodes.containsKey(depId)) {
        throw ArgumentError('Dependency not found: $depId');
      }
    }

    if (_wouldCreateCycle(dependencies)) {
      throw StateError('Adding object would create a cycle');
    }

    final depth = dependencies.isEmpty
        ? 0
        : dependencies.map((id) => _nodes[id]!.depth).reduce(math.max) + 1;

    final node = DAGNode(
      id: object.id,
      object: object,
      parentIds: List.from(dependencies),
      depth: depth,
      isDirty: true,
    );

    _nodes[object.id] = node;

    for (final parentId in dependencies) {
      final parent = _nodes[parentId]!;
      _nodes[parentId] = parent.copyWith(
        childIds: [...parent.childIds, object.id],
      );
    }

    return object.id;
  }

  void updateObject(String id, GeometryObject updatedObject) {
    final node = _nodes[id];
    if (node == null) {
      throw ArgumentError('Object not found: $id');
    }

    history.record();

    _nodes[id] = node.copyWith(
      object: updatedObject,
      isDirty: true,
      lastModified: DateTime.now(),
    );

    _markDescendantsDirty(id);
  }

  void deleteObject(String id, {bool cascade = false}) {
    final node = _nodes[id];
    if (node == null) {
      throw ArgumentError('Object not found: $id');
    }

    if (!cascade && node.hasChildren) {
      throw StateError(
        'Cannot delete object with dependents. Use cascade=true to delete all dependents.',
      );
    }

    history.record();

    if (cascade) {
      final descendants = _getDescendants(id);
      for (final descId in descendants.reversed) {
        _deleteNodeInternal(descId);
      }
    }

    _deleteNodeInternal(id);
  }

  void _deleteNodeInternal(String id) {
    final node = _nodes[id];
    if (node == null) return;

    for (final parentId in node.parentIds) {
      final parent = _nodes[parentId];
      if (parent != null) {
        _nodes[parentId] = parent.copyWith(
          childIds: parent.childIds.where((cid) => cid != id).toList(),
        );
      }
    }

    _nodes.remove(id);
  }

  void _markDescendantsDirty(String id) {
    final node = _nodes[id];
    if (node == null) return;

    for (final childId in node.childIds) {
      final child = _nodes[childId];
      if (child != null && !child.isDirty) {
        _nodes[childId] = child.copyWith(isDirty: true);
        _markDescendantsDirty(childId);
      }
    }
  }

  List<String> _getDescendants(String id) {
    final descendants = <String>[];
    final queue = Queue<String>()..add(id);
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();
      if (visited.contains(currentId)) continue;
      visited.add(currentId);

      final node = _nodes[currentId];
      if (node != null) {
        descendants.add(currentId);
        queue.addAll(node.childIds);
      }
    }

    descendants.remove(id);
    return descendants;
  }

  void propagateUpdates() {
    final dirtyNodes = _nodes.values.where((node) => node.isDirty).toList();
    if (dirtyNodes.isEmpty) return;

    final sorted = topologicalSort(dirtyNodes);

    for (final node in sorted) {
      if (node.isFree) {
        _nodes[node.id] = node.copyWith(isDirty: false);
        continue;
      }

      final parents = node.parentIds
          .map((id) => _nodes[id]?.object)
          .whereType<GeometryObject>()
          .toList();

      if (parents.length != node.parentIds.length) {
        continue;
      }

      final rebuilt = _reconstructObject(node.object, parents);

      if (rebuilt != null) {
        _nodes[node.id] = node.copyWith(
          object: rebuilt,
          isDirty: false,
          lastModified: DateTime.now(),
        );
      } else {
        _nodes[node.id] = node.copyWith(isDirty: false);
      }
    }
  }

  GeometryObject? _reconstructObject(
    GeometryObject obj,
    List<GeometryObject> parents,
  ) {
    final points = parents.whereType<GeoPoint>().toList();
    if (points.length != parents.length) return null;

    if (obj is GeoLine2P && points.length == 2) {
      return GeoLine2P.fromPoints(
        id: obj.id,
        label: obj.label,
        p1: points[0],
        p2: points[1],
        thickness: obj.thickness,
        style: obj.style,
        color: obj.color,
        visible: obj.visible,
      );
    }

    if (obj is GeoCircle2P && points.length == 2) {
      return GeoCircle2P.fromPoints(
        id: obj.id,
        label: obj.label,
        center: points[0],
        pointOnCircle: points[1],
        thickness: obj.thickness,
        filled: obj.filled,
        color: obj.color,
        visible: obj.visible,
      );
    }

    if (obj is GeoMidpoint && points.length == 2) {
      return GeoMidpoint.fromPoints(
        id: obj.id,
        label: obj.label,
        p1: points[0],
        p2: points[1],
        size: obj.size,
        color: obj.color,
        visible: obj.visible,
      );
    }

    return null;
  }

  List<DAGNode> topologicalSort([List<DAGNode>? nodesToSort]) {
    final nodes = nodesToSort ?? _nodes.values.toList();
    final sorted = List<DAGNode>.from(nodes)
      ..sort((a, b) => a.depth.compareTo(b.depth));

    return sorted;
  }

  bool _wouldCreateCycle(List<String> dependencies) {
    return false;
  }

  List<GeometryObject> proximitySearch(
    Offset position, {
    double threshold = 10.0,
  }) {
    final candidates = <(GeometryObject, double)>[];

    for (final node in _nodes.values) {
      if (!node.object.visible) continue;

      final distance = node.object.distanceTo(position);
      if (distance < threshold) {
        candidates.add((node.object, distance));
      }
    }

    candidates.sort((a, b) => a.$2.compareTo(b.$2));
    return candidates.map((c) => c.$1).toList();
  }

  void clear() {
    history.record();
    _nodes.clear();
    _idCounter = 0;
  }

  int get nodeCount => _nodes.length;

  String generateId([String prefix = 'obj']) {
    return '${prefix}_${_idCounter++}';
  }

  /// History helpers -------------------------------------------------------

  bool undo() {
    return history.undo();
  }

  bool redo() {
    return history.redo();
  }

  bool get canUndo => history.canUndo;

  bool get canRedo => history.canRedo;

  HistoryMarker markHistory() => history.mark();

  void rollbackToMarker(HistoryMarker marker) {
    history.rollbackToMarker(marker);
  }

  _DagState _snapshot() {
    final nodeCopies = <String, DAGNode>{};
    for (final entry in _nodes.entries) {
      final node = entry.value;
      nodeCopies[entry.key] = DAGNode(
        id: node.id,
        object: node.object,
        parentIds: List<String>.from(node.parentIds),
        childIds: List<String>.from(node.childIds),
        depth: node.depth,
        isDirty: node.isDirty,
        lastModified: node.lastModified,
      );
    }

    final metadataCopy = <String, dynamic>{};
    metadata.forEach((key, value) {
      metadataCopy[key] = value;
    });

    final constraintsCopy = List<dynamic>.from(constraints);

    Viewport? viewportCopy;
    if (viewport != null) {
      viewportCopy = Viewport(
        center: viewport!.center,
        zoom: viewport!.zoom,
        gridVisible: viewport!.gridVisible,
        canvasSize: viewport!.canvasSize,
      );
    }

    return _DagState(
      nodes: nodeCopies,
      idCounter: _idCounter,
      metadata: metadataCopy,
      constraints: constraintsCopy,
      viewport: viewportCopy,
    );
  }

  void _restore(_DagState state) {
    _nodes
      ..clear()
      ..addAll(state.nodes);
    _idCounter = state.idCounter;
    metadata = Map<String, dynamic>.from(state.metadata);
    constraints = List<dynamic>.from(state.constraints);
    viewport = state.viewport;
  }
}

class Viewport {
  Offset center;
  double zoom;
  bool gridVisible;
  Size canvasSize;

  Viewport({
    this.center = Offset.zero,
    this.zoom = 1.0,
    this.gridVisible = true,
    this.canvasSize = const Size(800, 600),
  });

  Offset screenToWorld(Offset screen) {
    return Offset(
      (screen.dx - canvasSize.width / 2) / zoom + center.dx,
      (screen.dy - canvasSize.height / 2) / zoom + center.dy,
    );
  }

  Offset worldToScreen(Offset world) {
    return Offset(
      (world.dx - center.dx) * zoom + canvasSize.width / 2,
      (world.dy - center.dy) * zoom + canvasSize.height / 2,
    );
  }

  void pan(Offset delta) {
    center -= delta / zoom;
  }

  void zoomAt(Offset screenPoint, double factor) {
    final worldPoint = screenToWorld(screenPoint);
    zoom *= factor;
    center =
        worldPoint -
        (screenPoint - Offset(canvasSize.width / 2, canvasSize.height / 2)) /
            zoom;
  }
}

/// Internal snapshot of DAG state used for undo/redo
class _DagState {
  final Map<String, DAGNode> nodes;
  final int idCounter;
  final Map<String, dynamic> metadata;
  final List<dynamic> constraints;
  final Viewport? viewport;

  _DagState({
    required this.nodes,
    required this.idCounter,
    required this.metadata,
    required this.constraints,
    required this.viewport,
  });
}

/// Marker used to roll back multiple operations (e.g. tool transactions)
class HistoryMarker {
  final int undoDepth;

  const HistoryMarker(this.undoDepth);
}

/// Manages undo/redo stacks for DAG operations
class DagHistory {
  final List<_DagState> _undoStack = [];
  final List<_DagState> _redoStack = [];

  late _DagState Function() _snapshot;
  late void Function(_DagState) _restore;

  void attach({
    required _DagState Function() snapshot,
    required void Function(_DagState) restore,
  }) {
    _snapshot = snapshot;
    _restore = restore;
    reset();
  }

  void reset() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void record() {
    _undoStack.add(_snapshot());
    _redoStack.clear();
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    final previous = _undoStack.removeLast();
    _redoStack.add(_snapshot());
    _restore(previous);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    final next = _redoStack.removeLast();
    _undoStack.add(_snapshot());
    _restore(next);
    return true;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  HistoryMarker mark() => HistoryMarker(_undoStack.length);

  void rollbackToMarker(HistoryMarker marker) {
    while (_undoStack.length > marker.undoDepth) {
      if (!undo()) {
        break;
      }
    }
    clearRedo();
  }

  void clearRedo() => _redoStack.clear();
}
