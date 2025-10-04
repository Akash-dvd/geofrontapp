import 'package:flutter/material.dart';

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
}
