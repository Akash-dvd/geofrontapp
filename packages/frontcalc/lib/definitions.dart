part of 'Multivector.dart';

/// Extension methods for Multivector
extension MultivectorUtils on Multivector {
  /// Returns the reflection as Option<Multivector>
  /// Returns None if norm is None (not a scalar) or if norm is too small
  Option<Multivector> reflection(Multivector object) {
    return norm().flatMap((normValue) {
      final absNormValue = normValue.abs();
      if (absNormValue < 1e-14) {
        return this;
      }
      final result = reversion() * object * this;
      return Some(result.scalarDivide(absNormValue));
    });
  }


}