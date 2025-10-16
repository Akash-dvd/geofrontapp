import 'package:equatable/equatable.dart';

import '../../models/geometry_object.dart';

/// Represents a node in the Directed Acyclic Graph (DAG)
class DAGNode with EquatableMixin {
  final String id;
  final GeometryObject object;
  final List<String> parentIds;
  final List<String> childIds;
  final int depth;
  final bool isDirty;
  final DateTime lastModified;

  DAGNode({
    required this.id,
    required this.object,
    required this.parentIds,
    List<String>? childIds,
    int? depth,
    bool? isDirty,
    DateTime? lastModified,
  }) : childIds = childIds ?? [],
       depth = depth ?? 0,
       isDirty = isDirty ?? false,
       lastModified = lastModified ?? DateTime.now();

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

  bool get isFree => parentIds.isEmpty;

  bool get hasChildren => childIds.isNotEmpty;

  @override
  List<Object?> get props => [id, object, parentIds, childIds, depth, isDirty];

  @override
  String toString() {
    return 'DAGNode{id: $id, label: ${object.label}, depth: $depth, '
        'parents: ${parentIds.length}, children: ${childIds.length}, dirty: $isDirty}';
  }
}
