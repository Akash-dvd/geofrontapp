import 'package:flutter/material.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';

/// Resolves style overrides by comparing the provided [style] or [fallbackColor]
/// against the type defaults. Returns an unmodifiable map when overrides exist
/// or `null` when no overrides are required.
Map<String, dynamic>? styleOverridesForType({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    final diff = style.diff(defaults);
    if (diff.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.unmodifiable(diff);
  }

  if (fallbackColor != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    if (fallbackColor.value == defaults.strokeColor.value) {
      return null;
    }
    return Map<String, dynamic>.unmodifiable({
      'strokeColor': CanvasStyle.colorToHex(fallbackColor),
    });
  }

  return null;
}

/// Extracts persisted style overrides from a geometry object's JSON payload.
Map<String, dynamic>? styleOverridesFromJson(Map<String, dynamic> json) {
  final rawStyle = json['style'];
  if (rawStyle is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(rawStyle);
  }
  if (rawStyle is Map) {
    return Map<String, dynamic>.unmodifiable(
      rawStyle.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
  return null;
}

/// Attempts to treat an arbitrary JSON value as a string-keyed map.
Map<String, dynamic>? castJsonObject(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return null;
}
