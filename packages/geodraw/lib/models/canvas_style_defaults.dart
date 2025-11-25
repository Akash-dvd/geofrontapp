import 'dart:collection';

import 'package:flutter/material.dart';

import 'canvas_object.dart';
import 'canvas_style.dart';
import 'geometry_object.dart';
import 'simple/geo_circle.dart';
import 'simple/geo_line.dart';
import 'simple/geo_point.dart';
import 'text/canvas_text.dart';
import 'type_hierarchy.dart';

/// Maintains default style presets for every [CanvasObject] type.
class CanvasStyleDefaults {
  CanvasStyleDefaults._internal() {
    _registerBuiltIns();
  }

  /// Singleton instance used across the package.
  static final CanvasStyleDefaults instance = CanvasStyleDefaults._internal();

  final Map<Type, CanvasStyle> _overrides = HashMap<Type, CanvasStyle>();

  void _registerBuiltIns() {
    registerStyle(CanvasObject, CanvasStyle.baseDefaults);

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
        // Highlight: glowing effect for points
        highlightUseGlow: true,
        highlightGlowRadius: 3.0,
        highlightStrokeColor: Colors.orange,
        highlightFillColor: Colors.orange.withOpacity(0.8),
        highlightStrokeWidthMultiplier: 1.3,
      ),
    );

    // GeoPointer should always be solid (filled)
    registerStyle(
      GeoPointer,
      CanvasStyle.baseDefaults.copyWith(
        pointRadius: 6.0,
        filled: true, // Solid/filled style
        strokeWidth: 1.5,
        strokeColor: CanvasStyle.colorFromHex('#cc8f2e'), // Darker stroke
        fillColor: CanvasStyle.colorFromHex('#ffb239'),
        // Highlight: glowing effect for pointer points
        highlightUseGlow: true,
        highlightGlowRadius: 3.0,
        highlightStrokeColor: Colors.orange,
        highlightFillColor: Colors.orange.withOpacity(0.8),
        highlightStrokeWidthMultiplier: 1.3,
      ),
    );

    registerStyle(
      GeoLine,
      CanvasStyle.baseDefaults.copyWith(
        pointRadius: 0,
        filled: false,
        strokeWidth: 2.0,
        // Highlight: green, thicker stroke
        highlightStrokeColor: Colors.green,
        highlightStrokeWidthMultiplier: 1.5,
      ),
    );

    registerStyle(
      GeoCircle,
      CanvasStyle.baseDefaults.copyWith(
        pointRadius: 0,
        filled: false,
        strokeWidth: 2.0,
        // Highlight: blue, thicker stroke
        highlightStrokeColor: Colors.blue,
        highlightStrokeWidthMultiplier: 1.5,
      ),
    );
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
    for (final candidate in TypeHierarchy.instance.ancestorsOf(type)) {
      final style = _overrides[candidate];
      if (style != null) {
        return style;
      }
    }

    return CanvasStyle.baseDefaults;
  }
}
