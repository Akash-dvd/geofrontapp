import 'package:flutter/material.dart';

import 'canvas_style.dart';
import 'canvas_style_defaults.dart';

/// Abstract base class for all objects that can be drawn on the canvas
abstract class CanvasObject {
  /// Draw the object on the canvas
  void draw(Canvas canvas, Paint paint);

  /// Check if a point is contained within this object's bounds
  bool contains(Offset position);

  /// Get the bounding rectangle of this object
  Rect getBounds();

  /// Whether this object is visible
  bool get visible;

  /// Unique identifier for this object
  String get id;

  /// Default style applied when no overrides are present
  CanvasStyle get defaultStyle => CanvasStyleDefaults.instance.resolveFor(this);

  /// Effective style for this object (defaults merged with overrides)
  CanvasStyle get style;

  /// Serialize this object to JSON
  /// Each concrete class must implement its own serialization logic
  /// that captures all of its specific properties and intricacies.
  Map<String, dynamic> toJson();

  /// Get the type identifier for this object class
  /// Used during deserialization to determine which fromJson to call
  String get type;
}
