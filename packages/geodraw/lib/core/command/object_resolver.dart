/// Utilities for resolving references into DAG objects
library;

import '../dag/dag_manager.dart';
import '../../models/geometry_object.dart';

/// Simple resolver for converting string IDs/labels to objects
class ObjectResolver {
  final DAGManager dagManager;

  ObjectResolver(this.dagManager);

  /// Resolve a single reference (ID or label) to an object
  dynamic resolve(String reference) {
    final trimmed = reference.trim();

    final byId = dagManager.getObject(trimmed);
    if (byId != null) return byId;

    for (final node in dagManager.nodes.values) {
      final object = node.object;
      if (object is GeometryObject && object.label == trimmed) {
        return object;
      }
    }

    return null;
  }

  /// Resolve a list of arguments (keeps non-strings as-is)
  List<dynamic> resolveArguments(List<dynamic> arguments) {
    return arguments.map((arg) {
      if (arg is String) {
        final resolved = resolve(arg);
        return resolved ?? arg;
      }
      return arg;
    }).toList();
  }

  /// Batch resolve multiple references
  List<dynamic> resolveAll(List<String> references) {
    return references.map(resolve).toList();
  }
}
