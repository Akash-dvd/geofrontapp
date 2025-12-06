part of 'Multivector.dart';

/// Extension methods for Multivector
extension MultivectorDefinitions on Multivector {
  static const double tolerance = 1e-14;
  // static const double tolerance = 1e-5;

  double _effectiveTolerance(double? customTolerance) =>
      customTolerance ?? tolerance;


  /// Example function - replace with your actual implementation
  bool isZero({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is a zero if all components are zero
    return s.abs() < threshold &&
        o.abs() < threshold &&
        e1.abs() < threshold &&
        e2.abs() < threshold &&
        O.abs() < threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  /// Check if multivector represents infinity (only O component is finite)
  bool isInf({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is infinity if only O component is finite (non-zero)
    return O.abs() >= threshold &&
        s.abs() < threshold &&
        o.abs() < threshold &&
        e1.abs() < threshold &&
        e2.abs() < threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  /// Example function - replace with your actual implementation
  bool isScalar({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is a scalar if all components except the scalar part are zero
    return o.abs() < threshold &&
        e1.abs() < threshold &&
        e2.abs() < threshold &&
        O.abs() < threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  bool isVector({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is a vector if only the vector components are non-zero
    return s.abs() < threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  bool isLine({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is a line if only the line components are non-zero
    return s.abs() < threshold &&
        o.abs() < threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  bool isCircle({double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    // A multivector is a circle if only the circle components are non-zero
    return s.abs() < threshold &&
        o.abs() > threshold &&
        oe1.abs() < threshold &&
        oe2.abs() < threshold &&
        oO.abs() < threshold &&
        e12.abs() < threshold &&
        e1O.abs() < threshold &&
        e2O.abs() < threshold &&
        oe12.abs() < threshold &&
        oe1O.abs() < threshold &&
        oe2O.abs() < threshold &&
        e12O.abs() < threshold &&
        oe12O.abs() < threshold;
  }

  bool isPoint({double? customTolerance}) {
    // A multivector is a point if only the point components are non-zero
    return isCircle(customTolerance: customTolerance) &&
        (this | this).isZero(customTolerance: customTolerance);
  }

  Multivector scalarDivide(double scalar, {double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    if (scalar.abs() < threshold) {
      throw ArgumentError('Division by zero or near-zero scalar');
    }
    return Multivector(
      s: s / scalar,
      o: o / scalar,
      e1: e1 / scalar,
      e2: e2 / scalar,
      O: O / scalar,
      oe1: oe1 / scalar,
      oe2: oe2 / scalar,
      oO: oO / scalar,
      e12: e12 / scalar,
      e1O: e1O / scalar,
      e2O: e2O / scalar,
      oe12: oe12 / scalar,
      oe1O: oe1O / scalar,
      oe2O: oe2O / scalar,
      e12O: e12O / scalar,
      oe12O: oe12O / scalar,
    );
  }

  Multivector scalarMultiply(double scalar, {double? customTolerance}) {
    final threshold = _effectiveTolerance(customTolerance);
    if (scalar.abs() < threshold) {
      return Multivector.zero();
    }
    return Multivector(
      s: s * scalar,
      o: o * scalar,
      e1: e1 * scalar,
      e2: e2 * scalar,
      O: O * scalar,
      oe1: oe1 * scalar,
      oe2: oe2 * scalar,
      oO: oO * scalar,
      e12: e12 * scalar,
      e1O: e1O * scalar,
      e2O: e2O * scalar,
      oe12: oe12 * scalar,
      oe1O: oe1O * scalar,
      oe2O: oe2O * scalar,
      e12O: e12O * scalar,
      oe12O: oe12O * scalar,
    );
  }

  Multivector sanitize([double? customTolerance]) {
    final threshold = _effectiveTolerance(customTolerance);
    double sanitizeComponent(double value) =>
        value.abs() < threshold ? 0.0 : value;

    return Multivector(
      s: sanitizeComponent(s),
      o: sanitizeComponent(o),
      e1: sanitizeComponent(e1),
      e2: sanitizeComponent(e2),
      O: sanitizeComponent(O),
      oe1: sanitizeComponent(oe1),
      oe2: sanitizeComponent(oe2),
      oO: sanitizeComponent(oO),
      e12: sanitizeComponent(e12),
      e1O: sanitizeComponent(e1O),
      e2O: sanitizeComponent(e2O),
      oe12: sanitizeComponent(oe12),
      oe1O: sanitizeComponent(oe1O),
      oe2O: sanitizeComponent(oe2O),
      e12O: sanitizeComponent(e12O),
      oe12O: sanitizeComponent(oe12O),
    );
  }

  Multivector vectorize([double? customTolerance]) {
    final threshold = _effectiveTolerance(customTolerance);
    double sanitizeComponent(double value) =>
        value.abs() < threshold ? 0.0 : value;
    
    // Keep only o, e1, e2, O components; set all others to zero
    return Multivector(
      s: 0.0,
      o: sanitizeComponent(o),
      e1: sanitizeComponent(e1),
      e2: sanitizeComponent(e2),
      O: sanitizeComponent(O),
      oe1: 0.0,
      oe2: 0.0,
      oO: 0.0,
      e12: 0.0,
      e1O: 0.0,
      e2O: 0.0,
      oe12: 0.0,
      oe1O: 0.0,
      oe2O: 0.0,
      e12O: 0.0,
      oe12O: 0.0,
    );
  }
}
