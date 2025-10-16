import 'dart:collection';

import 'package:flutter/material.dart';

import 'canvas_object.dart';
import 'canvas_style.dart';
import 'geometry_object.dart';
import 'simple/geo_line.dart';
import 'simple/geo_point.dart';
import 'text/canvas_text.dart';

/// Maintains default style presets for every [CanvasObject] type.
class CanvasStyleDefaults {
  CanvasStyleDefaults._internal() {
    _registerBuiltIns();
  }

  /// Singleton instance used across the package.
  static final CanvasStyleDefaults instance = CanvasStyleDefaults._internal();

  final Map<Type, CanvasStyle> _overrides = HashMap<Type, CanvasStyle>();
  final Map<Type, Set<Type>> _parents = HashMap<Type, Set<Type>>();

  void _registerBuiltIns() {
    registerStyle(CanvasObject, CanvasStyle.baseDefaults);
    registerInheritance(CanvasObject, {Object});

    registerStyle(
      GeometryObject,
      CanvasStyle.baseDefaults.copyWith(strokeWidth: 2.0, filled: false),
    );

    registerStyle(
      CanvasText,
      CanvasStyle.baseDefaults.copyWith(
        strokeColor: Colors.transparent,
        fillColor: Colors.transparent,
        filled: false,
        pointRadius: 0,
        labelColor: Colors.black87,
        labelFontSize: 16.0,
      ),
    );

    registerStyle(
      GeoPoint,
      CanvasStyle.baseDefaults.copyWith(
        pointRadius: 6.0,
        filled: true,
        strokeWidth: 1.5,
      ),
    );

    registerStyle(
      GeoLine,
      CanvasStyle.baseDefaults.copyWith(
        pointRadius: 0,
        filled: false,
        strokeWidth: 2.0,
      ),
    );
  }

  /// Register explicit inheritance information for a [type].
  void registerInheritance(Type type, Set<Type> parents) {
    if (parents.isEmpty) return;
    _parents[type] = {...parents};
  }

  /// Register a style override for a specific [type].
  void registerStyle(Type type, CanvasStyle style) {
    _overrides[type] = style;
  }

  /// Resolve the default style for a specific [object] instance.
  CanvasStyle resolveFor(CanvasObject object) {
    return resolve(object.runtimeType);
  }

  /// Resolve the default style for a runtime [type].
  CanvasStyle resolveForType(Type type) {
    return resolve(type);
  }

  /// Resolve the default style for a runtime [type].
  CanvasStyle resolve(Type type) {
    final visited = <Type>{};
    final queue = Queue<Type>()..add(type);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final style = _overrides[current];
      if (style != null) {
        return style;
      }

      visited.add(current);
      final parents = _parents[current];
      if (parents == null) {
        continue;
      }

      for (final parent in parents) {
        if (!visited.contains(parent)) {
          queue.add(parent);
        }
      }
    }

    return CanvasStyle.baseDefaults;
  }
}
