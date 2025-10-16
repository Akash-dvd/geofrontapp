/// Runtime type hierarchy utilities for command validation
library;

import 'dart:collection';

import '../../models/canvas_object.dart';
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

  void _registerType(Type type, Set<Type> parents) {
    final normalized = {...parents};
    _parents[type] = normalized;
    CanvasStyleDefaults.instance.registerInheritance(type, normalized);
  }

  void _registerBuiltIns() {
    // Core canvas hierarchy
    _registerType(CanvasObject, {Object});
    _registerType(GeometryObject, {CanvasObject});
    _registerType(CanvasText, {CanvasObject});
    _registerType(SimpleGeometryObject, {GeometryObject});
    _registerType(SimpleGeometryObjectList, {GeometryObject});
    _registerType(ComplexGeometryObject, {GeometryObject});
    _registerType(ComplexGeometryObjectList, {GeometryObject});

    // Point family
    _registerType(GeoPoint, {SimpleGeometryObject});
    _registerType(GeoPointer, {GeoPoint});
    _registerType(GeoMidpoint, {GeoPoint});
    _registerType(GeoInvPoint, {GeoPoint});

    // Line family
    _registerType(GeoLine, {SimpleGeometryObject});
    _registerType(GeoLine2P, {GeoLine});
    _registerType(GeoPerpendicularBisector, {GeoLine});
    _registerType(GeoPerpendicularLine, {GeoLine});
    _registerType(GeoParallelLine, {GeoLine});

    // Circle family
    _registerType(GeoCircle, {SimpleGeometryObject});
    _registerType(GeoCircle2P, {GeoCircle});
    _registerType(GeoCircle3P, {GeoCircle});
    _registerType(GeoInvCircle, {GeoCircle});

    // Transformation family
    _registerType(GeoTrans, {SimpleGeometryObject});
    _registerType(GeoInverse, {GeoTrans});
    _registerType(GeoRotate, {GeoTrans});
    _registerType(GeoDilate, {GeoTrans});

    // Simple geometry lists
    _registerType(GeoIntersection, {SimpleGeometryObjectList});
    _registerType(GeoTangent, {SimpleGeometryObjectList});

    // Complex geometry
    _registerType(GeoSegment, {ComplexGeometryObject});
    _registerType(GeoTriangle, {ComplexGeometryObjectList});
    _registerType(GeoPolygon, {ComplexGeometryObjectList});
  }

  /// Register a runtime type and its direct parents.
  /// Only the immediate parents are required; indirect ancestors are inferred.
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
