# FrontCalc

A mathematical calculator package for parsing and evaluating expressions.

## Features

- Basic arithmetic operations (+, -, *, /)
- Power operations
- Simple expression parsing
- Clean API for mathematical calculations

## Usage

```dart
import 'package:frontcalc/frontcalc.dart';

void main() {
  final calculator = Calculator();
  final parser = ExpressionParser();
  
  // Basic operations
  print(calculator.add(2, 3)); // 5.0
  print(calculator.multiply(4, 5)); // 20.0
  
  // Expression parsing
  print(parser.evaluate("10 + 5")); // 15.0
  print(parser.evaluate("20 / 4")); // 5.0
}
```

## API Reference

### Calculator

- `add(double a, double b)` - Addition
- `subtract(double a, double b)` - Subtraction  
- `multiply(double a, double b)` - Multiplication
- `divide(double a, double b)` - Division
- `power(double base, double exponent)` - Power operation

### ExpressionParser

- `evaluate(String expression)` - Parse and evaluate mathematical expressions