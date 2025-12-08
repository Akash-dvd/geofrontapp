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

  // Case 2: One point, one circle -> external tangents (treat point as circle with radius 0)
  if (mv1.isPoint(customTolerance: tolerance) && mv2.isCircle(customTolerance: tolerance)) {
    final pointInf = infForm(mv1);
    final circleInf = infForm(mv2);
    final center2 = getCircleCenter(circleInf);
    final radius2 = measureCircleRadius(circleInf);
    final p1 = pointInf;
    final p2 = infForm(center2);
    // Treat point as circle with radius 0, compute external tangents
    return _computeOuterTangents(mv1, mv2, p1, p2, 0.0, radius2);
  }
  if (mv1.isCircle(customTolerance: tolerance) && mv2.isPoint(customTolerance: tolerance)) {
    final circleInf = infForm(mv1);
    final pointInf = infForm(mv2);
    final center1 = getCircleCenter(circleInf);
    final radius1 = measureCircleRadius(circleInf);
    final p1 = infForm(center1);
    final p2 = pointInf;
    // Treat point as circle with radius 0, compute external tangents
    return _computeOuterTangents(mv1, mv2, p1, p2, radius1, 0.0);
  }

  // Case 3: Two circles -> both internal and external tangents
  if (mv1.isCircle(customTolerance: tolerance) && mv2.isCircle(customTolerance: tolerance)) {
    return _constructCommonTangents(mv1, mv2);
  }

  // Invalid combination
  throw ArgumentError(
    'constructTangents: Invalid combination. '
    'Inputs must be: two points, one point and one circle, or two circles.'
  );
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

  // Compute all common tangents - lower functions handle boundary conditions
  return _computeAllCommonTangents(c1, c2, p1, p2, radius1, radius2);
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
/// Uses algebraic formulas from geometric algebra calculations
/// Sl1 and Sl2 are the two external lines
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
  
  // Extract circle parameters: g1, h1, r1 and g2, h2, r2
  // Sc1 and Sc2 are the two circles or points
  final g1 = p1.e1; // e_x is e1
  final h1 = p1.e2; // e_y is e2
  final r1 = radius1;
  final g2 = p2.e1; // e_x is e1
  final h2 = p2.e2; // e_y is e2
  final r2 = radius2;
  
  // Base expression for external tangents
  // base = g1^2 - 2*g1*g2 + g2^2 + h1^2 - 2*h1*h2 + h2^2 - r1^2 + 2*r1*r2 - r2^2
  final base = g1 * g1 - 2 * g1 * g2 + g2 * g2 +
               h1 * h1 - 2 * h1 * h2 + h2 * h2 -
               r1 * r1 + 2 * r1 * r2 - r2 * r2;
  
  // Boundary condition: square root must be greater than zero
  if (base <= 0) {
    // No external tangents (boundary condition not met)
    return [];
  }
  
  final sqrtExpr = math.sqrt(base);
  
  if (base.abs() < 1e-10) {
    return [];
  }
  
  final tangents = <Multivector>[];
  
  // If sqrtExpr is zero, return one line with sqrtExpr replaced by zero
  if (sqrtExpr.abs() < 1e-10) {
    // When sqrtExpr = 0, the formulas simplify to just the constant terms
    final sl1_e1 = (-g1 * r1 + g1 * r2 + g2 * r1 - g2 * r2);
    final sl1_e2 = (-h1 * r1 + h1 * r2 + h2 * r1 - h2 * r2);
    final sl1_O = (g1 * g1 * r2 - g1 * g2 * r1 - g1 * g2 * r2 + g2 * g2 * r1 +
                  h1 * h1 * r2 - h1 * h2 * r1 - h1 * h2 * r2 + h2 * h2 * r1);
    tangents.add(uniForm(Multivector(e1: sl1_e1, e2: sl1_e2, O: sl1_O)));
    return tangents;
  }
  
  // Sl1: First external tangent
  final sl1_e1 = (h1 - h2) * sqrtExpr + (-g1 * r1 + g1 * r2 + g2 * r1 - g2 * r2);
  final sl1_e2 = (-g1 + g2) * sqrtExpr + (-h1 * r1 + h1 * r2 + h2 * r1 - h2 * r2);
  final sl1_O = (-g1 * h2 + g2 * h1) * sqrtExpr +
                 (g1 * g1 * r2 - g1 * g2 * r1 - g1 * g2 * r2 + g2 * g2 * r1 +
                  h1 * h1 * r2 - h1 * h2 * r1 - h1 * h2 * r2 + h2 * h2 * r1);


  tangents.add(uniForm(Multivector(e1: sl1_e1, e2: sl1_e2, O: sl1_O)));
  
  // Sl2: Second external tangent
  // Simplified: (A*base + B*sqrtExpr) / (base*sqrtExpr) = A/sqrtExpr + B/base
  // final sl2_e1 = (h1 - h2) * invSqrtExpr + (-g1 * r1 + g1 * r2 + g2 * r1 - g2 * r2) * invBase;
  // final sl2_e2 = (-g1 + g2) * invSqrtExpr + (-h1 * r1 + h1 * r2 + h2 * r1 - h2 * r2) * invBase;
  // final sl2_O = (-g1 * h2 + g2 * h1) * invSqrtExpr +
  //                (g1 * g1 * r2 - g1 * g2 * r1 - g1 * g2 * r2 + g2 * g2 * r1 +
  //                 h1 * h1 * r2 - h1 * h2 * r1 - h1 * h2 * r2 + h2 * h2 * r1) * invBase;

  final sl2_e1 = (h1 - h2) * sqrtExpr - (-g1 * r1 + g1 * r2 + g2 * r1 - g2 * r2) ;
  final sl2_e2 = (-g1 + g2) * sqrtExpr - (-h1 * r1 + h1 * r2 + h2 * r1 - h2 * r2) ;
  final sl2_O = (-g1 * h2 + g2 * h1) * sqrtExpr -
                 (g1 * g1 * r2 - g1 * g2 * r1 - g1 * g2 * r2 + g2 * g2 * r1 +
                  h1 * h1 * r2 - h1 * h2 * r1 - h1 * h2 * r2 + h2 * h2 * r1);
  
  tangents.add(uniForm(Multivector(e1: sl2_e1, e2: sl2_e2, O: sl2_O)));
  
  return tangents;
}

/// Compute 2 inner common tangents for two circles
/// Uses algebraic formulas from geometric algebra calculations
/// Sl3 and Sl4 are the two internal lines
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
  
  // Extract circle parameters: g1, h1, r1 and g2, h2, r2
  // Sc1 and Sc2 are the two circles or points
  final g1 = p1.e1; // e_x is e1
  final h1 = p1.e2; // e_y is e2
  final r1 = radius1;
  final g2 = p2.e1; // e_x is e1
  final h2 = p2.e2; // e_y is e2
  final r2 = radius2;
  
  // Base expression for internal tangents
  // base = g1^2 - 2*g1*g2 + g2^2 + h1^2 - 2*h1*h2 + h2^2 - r1^2 - 2*r1*r2 - r2^2
  final base = g1 * g1 - 2 * g1 * g2 + g2 * g2 +
               h1 * h1 - 2 * h1 * h2 + h2 * h2 -
               r1 * r1 - 2 * r1 * r2 - r2 * r2;
  
  // Boundary condition: square root must be greater than zero
  if (base <= 0) {
    // No internal tangents (boundary condition not met)
    return [];
  }
  
  final sqrtExpr = math.sqrt(base);
  
  if (base.abs() < 1e-10) {
    return [];
  }
  
  final tangents = <Multivector>[];
  
  // If sqrtExpr is zero, return one line with sqrtExpr replaced by zero
  if (sqrtExpr.abs() < 1e-10) {
    // When sqrtExpr = 0, the formulas simplify to just the constant terms
    final sl3_e1 = - (g1 * r1 + g1 * r2 - g2 * r1 - g2 * r2);
    final sl3_e2 = - (h1 * r1 + h1 * r2 - h2 * r1 - h2 * r2);
    final sl3_O = -(g1 * g1 * r2 + g1 * g2 * r1 - g1 * g2 * r2 - g2 * g2 * r1 +
                  h1 * h1 * r2 + h1 * h2 * r1 - h1 * h2 * r2 - h2 * h2 * r1);
    tangents.add(uniForm(Multivector(e1: sl3_e1, e2: sl3_e2, O: sl3_O)));
    return tangents;
  }
  
  // Sl3: First internal tangent
  final sl3_e1 = (h1 - h2) * sqrtExpr - (g1 * r1 + g1 * r2 - g2 * r1 - g2 * r2);
  final sl3_e2 = (-g1 + g2) * sqrtExpr - (h1 * r1 + h1 * r2 - h2 * r1 - h2 * r2);
  final sl3_O = (-g1 * h2 + g2 * h1) * sqrtExpr -
                 (g1 * g1 * r2 + g1 * g2 * r1 - g1 * g2 * r2 - g2 * g2 * r1 +
                  h1 * h1 * r2 + h1 * h2 * r1 - h1 * h2 * r2 - h2 * h2 * r1);
  
  tangents.add(uniForm(Multivector(e1: sl3_e1, e2: sl3_e2, O: sl3_O)));
  
  // Sl4: Second internal tangent
  // Simplified: (-A*baseNeg + B*sqrtExpr) / (base*sqrtExpr) = -A*baseNegOverDenom + B/base
  final sl4_e1 = (-h1 + h2) * sqrtExpr + (-g1 * r1 - g1 * r2 + g2 * r1 + g2 * r2) ;
  final sl4_e2 = (g1 - g2) * sqrtExpr + (-h1 * r1 - h1 * r2 + h2 * r1 + h2 * r2) ;
  final sl4_O = (g1 * h2 - g2 * h1) * sqrtExpr +
                 (-g1 * g1 * r2 - g1 * g2 * r1 + g1 * g2 * r2 + g2 * g2 * r1 -
                  h1 * h1 * r2 - h1 * h2 * r1 + h1 * h2 * r2 + h2 * h2 * r1) ;
  
  tangents.add(uniForm(Multivector(e1: sl4_e1, e2: sl4_e2, O: sl4_O)));
  
  return tangents;
}
