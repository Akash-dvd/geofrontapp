import 'package:flutter/material.dart';
import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';
import 'geo_line.dart';

/// Helper function to create style overrides from a CanvasStyle
Map<String, dynamic>? styleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }
  if (style == null) {
    return null;
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  return Map<String, dynamic>.unmodifiable(style.diff(defaults));
}

/// Helper function to create style overrides from JSON
Map<String, dynamic>? styleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor) ?? fallbackColor;
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }
    final filled = legacyProps['filled'];
    if (filled is bool) {
      overrides['filled'] = filled;
    }
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}

/// Helper function to create line style overrides from a CanvasStyle
Map<String, dynamic>? lineStyleOverridesFromStyle({
  required Type type,
  CanvasStyle? style,
  Map<String, dynamic>? overrides,
  Color? fallbackColor,
  double? fallbackStrokeWidth,
  LineStyle? fallbackLineStyle,
}) {
  if (overrides != null) {
    return Map<String, dynamic>.unmodifiable(overrides);
  }

  if (style != null) {
    final defaults = CanvasStyleDefaults.instance.resolveForType(type);
    return Map<String, dynamic>.unmodifiable(style.diff(defaults));
  }

  final defaults = CanvasStyleDefaults.instance.resolveForType(type);
  final inferred = <String, dynamic>{};

  if (fallbackColor != null &&
      fallbackColor.value != defaults.strokeColor.value) {
    inferred['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (fallbackStrokeWidth != null &&
      !_almostEqual(fallbackStrokeWidth, defaults.strokeWidth)) {
    inferred['strokeWidth'] = fallbackStrokeWidth;
  }

  if (fallbackLineStyle != null) {
    final pattern = fallbackLineStyle.name;
    if (pattern != defaults.linePattern) {
      inferred['linePattern'] = pattern;
    }
  }

  if (inferred.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(inferred);
}

/// Helper function to create line style overrides from JSON
Map<String, dynamic>? lineStyleOverridesFromJson(
  Map<String, dynamic> json, {
  Map<String, dynamic>? legacyProps,
  Color? fallbackColor,
}) {
  final existing = GeometryObject.extractStyleOverrides(json);
  if (existing != null) {
    return Map<String, dynamic>.unmodifiable(existing);
  }

  final overrides = <String, dynamic>{};

  final rawColor = json.containsKey('color') ? json['color'] : null;
  final parsedColor = GeometryObject.parseColor(rawColor);
  if (parsedColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(parsedColor);
  }

  if (legacyProps != null) {
    final thickness = legacyProps['thickness'];
    if (thickness is num) {
      overrides['strokeWidth'] = thickness.toDouble();
    }

    final rawPattern = legacyProps['lineStyle'] ?? legacyProps['style'];
    final pattern = _normalizeLinePattern(rawPattern);
    if (pattern != null) {
      overrides['linePattern'] = pattern;
    }
  }

  if (overrides.isEmpty && fallbackColor != null) {
    overrides['strokeColor'] = CanvasStyle.colorToHex(fallbackColor);
  }

  if (overrides.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.unmodifiable(overrides);
}

String? _normalizeLinePattern(dynamic raw) {
  if (raw is String) {
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'solid':
      case 'dashed':
      case 'dotted':
        return lower;
    }
  } else if (raw is LineStyle) {
    return raw.name;
  }
  return null;
}

bool _almostEqual(double a, double b, [double epsilon = 0.0001]) {
  return (a - b).abs() < epsilon;
}

