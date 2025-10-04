import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/geometry_object.dart';
import 'dag_node.dart';

/// Manages the Directed Acyclic Graph (DAG) of geometry objects
/// Handles dependency tracking, update propagation, and object lifecycle
class DAGManager {
  /// Map of node IDs to nodes
  final Map<String, DAGNode> _nodes = {};
  
  /// Counter for generating unique IDs
  int _idCounter = 0;
  
  /// Viewport settings (can be managed externally)
  Viewport? viewport;
  
  /// Constraints (reserved for future use)
  List<dynamic> constraints = [];
  
  /// Metadata
  Map<String, dynamic> metadata = {};

  /// Get all nodes
  Map<String, DAGNode> get nodes => UnmodifiableMapView(_nodes);

  /// Get a specific node by ID
  DAGNode? getNode(String id) => _nodes[id];

  /// Get a specific object by ID
  GeometryObject? getObject(String id) => _nodes[id]?.object;

  /// Add an object to the DAG
  /// Returns the generated ID
  String addObject(GeometryObject object, List<String> dependencies) {
    // Validate dependencies exist
    for (final depId in dependencies) {
      if (!_nodes.containsKey(depId)) {
        throw ArgumentError('Dependency not found: $depId');
      }
    }

    // Check for cycles (should never occur with proper construction)
    if (_wouldCreateCycle(dependencies)) {
      throw StateError('Adding object would create a cycle');
    }

    // Calculate depth
    final depth = dependencies.isEmpty
        ? 0
        : dependencies.map((id) => _nodes[id]!.depth).reduce((a, b) => a > b ? a : b) + 1;

    // Create node
    final node = DAGNode(
      id: object.id,
      object: object,
      parentIds: List.from(dependencies),
      depth: depth,
      isDirty: true,
    );

    // Add to graph
    _nodes[object.id] = node;

    // Update parent nodes' childIds
    for (final parentId in dependencies) {
      final parent = _nodes[parentId]!;
      _nodes[parentId] = parent.copyWith(
        childIds: [...parent.childIds, object.id],
      );
    }

    return object.id;
  }

  /// Update an object's properties
  void updateObject(String id, GeometryObject updatedObject) {
    final node = _nodes[id];
    if (node == null) {
      throw ArgumentError('Object not found: $id');
    }

    // Update node with new object
    _nodes[id] = node.copyWith(
      object: updatedObject,
      isDirty: true,
      lastModified: DateTime.now(),
    );

    // Mark all descendants as dirty
    _markDescendantsDirty(id);
  }

  /// Delete an object from the DAG
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

    if (cascade) {
      // Delete all descendants recursively
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

    // Remove from parent nodes' childIds
    for (final parentId in node.parentIds) {
      final parent = _nodes[parentId];
      if (parent != null) {
        _nodes[parentId] = parent.copyWith(
          childIds: parent.childIds.where((cid) => cid != id).toList(),
        );
      }
    }

    // Remove node
    _nodes.remove(id);
  }

  /// Mark all descendants of a node as dirty
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

  /// Get all descendants of a node in topological order
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

    // Remove the original node
    descendants.remove(id);
    return descendants;
  }

  /// Propagate updates through the DAG
  /// Recalculates all dirty nodes in topological order
  void propagateUpdates() {
    final dirtyNodes = _nodes.values.where((node) => node.isDirty).toList();
    if (dirtyNodes.isEmpty) return;

    // Topologically sort dirty nodes
    final sorted = topologicalSort(dirtyNodes);

    // Update each node in order
    for (final node in sorted) {
      // Recalculate would happen here based on parent objects
      // For now, just mark as clean
      _nodes[node.id] = node.copyWith(isDirty: false);
    }
  }

  /// Topologically sort nodes by depth
  List<DAGNode> topologicalSort([List<DAGNode>? nodesToSort]) {
    final nodes = nodesToSort ?? _nodes.values.toList();
    
    // Sort by depth (lower depth = earlier in sort)
    final sorted = List<DAGNode>.from(nodes)
      ..sort((a, b) => a.depth.compareTo(b.depth));
    
    return sorted;
  }

  /// Check if adding dependencies would create a cycle
  bool _wouldCreateCycle(List<String> dependencies) {
    // In a proper DAG, we can't reach any ancestor from a descendant
    // This is a simplified check
    return false; // Simplified for now
  }

  /// Proximity search for objects near a position
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

    // Sort by distance
    candidates.sort((a, b) => a.$2.compareTo(b.$2));
    return candidates.map((c) => c.$1).toList();
  }

  /// Clear all nodes from the DAG
  void clear() {
    _nodes.clear();
    _idCounter = 0;
  }

  /// Get count of nodes
  int get nodeCount => _nodes.length;

  /// Generate a unique ID
  String generateId([String prefix = 'obj']) {
    return '${prefix}_${_idCounter++}';
  }
}

/// Viewport configuration for canvas rendering
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

  /// Convert screen coordinates to world coordinates
  Offset screenToWorld(Offset screen) {
    return Offset(
      (screen.dx - canvasSize.width / 2) / zoom + center.dx,
      (screen.dy - canvasSize.height / 2) / zoom + center.dy,
    );
  }

  /// Convert world coordinates to screen coordinates
  Offset worldToScreen(Offset world) {
    return Offset(
      (world.dx - center.dx) * zoom + canvasSize.width / 2,
      (world.dy - center.dy) * zoom + canvasSize.height / 2,
    );
  }

  /// Pan viewport
  void pan(Offset delta) {
    center -= delta / zoom;
  }

  /// Zoom viewport at a specific screen point
  void zoomAt(Offset screenPoint, double factor) {
    final worldPoint = screenToWorld(screenPoint);
    zoom *= factor;
    center = worldPoint -
        (screenPoint - Offset(canvasSize.width / 2, canvasSize.height / 2)) /
            zoom;
  }
}
