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
      return Some(result.scalarDivide(absNormValue).sanitize());
    });
  }
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;

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

/// Construct signed infForm
Multivector signedInfForm(Multivector circle) {
  if (circle.isCircle()) {
    final orientation = circle.o;
    if (orientation == 0) {
      throw ArgumentError('infSignedForm: Circle has zero orientation');
    }
    return circle.scalarDivide(orientation).scalarMultiply(orientation.sign);
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
  // The polar line is the dual of (point ^ circle)
  return uniForm(Multivector(O: 1) < (point ^ circle));
}

/// Construct angle bisector of three points (vertex at point2)
/// Returns: Multivector representing the angle bisector line
Multivector constructAngleBisector3Points(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  // Construct the two lines from vertex to each point
  final line1 = constructLineFrom2Points(point2, point1);
  final line2 = constructLineFrom2Points(point2, point3);
  
  // The angle bisector passes through the vertex and bisects the angle
  // It can be found using the normalized sum of the two lines
  final bisector = uniForm(line1 + line2);
  
  return bisector;
}

/// Construct angle bisector of two lines
/// Returns: List of Multivector (2 bisector lines)
List<Multivector> constructAngleBisector2Lines(
  Multivector line1,
  Multivector line2,
) {
  // The two angle bisectors are the sum and difference of normalized lines
  final l1 = uniForm(line1);
  final l2 = uniForm(line2);
  
  return [
    uniForm(l1 + l2),  // Internal bisector
    uniForm(l1 - l2),  // External bisector
  ];
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

/// Construct circle through three points
/// Returns: Multivector representing the circle
Multivector constructCircleThrough3PointsSigned(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  return signedInfForm((point1 ^ point2 ^ point3).dual());
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
  // Get the polar line of the point with respect to the circle
  final polarLine = constructPolarLine(point, circle);
  
  // The tangent points are the intersections of the polar line with the circle
  final tangentPoints = constructLineCircleIntersection(polarLine, circle);
  
  // Construct lines from the external point to each tangent point
  return tangentPoints
      .map((tangentPoint) => constructLineFrom2Points(point, tangentPoint))
      .toList();
}

// ----------------------------------------------------------------------------
// TRANSFORMATION CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct rotation operator around [center] by [angleRadians]
/// Returns: Multivector representing the rotor
Multivector constructRotationOperator(
  Multivector center,
  double angleRadians,
) {
  final mv = (Multivector(O: 1) ^ center).dual();
  final halfAngle = angleRadians / 2;
  return Multivector(s: math.cos(halfAngle)) +
      mv.scalarMultiply(math.sin(halfAngle));
}

/// Construct rotation of object around center by angle
/// Returns: Multivector representing the rotated object
Multivector constructRotation(
  Multivector object,
  Multivector center,
  double angleRadians,
) {
  final rotor = constructRotationOperator(center, angleRadians);
  return rotor.reflection(object).getOrElse(() => object);
}

/// Apply a rotation rotor to an object multivector
Multivector applyRotationOperator(
  Multivector rotor,
  Multivector object,
) {
  return rotor.reflection(object).getOrElse(() => object);
}

/// Construct dilation operator from [center] with [scaleFactor]
Multivector constructDilationOperator(
  Multivector center,
  double scaleFactor,
) {
  final mv = (center ^ Multivector(O: 1));
  final halfAngle = scaleFactor / 2;
  return Multivector(s: _cosh(halfAngle)) + mv.scalarMultiply(_sinh(halfAngle));
}

/// Construct dilation of object from center with scale factor
/// Returns: Multivector representing the dilated object
Multivector constructDilation(
  Multivector object,
  Multivector center,
  double scaleFactor,
) {
  final dilator = constructDilationOperator(center, scaleFactor);
  return dilator.reflection(object).getOrElse(() => object);
}

/// Apply a dilation operator to an object multivector
Multivector applyDilationOperator(
  Multivector dilator,
  Multivector object,
) {
  return dilator.reflection(object).getOrElse(() => object);
}

/// Construct reflection operator across a normalized line.
Multivector constructLineReflectionOperator(Multivector line) {
  return uniForm(line);
}

/// Construct reflection operator across a normalized circle.
Multivector constructCircleReflectionOperator(Multivector circle) {
  return infForm(circle);
}

/// Construct reflection operator across a point.
Multivector constructPointReflectionOperator(Multivector point) {
  return point ^ Multivector(O: 1);
}

// ----------------------------------------------------------------------------
// REFLECTION HELPERS
// ----------------------------------------------------------------------------

/// Construct reflection of object across line
/// Returns: Multivector representing the reflected object
Multivector constructReflectionAcrossLine(
  Multivector object,
  Multivector line,
) {
  return _finalizeReflection(
    object: object,
    operator: constructLineReflectionOperator(line),
    signed: false,
  );
}

/// Construct reflection of object across point
/// Returns: Multivector representing the reflected object
Multivector constructReflectionAcrossPoint(
  Multivector object,
  Multivector point,
) {
  return _finalizeReflection(
    object: object,
    operator: constructPointReflectionOperator(point),
    signed: false,
  );
}


/// Construct reflection of object across circle
/// Returns: Multivector representing the reflected object
Multivector constructReflectionAcrossCircle(
  Multivector object,
  Multivector circle,
) {
  return _finalizeReflection(
    object: object,
    operator: constructCircleReflectionOperator(circle),
    signed: false,
  );
}

/// Construct reflection of object across line
/// Returns: Multivector representing the reflected object
Multivector constructSignedReflectionAcrossLine(
  Multivector object,
  Multivector line,
) {
  return _finalizeReflection(
    object: object,
    operator: constructLineReflectionOperator(line),
    signed: true,
  );
}

/// Construct reflection of object across point
/// Returns: Multivector representing the reflected object
Multivector constructSignedReflectionAcrossPoint(
  Multivector object,
  Multivector point,
) {
  return _finalizeReflection(
    object: object,
    operator: constructPointReflectionOperator(point),
    signed: true,
  );
}

/// Construct reflection of object across circle
/// Returns: Multivector representing the reflected object
Multivector constructSignedReflectionAcrossCircle(
  Multivector object,
  Multivector circle,
) {
  return _finalizeReflection(
    object: object,
    operator: constructCircleReflectionOperator(circle),
    signed: true,
  );
}

Multivector _finalizeReflection({
  required Multivector object,
  required Multivector operator,
  required bool signed,
}) {
  final reflected = operator.reflection(object).getOrElse(() => object);

  if (reflected.isCircle()) {
    return signed ? signedInfForm(reflected) : infForm(reflected);
  }

  if (reflected.isLine()) {
    return uniForm(reflected);
  }

  if (reflected.isPoint()) {
    return infForm(reflected);
  }

  return reflected;
}

/// Normalize a multivector after transformation to ensure it's in proper form
/// This handles cases where transformations produce valid but unnormalized multivectors
/// Returns: Normalized multivector (as line or circle), or original if normalization fails
Multivector normalizeTransformedMultivector(Multivector mv) {
  // Check if it looks like a line (has e1, e2, O components, o might be 0 or small)
  final looksLikeLine = mv.o.abs() < 1e-10 && 
                        (mv.e1.abs() > 1e-10 || mv.e2.abs() > 1e-10);
  // Check if it looks like a circle (has o component)
  final looksLikeCircle = mv.o.abs() > 1e-10;
  
  if (mv.isLine() || looksLikeLine) {
    try {
      return uniForm(mv);
    } catch (e) {
      // Normalization failed, return original
      return mv;
    }
  } else if (mv.isCircle() || looksLikeCircle) {
    try {
      return infForm(mv);
    } catch (e) {
      // Normalization failed, return original
      return mv;
    }
  }
  
  // Not a line or circle, return as-is
  return mv;
}

// ----------------------------------------------------------------------------
// MEASUREMENT FUNCTIONS
// ----------------------------------------------------------------------------

/// Calculate distance between two points
/// Returns: double representing the distance
double measureDistance(Multivector point1, Multivector point2) {
  return distancePointToPoint(point1, point2);
}

/// Calculate angle between three points (vertex at point2)
/// Returns: double representing the angle in radians
double measureAngle(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  // Convert points to coordinate form
  final p1 = infForm(point1);
  final p2 = infForm(point2);
  final p3 = infForm(point3);
  
  // Calculate vectors from vertex to the two points
  final v1x = p1.e1 - p2.e1;
  final v1y = p1.e2 - p2.e2;
  final v2x = p3.e1 - p2.e1;
  final v2y = p3.e2 - p2.e2;
  
  // Calculate angle using atan2
  final angle1 = math.atan2(v1y, v1x);
  final angle2 = math.atan2(v2y, v2x);
  
  var angle = angle2 - angle1;
  
  // Normalize to [0, 2π]
  while (angle < 0) {
    angle += 2 * math.pi;
  }
  while (angle > 2 * math.pi) {
    angle -= 2 * math.pi;
  }
  
  return angle;
}

/// Calculate length of a segment
/// Returns: double representing the length
double measureSegmentLength(Multivector startPoint, Multivector endPoint) {
  return distancePointToPoint(startPoint, endPoint);
}

/// Calculate arc length on a circle between two points
/// Returns: double representing the arc length
double measureArcLength(
  Multivector circle,
  Multivector startPoint,
  Multivector endPoint,
  bool longerArc,
) {
  final radius = measureCircleRadius(circle);
  final center = getCircleCenter(circle);
  
  // Convert points to coordinate form
  final c = infForm(center);
  final p1 = infForm(startPoint);
  final p2 = infForm(endPoint);
  
  // Calculate angles from center to each point
  final angle1 = math.atan2(p1.e2 - c.e2, p1.e1 - c.e1);
  final angle2 = math.atan2(p2.e2 - c.e2, p2.e1 - c.e1);
  
  // Calculate angular difference
  var angleDiff = angle2 - angle1;
  
  // Normalize to [0, 2π]
  while (angleDiff < 0) {
    angleDiff += 2 * math.pi;
  }
  while (angleDiff > 2 * math.pi) {
    angleDiff -= 2 * math.pi;
  }
  
  // Choose shorter or longer arc
  if (longerArc && angleDiff < math.pi) {
    angleDiff = 2 * math.pi - angleDiff;
  } else if (!longerArc && angleDiff > math.pi) {
    angleDiff = 2 * math.pi - angleDiff;
  }
  
  return radius * angleDiff;
}

/// Calculate area of a polygon given its vertices
/// Returns: double representing the area
double measurePolygonArea(List<Multivector> vertices) {
  if (vertices.length < 3) return 0.0;
  
  // Use shoelace formula
  double area = 0.0;
  
  for (int i = 0; i < vertices.length; i++) {
    final p1 = infForm(vertices[i]);
    final p2 = infForm(vertices[(i + 1) % vertices.length]);
    
    area += (p1.e1 * p2.e2) - (p2.e1 * p1.e2);
  }
  
  return area.abs() / 2.0;
}

/// Calculate radius of a circle
/// Returns: double representing the radius
double measureCircleRadius(Multivector circle) {
  if (!circle.isCircle()) {
    throw ArgumentError('measureCircleRadius: Input is not a circle');
  }
  
  // For a circle in the form (o, e1, e2, O):
  // radius² = (e1² + e2²) / o² - 2*O/o
  final circleInf = infForm(circle);
  final radiusSquared = circleInf.e1 * circleInf.e1 + 
                        circleInf.e2 * circleInf.e2 - 
                        2 * circleInf.O;
  
  if (radiusSquared < 0) return 0.0;
  
  return math.sqrt(radiusSquared);
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
  final p1 = infForm(point);
  final l1 = uniForm(line);
  final d = (l1 | p1).s;
  return d.abs();
}

/// Calculate distance from a point to a circle
/// Returns: double representing the distance to the circle's circumference
double distancePointToCircle(Multivector point, Multivector circle) {
  final p1 = infForm(point);
  final c1 = infForm(circle);
  final scalar = (p1 | c1).s;
  // 10x the scale
  final multiplier = scalar > 0 ? .2 : -.2;
  final d = math.sqrt(scalar * multiplier);
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
