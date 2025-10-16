/// Runtime type hierarchy utilities for command validation
library;

import 'dart:collection';

import 'package:flutter/material.dart';

import '../../models/canvas_object.dart';
import '../../models/canvas_style.dart';
import '../../models/canvas_style_defaults.dart';
import '../../models/geometry_object.dart';
import '../../models/simple/geo_circle.dart';
import '../../models/simple/geo_line.dart';
import '../../models/simple/geo_point.dart';
import '../../models/simple/geo_trans.dart';
import '../../models/simple_lists/geo_intersection.dart';
import '../../models/complex/geo_shapes.dart';
import '../../models/text/canvas_text.dart';

/// Maintains runtime type relationships for canvas objects.
class TypeHierarchy {
  TypeHierarchy._internal() {
    _registerBuiltIns();
  }

  /// Global singleton instance.
  static final TypeHierarchy instance = TypeHierarchy._internal();

  final Map<Type, Set<Type>> _parents = HashMap<Type, Set<Type>>();

  void _registerType(Type type, Set<Type> parents, {CanvasStyle? style}) {
    final normalized = {...parents};
    _parents[type] = normalized;
    CanvasStyleDefaults.instance.registerInheritance(type, normalized);
    if (style != null) {
      CanvasStyleDefaults.instance.registerStyle(type, style);
    }
  }

  void _registerBuiltIns() {
    // Core canvas hierarchy
    _registerType(CanvasObject, {Object}, style: CanvasStyle.baseDefaults);
    _registerType(
      GeometryObject,
      {CanvasObject, Object},
      style: CanvasStyle.baseDefaults.copyWith(strokeWidth: 2.0, filled: false),
    );
    _registerType(
      CanvasText,
      {CanvasObject, Object},
      style: CanvasStyle.baseDefaults.copyWith(
        strokeColor: Colors.transparent,
        fillColor: Colors.transparent,
        filled: false,
        pointRadius: 0,
        labelColor: Colors.black87,
        labelFontSize: 16.0,
      ),
    );
    _registerType(SimpleGeometryObject, {GeometryObject, CanvasObject, Object});
    _registerType(SimpleGeometryObjectList, {
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(ComplexGeometryObject, {
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(ComplexGeometryObjectList, {
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Point family
    _registerType(
      GeoPoint,
      {SimpleGeometryObject, GeometryObject, CanvasObject, Object},
      style: CanvasStyle.baseDefaults.copyWith(
        pointRadius: 6.0,
        filled: true,
        strokeWidth: 1.5,
      ),
    );
    _registerType(GeoPointer, {
      GeoPoint,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoMidpoint, {
      GeoPoint,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoInvPoint, {
      GeoPoint,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Line family
    _registerType(
      GeoLine,
      {SimpleGeometryObject, GeometryObject, CanvasObject, Object},
      style: CanvasStyle.baseDefaults.copyWith(
        pointRadius: 0,
        filled: false,
        strokeWidth: 2.0,
      ),
    );
    _registerType(GeoLine2P, {
      GeoLine,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoPerpendicularBisector, {
      GeoLine,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoPerpendicularLine, {
      GeoLine,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoParallelLine, {
      GeoLine,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Circle family
    _registerType(GeoCircle, {
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoCircle2P, {
      GeoCircle,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoCircle3P, {
      GeoCircle,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoInvCircle, {
      GeoCircle,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Transformation family
    _registerType(GeoTrans, {
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoInverse, {
      GeoTrans,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoRotate, {
      GeoTrans,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoDilate, {
      GeoTrans,
      SimpleGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Simple geometry lists
    _registerType(GeoIntersection, {
      SimpleGeometryObjectList,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoTangent, {
      SimpleGeometryObjectList,
      GeometryObject,
      CanvasObject,
      Object,
    });

    // Complex geometry
    _registerType(GeoSegment, {
      ComplexGeometryObject,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoTriangle, {
      ComplexGeometryObjectList,
      GeometryObject,
      CanvasObject,
      Object,
    });
    _registerType(GeoPolygon, {
      ComplexGeometryObjectList,
      GeometryObject,
      CanvasObject,
      Object,
    });
  }

  /// Register a runtime type and its direct parents.
  /// Parents should include the full direct ancestry chain for accurate lookup.
  void register(Type type, Set<Type> parents) {
    if (_parents.containsKey(type)) {
      return;
    }
    _registerType(type, parents);
  }

  /// Check if [testType] is the same as or derives from [superType].
  bool isSubtypeOf(Type testType, Type superType) {
    if (testType == superType) return true;

    final parents = _parents[testType];
    if (parents == null || parents.isEmpty) {
      return false;
    }

    if (parents.contains(superType)) {
      return true;
    }

    for (final parent in parents) {
      if (isSubtypeOf(parent, superType)) {
        return true;
      }
    }
    return false;
  }

  /// Return all registered parent types for a given type.
  Set<Type> parentsOf(Type type) => _parents[type] ?? const {};

  /// Safe registration helper for newly created runtime types.
  void tryRegister(Type type, Set<Type> parents) {
    if (_parents.containsKey(type)) {
      return;
    }
    _registerType(type, parents);
  }
}
