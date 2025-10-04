import 'package:equatable/equatable.dart';
import '../models/geometry_object.dart';

/// Represents a node in the Directed Acyclic Graph (DAG)
/// Each node contains a geometry object and tracks its dependencies
class DAGNode with EquatableMixin {
  /// Unique identifier
  final String id;
  
  /// The geometry object at this node
  final GeometryObject object;
  
  /// IDs of parent nodes (dependencies)
  final List<String> parentIds;
  
  /// IDs of child nodes (dependents)
  final List<String> childIds;
  
  /// Depth in the DAG (distance from root free objects)
  final int depth;
  
  /// Whether this node needs recalculation
  bool isDirty;
  
  /// Last modification timestamp
  DateTime lastModified;

  DAGNode({
    required this.id,
    required this.object,
    required this.parentIds,
    List<String>? childIds,
    int? depth,
    bool? isDirty,
    DateTime? lastModified,
  })  : childIds = childIds ?? [],
        depth = depth ?? 0,
        isDirty = isDirty ?? false,
        lastModified = lastModified ?? DateTime.now();

  /// Create a copy with updated fields
  DAGNode copyWith({
    String? id,
    GeometryObject? object,
    List<String>? parentIds,
    List<String>? childIds,
    int? depth,
    bool? isDirty,
    DateTime? lastModified,
  }) {
    return DAGNode(
      id: id ?? this.id,
      object: object ?? this.object,
      parentIds: parentIds ?? this.parentIds,
      childIds: childIds ?? this.childIds,
      depth: depth ?? this.depth,
      isDirty: isDirty ?? this.isDirty,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Check if this is a free object (no dependencies)
  bool get isFree => parentIds.isEmpty;

  /// Check if this object has dependents
  bool get hasChildren => childIds.isNotEmpty;

  @override
  List<Object?> get props => [id, object, parentIds, childIds, depth, isDirty];

  @override
  String toString() {
    return 'DAGNode{id: $id, label: ${object.label}, depth: $depth, '
        'parents: ${parentIds.length}, children: ${childIds.length}, dirty: $isDirty}';
  }
}
