import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../canvas_object.dart';
import '../canvas_style.dart';
import '../canvas_style_defaults.dart';

/// Text annotation rendered on the canvas.
class CanvasText extends CanvasObject {
  @override
  final String id;

  final String text;
  final Offset position;
  final bool _visible;
  final TextAlign align;
  final double rotationDegrees;

  /// Serialized style overrides relative to [defaultStyle].
  final Map<String, dynamic> styleOverrides;

  CanvasText({
    required this.id,
    required this.text,
    required this.position,
    bool visible = true,
    this.align = TextAlign.left,
    this.rotationDegrees = 0,
    CanvasStyle? style,
    Map<String, dynamic>? styleOverrides,
  }) : _visible = visible,
       styleOverrides = Map.unmodifiable(
         styleOverrides ??
             (style == null
                 ? const {}
                 : style.diff(
                     CanvasStyleDefaults.instance.resolveForType(CanvasText),
                   )),
       );

  @override
  CanvasStyle get style => CanvasStyle.fromDiff(defaultStyle, styleOverrides);

  @override
  bool contains(Offset position) {
    if (!visible) return false;
    final bounds = getBounds();
    return bounds.contains(position);
  }

  @override
  void draw(Canvas canvas, Paint paint) {
    if (!visible) return;

    final effectiveStyle = style;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: effectiveStyle.labelColor,
          fontSize: effectiveStyle.labelFontSize,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final screenPos = position;

    canvas.save();
    canvas.translate(screenPos.dx, screenPos.dy);
    if (rotationDegrees != 0) {
      canvas.rotate(rotationDegrees * (math.pi / 180));
    }
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  Rect getBounds() {
    final effectiveStyle = style;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: effectiveStyle.labelColor,
          fontSize: effectiveStyle.labelFontSize,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    return Rect.fromCenter(
      center: position,
      width: textPainter.width,
      height: textPainter.height,
    );
  }

  @override
  @override
  bool get visible => _visible;

  @override
  String get type => 'CanvasText';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'text': text,
      'x': position.dx,
      'y': position.dy,
      'visible': visible,
      'rotation': rotationDegrees,
      'align': align.name,
    };

    if (styleOverrides.isNotEmpty) {
      json['style'] = styleOverrides;
    }

    return json;
  }
}
