import 'dart:math' as math;

/// A simple calculator class for basic mathematical operations
class Calculator {
  /// Adds two numbers
  double add(double a, double b) => a + b;

  /// Subtracts two numbers
  double subtract(double a, double b) => a - b;

  /// Multiplies two numbers
  double multiply(double a, double b) => a * b;

  /// Divides two numbers
  double divide(double a, double b) {
    if (b == 0) {
      throw ArgumentError('Division by zero is not allowed');
    }
    return a / b;
  }

  /// Calculates power of a number
  double power(double base, double exponent) {
    return math.pow(base, exponent).toDouble();
  }
}