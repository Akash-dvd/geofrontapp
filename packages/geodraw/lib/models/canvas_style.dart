import 'package:flutter/material.dart';

/// Shared style descriptor for all canvas-renderable objects.
class CanvasStyle {
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final double pointRadius;
  final bool filled;
  final String linePattern;
  final Color labelColor;
  final double labelFontSize;

  const CanvasStyle({
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.pointRadius,
    required this.filled,
    required this.linePattern,
    required this.labelColor,
    required this.labelFontSize,
  });

  /// Base defaults used when an object does not supply its own defaults.
  static const CanvasStyle baseDefaults = CanvasStyle(
    strokeColor: Colors.blue,
    fillColor: Colors.transparent,
    strokeWidth: 2.0,
    pointRadius: 5.0,
    filled: false,
    linePattern: 'solid',
    labelColor: Colors.black,
    labelFontSize: 14.0,
  );

  CanvasStyle copyWith({
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    double? pointRadius,
    bool? filled,
    String? linePattern,
    Color? labelColor,
    double? labelFontSize,
  }) {
    return CanvasStyle(
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      pointRadius: pointRadius ?? this.pointRadius,
      filled: filled ?? this.filled,
      linePattern: linePattern ?? this.linePattern,
      labelColor: labelColor ?? this.labelColor,
      labelFontSize: labelFontSize ?? this.labelFontSize,
    );
  }

  /// Calculate the difference between this style and the provided defaults.
  Map<String, dynamic> diff(CanvasStyle defaults) {
    final diff = <String, dynamic>{};

    if (strokeColor.value != defaults.strokeColor.value) {
      diff['strokeColor'] = colorToHex(strokeColor);
    }
    if (fillColor.value != defaults.fillColor.value) {
      diff['fillColor'] = colorToHex(fillColor);
    }
    if (!_equalsDouble(strokeWidth, defaults.strokeWidth)) {
      diff['strokeWidth'] = strokeWidth;
    }
    if (!_equalsDouble(pointRadius, defaults.pointRadius)) {
      diff['pointRadius'] = pointRadius;
    }
    if (filled != defaults.filled) {
      diff['filled'] = filled;
    }
    if (linePattern != defaults.linePattern) {
      diff['linePattern'] = linePattern;
    }
    if (labelColor.value != defaults.labelColor.value) {
      diff['labelColor'] = colorToHex(labelColor);
    }
    if (!_equalsDouble(labelFontSize, defaults.labelFontSize)) {
      diff['labelFontSize'] = labelFontSize;
    }

    return diff;
  }

  /// Construct a style by applying [diff] to [defaults].
  static CanvasStyle fromDiff(
    CanvasStyle defaults,
    Map<String, dynamic>? diff,
  ) {
    if (diff == null || diff.isEmpty) {
      return defaults;
    }

    Color resolveColor(String key, Color fallback) {
      final value = diff[key];
      if (value is String) {
        return colorFromHex(value);
      }
      if (value is int) {
        return Color(value);
      }
      return fallback;
    }

    double resolveDouble(String key, double fallback) {
      final value = diff[key];
      if (value is num) {
        return value.toDouble();
      }
      return fallback;
    }

    return CanvasStyle(
      strokeColor: diff.containsKey('strokeColor')
          ? resolveColor('strokeColor', defaults.strokeColor)
          : defaults.strokeColor,
      fillColor: diff.containsKey('fillColor')
          ? resolveColor('fillColor', defaults.fillColor)
          : defaults.fillColor,
      strokeWidth: resolveDouble('strokeWidth', defaults.strokeWidth),
      pointRadius: resolveDouble('pointRadius', defaults.pointRadius),
      filled: diff.containsKey('filled')
          ? (diff['filled'] as bool? ?? defaults.filled)
          : defaults.filled,
      linePattern: diff['linePattern'] as String? ?? defaults.linePattern,
      labelColor: diff.containsKey('labelColor')
          ? resolveColor('labelColor', defaults.labelColor)
          : defaults.labelColor,
      labelFontSize: resolveDouble('labelFontSize', defaults.labelFontSize),
    );
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  static Color colorFromHex(String hex) {
    var normalized = hex.replaceFirst('#', '');
    if (normalized.length == 6) {
      normalized = 'ff$normalized';
    }
    final value = int.parse(normalized, radix: 16);
    return Color(value);
  }

  static bool _equalsDouble(double a, double b, [double epsilon = 0.0001]) {
    return (a - b).abs() < epsilon;
  }
}
