part of 'Multivector.dart';

/// Extension methods for Multivector
extension MultivectorDefinitions on Multivector {
  static const double tolerance = 1e-14;

  /// Example function - replace with your actual implementation
  bool isZero() {
    // A multivector is a zero if all components are zero
    return 
    s.abs() < tolerance &&
    o.abs() < tolerance && e1.abs() < tolerance && e2.abs() < tolerance && O.abs() < tolerance 
    && oe1.abs() < tolerance && oe2.abs() < tolerance && oO.abs() < tolerance 
    && e12.abs() < tolerance && e1O.abs() < tolerance && e2O.abs() < tolerance 
    && oe12.abs() < tolerance && oe1O.abs() < tolerance && oe2O.abs() < tolerance
    && e12O.abs() < tolerance && oe12O.abs() < tolerance;
  }
  /// Example function - replace with your actual implementation
  bool isScalar() {
    // A multivector is a scalar if all components except the scalar part are zero
    return 
    o.abs() < tolerance && e1.abs() < tolerance && e2.abs() < tolerance && O.abs() < tolerance 
    && oe1.abs() < tolerance && oe2.abs() < tolerance && oO.abs() < tolerance 
    && e12.abs() < tolerance && e1O.abs() < tolerance && e2O.abs() < tolerance 
    && oe12.abs() < tolerance && oe1O.abs() < tolerance && oe2O.abs() < tolerance
    && e12O.abs() < tolerance && oe12O.abs() < tolerance;
  }

  bool isVector() {
    // A multivector is a vector if only the vector components are non-zero
    return 
    s.abs() < tolerance 
    && oe1.abs() < tolerance && oe2.abs() < tolerance && oO.abs() < tolerance 
    && e12.abs() < tolerance && e1O.abs() < tolerance && e2O.abs() < tolerance 
    && oe12.abs() < tolerance && oe1O.abs() < tolerance && oe2O.abs() < tolerance
    && e12O.abs() < tolerance && oe12O.abs() < tolerance;
  }

  bool isline() {
    // A multivector is a line if only the line components are non-zero
    return 
    s.abs() < tolerance && o.abs() < tolerance
    && oe1.abs() < tolerance && oe2.abs() < tolerance && oO.abs() < tolerance 
    && e12.abs() < tolerance && e1O.abs() < tolerance && e2O.abs() < tolerance 
    && oe12.abs() < tolerance && oe1O.abs() < tolerance && oe2O.abs() < tolerance
    && e12O.abs() < tolerance && oe12O.abs() < tolerance;
  }

  bool isCircle() {
    // A multivector is a circle if only the circle components are non-zero
    return isVector();
  }

  bool isPoint() {
    // A multivector is a point if only the point components are non-zero
    return isVector && (this|this).isZero();
  }

  Multivector scalarDivide(double scalar) {
    if (scalar.abs() < tolerance) {
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
}