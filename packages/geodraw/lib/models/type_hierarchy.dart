/// Runtime type hierarchy utilities for command validation
library;

import 'dart:collection';

import 'canvas_object.dart';
import 'geometry_object.dart';
import 'simple/geo_circle.dart';
import 'simple/geo_line.dart';
import 'simple/geo_point.dart';
import 'simple/geo_Inf.dart';
import 'simple/geo_flex.dart';
import 'simple/geo_transformed_simple.dart';
import 'transforms/geo_trans.dart';
import 'simple_lists/geo_intersection.dart';
import 'simple_lists/geo_tangent.dart';
import 'complex/geo_shapes.dart';
import 'complex/complex_geometry_object.dart';
import 'complex/geo_shapes_list.dart';
import 'complex/geo_transformed_complex.dart';
import 'text/canvas_text.dart';

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
  }

  void _registerBuiltIns() {
    // Core canvas hierarchy
    _registerType(CanvasObject, {Object});
    _registerType(GeometryObject, {CanvasObject});
    _registerType(CanvasText, {CanvasObject});
    _registerType(SimpleGeometryObject, {GeometryObject});
    _registerType(ComplexGeometryObject, {GeometryObject});
    _registerType(UnionGeometryObjectList, {GeometryObject});
    _registerType(GenSimpleGeometryObjectList, {UnionGeometryObjectList});
    _registerType(UnionComplexObjectList, {UnionGeometryObjectList});
    _registerType(RecursiveUnionGeo, {GeometryObject});

    // Point family
    _registerType(GeoPoint, {SimpleGeometryObject});
    _registerType(GeoPointer, {GeoPoint});
    _registerType(GeoMidpoint, {GeoPoint});
    _registerType(GeoOrthocenter, {GeoPoint});
    _registerType(GeoConstructedPoint, {GeoPoint});
    _registerType(GeoGliderPoint, {GeoPoint});
    _registerType(GeoTransPoint, {GeoPoint});
    _registerType(GeoInf, {SimpleGeometryObject});

    // Line family
    _registerType(GeoLine, {SimpleGeometryObject});
    _registerType(GeoLine2P, {GeoLine});
    _registerType(GeoLine2Sim, {GeoLine});
    _registerType(GeoPerpendicularBisector, {GeoLine});
    _registerType(GeoPerpendicularBisectorFlex, {GeoLine});
    _registerType(GeoPerpendicularLine, {GeoLine});
    _registerType(GeoPerpendicularLineFlex, {GeoLine});
    _registerType(GeoParallelLine, {GeoLine});
    _registerType(GeoParallelLineFlex, {GeoLine});
    _registerType(GeoAngleBisector3P, {GeoLine});
    _registerType(GeoPolarLine, {GeoLine});
    _registerType(GeoTangentLine, {GeoLine});

    // Circle family
    _registerType(GeoCircle, {SimpleGeometryObject});
    _registerType(GeoCircle2P, {GeoCircle});
    _registerType(GeoCircle3P, {GeoCircle});
    _registerType(GeoCircleFlex, {GeoCircle});
    _registerType(GeoTransCircle, {GeoCircle});
    _registerType(GeoIncircle, {GeoCircle});
    _registerType(GeoExcircle, {GeoCircle});
    _registerType(GeoIcircle, {GeoCircle});
    
    // Generic flexible geometry
    _registerType(Geo3Flex, {SimpleGeometryObject});
    _registerType(GeoALCbc, {SimpleGeometryObject});

    // Transformation family
    _registerType(GeoTrans, {SimpleGeometryObject});
    _registerType(GeoLineInverse, {GeoTrans});
    _registerType(GeoCircleInverse, {GeoTrans});
    _registerType(GeoPointInverse, {GeoTrans});
    _registerType(GeoRotate, {GeoTrans});
    _registerType(GeoDilate, {GeoTrans});
    _registerType(GeoTranslate, {GeoTrans});
    _registerType(GeoTransLine, {GeoLine});
    _registerType(GeoTransSegment, {GeoSegment});
    _registerType(GeoTransArc, {GeoArc});
    _registerType(GeoTransUnionGeometryObjectList, {UnionGeometryObjectList});

    // Simple geometry lists
    _registerType(GeoIntersection, {GenSimpleGeometryObjectList});
    _registerType(GeoTangentList, {GenSimpleGeometryObjectList});

    // Complex geometry
    _registerType(GeoArc, {ComplexGeometryObject});
    _registerType(GeoArc3P, {GeoArc});
    _registerType(GeoSegment, {ComplexGeometryObject});
    _registerType(GeoSegment2P, {GeoSegment});
    _registerType(GeoPolyArcBase, {UnionComplexObjectList});
    _registerType(GeoPolyArc, {GeoPolyArcBase});
    _registerType(GeoPolyArcGon, {GeoPolyArcBase});
    _registerType(GeoPolyLine, {GeoPolyArcBase});
    _registerType(GeoPolygon, {GeoPolyArcGon});
    _registerType(GeoTriangle, {GeoPolygon});
    _registerType(GeoRegularPolygon, {GeoPolygon});
    _registerType(GeoRegularPolygon2P, {GeoRegularPolygon});
    _registerType(GeoRegularPolygonSegment, {GeoRegularPolygon});
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

  /// Return the type and all ancestor types in breadth-first order.
  Iterable<Type> ancestorsOf(Type type) sync* {
    final visited = <Type>{};
    final queue = Queue<Type>()..add(type);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!visited.add(current)) {
        continue;
      }

      yield current;

      final parents = _parents[current];
      if (parents == null) {
        continue;
      }

      for (final parent in parents) {
        if (!visited.contains(parent)) {
          queue.add(parent);
        }
      }
    }
  }
}
