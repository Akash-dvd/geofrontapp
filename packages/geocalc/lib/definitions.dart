part of 'Multivector.dart';

/// Extension methods for Multivector
extension MultivectorUtils on Multivector {
  /// Returns the reflection as Option<Multivector>
  /// Returns None if norm is None (not a scalar) or if norm is too small
  Option<Multivector> reflection(Multivector object) {
    return norm().flatMap((normValue) {
      final absNormValue = normValue.abs();
      if (absNormValue < 1e-14) {
        return Some(this);
      }
      final result = reversion() * object * this;
      return Some(result.scalarDivide(absNormValue));
    });
  }
}

// ============================================================================
// GEOMETRIC CONSTRUCTION FUNCTIONS (PLACEHOLDERS)
// ============================================================================
// These functions are invoked by geodraw objects to perform geometric
// calculations using Multivector geometric algebra.
//
// IMPLEMENTATION NOTE: These are placeholder signatures. Actual Multivector-
// based calculations will be populated by the maintainer.
// ============================================================================

// ----------------------------------------------------------------------------
// POINT CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct a free point at given coordinates
/// Returns: Multivector representing the point
Multivector constructFreePoint(double x, double y) {
  // print("constructFreePoint called");
  return Multivector(
    o: 1,
    e1: x,
    e2: y,
    O: (x * x + y * y) / 2,
  ); // Placeholder implementation
}

/// Construct uniForm
Multivector uniForm(Multivector line) {
  if (line.isLine()) {
    return line.scalarDivide(math.sqrt((line | line).s));
  } else {
    throw ArgumentError('constructPointFromCircle: Input is not a circle');
  }
}

/// Construct infForm
Multivector infForm(Multivector circle) {
  if (circle.isCircle()) {
    return circle.scalarDivide(circle.o);
  } else {
    throw ArgumentError('constructPointFromCircle: Input is not a circle');
  }
}

/// Construct point from circle
/// Returns: Multivector representing the point
Multivector constructPointFromCircle(Multivector circle) {
  final circleInf = infForm(circle);

  return circleInf +
      Multivector(O: (circleInf.norm().getOrElse(() => 0.0))).scalarDivide(2);
}

/// Construct midpoint between two points
/// Returns: Multivector representing the midpoint
Multivector constructMidpoint(Multivector point1, Multivector point2) {
  return constructPointFromCircle(point1 + point2);
}

/// Construct intersection point of two lines
/// Returns: Multivector representing the intersection point
Multivector constructLineLineIntersection(
  Multivector line1,
  Multivector line2,
) {
  return constructPointFromCircle((Multivector(o: 1) ^ line1 ^ line2).dual());
}

/// Construct intersection points of line and circle
/// Returns: List of Multivector (0, 1, or 2 points)
List<Multivector> constructLineCircleIntersection(
  Multivector line,
  Multivector circle,
) {
  final B = (line ^ circle).dual();
  final discriminant = (B | B).s;
  if (discriminant < -1e-10) {
    return [];
  } else if (discriminant.abs() < 1e-10) {
    return [constructPointFromCircle(B)];
  } else {
    final sqrtD = math.sqrt(discriminant);
    final rO = Multivector(s: 1) + B.scalarDivide(sqrtD);
    final x = Multivector(o: 1) < (B);

    final b1 = rO * x;
    final b2 = x * rO;
    return [constructPointFromCircle(b1), constructPointFromCircle(b2)];
  }
}

/// Construct intersection points of two circles
/// Returns: List of Multivector (0, 1, or 2 points)
List<Multivector> constructCircleCircleIntersection(
  Multivector circle1,
  Multivector circle2,
) {
  // TODO order of circle1 and circle2 should not matter
  final B = (circle1 ^ circle2).dual();
  final discriminant = (B | B).s;
  if (discriminant < -1e-10) {
    return [];
  } else if (discriminant.abs() < 1e-10) {
    return [constructPointFromCircle(B)];
  } else {
    final sqrtD = math.sqrt(discriminant);
    final rO = Multivector(s: 1) + B.scalarDivide(sqrtD);
    final x = Multivector(o: 1) < (B);

    final b1 = rO * x;
    final b2 = x * rO;
    return [constructPointFromCircle(b1), constructPointFromCircle(b2)];
  }
}

/// Construct inverse point with respect to a circle
/// Returns: Multivector representing the inverted point
Multivector constructInversePoint(Multivector point, Multivector circle) {
  return constructPointFromCircle(
    circle.reflection(point).getOrElse(() => point),
  );
}

// ----------------------------------------------------------------------------
// LINE CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct line through two points
/// Returns: Multivector representing the line
Multivector constructLineFrom2Points(Multivector point1, Multivector point2) {
  return uniForm((point1 ^ point2 ^ Multivector(O: 1)).dual());
}

/// Construct perpendicular bisector of two points
/// Returns: Multivector representing the perpendicular bisector line
Multivector constructPerpendicularBisector(
  Multivector point1,
  Multivector point2,
) {
  return uniForm(Multivector(O: 1) < (point1 ^ point2));
}

/// Construct perpendicular line through a point
/// Returns: Multivector representing the perpendicular line
Multivector constructPerpendicularLine(Multivector line, Multivector point) {
  return uniForm((point ^ line ^ Multivector(O: 1)).dual());
}

/// Construct parallel line through a point
/// Returns: Multivector representing the parallel line
Multivector constructParallelLine(Multivector line, Multivector point) {
  return uniForm(point < (line ^ Multivector(O: 1)));
}

/// Construct polar line of a point with respect to a circle
/// Returns: Multivector representing the polar line
Multivector constructPolarLine(Multivector point, Multivector circle) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructPolarLine: Multivector implementation pending',
  );
}

/// Construct angle bisector of three points (vertex at point2)
/// Returns: Multivector representing the angle bisector line
Multivector constructAngleBisector3Points(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructAngleBisector3Points: Multivector implementation pending',
  );
}

/// Construct angle bisector of two lines
/// Returns: List of Multivector (2 bisector lines)
List<Multivector> constructAngleBisector2Lines(
  Multivector line1,
  Multivector line2,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructAngleBisector2Lines: Multivector implementation pending',
  );
}

// ----------------------------------------------------------------------------
// CIRCLE CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct circle with center and point on circumference
/// Returns: Multivector representing the circle
Multivector constructCircleFromCenterAndPoint(
  Multivector center,
  Multivector pointOnCircle,
) {
  return infForm(pointOnCircle < (center ^ Multivector(O: 1)));
}

/// Construct circle with center and radius
/// Returns: Multivector representing the circle
Multivector constructCircleFromCenterAndRadius(
  Multivector center,
  double radius,
) {
  if (center.isPoint()) {
    final rSquared = radius * radius;
    return Multivector(
      o: 1,
      e1: center.e1,
      e2: center.e2,
      O: (center.e1 * center.e1 + center.e2 * center.e2 - rSquared) / 2,
    );
  } else {
    throw ArgumentError(
      'constructCircleFromCenterAndRadius: Input is not a point',
    );
  }
}

/// Construct circle through three points
/// Returns: Multivector representing the circle
Multivector constructCircleThrough3Points(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  return infForm((point1 ^ point2 ^ point3).dual());
}

/// Construct inverse circle with respect to a circle
/// Returns: Multivector representing the inverted circle
Multivector constructInverseCircle(
  Multivector circleToInvert,
  Multivector inversionCircle,
) {
  return infForm(
    inversionCircle.reflection(circleToInvert).getOrElse(() => circleToInvert),
  );
}

/// Construct tangent lines from external point to circle
/// Returns: List of Multivector (0, 1, or 2 tangent lines)
List<Multivector> constructTangentLines(Multivector point, Multivector circle) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructTangentLines: Multivector implementation pending',
  );
}

// ----------------------------------------------------------------------------
// TRANSFORMATION CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct rotation of object around center by angle
/// Returns: Multivector representing the rotated object
Multivector constructRotation(
  Multivector object,
  Multivector center,
  double angleRadians,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructRotation: Multivector implementation pending',
  );
}

/// Construct dilation of object from center with scale factor
/// Returns: Multivector representing the dilated object
Multivector constructDilation(
  Multivector object,
  Multivector center,
  double scaleFactor,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'constructDilation: Multivector implementation pending',
  );
}

/// Construct reflection of object across line
/// Returns: Multivector representing the reflected object
Multivector constructReflectionAcrossLine(
  Multivector object,
  Multivector line,
) {
  return line.reflection(object).getOrElse(() => object);
}

/// Construct reflection of object across point
/// Returns: Multivector representing the reflected object
Multivector constructReflectionAcrossPoint(
  Multivector object,
  Multivector point,
) {
  return (point ^ Multivector(O: 1)).reflection(object).getOrElse(() => object);
}

// ----------------------------------------------------------------------------
// MEASUREMENT FUNCTIONS
// ----------------------------------------------------------------------------

/// Calculate distance between two points
/// Returns: double representing the distance
double measureDistance(Multivector point1, Multivector point2) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'measureDistance: Multivector implementation pending',
  );
}

/// Calculate angle between three points (vertex at point2)
/// Returns: double representing the angle in radians
double measureAngle(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError('measureAngle: Multivector implementation pending');
}

/// Calculate length of a segment
/// Returns: double representing the length
double measureSegmentLength(Multivector startPoint, Multivector endPoint) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'measureSegmentLength: Multivector implementation pending',
  );
}

/// Calculate arc length on a circle between two points
/// Returns: double representing the arc length
double measureArcLength(
  Multivector circle,
  Multivector startPoint,
  Multivector endPoint,
  bool longerArc,
) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'measureArcLength: Multivector implementation pending',
  );
}

/// Calculate area of a polygon given its vertices
/// Returns: double representing the area
double measurePolygonArea(List<Multivector> vertices) {
  // TODO: Implement using Multivector geometric algebra (shoelace formula)
  throw UnimplementedError(
    'measurePolygonArea: Multivector implementation pending',
  );
}

/// Calculate radius of a circle
/// Returns: double representing the radius
double measureCircleRadius(Multivector circle) {
  // TODO: Implement using Multivector geometric algebra
  throw UnimplementedError(
    'measureCircleRadius: Multivector implementation pending',
  );
}

// ----------------------------------------------------------------------------
// DISTANCE CALCULATIONS
/// Calculate distance from a point to another point
/// Returns: double representing the distance
double distancePointToPoint(Multivector point1, Multivector point2) {
  final p1 = infForm(point1);
  final p2 = infForm(point2);
  final d = math.sqrt(((p1 | p2).s) * (-2));
  return d;
}

/// Calculate distance from a point to a line
/// Returns: double representing the perpendicular distance
double distancePointToLine(Multivector point, Multivector line) {
  final l1 = infForm(point);
  final p1 = uniForm(line);
  final d = (l1 | p1).s.abs();
  return d;
}

/// Calculate distance from a point to a circle
/// Returns: double representing the distance to the circle's circumference
double distancePointToCircle(Multivector point, Multivector circle) {
  final p1 = infForm(point);
  final c1 = infForm(circle);
  final d = math.sqrt(((p1 | c1).s) * (-2));
  return d;
}

// ----------------------------------------------------------------------------
// GEOMETRIC QUERIES
// ----------------------------------------------------------------------------

/// Check if a point lies on a line
/// Returns: bool indicating if point is on line (within tolerance)
bool isPointOnLine(
  Multivector point,
  Multivector line, {
  double tolerance = 1e-10,
}) {
  if (!point.isPoint()) {
    throw ArgumentError('isPointOnLine: Input is not a point');
  }
  if (!line.isLine()) {
    throw ArgumentError('isPointOnLine: Input is not a line');
  }
  return (point | line).isZero();
}

/// Check if a point lies on a circle
/// Returns: bool indicating if point is on circle (within tolerance)
bool isPointOnCircle(
  Multivector point,
  Multivector circle, {
  double tolerance = 1e-10,
}) {
  if (!point.isPoint()) {
    throw ArgumentError('isPointOnCircle: Input is not a point');
  }
  if (!circle.isCircle()) {
    throw ArgumentError('isPointOnCircle: Input is not a circle');
  }
  return (point | circle).isZero();
}

/// Check if two lines are parallel
/// Returns: bool indicating if lines are parallel (within tolerance)
bool areLinesParallel(
  Multivector line1,
  Multivector line2, {
  double tolerance = 1e-10,
}) {
  final B = line1 ^ line2;
  return (B | B).isZero();
}

/// Check if two lines are perpendicular
/// Returns: bool indicating if lines are perpendicular (within tolerance)
bool areLinesPerpendicular(
  Multivector line1,
  Multivector line2, {
  double tolerance = 1e-10,
}) {
  return (line1 | line2).isZero();
}

/// Get center of a circle
/// Returns: Multivector representing the center point
Multivector getCircleCenter(Multivector circle) {
  return infForm(circle);
}
