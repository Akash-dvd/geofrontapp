import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/canvas_object.dart';
import '../../models/geometry_object.dart';
import '../../models/simple/geo_point.dart';
import '../../models/complex/complex_geometry_object.dart';
import '../../models/simple_lists/geo_intersection.dart';
import 'dag_node.dart';
import '../command/command_registry.dart';

/// Manages the Directed Acyclic Graph (DAG) of geometry objects
/// Handles dependency tracking, update propagation, undo/redo, and object lifecycle
class DAGManager {
  final Map<String, DAGNode> _nodes = {};
  int _idCounter = 0;

  /// Maps element ID to container ID for efficient element lookup
  /// Used to track which container owns each element (for GenSimpleGeometryObjectList)
  final Map<String, String> elementToContainer = {};

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

  /// Get object by ID, with element resolution via elementToContainer map
  /// First checks direct node lookup, then checks elementToContainer map
  CanvasObject? getObject(String id) {
    // First, try direct lookup (normal objects)
    final node = _nodes[id];
    if (node != null) {
      return node.object;
    }

    // Check elementToContainer map for element lookup
    final containerId = elementToContainer[id];
    if (containerId != null) {
      final containerNode = _nodes[containerId];
      if (containerNode?.object is GeometryObject) {
        final container = containerNode!.object as GeometryObject;
        
        if (container is GenSimpleGeometryObjectList) {
          for (final element in container.objects) {
            if (element.id == id) {
              return element;
            }
          }
        } else if (container is UnionGeometryObjectList) {
          // Union elements are DAG nodes, not elements, so check nodes
          for (final element in container.elements) {
            if (element.id == id) {
              return element;
            }
          }
        }
      }
    }

    // Fallback: Direct search through all containers (for backward compatibility)
    // This handles edge cases where elementToContainer might not be populated
    for (final node in _nodes.values) {
      final obj = node.object;
      if (obj is! GeometryObject) continue;

      if (obj is GenSimpleGeometryObjectList) {
        for (final element in obj.objects) {
          if (element.id == id) {
            return element;
          }
        }
      }

      if (obj is UnionGeometryObjectList) {
        for (final element in obj.elements) {
          if (element.id == id) {
            return element;
          }
        }
      }
    }

    return null;
  }

  /// Get the container ID for a given element ID
  String? getContainerForElement(String elementId) {
    return elementToContainer[elementId];
  }

  /// Register an element in the elementToContainer map
  void registerElement(String elementId, String containerId) {
    elementToContainer[elementId] = containerId;
  }

  /// Unregister an element from the elementToContainer map
  void unregisterElement(String elementId) {
    elementToContainer.remove(elementId);
  }

  /// Update an element's ID and update all dependent objects' dependency lists
  /// This is used when renaming an element (element ID = label)
  /// 
  /// **CRITICAL**: This method:
  /// 1. Updates the element's ID in the container
  /// 2. Updates elementToContainer map
  /// 3. Finds all DAG nodes that depend on the old element ID
  /// 4. Updates their dependency lists to use the new element ID
  /// 5. Triggers rebuilds for dependent objects if needed
  void updateElementId({
    required String oldElementId,
    required String newElementId,
    required GeometryObject updatedElement,
  }) {
    history.record();

    // Get the container that owns this element
    final containerId = elementToContainer[oldElementId];
    if (containerId == null) {
      throw ArgumentError('Element $oldElementId is not registered in elementToContainer');
    }

    final containerNode = _nodes[containerId];
    if (containerNode == null) {
      throw ArgumentError('Container $containerId not found');
    }

    final container = containerNode.object;
    if (container is! GenSimpleGeometryObjectList) {
      throw ArgumentError('Container $containerId is not a GenSimpleGeometryObjectList');
    }

    // Update the element in the container's objects list
    final updatedObjects = container.objects.map((element) {
      if (element.id == oldElementId) {
        return updatedElement;
      }
      return element;
    }).toList();

    // Create updated container
    // Note: copyWith signature depends on the specific container type
    // For GeoIntersection, use objects parameter
    GenSimpleGeometryObjectList updatedContainer;
    if (container is GeoIntersection) {
      updatedContainer = container.copyWith(objects: updatedObjects.cast<GeoPoint>());
    } else {
      // For other container types, we need to recreate with updated objects
      // This is a fallback - specific types should handle their own copyWith
      throw ArgumentError('updateElementId not fully implemented for ${container.runtimeType}');
    }

    // Update elementToContainer map
    unregisterElement(oldElementId);
    registerElement(newElementId, containerId);

    // Update container in DAG
    updateObject(containerId, updatedContainer);

    // Find all DAG nodes that depend on the old element ID
    // We need to check both:
    // 1. Direct dependencies (node.dependencies contains oldElementId)
    // 2. Container dependencies (node depends on container, and container contains oldElementId)
    final dependentNodes = <DAGNode>[];
    for (final node in _nodes.values) {
      final obj = node.object;
      if (obj is! GeometryObject) continue;

      // Check if this node directly depends on the old element ID
      if (obj.dependencies.contains(oldElementId)) {
        dependentNodes.add(node);
        continue;
      }

      // Check if this node depends on the container and uses the old element ID
      if (node.parentIds.contains(containerId) && obj.dependencies.contains(oldElementId)) {
        dependentNodes.add(node);
      }
    }

    // Update all dependent nodes' dependency lists
    for (final dependentNode in dependentNodes) {
      final dependentObj = dependentNode.object;
      if (dependentObj is! GeometryObject) continue;

      // Update dependencies list
      final updatedDependencies = dependentObj.dependencies.map((depId) {
        return depId == oldElementId ? newElementId : depId;
      }).toList();

      // Create updated object with new dependencies
      final updatedDependentObj = dependentObj.copyWith(dependencies: updatedDependencies);

      // Update the node
      _nodes[dependentNode.id] = dependentNode.copyWith(
        object: updatedDependentObj,
        isDirty: true,
        lastModified: DateTime.now(),
      );

      // Mark descendants as dirty to trigger rebuilds
      _markDescendantsDirty(dependentNode.id);
    }
  }

  String addObject(CanvasObject object, List<String> dependencies) {
    history.record();

    // Resolve pattern IDs to actual DAG node IDs
    final resolvedDependencies = <String>[];
    for (final depId in dependencies) {
      // First check if it's a direct node
      if (_nodes.containsKey(depId)) {
        resolvedDependencies.add(depId);
        continue;
      }
      
      // Try to resolve as pattern ID (e.g., intersection_6_0)
      final obj = getObject(depId);
      if (obj == null) {
        throw ArgumentError('Dependency not found: $depId');
      }
      
      // Find the container that owns this element
      String? containerId;
      for (final node in _nodes.values) {
        if (node.object is GenSimpleGeometryObjectList) {
          final container = node.object as GenSimpleGeometryObjectList;
          if (container.objects.any((element) => element.id == depId)) {
            containerId = node.id;
            break;
          }
        } else if (node.object is UnionGeometryObjectList) {
          final container = node.object as UnionGeometryObjectList;
          if (container.elements.any((element) => element.id == depId)) {
            containerId = node.id;
            break;
          }
        } else if (node.object.id == depId) {
          // The object itself is a direct DAG node
          containerId = depId;
          break;
        }
      }
      
      if (containerId == null) {
        throw ArgumentError('Dependency not found in DAG: $depId (resolved object: ${obj.runtimeType})');
      }
      
      resolvedDependencies.add(containerId);
    }

    if (_wouldCreateCycle(resolvedDependencies)) {
      throw StateError('Adding object would create a cycle');
    }

    final depth = resolvedDependencies.isEmpty
        ? 0
        : resolvedDependencies.map((id) => _nodes[id]!.depth).reduce(math.max) + 1;

    final node = DAGNode(
      id: object.id,
      object: object,
      parentIds: List.from(resolvedDependencies),
      depth: depth,
      isDirty: true,
    );

    _nodes[object.id] = node;

    for (final parentId in resolvedDependencies) {
      final parent = _nodes[parentId]!;
      _nodes[parentId] = parent.copyWith(
        childIds: [...parent.childIds, object.id],
      );
    }

    // Register elements in elementToContainer map if object is a container
    if (object is GenSimpleGeometryObjectList) {
      for (final element in object.objects) {
        registerElement(element.id, object.id);
      }
    }
    // Note: UnionGeometryObjectList elements are DAG nodes, not elements,
    // so they don't need to be registered in elementToContainer

    return object.id;
  }

  void updateObject(String id, CanvasObject updatedObject) {
    final node = _nodes[id];
    if (node == null) {
      throw ArgumentError('Object not found: $id');
    }

    history.record();

    // Update elementToContainer map if container's elements changed
    final oldObject = node.object;
    if (oldObject is GenSimpleGeometryObjectList && updatedObject is GenSimpleGeometryObjectList) {
      // Compare old vs new elements
      final oldElementIds = oldObject.objects.map((e) => e.id).toSet();
      final newElementIds = updatedObject.objects.map((e) => e.id).toSet();
      
      // Unregister removed elements
      for (final elementId in oldElementIds) {
        if (!newElementIds.contains(elementId)) {
          unregisterElement(elementId);
        }
      }
      
      // Register new elements
      for (final element in updatedObject.objects) {
        registerElement(element.id, id);
      }
    }

    _nodes[id] = node.copyWith(
      object: updatedObject,
      isDirty: true,
      lastModified: DateTime.now(),
    );

    _markDescendantsDirty(id);
  }

  void replaceObjectWithDependencies(
    String id,
    CanvasObject updatedObject,
    List<String> dependencies,
  ) {
    final node = _nodes[id];
    if (node == null) {
      throw ArgumentError('Object not found: $id');
    }

    for (final depId in dependencies) {
      if (!_nodes.containsKey(depId)) {
        throw ArgumentError('Dependency not found: $depId');
      }
    }

    if (_wouldCreateCycle(dependencies)) {
      throw StateError('Replacing object would create a cycle');
    }

    history.record();

    final oldParents = Set<String>.from(node.parentIds);
    final newParents = <String>{};
    final orderedParents = <String>[];
    for (final depId in dependencies) {
      if (newParents.add(depId)) {
        orderedParents.add(depId);
      }
    }

    for (final oldParent in oldParents) {
      if (newParents.contains(oldParent)) {
        continue;
      }

      final parentNode = _nodes[oldParent];
      if (parentNode == null) {
        continue;
      }

      final updatedChildren = parentNode.childIds
          .where((child) => child != id)
          .toList();
      _nodes[oldParent] = parentNode.copyWith(childIds: updatedChildren);
    }

    for (final newParent in newParents) {
      final parentNode = _nodes[newParent];
      if (parentNode == null) {
        throw ArgumentError('Dependency not found: $newParent');
      }

      if (!parentNode.childIds.contains(id)) {
        final updatedChildren = List<String>.from(parentNode.childIds)..add(id);
        _nodes[newParent] = parentNode.copyWith(childIds: updatedChildren);
      }
    }

    final depth = orderedParents.isEmpty
        ? 0
        : orderedParents.map((depId) => _nodes[depId]!.depth).reduce(math.max) +
              1;

    _nodes[id] = node.copyWith(
      object: updatedObject,
      parentIds: orderedParents,
      depth: depth,
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

    // Unregister elements from elementToContainer if this is a container
    final obj = node.object;
    if (obj is GenSimpleGeometryObjectList) {
      for (final element in obj.objects) {
        unregisterElement(element.id);
      }
    }

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

      final obj = node.object;
      if (obj is! GeometryObject) {
        _nodes[node.id] = node.copyWith(isDirty: false);
        continue;
      }

      // Resolve parents - if a parent is a container and we depend on an element within it,
      // extract that element instead of using the container
      // We need to match each parent position with the corresponding dependency
      final parents = <GeometryObject>[];
      final usedDependencyIndices = <int>{};
      
      for (var i = 0; i < node.parentIds.length; i++) {
        final parentId = node.parentIds[i];
        final parentNode = _nodes[parentId];
        if (parentNode == null) continue;
        
        final parentObj = parentNode.object;
        if (parentObj is! GeometryObject) continue;
        
        // Check if this parent is a container and we depend on an element within it
        // Match by position: parent at index i should match dependency at index i
        GeometryObject? resolvedParent;
        if (i < obj.dependencies.length) {
          final depId = obj.dependencies[i];
          resolvedParent = _resolveElementFromContainer(
            container: parentObj,
            elementId: depId,
          );
        }
        
        // If not found by position, try finding any unused matching element
        if (resolvedParent == null) {
          resolvedParent = _resolveParentFromContainer(
            container: parentObj,
            originalDependencies: obj.dependencies,
            usedIndices: usedDependencyIndices,
          );
          if (resolvedParent != null) {
            // Mark which dependency index was used
            final depIndex = obj.dependencies.indexWhere(
              (id) => id == resolvedParent!.id,
            );
            if (depIndex >= 0) {
              usedDependencyIndices.add(depIndex);
            }
          }
        }
        
        parents.add(resolvedParent ?? parentObj);
      }

      if (parents.length != node.parentIds.length) {
        continue;
      }

      final rebuilt = _reconstructObject(obj, parents);

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

  /// Resolve a specific element from a container by element ID
  /// Returns the element if found, otherwise returns null
  GeometryObject? _resolveElementFromContainer({
    required GeometryObject container,
    required String elementId,
  }) {
    if (container is GenSimpleGeometryObjectList) {
      for (final element in container.objects) {
        if (element.id == elementId) {
          return element;
        }
      }
    } else if (container is UnionGeometryObjectList) {
      for (final element in container.elements) {
        if (element.id == elementId) {
          return element;
        }
      }
    }
    
    return null;
  }

  /// Resolve a parent object from a container if we depend on an element within it
  /// Returns an unused element if found, otherwise returns null (use container)
  GeometryObject? _resolveParentFromContainer({
    required GeometryObject container,
    required List<String> originalDependencies,
    Set<int>? usedIndices,
  }) {
    final used = usedIndices ?? <int>{};
    
    // Check if container has elements that match our original dependencies
    // (but not ones we've already used)
    if (container is GenSimpleGeometryObjectList) {
      for (var i = 0; i < container.objects.length; i++) {
        final element = container.objects[i];
        final depIndex = originalDependencies.indexWhere((id) => id == element.id);
        if (depIndex >= 0 && !used.contains(depIndex)) {
          return element;
        }
      }
    } else if (container is UnionGeometryObjectList) {
      for (var i = 0; i < container.elements.length; i++) {
        final element = container.elements[i];
        final depIndex = originalDependencies.indexWhere((id) => id == element.id);
        if (depIndex >= 0 && !used.contains(depIndex)) {
          return element;
        }
      }
    }
    
    // No matching element found, return null to use container
    return null;
  }

  GeometryObject? _reconstructObject(
    GeometryObject obj,
    List<GeometryObject> parents,
  ) {
    // Pass DAGManager to rebuildFromParents for label management
    return obj.rebuildFromParents(List<GeometryObject>.from(parents), this);
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

  /// Search for elements near a position, returning only actual elements (not containers)
  /// Prioritizes points if present
  List<GeometryObject> proximitySearch(
    Offset position, {
    double threshold = 10.0,
  }) {
    final pointCandidates = <(GeometryObject, double)>[];
    final otherCandidates = <(GeometryObject, double)>[];

    for (final node in _nodes.values) {
      final obj = node.object;
      if (obj is! GeometryObject) continue;
      if (!obj.visible) continue;

      // For list-type objects, search within elements
      if (obj is GenSimpleGeometryObjectList) {
        for (final element in obj.objects) {
          if (!element.visible) continue;
          final distance = element.distanceTo(position);
          if (distance < threshold) {
            if (element is GeoPoint) {
              pointCandidates.add((element, distance));
            } else {
              otherCandidates.add((element, distance));
            }
          }
        }
      } else if (obj is UnionGeometryObjectList) {
        for (final element in obj.elements) {
          if (!element.visible) continue;
          final distance = element.distanceTo(position);
          if (distance < threshold) {
            if (element is GeoPoint) {
              pointCandidates.add((element, distance));
            } else {
              otherCandidates.add((element, distance));
            }
          }
        }
      } else {
        // Regular object (not a container) - add directly
        final distance = obj.distanceTo(position);
        if (distance < threshold) {
          if (obj is GeoPoint) {
            pointCandidates.add((obj, distance));
          } else {
            otherCandidates.add((obj, distance));
          }
        }
      }
    }

    int compareDistance(
      (GeometryObject, double) a,
      (GeometryObject, double) b,
    ) {
      return a.$2.compareTo(b.$2);
    }

    pointCandidates.sort(compareDistance);
    otherCandidates.sort(compareDistance);

    return [
      ...pointCandidates.map((c) => c.$1),
      ...otherCandidates.map((c) => c.$1),
    ];
  }

  /// Find all containers (groups) that contain the given element
  /// Returns list from innermost to outermost container
  List<GeometryObject> findContainers(GeometryObject element) {
    final containers = <GeometryObject>[];

    // Search all DAG nodes for containers
    for (final node in _nodes.values) {
      final obj = node.object;
      if (obj is! GeometryObject) continue;

      // Check GenSimpleGeometryObjectList
      if (obj is GenSimpleGeometryObjectList) {
        if (obj.objects.contains(element)) {
          containers.add(obj);
        }
      }

      // Check UnionGeometryObjectList
      if (obj is UnionGeometryObjectList) {
        if (obj.elements.contains(element)) {
          containers.add(obj);
        }
      }
    }

    // Sort by depth (innermost first) - containers with fewer children are more specific
    // Also consider containment depth (how many levels deep)
    containers.sort((a, b) {
      final aNode = _nodes[a.id];
      final bNode = _nodes[b.id];
      final aDepth = aNode?.depth ?? 0;
      final bDepth = bNode?.depth ?? 0;
      
      // Prefer containers that are closer in the DAG (higher depth = more specific)
      if (aDepth != bDepth) {
        return bDepth.compareTo(aDepth); // Higher depth first (innermost)
      }
      
      // If same depth, prefer smaller containers (more specific)
      final aSize = a is GenSimpleGeometryObjectList 
          ? a.objects.length 
          : (a is UnionGeometryObjectList ? a.elements.length : 0);
      final bSize = b is GenSimpleGeometryObjectList 
          ? b.objects.length 
          : (b is UnionGeometryObjectList ? b.elements.length : 0);
      
      return aSize.compareTo(bSize); // Smaller first (more specific)
    });

    return containers;
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
        axesVisible: viewport!.axesVisible,
        canvasSize: viewport!.canvasSize,
      );
    }

    // Copy elementToContainer map
    final elementToContainerCopy = <String, String>{};
    elementToContainer.forEach((key, value) {
      elementToContainerCopy[key] = value;
    });

    return _DagState(
      nodes: nodeCopies,
      idCounter: _idCounter,
      metadata: metadataCopy,
      constraints: constraintsCopy,
      viewport: viewportCopy,
      elementToContainer: elementToContainerCopy,
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
    
    // Restore elementToContainer map
    elementToContainer
      ..clear()
      ..addAll(state.elementToContainer);
  }
}

class Viewport {
  Offset center;
  double zoom;
  bool gridVisible;
  bool axesVisible;
  Size canvasSize;

  Viewport({
    this.center = Offset.zero,
    this.zoom = 1.0,
    this.gridVisible = true,
    this.axesVisible = true,
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
    center += delta / zoom;
  }

  void zoomAt(Offset screenPoint, double factor) {
    final worldPoint = screenToWorld(screenPoint);
    zoom *= factor;
    center =
        worldPoint -
        (screenPoint - Offset(canvasSize.width / 2, canvasSize.height / 2)) /
            zoom;
  }

  void resetView() {
    center = Offset.zero;
    zoom = 1.0;
  }

  void zoomIn([Offset? screenPoint]) {
    zoomAt(screenPoint ?? Offset(canvasSize.width / 2, canvasSize.height / 2), 1.2);
  }

  void zoomOut([Offset? screenPoint]) {
    zoomAt(screenPoint ?? Offset(canvasSize.width / 2, canvasSize.height / 2), 1 / 1.2);
  }
}

/// Internal snapshot of DAG state used for undo/redo
class _DagState {
  final Map<String, DAGNode> nodes;
  final int idCounter;
  final Map<String, dynamic> metadata;
  final List<dynamic> constraints;
  final Viewport? viewport;
  final Map<String, String> elementToContainer;

  _DagState({
    required this.nodes,
    required this.idCounter,
    required this.metadata,
    required this.constraints,
    required this.viewport,
    Map<String, String>? elementToContainer,
  }) : elementToContainer = elementToContainer ?? {};
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
