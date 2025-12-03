/// Label management utilities for geometry objects
/// Handles label generation, validation, and uniqueness checking
library;

import 'dag/dag_manager.dart';
import '../../models/geometry_object.dart';
import '../../models/complex/complex_geometry_object.dart';

/// Types of geometry objects for label naming conventions
enum GeometryObjectType {
  point, // GeoPoint, intersection point elements (A-Z, AA-ZZ, ...)
  line, // GeoLine, GeoSegment, GeoArc (a-z, aa-zz, ...)
  circle, // GeoCircle (a-z, aa-zz, ...)
  arc, // GeoArc (a-z, aa-zz, ...)
  simpleList, // GenSimpleGeometryObjectList containers (SL1, SL2, ...)
  union, // UnionGeometryObjectList containers (U1, U2, ...)
  polygon, // GeoPolygon
  polyLine, // GeoPolyLine
  polyArc, // GeoPolyArc
  polyArcGon, // GeoPolyArcGon
  transform, // GeoTrans objects (GeoRotate, GeoDilate, GeoInverse)
  text, // CanvasText (may keep custom format)
}

/// Manages label generation and validation for geometry objects
class LabelManager {
  /// Get the next available label for a given object type
  /// Uses frugal naming: always checks from start to reuse deleted labels
  static String getNextAvailableLabel(
    DAGManager dagManager,
    GeometryObjectType type, {
    String? preferred,
  }) {
    // If preferred label is provided and unique, use it
    if (preferred != null && preferred.isNotEmpty) {
      if (isLabelUnique(dagManager, preferred)) {
        return preferred;
      }
    }

    // Generate label based on type
    switch (type) {
      case GeometryObjectType.point:
        return _findFirstAvailableUppercase(dagManager);
      case GeometryObjectType.line:
      case GeometryObjectType.circle:
      case GeometryObjectType.arc:
        return _findFirstAvailableLowercase(dagManager);
      case GeometryObjectType.simpleList:
        return _findNextContainerLabel(dagManager, 'SL');
      case GeometryObjectType.union:
        return _findNextContainerLabel(dagManager, 'U');
      case GeometryObjectType.polygon:
      case GeometryObjectType.polyLine:
      case GeometryObjectType.polyArc:
      case GeometryObjectType.polyArcGon:
        // For now, use lowercase convention
        return _findFirstAvailableLowercase(dagManager);
      case GeometryObjectType.transform:
        // Transform labels - may need custom handling
        return _findFirstAvailableLowercase(dagManager);
      case GeometryObjectType.text:
        // Text labels - may keep custom format
        return _findFirstAvailableLowercase(dagManager);
    }
  }

  /// Get next available label for a transformed object
  /// Adds apostrophe (') to base label: A → A', a → a'
  /// If A' exists, tries A'' (double apostrophe), etc.
  static String getNextAvailableLabelForTransformation(
    DAGManager dagManager,
    String baseLabel,
  ) {
    // Try single apostrophe first
    String candidate = '$baseLabel\'';
    if (isLabelUnique(dagManager, candidate)) {
      return candidate;
    }

    // Try double apostrophe
    candidate = '$baseLabel\'\'';
    if (isLabelUnique(dagManager, candidate)) {
      return candidate;
    }

    // Try triple apostrophe
    candidate = '$baseLabel\'\'\'';
    if (isLabelUnique(dagManager, candidate)) {
      return candidate;
    }

    // If all apostrophes taken, add more apostrophes
    int apostropheCount = 4;
    while (true) {
      candidate = '$baseLabel${'\'' * apostropheCount}';
      if (isLabelUnique(dagManager, candidate)) {
        return candidate;
      }
      apostropheCount++;
      // Safety limit
      if (apostropheCount > 10) {
        break;
      }
    }

    // Fallback: use base label with number
    int suffix = 1;
    while (true) {
      candidate = '$baseLabel\'$suffix';
      if (isLabelUnique(dagManager, candidate)) {
        return candidate;
      }
      suffix++;
      if (suffix > 1000) {
        // Should never happen, but safety check
        throw StateError('Unable to generate unique transformed label for $baseLabel');
      }
    }
  }

  /// Check if a label is unique globally (across all nodes AND elements)
  static bool isLabelUnique(
    DAGManager dagManager,
    String label, {
    String? excludeId,
  }) {
    final usedLabels = getAllUsedLabels(dagManager);
    if (excludeId != null) {
      usedLabels.remove(excludeId);
    }
    return !usedLabels.contains(label);
  }

  /// Get all used labels from DAG nodes and elements
  static Set<String> getAllUsedLabels(DAGManager dagManager) {
    final usedLabels = <String>{};

    // Collect labels from DAG nodes
    for (final node in dagManager.nodes.values) {
      final obj = node.object;
      if (obj is GeometryObject) {
        // For regular objects, label is the display label
        if (obj.label.isNotEmpty) {
          usedLabels.add(obj.label);
        }
        // Also check ID (which equals label in new system)
        usedLabels.add(obj.id);
      }
    }

    // Collect element IDs from containers
    for (final node in dagManager.nodes.values) {
      final obj = node.object;
      if (obj is GenSimpleGeometryObjectList) {
        for (final element in obj.objects) {
          // Element ID is the label in new system
          usedLabels.add(element.id);
          if (element.label.isNotEmpty) {
            usedLabels.add(element.label);
          }
        }
      } else if (obj is UnionGeometryObjectList) {
        // Union elements are DAG nodes, not elements, so already collected above
        // But check their labels anyway
        for (final element in obj.elements) {
          // Elements in UnionGeometryObjectList are always GeometryObject
          usedLabels.add(element.id);
          if (element.label.isNotEmpty) {
            usedLabels.add(element.label);
          }
        }
      }
    }

    return usedLabels;
  }

  /// Suggest next available label variant based on type
  static String suggestNextLabel(
    DAGManager dagManager,
    String baseLabel,
    GeometryObjectType type,
  ) {
    // If base label is unique, return it
    if (isLabelUnique(dagManager, baseLabel)) {
      return baseLabel;
    }

    // Otherwise, suggest next available variant
    switch (type) {
      case GeometryObjectType.point:
        return _suggestNextUppercase(dagManager, baseLabel);
      case GeometryObjectType.line:
      case GeometryObjectType.circle:
      case GeometryObjectType.arc:
        return _suggestNextLowercase(dagManager, baseLabel);
      case GeometryObjectType.simpleList:
        return _suggestNextContainer(dagManager, baseLabel, 'SL');
      case GeometryObjectType.union:
        return _suggestNextContainer(dagManager, baseLabel, 'U');
      default:
        return getNextAvailableLabel(dagManager, type);
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// Find first available uppercase label (A-Z, then AA-ZZ, then AAA-ZZZ, ...)
  /// Frugal naming: checks from start to reuse deleted labels
  static String _findFirstAvailableUppercase(DAGManager dagManager) {
    final usedLabels = getAllUsedLabels(dagManager);

    // Try single letters first (A-Z)
    for (int i = 0; i < 26; i++) {
      final label = String.fromCharCode(65 + i); // A-Z
      if (!usedLabels.contains(label)) {
        return label;
      }
    }

    // Try double letters (AA-ZZ)
    for (int i = 0; i < 26; i++) {
      final first = String.fromCharCode(65 + i);
      for (int j = 0; j < 26; j++) {
        final second = String.fromCharCode(65 + j);
        final label = '$first$second';
        if (!usedLabels.contains(label)) {
          return label;
        }
      }
    }

    // Try triple letters (AAA-ZZZ)
    for (int i = 0; i < 26; i++) {
      final first = String.fromCharCode(65 + i);
      for (int j = 0; j < 26; j++) {
        final second = String.fromCharCode(65 + j);
        for (int k = 0; k < 26; k++) {
          final third = String.fromCharCode(65 + k);
          final label = '$first$second$third';
          if (!usedLabels.contains(label)) {
            return label;
          }
        }
      }
    }

    // Fallback (should never reach here in practice)
    throw StateError('Unable to generate unique uppercase label');
  }

  /// Find first available lowercase label (a-z, then aa-zz, then aaa-zzz, ...)
  /// Frugal naming: checks from start to reuse deleted labels
  static String _findFirstAvailableLowercase(DAGManager dagManager) {
    final usedLabels = getAllUsedLabels(dagManager);

    // Try single letters first (a-z)
    for (int i = 0; i < 26; i++) {
      final label = String.fromCharCode(97 + i); // a-z
      if (!usedLabels.contains(label)) {
        return label;
      }
    }

    // Try double letters (aa-zz)
    for (int i = 0; i < 26; i++) {
      final first = String.fromCharCode(97 + i);
      for (int j = 0; j < 26; j++) {
        final second = String.fromCharCode(97 + j);
        final label = '$first$second';
        if (!usedLabels.contains(label)) {
          return label;
        }
      }
    }

    // Try triple letters (aaa-zzz)
    for (int i = 0; i < 26; i++) {
      final first = String.fromCharCode(97 + i);
      for (int j = 0; j < 26; j++) {
        final second = String.fromCharCode(97 + j);
        for (int k = 0; k < 26; k++) {
          final third = String.fromCharCode(97 + k);
          final label = '$first$second$third';
          if (!usedLabels.contains(label)) {
            return label;
          }
        }
      }
    }

    // Fallback (should never reach here in practice)
    throw StateError('Unable to generate unique lowercase label');
  }

  /// Find next available container label (SL1, SL2, ... or U1, U2, ...)
  /// Frugal naming: checks from 1 to reuse deleted labels
  static String _findNextContainerLabel(DAGManager dagManager, String prefix) {
    final usedLabels = getAllUsedLabels(dagManager);

    // Check from 1 onwards (frugal naming)
    int index = 1;
    while (true) {
      final label = '$prefix$index';
      if (!usedLabels.contains(label)) {
        return label;
      }
      index++;
      // Safety limit
      if (index > 100000) {
        throw StateError('Unable to generate unique container label for $prefix');
      }
    }
  }

  /// Suggest next uppercase label variant
  static String _suggestNextUppercase(DAGManager dagManager, String baseLabel) {
    // If base label is uppercase, try incrementing it
    if (_isUppercaseLabel(baseLabel)) {
      final next = _generateNextUppercase(baseLabel);
      if (isLabelUnique(dagManager, next)) {
        return next;
      }
    }
    // Otherwise, just get next available
    return _findFirstAvailableUppercase(dagManager);
  }

  /// Suggest next lowercase label variant
  static String _suggestNextLowercase(DAGManager dagManager, String baseLabel) {
    // If base label is lowercase, try incrementing it
    if (_isLowercaseLabel(baseLabel)) {
      final next = _generateNextLowercase(baseLabel);
      if (isLabelUnique(dagManager, next)) {
        return next;
      }
    }
    // Otherwise, just get next available
    return _findFirstAvailableLowercase(dagManager);
  }

  /// Suggest next container label variant
  static String _suggestNextContainer(
    DAGManager dagManager,
    String baseLabel,
    String prefix,
  ) {
    // If base label matches container pattern, try incrementing
    if (_isContainerLabel(baseLabel, prefix)) {
      final match = RegExp('^$prefix(\\d+)\$').firstMatch(baseLabel);
      if (match != null) {
        final index = int.tryParse(match.group(1)!);
        if (index != null) {
          int nextIndex = index + 1;
          while (true) {
            final candidate = '$prefix$nextIndex';
            if (isLabelUnique(dagManager, candidate)) {
              return candidate;
            }
            nextIndex++;
            if (nextIndex > index + 100) {
              break;
            }
          }
        }
      }
    }
    // Otherwise, just get next available
    return _findNextContainerLabel(dagManager, prefix);
  }

  /// Generate next uppercase label in sequence
  static String _generateNextUppercase(String current) {
    if (current.isEmpty) return 'A';

    // Single letter: A -> B, Z -> AA
    if (current.length == 1) {
      final code = current.codeUnitAt(0);
      if (code >= 65 && code < 90) {
        // A-Y -> B-Z
        return String.fromCharCode(code + 1);
      } else if (code == 90) {
        // Z -> AA
        return 'AA';
      }
    }

    // Multi-letter: increment last character, carry over if needed
    final chars = current.split('');
    int i = chars.length - 1;
    while (i >= 0) {
      final code = chars[i].codeUnitAt(0);
      if (code >= 65 && code < 90) {
        chars[i] = String.fromCharCode(code + 1);
        return chars.join();
      } else if (code == 90) {
        chars[i] = 'A';
        i--;
        if (i < 0) {
          // All Z's, add another A at front
          return 'A${chars.join()}';
        }
      } else {
        break;
      }
    }

    // Fallback: just return next available
    return 'AA';
  }

  /// Generate next lowercase label in sequence
  static String _generateNextLowercase(String current) {
    if (current.isEmpty) return 'a';

    // Single letter: a -> b, z -> aa
    if (current.length == 1) {
      final code = current.codeUnitAt(0);
      if (code >= 97 && code < 122) {
        // a-y -> b-z
        return String.fromCharCode(code + 1);
      } else if (code == 122) {
        // z -> aa
        return 'aa';
      }
    }

    // Multi-letter: increment last character, carry over if needed
    final chars = current.split('');
    int i = chars.length - 1;
    while (i >= 0) {
      final code = chars[i].codeUnitAt(0);
      if (code >= 97 && code < 122) {
        chars[i] = String.fromCharCode(code + 1);
        return chars.join();
      } else if (code == 122) {
        chars[i] = 'a';
        i--;
        if (i < 0) {
          // All z's, add another a at front
          return 'a${chars.join()}';
        }
      } else {
        break;
      }
    }

    // Fallback: just return next available
    return 'aa';
  }

  /// Check if label follows uppercase convention
  static bool _isUppercaseLabel(String label) {
    if (label.isEmpty) return false;
    return RegExp(r'^[A-Z]+$').hasMatch(label);
  }

  /// Check if label follows lowercase convention
  static bool _isLowercaseLabel(String label) {
    if (label.isEmpty) return false;
    return RegExp(r'^[a-z]+$').hasMatch(label);
  }

  /// Check if label is a container label (SL1, U1, etc.)
  static bool _isContainerLabel(String label, String prefix) {
    if (label.isEmpty) return false;
    final pattern = RegExp('^$prefix\\d+\$');
    return pattern.hasMatch(label);
  }
}

