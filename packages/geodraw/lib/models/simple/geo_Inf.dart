import 'package:flutter/material.dart';
import 'package:geocalc/Multivector.dart';

import '../canvas_style.dart';
import '../canvas_style_defaults.dart';
import '../geometry_object.dart';

/// Represents a point at infinity (multivector where only O component is finite)
class GeoInf extends SimpleGeometryObject {
  GeoInf({
    required super.id,
    required super.label,
    required super.dependencies,
    required super.multivector,
    super.visible,
    super.styleOverrides,
  }) : assert(
         multivector.isInf(),
         'GeoInf requires a multivector where only O component is finite',
       );

  /// Create a GeoInf from a multivector with only O component finite
  static GeoInf fromMultivector({
    required String id,
    required String label,
    required Multivector multivector,
    List<String> dependencies = const [],
    bool visible = true,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    if (!multivector.isInf()) {
      throw ArgumentError('Multivector must have only O component finite for GeoInf');
    }

    final normalizedOverrides = _styleOverridesFromStyle(
      type: GeoInf,
      style: style,
      overrides: styleOverrides,
    );

    return GeoInf(
      id: id,
      label: label,
      dependencies: dependencies,
      multivector: multivector,
      visible: visible,
      styleOverrides: normalizedOverrides,
    );
  }

  /// Get the O component value (the only finite component)
  double get oValue => multivector.O;

  @override
  GeoInf copyWith({
    String? id,
    String? label,
    List<String>? dependencies,
    Multivector? multivector,
    bool? visible,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) {
    final overrides =
        styleOverrides ??
        (style == null ? this.styleOverrides : resolveStyleOverrides(style));
    return GeoInf(
      id: id ?? this.id,
      label: label ?? this.label,
      dependencies: dependencies ?? this.dependencies,
      multivector: multivector ?? this.multivector,
      visible: visible ?? this.visible,
      styleOverrides: overrides,
    );
  }

  @override
  String get type => 'GeoInf';

  @override
  void draw(Canvas canvas, Paint paint) {
    // GeoInf is drawn in screen space by the canvas painter
    // This method is kept for compatibility but won't be called for GeoInf
    // The actual drawing happens in GeoDrawCanvasPainter._drawInfinityPoint()
    if (!visible) return;
    // No-op: drawing handled in screen space by canvas painter
  }

  @override
  bool contains(Offset position) {
    // Infinity points are not contained at any finite position
    return false;
  }

  @override
  Rect getBounds() {
    // Infinity points have no finite bounds
    return Rect.zero;
  }

  @override
  double distanceTo(Offset point) {
    // Distance to infinity is always infinite
    return double.infinity;
  }

  @override
  bool intersects(SimpleGeometryObject other) {
    // Infinity points don't intersect with finite geometry
    // They may be used in geometric constructions but don't have finite intersections
    return false;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['properties'] = {
      'O': multivector.O,
    };
    return json;
  }

  static GeoInf fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? const {};
    final mv = SimpleGeometryObject.decodeMultivector(
      json[SimpleGeometryObject.multivectorKey],
    );
    
    // Ensure multivector has only O component finite
    final oValue = (props['O'] as num?)?.toDouble() ?? mv.O;
    final infMv = Multivector(O: oValue);

    final styleOverrides = _styleOverridesFromJson(
      json,
      legacyProps: props,
      fallbackColor: CanvasStyleDefaults.instance
          .resolveForType(GeoInf)
          .strokeColor,
    );
    final deps = (json['dependencies'] as List?)?.cast<String>() ?? const [];

    return GeoInf(
      id: json['id'] as String,
      label: json['label'] as String,
      dependencies: deps,
      multivector: infMv,
      visible: json['visible'] as bool? ?? true,
      styleOverrides: styleOverrides,
    );
  }

  @override
  GeometryObject? rebuildFromParents(List<GeometryObject> parents, dynamic dagManager) {
    // Infinity points typically don't rebuild from parents
    // They are usually created directly from multivector calculations
    return null;
  }
}

Map<String, dynamic>? _styleOverridesFromStyle({
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

Map<String, dynamic>? _styleOverridesFromJson(
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
