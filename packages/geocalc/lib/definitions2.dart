part of 'Multivector.dart';

// ============================================================================
// TRIANGLE CONSTRUCTION FUNCTIONS
// ============================================================================
// Extended geometric construction functions for triangle-related operations
// ============================================================================

// ----------------------------------------------------------------------------
// TRIANGLE CENTERS
// ----------------------------------------------------------------------------

/// Construct the incircle of a triangle from three vertices
/// The incircle is the circle inscribed in the triangle, tangent to all three sides
/// Returns: Multivector representing the incircle
Multivector constructIncircleFrom3Vertices(
  Multivector vertex1,
  Multivector vertex2,
  Multivector vertex3,
) {
  // Ensure all inputs are points
  if (!vertex1.isPoint() || !vertex2.isPoint() || !vertex3.isPoint()) {
    throw ArgumentError('constructIncircleFrom3Vertices: All inputs must be points');
  }

  // Convert to infForm for calculations
  final v1 = infForm(vertex1);
  final v2 = infForm(vertex2);
  final v3 = infForm(vertex3);

  // Construct the three sides of the triangle
  final side1 = constructLineFrom2Points(v2, v3); // Side opposite to vertex1
  // final side2 = constructLineFrom2Points(v3, v1); // Side opposite to vertex2 (not needed for incircle)
  // final side3 = constructLineFrom2Points(v1, v2); // Side opposite to vertex3 (not needed for incircle)

  // Calculate side lengths for weighted incenter calculation
  final a = distancePointToPoint(v2, v3); // Length of side opposite vertex1
  final b = distancePointToPoint(v3, v1); // Length of side opposite vertex2
  final c = distancePointToPoint(v1, v2); // Length of side opposite vertex3

  final perimeter = a + b + c;
  if (perimeter < 1e-10) {
    throw ArgumentError('constructIncircleFrom3Vertices: Triangle is degenerate (collinear points)');
  }

  // Calculate incenter using barycentric coordinates
  // Incenter = (a*v1 + b*v2 + c*v3) / (a + b + c)
  // where a, b, c are lengths of sides opposite to v1, v2, v3 respectively
  final incenterX = (a * v1.e1 + b * v2.e1 + c * v3.e1) / perimeter;
  final incenterY = (a * v1.e2 + b * v2.e2 + c * v3.e2) / perimeter;

  // Create incenter point
  // constructFreePoint always creates a valid point, so no validation needed
  final incenter = constructFreePoint(incenterX, incenterY);

  // Calculate inradius (distance from incenter to any side)
  final inradius = distancePointToLine(incenter, side1);

  // Construct circle with incenter and inradius
  return constructCircleFromCenterAndRadius(incenter, inradius);
}

/// Construct an excircle of a triangle from three vertices and a side (line)
/// The excircle is tangent to the specified side and to the extensions of the other two sides
/// The side parameter identifies which side the excircle is opposite to
/// Returns: Multivector representing the excircle
Multivector constructExcircleFrom3VerticesAndSide(
  Multivector vertex1,
  Multivector vertex2,
  Multivector vertex3,
  Multivector side,
) {
  // Ensure all inputs are points (for vertices) and line (for side)
  if (!vertex1.isPoint() || !vertex2.isPoint() || !vertex3.isPoint()) {
    throw ArgumentError('constructExcircleFrom3VerticesAndSide: All vertices must be points');
  }
  if (!side.isLine()) {
    throw ArgumentError('constructExcircleFrom3VerticesAndSide: Side must be a line');
  }

  // Convert to infForm for calculations
  final v1 = infForm(vertex1);
  final v2 = infForm(vertex2);
  final v3 = infForm(vertex3);
  final sideLine = uniForm(side);

  // Identify which side the line corresponds to
  // Check which two vertices the side line passes through (or is closest to)
  final side12 = constructLineFrom2Points(v1, v2);
  final side23 = constructLineFrom2Points(v2, v3);
  final side31 = constructLineFrom2Points(v3, v1);

  // Normalize all sides for comparison
  final side12Norm = uniForm(side12);
  final side23Norm = uniForm(side23);
  final side31Norm = uniForm(side31);

  // Find which side matches (within tolerance)
  final tolerance = 1e-8;
  Multivector? oppositeVertex;
  Multivector vertexA, vertexB;

  // Check if side matches side12 (opposite to vertex3)
  final diff12 = (sideLine - side12Norm).norm().fold(() => 0.0, (v) => v.abs());
  final diff12Alt = (sideLine + side12Norm).norm().fold(() => 0.0, (v) => v.abs());
  if (diff12 < tolerance || diff12Alt < tolerance) {
    oppositeVertex = v3;
    vertexA = v1;
    vertexB = v2;
  }
  // Check if side matches side23 (opposite to vertex1)
  else {
    final diff23 = (sideLine - side23Norm).norm().fold(() => 0.0, (v) => v.abs());
    final diff23Alt = (sideLine + side23Norm).norm().fold(() => 0.0, (v) => v.abs());
    if (diff23 < tolerance || diff23Alt < tolerance) {
      oppositeVertex = v1;
      vertexA = v2;
      vertexB = v3;
    }
    // Check if side matches side31 (opposite to vertex2)
    else {
      final diff31 = (sideLine - side31Norm).norm().fold(() => 0.0, (v) => v.abs());
      final diff31Alt = (sideLine + side31Norm).norm().fold(() => 0.0, (v) => v.abs());
      if (diff31 < tolerance || diff31Alt < tolerance) {
        oppositeVertex = v2;
        vertexA = v3;
        vertexB = v1;
      } else {
        throw ArgumentError(
          'constructExcircleFrom3VerticesAndSide: '
          'The provided side does not match any side of the triangle'
        );
      }
    }
  }

  // Now we have:
  // - oppositeVertex: the vertex opposite to the side
  // - vertexA, vertexB: the two vertices on the side
  // - sideLine: the side line

  // Construct the two sides that extend from vertexA and vertexB
  final sideFromA = constructLineFrom2Points(vertexA, oppositeVertex);
  final sideFromB = constructLineFrom2Points(vertexB, oppositeVertex);

  // Get external angle bisectors at vertices A and B
  // External bisector is the difference of normalized lines (from constructAngleBisector2Lines)
  final sideFromANorm = uniForm(sideFromA);
  final sideFromBNorm = uniForm(sideFromB);
  final sideLineNorm = uniForm(sideLine);

  // External bisector at vertexA: bisects external angle between sideLine and sideFromA
  // constructAngleBisector2Lines returns [internal, external] where:
  // - internal = l1 + l2 (sum)
  // - external = l1 - l2 (difference)
  final bisectorsAtA = constructAngleBisector2Lines(sideLineNorm, sideFromANorm);
  // External bisector at vertexB: bisects external angle between sideLine and sideFromB
  final bisectorsAtB = constructAngleBisector2Lines(sideLineNorm, sideFromBNorm);

  // Use the external bisector (second element, which is l1 - l2)
  // This is the bisector of the external angle (outside the triangle)
  if (bisectorsAtA.length < 2 || bisectorsAtB.length < 2) {
    throw ArgumentError(
      'constructExcircleFrom3VerticesAndSide: '
      'Could not compute external angle bisectors'
    );
  }
  final externalBisectorA = bisectorsAtA[1]; // External bisector
  final externalBisectorB = bisectorsAtB[1]; // External bisector

  // Find intersection of the two external bisectors (this is the excenter)
  final excenter = constructLineLineIntersection(externalBisectorA, externalBisectorB);

  // Ensure excenter is a valid finite point (not at infinity)
  // Use relaxed tolerance for floating point precision
  if (!excenter.isPoint(customTolerance: 1e-8) || excenter.isInf(customTolerance: 1e-8)) {
    throw ArgumentError(
      'constructExcircleFrom3VerticesAndSide: '
      'Could not compute valid excenter (external bisectors may be parallel or invalid)'
    );
  }

  // Calculate exradius (distance from excenter to the side)
  final exradius = distancePointToLine(excenter, sideLine);

  // Construct circle with excenter and exradius
  return constructCircleFromCenterAndRadius(excenter, exradius);
}

/// Construct the incircle of a triangle from two vertices
/// This constructs the incircle assuming the third vertex completes the triangle
/// Note: This is a convenience function - the third vertex is calculated from the triangle's geometry
/// Returns: Multivector representing the incircle
/// 
/// WARNING: This function requires additional information. For a proper incircle,
/// use constructIncircleFrom3Vertices with all three vertices.
Multivector constructIncircleFrom2Vertices(
  Multivector vertex1,
  Multivector vertex2,
) {
  // This is a placeholder - incircle requires 3 vertices
  // If you have a specific use case, please provide the third vertex
  throw ArgumentError(
    'constructIncircleFrom2Vertices: Incircle requires 3 vertices. '
    'Use constructIncircleFrom3Vertices instead.'
  );
}

/// Construct the orthocenter of a triangle from three vertices
/// The orthocenter is the intersection point of the three altitudes
/// Returns: Multivector representing the orthocenter point
Multivector constructOrthocenterFrom3Vertices(
  Multivector vertex1,
  Multivector vertex2,
  Multivector vertex3,
) {
  // Ensure all inputs are points
  if (!vertex1.isPoint() || !vertex2.isPoint() || !vertex3.isPoint()) {
    throw ArgumentError('constructOrthocenterFrom3Vertices: All inputs must be points');
  }

  // Convert to infForm for calculations
  final v1 = infForm(vertex1);
  final v2 = infForm(vertex2);
  final v3 = infForm(vertex3);

  // Construct the three sides of the triangle
  final side1 = constructLineFrom2Points(v2, v3); // Side opposite to vertex1
  final side2 = constructLineFrom2Points(v3, v1); // Side opposite to vertex2
  // final side3 = constructLineFrom2Points(v1, v2); // Side opposite to vertex3 (not needed for orthocenter)

  // Construct altitudes (perpendicular from vertex to opposite side)
  final altitude1 = constructPerpendicularLine(side1, v1); // Altitude from vertex1
  final altitude2 = constructPerpendicularLine(side2, v2); // Altitude from vertex2

  // Find intersection of two altitudes (this is the orthocenter)
  final orthocenter = constructLineLineIntersection(altitude1, altitude2);

  return orthocenter;
}

// ----------------------------------------------------------------------------
// TANGENT CONSTRUCTIONS
// ----------------------------------------------------------------------------

/// Construct tangents between two multivectors
/// Handles: point-point (line), point-circle (tangents), circle-circle (common tangents)
/// Lines are not allowed as input
/// Returns: List of Multivector representing tangent lines
List<Multivector> constructTangents(
  Multivector mv1,
  Multivector mv2,
) {
  // Use relaxed tolerance for type checks
  const tolerance = 1e-8;
  
  // Lines are not allowed
  if (mv1.isLine(customTolerance: tolerance) || mv2.isLine(customTolerance: tolerance)) {
    throw ArgumentError('constructTangents: Lines are not allowed as input');
  }

  // Case 1: Two points -> return line through them
  if (mv1.isPoint(customTolerance: tolerance) && mv2.isPoint(customTolerance: tolerance)) {
    return [constructLineFrom2Points(mv1, mv2)];
  }

  // Case 2: One point, one circle -> tangents from point to circle
  if (mv1.isPoint(customTolerance: tolerance) && mv2.isCircle(customTolerance: tolerance)) {
    return _constructTangentsPointToCircle(mv1, mv2);
  }
  if (mv1.isCircle(customTolerance: tolerance) && mv2.isPoint(customTolerance: tolerance)) {
    return _constructTangentsPointToCircle(mv2, mv1);
  }

  // Case 3: Two circles -> common tangents
  if (mv1.isCircle(customTolerance: tolerance) && mv2.isCircle(customTolerance: tolerance)) {
    return _constructCommonTangents(mv1, mv2);
  }

  // Invalid combination
  throw ArgumentError(
    'constructTangents: Invalid combination. '
    'Inputs must be: two points, one point and one circle, or two circles.'
  );
}

/// Construct tangents from a point to a circle
/// Returns: 0, 1, or 2 tangent lines
List<Multivector> _constructTangentsPointToCircle(
  Multivector point,
  Multivector circle,
) {
  // Normalize inputs to infForm for calculations
  final pointInf = infForm(point);
  final circleInf = infForm(circle);
  
  // Use the existing constructTangentLines function
  // It already handles the cases: outside (2), on (1), inside (0)
  return constructTangentLines(pointInf, circleInf);
}

/// Construct common tangents between two circles
/// Returns: 0, 1, 2, 3, or 4 tangent lines depending on circle positions
List<Multivector> _constructCommonTangents(
  Multivector circle1,
  Multivector circle2,
) {
  // Normalize circles to infForm for calculations
  final c1 = infForm(circle1);
  final c2 = infForm(circle2);

  // Get centers and radii
  final center1 = getCircleCenter(c1);
  final center2 = getCircleCenter(c2);
  final radius1 = measureCircleRadius(c1);
  final radius2 = measureCircleRadius(c2);

  // Convert centers to infForm for coordinate extraction
  final p1 = infForm(center1);
  final p2 = infForm(center2);

  // Calculate distance between centers
  final centerDistance = distancePointToPoint(p1, p2);
  final radiusSum = radius1 + radius2;
  final radiusDiff = (radius1 - radius2).abs();

  // Determine relative positions
  final tangents = <Multivector>[];

  // Check if circles intersect
  final intersections = constructCircleCircleIntersection(c1, c2);
  final numIntersections = intersections.length;

  if (numIntersections == 0) {
    // No intersections - could be separate or one inside another
    if (centerDistance < radiusDiff - 1e-10) {
      // One circle completely inside another -> 0 tangents
      return [];
    } else if (centerDistance > radiusSum) {
      // Separate circles (non-intersecting) -> 4 common tangents
      tangents.addAll(_computeAllCommonTangents(c1, c2, p1, p2, radius1, radius2));
    } else {
      // Circles are close but not intersecting (radiusDiff <= centerDistance <= radiusSum)
      // This can happen when circles are very close but don't touch
      // Still compute tangents (they exist as long as circles don't intersect)
      tangents.addAll(_computeAllCommonTangents(c1, c2, p1, p2, radius1, radius2));
    }
  } else if (numIntersections == 1) {
    // Tangent (touching) -> determine if outer or inner tangent
    if ((centerDistance - radiusSum).abs() < 1e-10) {
      // Outer tangent (touching externally)
      // The tangent at the touch point is perpendicular to line connecting centers
      final touchPoint = intersections[0];
      final lineConnectingCenters = constructLineFrom2Points(p1, p2);
      final tangentAtTouch = constructPerpendicularLine(lineConnectingCenters, touchPoint);
      tangents.add(uniForm(tangentAtTouch));
      // Add 2 other outer tangents
      final outerTangents = _computeOuterTangents(c1, c2, p1, p2, radius1, radius2);
      // Filter out duplicates and add the others
      for (final tangent in outerTangents) {
        final tan1 = uniForm(tangent);
        final tan2 = uniForm(tangentAtTouch);
        // Check if this tangent is different from the one at touch point
        final diff = (tan1 - tan2).norm().fold(() => 0.0, (v) => v.abs());
        if (diff > 1e-8) {
          tangents.add(tan1);
        }
      }
    } else if ((centerDistance - radiusDiff).abs() < 1e-10) {
      // Inner tangent (one touches the other from inside)
      // The tangent at the touch point is perpendicular to line connecting centers
      final touchPoint = intersections[0];
      final lineConnectingCenters = constructLineFrom2Points(p1, p2);
      final tangentAtTouch = constructPerpendicularLine(lineConnectingCenters, touchPoint);
      tangents.add(uniForm(tangentAtTouch));
    } else {
      // Should not happen, but handle gracefully
      return [];
    }
  } else {
    // 2 intersections -> circles intersect -> 2 outer tangents
    tangents.addAll(_computeOuterTangents(c1, c2, p1, p2, radius1, radius2));
  }

  return tangents;
}

/// Compute all 4 common tangents (2 outer, 2 inner) for two separate circles
List<Multivector> _computeAllCommonTangents(
  Multivector circle1,
  Multivector circle2,
  Multivector center1,
  Multivector center2,
  double radius1,
  double radius2,
) {
  final tangents = <Multivector>[];
  
  // Add 2 outer tangents
  tangents.addAll(_computeOuterTangents(circle1, circle2, center1, center2, radius1, radius2));
  
  // Add 2 inner tangents
  tangents.addAll(_computeInnerTangents(circle1, circle2, center1, center2, radius1, radius2));
  
  return tangents;
}

/// Compute 2 outer common tangents for two circles
List<Multivector> _computeOuterTangents(
  Multivector circle1,
  Multivector circle2,
  Multivector center1,
  Multivector center2,
  double radius1,
  double radius2,
) {
  final p1 = infForm(center1);
  final p2 = infForm(center2);
  
  // Vector from center1 to center2
  final dx = p2.e1 - p1.e1;
  final dy = p2.e2 - p1.e2;
  final d = math.sqrt(dx * dx + dy * dy);
  
  if (d < 1e-10) {
    // Concentric circles - no common tangents
    return [];
  }
  
  // Angle of line connecting centers
  final theta = math.atan2(dy, dx);
  
  // For outer tangents, use the correct formula from geometry:
  // The radius angle is: theta ± beta where:
  // - theta = angle of line connecting centers
  // - beta = arcsin((r1 - r2) / d)
  // Note: Using (r1 - r2) as per standard geometric formula
  final rDiff = radius1 - radius2;
  final sinBeta = rDiff / d;
  
  if (sinBeta.abs() >= 1.0) {
    // No outer tangents (circles are too close or one inside another)
    return [];
  }
  
  final beta = math.asin(sinBeta);
  
  final tangents = <Multivector>[];
  
  // For outer tangents, both radii are parallel
  // The radius angle is: theta + beta and theta - beta
  // where theta is the angle of the line connecting centers
  
  // Tangent 1: radius angle = theta + beta (both circles use same angle)
  final tan1Angle = theta + beta;
  
  final tan1Point1 = constructFreePoint(
    p1.e1 + radius1 * math.cos(tan1Angle),
    p1.e2 + radius1 * math.sin(tan1Angle),
  );
  final tan1Point2 = constructFreePoint(
    p2.e1 + radius2 * math.cos(tan1Angle),
    p2.e2 + radius2 * math.sin(tan1Angle),
  );
  tangents.add(uniForm(constructLineFrom2Points(tan1Point1, tan1Point2)));
  
  // Tangent 2: radius angle = theta - beta (both circles use same angle)
  final tan2Angle = theta - beta;
  
  final tan2Point1 = constructFreePoint(
    p1.e1 + radius1 * math.cos(tan2Angle),
    p1.e2 + radius1 * math.sin(tan2Angle),
  );
  final tan2Point2 = constructFreePoint(
    p2.e1 + radius2 * math.cos(tan2Angle),
    p2.e2 + radius2 * math.sin(tan2Angle),
  );
  tangents.add(uniForm(constructLineFrom2Points(tan2Point1, tan2Point2)));
  
  return tangents;
}

/// Compute 2 inner common tangents for two circles
List<Multivector> _computeInnerTangents(
  Multivector circle1,
  Multivector circle2,
  Multivector center1,
  Multivector center2,
  double radius1,
  double radius2,
) {
  final p1 = infForm(center1);
  final p2 = infForm(center2);
  
  // Vector from center1 to center2
  final dx = p2.e1 - p1.e1;
  final dy = p2.e2 - p1.e2;
  final d = math.sqrt(dx * dx + dy * dy);
  
  if (d < 1e-10) {
    // Concentric circles - no common tangents
    return [];
  }
  
  // Angle of line connecting centers
  final alpha = math.atan2(dy, dx);
  
  // For inner tangents, the tangent lines cross between the circles
  final rSum = radius1 + radius2;
  final sinTheta = rSum / d;
  
  if (sinTheta >= 1.0) {
    // No inner tangents (circles are too close)
    return [];
  }
  
  final theta = math.asin(sinTheta);
  
  // Two inner tangent directions
  final angle1 = alpha + (math.pi / 2 - theta);
  final angle2 = alpha - (math.pi / 2 - theta);
  
  final tangents = <Multivector>[];
  
  // Tangent 1
  final tan1DirX = math.cos(angle1);
  final tan1DirY = math.sin(angle1);
  final tan1Point1 = constructFreePoint(
    p1.e1 + radius1 * tan1DirX,
    p1.e2 + radius1 * tan1DirY,
  );
  final tan1Point2 = constructFreePoint(
    p2.e1 - radius2 * tan1DirX,
    p2.e2 - radius2 * tan1DirY,
  );
  tangents.add(constructLineFrom2Points(tan1Point1, tan1Point2));
  
  // Tangent 2
  final tan2DirX = math.cos(angle2);
  final tan2DirY = math.sin(angle2);
  final tan2Point1 = constructFreePoint(
    p1.e1 + radius1 * tan2DirX,
    p1.e2 + radius1 * tan2DirY,
  );
  final tan2Point2 = constructFreePoint(
    p2.e1 - radius2 * tan2DirX,
    p2.e2 - radius2 * tan2DirY,
  );
  tangents.add(constructLineFrom2Points(tan2Point1, tan2Point2));
  
  return tangents;
}
