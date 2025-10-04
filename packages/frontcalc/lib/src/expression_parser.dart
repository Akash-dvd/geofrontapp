import 'calculator.dart';

/// A simple expression parser for basic mathematical expressions
class ExpressionParser {
  final Calculator _calculator = Calculator();

  /// Evaluates a simple mathematical expression from a string
  /// Supports basic operations: +, -, *, /, ^
  /// Example: "2 + 3 * 4" returns 14.0
  double evaluate(String expression) {
    // Remove spaces
    expression = expression.replaceAll(' ', '');
    
    // Very basic parser - in a real implementation you'd want a proper parser
    // This is just for demonstration
    if (expression.contains('+')) {
      final parts = expression.split('+');
      if (parts.length == 2) {
        return _calculator.add(double.parse(parts[0]), double.parse(parts[1]));
      }
    }
    
    if (expression.contains('-')) {
      final parts = expression.split('-');
      if (parts.length == 2) {
        return _calculator.subtract(double.parse(parts[0]), double.parse(parts[1]));
      }
    }
    
    if (expression.contains('*')) {
      final parts = expression.split('*');
      if (parts.length == 2) {
        return _calculator.multiply(double.parse(parts[0]), double.parse(parts[1]));
      }
    }
    
    if (expression.contains('/')) {
      final parts = expression.split('/');
      if (parts.length == 2) {
        return _calculator.divide(double.parse(parts[0]), double.parse(parts[1]));
      }
    }
    
    // If no operator found, try to parse as a single number
    return double.parse(expression);
  }
}