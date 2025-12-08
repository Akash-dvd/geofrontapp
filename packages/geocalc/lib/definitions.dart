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
      // If object is a vector, use vectorize(); otherwise use sanitize()
      if (object.isVector()) {
        return Some(result.scalarDivide(absNormValue).vectorize(1e-8));
      } else {
        return Some(result.scalarDivide(absNormValue).sanitize(1e-8));
      }
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
  // debugPrint("constructFreePoint called");
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
  // Some constructions (e.g., line-circle intersections) already yield
  // normalized point multivectors. Guard against that so we don't try to
  // treat a point as a circle.
  if (circle.isPoint()) {
    return infForm(circle);
  }

  // Extract coordinates from the circle multivector and use constructFreePoint
  final circleInf = infForm(circle);
  return constructFreePoint(circleInf.e1, circleInf.e2);
}

/// Construct midpoint between two points
/// Returns: Multivector representing the midpoint
Multivector constructMidpoint(Multivector point1, Multivector point2) {
  return constructPointFromCircle(point1 + point2);
}

// ----------------------------------------------------------------------------
// INTERSECTION FUNCTIONS
// ----------------------------------------------------------------------------

/// Construct intersection point of two lines
/// Returns: Multivector representing the intersection point
Multivector constructLineLineIntersection(
  Multivector line1,
  Multivector line2,
) {
  
  final mv1 = ((Multivector(o: 1) ^ line1 ^ line2).dual()).vectorize(1e-8);
  final mv2 = constructPointFromCircle(mv1);
  // debugPrint('constructLineLineIntersection called');
  return mv2;
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
  }
  else if (discriminant.abs() < 1e-10) {
    // Very small discriminant means tangent (one intersection) or no intersection
    // Check if B represents a valid point
    return [constructPointFromCircle(line<(B))];
  }
   else {
    final sqrtD = math.sqrt(discriminant);
    final bUnit = B.scalarDivide(sqrtD);
    final x = Multivector(o: 1) < (bUnit);
    final y = x < (bUnit);

    final b1 = constructPointFromCircle((x + y).vectorize(1e-8)).sanitize(1e-5);
    final b2 = constructPointFromCircle((x - y).vectorize(1e-8)).sanitize(1e-5);
    // debugPrint('b1: $b1');
    // debugPrint('b2: $b2');
    return [b1, b2];
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
  }
  else if (discriminant.abs() < 1e-10) {
    // Very small discriminant means tangent (one intersection) or no intersection
    // Check if B represents a valid point
    return [constructPointFromCircle(circle1<B)];
  }
   else {
    final sqrtD = math.sqrt(discriminant);
    final bUnit = B.scalarDivide(sqrtD);
    final x = Multivector(o: 1) < (bUnit);
    final y = x < (bUnit);

    final b1 = constructPointFromCircle((x + y).vectorize(1e-8)).sanitize(1e-5);
    final b2 = constructPointFromCircle((x - y).vectorize(1e-8)).sanitize(1e-5);
    return [b1, b2];
  }
}

// ----------------------------------------------------------------------------
// END INTERSECTION FUNCTIONS
// ----------------------------------------------------------------------------

/// Construct inverse point with respect to a circle
/// Returns: Multivector representing the inverted point
Multivector constructInversePoint(Multivector point, Multivector circle) {
  final mv1 = circle.reflection(point).getOrElse(() => point).vectorize(1e-8);
  return constructPointFromCircle(mv1);
}

// ----------------------------------------------------------------------------
// LINE CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct line through two points
/// Returns: Multivector representing the line
Multivector constructLineFrom2Points(Multivector point1, Multivector point2) {

  return uniForm(((point1 ^ point2 ^ Multivector(O: 1)).dual()).vectorize(1e-8));
}

/// Construct perpendicular bisector of two points
/// Returns: Multivector representing the perpendicular bisector line
Multivector constructPerpendicularBisector(
  Multivector point1,
  Multivector point2,
) {
  return uniForm((Multivector(O: 1) < (point1 ^ point2)).vectorize(1e-8));
}

/// Construct perpendicular line through a point
/// Returns: Multivector representing the perpendicular line
Multivector constructPerpendicularLine(Multivector line, Multivector point) {
  return uniForm(((point ^ line ^ Multivector(O: 1)).dual()).vectorize(1e-8));
}

/// Construct parallel line through a point
/// Returns: Multivector representing the parallel line
Multivector constructParallelLine(Multivector line, Multivector point) {
  return uniForm((point < (line ^ Multivector(O: 1))).vectorize(1e-8));
}

/// Construct polar line of a point with respect to a circle
/// Returns: Multivector representing the polar line
Multivector constructPolarLine(Multivector point, Multivector circle) {
  // The polar line is the dual of (point ^ circle)
  return uniForm((Multivector(O: 1) < (point ^ circle)).vectorize(1e-8));
}

/// Construct polar of a point with respect to a circle
/// First multivector is a point, second multivector is a circle
/// Returns: Multivector (to be implemented)
Multivector polar(Multivector point, Multivector circle) {
  return uniForm(Multivector(O: 1) < ((circle<(point^Multivector(O: 1)))^circle)).vectorize(1e-8);
}

/// aLCbc function
/// Takes three multivectors
/// Returns: Multivector (type not known beforehand - can be point, line, circle, or infinity)
Multivector aLCbc(Multivector mv1, Multivector mv2, Multivector mv3) {
  final result = (mv1 < (mv2 ^ mv3)).vectorize(1e-8);
  
  // Normalize based on result type
  // Check for infinity first
  if (result.isInf()) {
    return result; // Infinity doesn't need normalization
  }
  
  if (result.isLine()) {
    return uniForm(result);
  }
  
  if (result.isCircle()) {
    return infForm(result);
  }
  
  if (result.isPoint()) {
    return infForm(result);
  }
  
  // Fallback: return as-is if type is unclear
  return result;
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
  final bisector = uniForm((line1 + line2).vectorize(1e-8));
  
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
  return infForm((pointOnCircle < (center ^ Multivector(O: 1))).vectorize(1e-8));
}

/// Construct imaginary circle from two points
/// Returns: Multivector representing the imaginary circle (to be implemented)
Multivector? constructImaginaryCircleFrom2Points(
  Multivector point1,
  Multivector point2,
) {
  // TODO: Implementation to be filled in
  return null;
}

/// Construct circle with center and radius
/// Returns: Multivector representing the circle
Multivector constructCircleFromCenterAndRadius(
  Multivector center,
  double radius,
) {
  // Normalize center to infForm first to ensure it's in the correct form
  // Use relaxed tolerance for point validation
  Multivector centerInf;
  if (center.isPoint(customTolerance: 1e-8)) {
    centerInf = infForm(center);
  } else if (center.isCircle(customTolerance: 1e-8)) {
    // If it's a circle (point representation), extract the point
    centerInf = infForm(center);
    // Verify it's actually a point (zero norm) with relaxed tolerance
    if (!centerInf.isPoint(customTolerance: 1e-8)) {
      throw ArgumentError(
        'constructCircleFromCenterAndRadius: Input is not a valid point',
      );
    }
  } else {
    // Try to extract coordinates directly if it looks like a point
    // (has o, e1, e2, O components)
    try {
      centerInf = infForm(center);
      // If we can extract coordinates, use them even if isPoint() fails
      // This handles cases where constructFreePoint creates a valid point
      // but isPoint() check is too strict
      final rSquared = radius * radius;
      return Multivector(
        o: 1,
        e1: centerInf.e1,
        e2: centerInf.e2,
        O: (centerInf.e1 * centerInf.e1 + centerInf.e2 * centerInf.e2 - rSquared) / 2,
      );
    } catch (e) {
      throw ArgumentError(
        'constructCircleFromCenterAndRadius: Input is not a point: $e',
      );
    }
  }
  
  final rSquared = radius * radius;
  return Multivector(
    o: 1,
    e1: centerInf.e1,
    e2: centerInf.e2,
    O: (centerInf.e1 * centerInf.e1 + centerInf.e2 * centerInf.e2 - rSquared) / 2,
  );
}

/// Construct circle through three points
/// Returns: Multivector representing the circle
Multivector constructCircleThrough3Points(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  return infForm(((point1 ^ point2 ^ point3).dual()).vectorize(1e-8));
}

/// Construct circle through three points
/// Returns: Multivector representing the circle
Multivector constructCircleThrough3GeoSimpleObjects(
  Multivector ob1,
  Multivector ob2,
  Multivector ob3,
) {
  return infForm(((ob1 ^ ob2 ^ ob3).dual()).vectorize(1e-8));
}


/// Construct circle through three points
/// Returns: Multivector representing the circle
Multivector constructCircleThrough3PointsSigned(
  Multivector point1,
  Multivector point2,
  Multivector point3,
) {
  return signedInfForm(((point1 ^ point2 ^ point3).dual()).vectorize(1e-8));
}

/// Construct inverse circle with respect to a circle
/// Returns: Multivector representing the inverted circle
Multivector constructInverseCircle(
  Multivector circleToInvert,
  Multivector inversionCircle,
) {
  return infForm(
    inversionCircle.reflection(circleToInvert).getOrElse(() => circleToInvert).vectorize(1e-8),
  );
}

/// Construct tangent lines from external point to circle
/// Returns: List of Multivector (0, 1, or 2 tangent lines)
List<Multivector> constructTangentLines(Multivector point, Multivector circle) {
  // Normalize inputs to infForm for calculations
  final pointInf = infForm(point);
  final circleInf = infForm(circle);
  
  // Get the polar line of the point with respect to the circle
  // Use the polar function which is the correct implementation
  final polarLine = polar(pointInf, circleInf);
  
  // Check distance from point to circle center to determine position
  final center = getCircleCenter(circleInf);
  final centerInf = infForm(center);
  final dist = distancePointToPoint(pointInf, centerInf);
  final radius = measureCircleRadius(circleInf);
  
  // Check if point is inside, on, or outside the circle
  if (dist < radius - 1e-8) {
    // Point is inside circle - no tangents
    return [];
  } else if ((dist - radius).abs() < 1e-8) {
    // Point is on circle - return single tangent (perpendicular to radius)
    final radiusLine = constructLineFrom2Points(centerInf, pointInf);
    final tangent = constructPerpendicularLine(radiusLine, pointInf);
    return [uniForm(tangent)];
  }
  
  // Point is outside circle - should have 2 tangents
  // Check if polar line is valid (is a line)
  if (!polarLine.isLine(customTolerance: 1e-8)) {
    // Polar line is invalid - this shouldn't happen for external points
    // Fall back to empty result
    return [];
  }
  
  // The tangent points are the intersections of the polar line with the circle
  final tangentPoints = constructLineCircleIntersection(polarLine, circleInf);
  
  // Construct lines from the external point to each tangent point
  return tangentPoints
      .map((tangentPoint) => constructLineFrom2Points(pointInf, tangentPoint))
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
  final mv = (Multivector(O: 1) ^ infForm(center)).dual();
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

/// Generic operator application - works for rotation, dilation, and any reflection-based operator
/// This is the common pattern: operator.reflection(object)
Multivector applyOperator(
  Multivector operator,
  Multivector object,
) {
  return operator.reflection(object).getOrElse(() => object);
}

/// Apply a rotation rotor to an object multivector
Multivector applyRotationOperator(
  Multivector rotor,
  Multivector object,
) {
  return applyOperator(rotor, object);
}

/// Construct dilation operator from [center] with [scaleFactor]
/// [scaleFactor] interpretation:
///   - scale = 1: no change
///   - 0 < scale < 1: compression (e.g., 0.5 = half size)
///   - scale > 1: dilation (e.g., 2.0 = 2x larger)
///   - scale = 0: merges into center (returns point reflection operator)
///   - -1 < scale < 0: reflection + dilation (e.g., -0.5 = reflect then dilate by 1/0.5 = 2x)
///   - scale < -1: reflection + compression (e.g., -2.0 = reflect then compress by 1/2 = 0.5x)
/// In conformal geometric algebra, dilation uses: D = cosh(γ/2) + O sinh(γ/2) where γ = ln(scaleFactor)
Multivector constructDilationOperator(
  Multivector center,
  double scaleFactor,
) {
  // Special case: scale = 0 merges into center (point reflection)
  if (scaleFactor == 0.0) {
    return constructPointReflectionOperator(center);
  }
  
  // Special case: scale = 1 means no change (identity operator)
  if (scaleFactor == 1.0) {
    return Multivector(s: 1.0); // Identity operator
  }
  
  final mv = (center ^ Multivector(O: 1));
  
  // Convert linear scale factor to logarithmic scale: γ = ln(|scaleFactor|)
  // Then use half-angle: γ/2 = ln(|scaleFactor|)/2
  // We can compute cosh(ln(s)/2) and sinh(ln(s)/2) more efficiently using sqrt:
  // cosh(ln(s)/2) = (sqrt(s) + 1/sqrt(s)) / 2
  // sinh(ln(s)/2) = (sqrt(s) - 1/sqrt(s)) / 2
  // For negative values, use sqrt(abs(scaleFactor)) as mentioned
  final absScaleFactor = scaleFactor.abs();
  final sqrtScale = math.sqrt(absScaleFactor);
  final invSqrtScale = 1.0 / sqrtScale;
  final coshValue = (sqrtScale + invSqrtScale) / 2;
  final sinhValue = (sqrtScale - invSqrtScale) / 2;
  
  // Build dilation operator (same for positive and negative, sign handled via reflection)
  final dilator = Multivector(s: coshValue) + mv.scalarMultiply(sinhValue);
  
  // If scaleFactor is negative, combine with reflection operator
  if (scaleFactor < 0) {
    final reflectionOp = constructPointReflectionOperator(center);
    // Compose: R * D (reflection then dilation)
    return reflectionOp * dilator;
  }
  
  return dilator;
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
  return applyOperator(dilator, object);
}

/// Construct translation operator for translation by vector (dx, dy)
/// The multivector stores the translation vector as a point at (dx, dy)
/// Returns: Multivector representing the translator
Multivector constructTranslationOperator(double dx, double dy) {
  // Store translation vector as a point multivector at (dx, dy)
  // This multivector will be used to extract dx and dy for translation
  return Multivector(
    o: 1.0,
    e1: dx,
    e2: dy,
    O: 0.5 * (dx * dx + dy * dy),
  );
}

/// Apply a translation operator to an object multivector
/// The translator multivector encodes the translation vector (dx, dy)
Multivector applyTranslationOperator(
  Multivector translator,
  Multivector object,
) {
  // Extract translation vector (dx, dy) from the translator multivector
  final dx = translator.e1;
  final dy = translator.e2;
  
  // Apply translation to the multivector
  return Multivector(
    o: object.o,
    e1: object.e1 + dx * object.o,
    e2: object.e2 + dy * object.o,
    O: object.O + (dx * object.e1 + dy * object.e2) +
       0.5 * (dx * dx + dy * dy) * object.o,
  );
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
  return infForm(point) ^ Multivector(O: 1);
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

/// Construct signed reflection of object across line
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

/// Construct signed reflection of object across point
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

/// Construct signed reflection of object across circle
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

/// Helper to apply reflection based on subject type (line, circle, or point)
/// Consolidates the repetitive type checking pattern
Multivector applyReflectionByType(
  Multivector object,
  Multivector subject,
  bool signed,
) {
  if (subject.isLine()) {
    return signed
        ? constructSignedReflectionAcrossLine(object, subject)
        : constructReflectionAcrossLine(object, subject);
  }
  
  if (subject.isCircle()) {
    return signed
        ? constructSignedReflectionAcrossCircle(object, subject)
        : constructReflectionAcrossCircle(object, subject);
  }
  
  if (subject.isPoint()) {
    return signed
        ? constructSignedReflectionAcrossPoint(object, subject)
        : constructReflectionAcrossPoint(object, subject);
  }
  
  // Fallback for unknown types
  return subject.reflection(object).getOrElse(() => object);
}

Multivector _finalizeReflection({
  required Multivector object,
  required Multivector operator,
  required bool signed,
}) {
  final reflected = operator.reflection(object).getOrElse(() => object);

  // Check for infinity first - infinity doesn't need normalization
  // This happens when a point at the center of a circle is inverted
  if (reflected.isInf()) {
    return reflected;
  }

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
  // debugPrint('isPointOnLine: stage0');
  if (!point.isPoint(customTolerance: tolerance)) {
    // debugPrint((point|point).s);
    throw ArgumentError('isPointOnLine: Input is not a point');
  }
  // debugPrint('isPointOnLine: stage1');
  if (!line.isLine()) {
    // debugPrint((line|line).s);
    throw ArgumentError('isPointOnLine: Input is not a line');
  }
  // debugPrint('isPointOnLine: stage2');
  return (point | line).isZero(customTolerance: tolerance);
}

/// Check if a point lies on a circle
/// Returns: bool indicating if point is on circle (within tolerance)
bool isPointOnCircle(
  Multivector point,
  Multivector circle, {
  double tolerance = 1e-10,
}) {
  // debugPrint('isPointOnCircle: stage0');
  if (!point.isPoint(customTolerance: tolerance)) {
    // debugPrint((point|point).s);
    throw ArgumentError('isPointOnCircle: Input is not a point');
  }
  // debugPrint('isPointOnCircle: stage1');
  if (!circle.isCircle()) {
    throw ArgumentError('isPointOnCircle: Input is not a circle');
  }
  // debugPrint('isPointOnCircle: stage2');
  return (point | circle).isZero(customTolerance: tolerance);
}

/// Check if two multivectors are perpendicular
/// Returns: bool indicating if multivectors are perpendicular (within tolerance)
bool isPerpendicular(
  Multivector mv1,
  Multivector mv2, {
  double tolerance = 1e-10,
}) {
  return (mv1 | mv2).isZero(customTolerance: tolerance);
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

// ----------------------------------------------------------------------------
// COMPLEX BOUNDARY
// ----------------------------------------------------------------------------

/// Pure mathematical representation of a complex geometric boundary.
/// Represents a curve (line or circle) bounded by two points.
/// This is the mathematical foundation, independent of application-specific types.
class ComplexBoundary extends Equatable {
  const ComplexBoundary({
    required this.startPoint,
    required this.endPoint,
    required this.curve,
  });

  /// Start point as a Multivector
  final Multivector startPoint;
  
  /// End point as a Multivector
  final Multivector endPoint;
  
  /// The underlying curve (line or circle) as a Multivector
  final Multivector curve;

  /// Check if this represents a segment (curve is a line)
  bool get isSegment => curve.isLine();

  /// Check if this represents an arc (curve is a circle)
  bool get isArc => curve.isCircle();

  ComplexBoundary copyWith({
    Multivector? startPoint,
    Multivector? endPoint,
    Multivector? curve,
  }) {
    return ComplexBoundary(
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      curve: curve ?? this.curve,
    );
  }

  @override
  List<Object?> get props => [startPoint, endPoint, curve];
}

// ----------------------------------------------------------------------------
// COMPLEX BOUNDARY QUERIES
// ----------------------------------------------------------------------------

/// Check if a point lies on a segment
/// [point] - The point to check (as Multivector)
/// [segment] - The segment boundary containing startPoint, endPoint, and curve multivector
/// Returns: bool indicating if point is on the segment (within tolerance)
bool isPointOnSegment(
  Multivector point,
  ComplexBoundary segment, {
  double tolerance = 1e-8,
}) {
  // debugPrint('isPointOnSegment: stage0');
  if (!point.isPoint(customTolerance: tolerance)) {
    // debugPrint('isPointOnSegment: point is not a point');
    throw ArgumentError('isPointOnSegment: point is not a point');
  }
  // debugPrint('isPointOnSegment: stage1');
  if (!segment.isSegment) {
    // debugPrint('isPointOnSegment: boundary is not a segment (curve is not a line)');
    throw ArgumentError('isPointOnSegment: boundary is not a segment (curve is not a line)');
  }
  // debugPrint('isPointOnSegment: stage2');
  // First check if point is on the line (using isPointOnLine)
  if (!isPointOnLine(point, segment.curve, tolerance: tolerance)) {
    // debugPrint('isPointOnSegment: point is not on the line');
    return false; // Point is not on the line
  }
  // debugPrint('isPointOnSegment: point is on the line');
  // Now we know point lies on the line, check if it's within the range [start, end]
  final p = infForm(point);
  final start = infForm(segment.startPoint);
  final end = infForm(segment.endPoint);
  
  // Vector from start to end
  final segmentVec = end - start;
  final segmentLengthSq = (segmentVec | segmentVec).s;
  
  if (segmentLengthSq < tolerance * tolerance) {
    // Degenerate segment - check if point equals start/end
    final distToStart = distancePointToPoint(p, start);
    final distToEnd = distancePointToPoint(p, end);
    return distToStart < tolerance || distToEnd < tolerance;
  }
  
  // Vector from start to point
  final toPoint = p - start;
  
  // Project point onto segment line
  final projection = (toPoint | segmentVec).s / segmentLengthSq;
  
  // Check if projection is within [0, 1] (point is between start and end)
  return projection >= -tolerance && projection <= 1 + tolerance;
}

/// Check if a point lies on an arc
/// [point] - The point to check (as Multivector)
/// [arc] - The arc boundary containing startPoint, endPoint, and circle multivector
/// Returns: bool indicating if point is on the arc (within tolerance)
bool isPointOnArc(
  Multivector point,
  ComplexBoundary arc, {
  double tolerance = 1e-8,
}) {
  // debugPrint('isPointOnArc: stage1');
  if (!point.isPoint(customTolerance: tolerance)) {
    // debugPrint('isPointOnArc: point is not a point');
    throw ArgumentError('isPointOnArc: point is not a point');
  }
  // debugPrint('isPointOnArc: stage2');
  if (!arc.isArc) {
    // debugPrint('isPointOnArc: boundary is not an arc (curve is not a circle)');
    throw ArgumentError('isPointOnArc: boundary is not an arc (curve is not a circle)');
  }
  // debugPrint('isPointOnArc: stage3');
  // First check if point is on the circle
  if (!isPointOnCircle(point, arc.curve, tolerance: tolerance)) {
    // debugPrint('isPointOnArc: point is not on the circle');
    return false;
  }
  
  // debugPrint('isPointOnArc: stage4');
  // Determine direction from circle orientation
  // Inverted: if o >= 0 was giving wrong results, try the opposite
  final counterClockwise = arc.curve.o < 0;
  
  final center = getCircleCenter(arc.curve);
  final c = infForm(center);
  final p = infForm(point);
  final start = infForm(arc.startPoint);
  final end = infForm(arc.endPoint);
  
  // Calculate angles
  final startAngle = math.atan2(start.e2 - c.e2, start.e1 - c.e1);
  final endAngle = math.atan2(end.e2 - c.e2, end.e1 - c.e1);
  final pointAngle = math.atan2(p.e2 - c.e2, p.e1 - c.e1);
  
  // Normalize angles to [0, 2π]
  double normalizeAngle(double angle) {
    while (angle < 0) angle += 2 * math.pi;
    while (angle >= 2 * math.pi) angle -= 2 * math.pi;
    return angle;
  }
  
  final startNorm = normalizeAngle(startAngle);
  final endNorm = normalizeAngle(endAngle);
  final pointNorm = normalizeAngle(pointAngle);
  
  // Invert the logic - check if point is NOT in the complementary arc
  // Fixed: The original logic was checking the complementary (invisible) arc instead of the visible arc
  // Now we correctly check the visible arc range
  if (counterClockwise) {
    if (startNorm < endNorm) {
      // Visible arc: [start, end] counter-clockwise
      // Accept points in this range
      return pointNorm >= startNorm - tolerance && 
             pointNorm <= endNorm + tolerance;
    } else {
      // Visible arc wraps: [start, 2π] ∪ [0, end] counter-clockwise
      // Accept points in this range (point >= start OR point <= end)
      return pointNorm >= startNorm - tolerance || 
             pointNorm <= endNorm + tolerance;
    }
  } else {
    // Clockwise: visible arc goes from end to start (opposite direction)
    if (startNorm > endNorm) {
      // Visible arc: [end, start] clockwise (decreasing angles)
      // Accept points in this range
      return pointNorm >= endNorm - tolerance && 
             pointNorm <= startNorm + tolerance;
    } else {
      // Visible arc wraps: [0, end] ∪ [start, 2π] clockwise
      // Accept points in this range (point <= end OR point >= start)
      return pointNorm <= endNorm + tolerance || 
             pointNorm >= startNorm - tolerance;
    }
  }
}

/// Check if a point lies on a complex boundary (segment or arc)
/// Uses the boundary's curve type to determine if it's a segment or arc
/// Returns: bool indicating if point is on the boundary
bool isPointOnBoundary(
  Multivector point,
  ComplexBoundary boundary, {
  double tolerance = 1e-10,
}) {
  if (boundary.isSegment) {
    return isPointOnSegment(
      point,
      boundary,
      tolerance: tolerance,
    );
  } else if (boundary.isArc) {
    return isPointOnArc(
      point,
      boundary,
      tolerance: tolerance,
    );
  }
  return false;
}

// ----------------------------------------------------------------------------
// POINT PROJECTION FUNCTIONS
// ----------------------------------------------------------------------------

/// Project a point onto a line
/// Returns: Multivector representing the projected point
Multivector projectPointToLine(Multivector point, Multivector line) {
  return  constructPointFromCircle(infForm(line<(point^line)));
}

/// Project a point onto a segment (clamped to endpoints)
/// [point] - The point to project (as Multivector)
/// [segment] - The segment boundary containing startPoint, endPoint, and curve multivector
/// Returns: Multivector representing the projected point
Multivector projectPointToSegment(
  Multivector point,
  ComplexBoundary segment, {
  double tolerance = 1e-8,
}) {
  if (!point.isPoint(customTolerance: tolerance)) {
    throw ArgumentError('projectPointToSegment: point is not a point');
  }
  if (!segment.isSegment) {
    throw ArgumentError('projectPointToSegment: boundary is not a segment (curve is not a line)');
  }
  
  // First, project point onto the line using projectPointToLine
  final lineProjection = projectPointToLine(point, segment.curve);
  
  // Check if the projected point lies on the segment
  if (isPointOnSegment(lineProjection, segment, tolerance: tolerance)) {
    // Projection is on the segment, return it
    return lineProjection;
  }
  
  // Projection is not on the segment, find nearest endpoint
  final p = infForm(point);
  final start = infForm(segment.startPoint);
  final end = infForm(segment.endPoint);
  
  // Calculate distances to endpoints
  final distToStart = distancePointToPoint(p, start);
  final distToEnd = distancePointToPoint(p, end);
  
  // Return the nearest endpoint
  return distToStart < distToEnd ? start : end;
}

/// Project a point onto a circle (nearest point on circumference)
/// Returns: Multivector representing the projected point
Multivector projectPointToCircle(Multivector point, Multivector circle) {
  final p = infForm(point);
  
  // Get center and radius
  final center = getCircleCenter(circle);
  final centerInf = infForm(center);
  final radius = measureCircleRadius(circle);
  
  if (radius <= 0) {
    // Degenerate circle, return center
    return center;
  }
  
  // Vector from center to point
  final toPoint = p - centerInf;
  final distToCenter = math.sqrt((toPoint | toPoint).s * (-2));
  
  if (distToCenter < 1e-10) {
    // Point is at center, project to arbitrary direction
    return infForm(centerInf + Multivector(e1: radius, e2: 0));
  }
  
  // Normalize and scale by radius
  final direction = toPoint.scalarDivide(distToCenter);
  final projected = centerInf + direction.scalarMultiply(radius);
  
  return infForm(projected);
}



/// Project a point onto an arc (nearest point on arc, considering boundaries)
/// Returns: Multivector representing the projected point, or null if arc is invalid
Multivector? projectPointToArc(
  Multivector point,
  Multivector circle,
  Multivector startPoint,
  Multivector endPoint,
  bool counterClockwise,
) {
  // Create ComplexBoundary for the arc
  final arcBoundary = ComplexBoundary(
    startPoint: startPoint,
    endPoint: endPoint,
    curve: circle,
  );
  
  // First project to circle
  final circleProjection = projectPointToCircle(point, circle);
  
  // Check if projection is on the arc
  if (isPointOnArc(circleProjection, arcBoundary)) {
    return circleProjection;
  }
  
  // Projection is not on arc, find nearest endpoint
  final p = infForm(point);
  final start = infForm(startPoint);
  final end = infForm(endPoint);
  
  final distToStart = distancePointToPoint(p, start);
  final distToEnd = distancePointToPoint(p, end);
  
  return distToStart < distToEnd ? start : end;
}
