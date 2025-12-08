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
  union, // UnionGeometryObjectList containers (UN1, UN2, ...)
  polygon, // GeoPolygon
  polyLine, // GeoPolyLine
  polyArc, // GeoPolyArc
  polyArcGon, // GeoPolyArcGon
  transform, // GeoTrans objects (GeoRotate, GeoDilate, GeoLineInverse, GeoCircleInverse, GeoPointInverse)
  text, // CanvasText (may keep custom format)
}

/// Manages label generation and validation for geometry objects
class LabelManager {
  /// Get the next available label for a given object type
  /// Uses frugal naming: always checks from start to reuse deleted labels
  /// [excludeContainerId] - If provided, excludes labels from this container (useful during rebuild)
  /// [reservedLabels] - If provided, these labels are reserved for this operation and won't be used by others
  /// [usedReservedLabels] - Mutable set tracking which reserved labels have been consumed (will be updated)
  static String getNextAvailableLabel(
    DAGManager dagManager,
    GeometryObjectType type, {
    String? preferred,
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    // If preferred label is provided and unique, validate it matches the type convention
    if (preferred != null && preferred.isNotEmpty) {
      // Validate preferred label matches the expected convention for this type
      bool isValidPreferred = false;
      switch (type) {
        case GeometryObjectType.point:
          // Points should be uppercase (A-Z, AA-ZZ, etc.)
          isValidPreferred = _isUppercaseLabel(preferred);
          break;
        case GeometryObjectType.line:
        case GeometryObjectType.circle:
        case GeometryObjectType.arc:
          // Lines/circles/arcs should be lowercase (a-z, aa-zz, etc.)
          isValidPreferred = _isLowercaseLabel(preferred);
          break;
        case GeometryObjectType.simpleList:
          // SimpleList containers should be SL1, SL2, etc.
          isValidPreferred = _isContainerLabel(preferred, 'SL');
          break;
        case GeometryObjectType.union:
        case GeometryObjectType.polygon:
        case GeometryObjectType.polyLine:
        case GeometryObjectType.polyArc:
        case GeometryObjectType.polyArcGon:
          // Union containers should be UN1, UN2, etc.
          isValidPreferred = _isContainerLabel(preferred, 'UN');
          break;
        default:
          // For other types, accept any preferred label if unique
          isValidPreferred = true;
      }
      
      // Only use preferred label if it's valid for this type and unique
      // Also check if it's in reserved labels (if provided)
      if (isValidPreferred) {
        if (reservedLabels != null && 
            usedReservedLabels != null &&
            reservedLabels.contains(preferred) &&
            !usedReservedLabels.contains(preferred)) {
          // Reserved label is available and not yet used - consume it
          usedReservedLabels.add(preferred);
          return preferred;
        }
        if (isLabelUnique(dagManager, preferred, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels)) {
          return preferred;
        }
      }
    }

    // Generate label based on type
    switch (type) {
      case GeometryObjectType.point:
        return _findFirstAvailableUppercase(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.line:
      case GeometryObjectType.circle:
      case GeometryObjectType.arc:
        return _findFirstAvailableLowercase(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.simpleList:
        return _findNextContainerLabel(dagManager, 'SL', excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.union:
        return _findNextContainerLabel(dagManager, 'UN', excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.polygon:
      case GeometryObjectType.polyLine:
      case GeometryObjectType.polyArc:
      case GeometryObjectType.polyArcGon:
        // These are UnionGeometryObjectList subtypes, use UN1, UN2, etc.
        return _findNextContainerLabel(dagManager, 'UN', excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.transform:
        // Transform labels - may need custom handling
        return _findFirstAvailableLowercase(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
      case GeometryObjectType.text:
        // Text labels - may keep custom format
        return _findFirstAvailableLowercase(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
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
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    final usedLabels = getAllUsedLabels(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
    if (excludeId != null) {
      usedLabels.remove(excludeId);
    }
    // Reserved labels are available for this operation (if not already used)
    if (reservedLabels != null && 
        reservedLabels.contains(label) &&
        (usedReservedLabels == null || !usedReservedLabels.contains(label))) {
      return true;
    }
    return !usedLabels.contains(label);
  }

  /// Get all used labels from DAG nodes and elements
  /// Includes elements registered in elementToContainer map (even if container not yet in DAG)
  /// [excludeContainerId] - If provided, excludes labels from this container (useful during rebuild)
  /// [reservedLabels] - If provided, these labels are reserved and won't be considered as used
  /// [usedReservedLabels] - Labels from reservedLabels that have been consumed (should be treated as used)
  static Set<String> getAllUsedLabels(
    DAGManager dagManager, {
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    final usedLabels = <String>{};

    // Collect labels from DAG nodes
    for (final node in dagManager.nodes.values) {
      final obj = node.object;
      if (obj is GeometryObject) {
        // For regular objects, label is the display label
        if (obj.label.isNotEmpty) {
          // Skip reserved labels that haven't been used yet (they're available for the current operation)
          if (reservedLabels == null || 
              !reservedLabels.contains(obj.label) ||
              (usedReservedLabels != null && usedReservedLabels.contains(obj.label))) {
            usedLabels.add(obj.label);
          }
        }
        // Also check ID (which equals label in new system)
        // Skip reserved labels that haven't been used yet
        if (reservedLabels == null || 
            !reservedLabels.contains(obj.id) ||
            (usedReservedLabels != null && usedReservedLabels.contains(obj.id))) {
          usedLabels.add(obj.id);
        }
      }
    }

    // Collect element IDs from containers
    for (final node in dagManager.nodes.values) {
      final obj = node.object;
      // Skip labels from the container being rebuilt
      if (excludeContainerId != null && node.id == excludeContainerId) {
        continue;
      }
      
      // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so this covers both
      if (obj is UnionGeometryObjectList) {
        // Union elements are DAG nodes, not elements, so already collected above
        // But check their labels anyway
        for (final element in obj.elements) {
          // Elements in UnionGeometryObjectList are always GeometryObject
          // Skip reserved labels that haven't been used yet
          if (reservedLabels == null || 
              !reservedLabels.contains(element.id) ||
              (usedReservedLabels != null && usedReservedLabels.contains(element.id))) {
            usedLabels.add(element.id);
          }
          if (element.label.isNotEmpty) {
            if (reservedLabels == null || 
                !reservedLabels.contains(element.label) ||
                (usedReservedLabels != null && usedReservedLabels.contains(element.label))) {
              usedLabels.add(element.label);
            }
          }
        }
      }
    }

    // CRITICAL: Also check elementToContainer map for elements that have been registered
    // but whose containers haven't been added to DAG yet (prevents duplicate labels
    // when creating multiple elements in quick succession)
    // Exclude elements from the container being rebuilt (only during rebuild, not initial creation)
    for (final elementId in dagManager.elementToContainer.keys) {
      final containerId = dagManager.elementToContainer[elementId];
      
      // During rebuild: exclude old container elements, but include newly created ones (via usedReservedLabels)
      if (excludeContainerId != null && reservedLabels != null) {
        // If this element belongs to the container being rebuilt
        if (containerId == excludeContainerId) {
          // Only skip if it's a reserved label that hasn't been used yet
          // If it's been used (in usedReservedLabels), include it (it's a newly created label)
          if (reservedLabels.contains(elementId) &&
              (usedReservedLabels == null || !usedReservedLabels.contains(elementId))) {
            continue; // Skip old reserved labels that haven't been reused yet
          }
          // Include newly created labels (in usedReservedLabels) or non-reserved labels
          usedLabels.add(elementId);
          continue;
        }
      }
      
      // Skip reserved labels that haven't been used yet (they're available for the current operation)
      if (reservedLabels != null && 
          reservedLabels.contains(elementId) &&
          (usedReservedLabels == null || !usedReservedLabels.contains(elementId))) {
        continue;
      }
      // Always include labels that are in usedReservedLabels (tracked as used in this operation)
      if (usedReservedLabels != null && usedReservedLabels.contains(elementId)) {
        usedLabels.add(elementId);
        continue;
      }
      usedLabels.add(elementId);
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
        return _suggestNextContainer(dagManager, baseLabel, 'UN');
      default:
        return getNextAvailableLabel(dagManager, type);
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// Find first available uppercase label (A-Z, then AA-ZZ, then AAA-ZZZ, ...)
  /// Frugal naming: checks from start to reuse deleted labels
  static String _findFirstAvailableUppercase(
    DAGManager dagManager, {
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    final usedLabels = getAllUsedLabels(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
    
    // First, try to get an unused reserved label (during rebuild)
    if (reservedLabels != null && usedReservedLabels != null) {
      for (final reserved in reservedLabels) {
        if (!usedReservedLabels.contains(reserved) && _isUppercaseLabel(reserved)) {
          // Consume this reserved label
          usedReservedLabels.add(reserved);
          return reserved;
        }
      }
    }

    // Try single letters first (A-Z)
    for (int i = 0; i < 26; i++) {
      final label = String.fromCharCode(65 + i); // A-Z
      if (!usedLabels.contains(label)) {
        // Track this label as used if tracking set is provided
        usedReservedLabels?.add(label);
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
          // Track this label as used if tracking set is provided
          usedReservedLabels?.add(label);
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
            // Track this label as used if tracking set is provided
            usedReservedLabels?.add(label);
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
  static String _findFirstAvailableLowercase(
    DAGManager dagManager, {
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    final usedLabels = getAllUsedLabels(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
    
    // First, try to get an unused reserved label
    if (reservedLabels != null && usedReservedLabels != null) {
      for (final reserved in reservedLabels) {
        if (!usedReservedLabels.contains(reserved) && _isLowercaseLabel(reserved)) {
          // Consume this reserved label
          usedReservedLabels.add(reserved);
          return reserved;
        }
      }
    }

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

  /// Find next available container label (SL1, SL2, ... or UN1, UN2, ...)
  /// Frugal naming: checks from 1 to reuse deleted labels
  static String _findNextContainerLabel(
    DAGManager dagManager,
    String prefix, {
    String? excludeContainerId,
    Set<String>? reservedLabels,
    Set<String>? usedReservedLabels,
  }) {
    final usedLabels = getAllUsedLabels(dagManager, excludeContainerId: excludeContainerId, reservedLabels: reservedLabels, usedReservedLabels: usedReservedLabels);
    
    // First, try to get an unused reserved label
    if (reservedLabels != null && usedReservedLabels != null) {
      for (final reserved in reservedLabels) {
        if (!usedReservedLabels.contains(reserved) && _isContainerLabel(reserved, prefix)) {
          // Consume this reserved label
          usedReservedLabels.add(reserved);
          return reserved;
        }
      }
    }

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

  /// Check if label is a container label (SL1, UN1, etc.)
  static bool _isContainerLabel(String label, String prefix) {
    if (label.isEmpty) return false;
    final pattern = RegExp('^$prefix\\d+\$');
    return pattern.hasMatch(label);
  }
}

