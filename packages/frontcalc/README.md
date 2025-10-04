# FrontCalc

A geometric algebra package implementing multivector operations for advanced mathematical computations.

## Features

- Complete Multivector implementation for geometric algebra
- Geometric product, wedge product, and contraction operations
- Dual, involution, reversion, and conjugation operations
- Type checking methods (isScalar, isVector, isPoint, etc.)
- Norm calculations with Option types
- Reflection operations
- Built with functional programming concepts using `dartz`

## Usage

```dart
import 'package:frontcalc/frontcalc.dart';

void main() {
  // Create multivectors
  final mv1 = Multivector(s: 1.0, e1: 2.0, e2: 3.0);
  final mv2 = Multivector(s: 2.0, e1: 1.0, O: 1.0);
  
  // Basic operations
  final sum = mv1 + mv2;
  final product = mv1 * mv2;  // Geometric product
  final wedge = mv1 ^ mv2;    // Wedge product
  
  // Dot product (returns scalar)
  final dot = mv1 | mv2;
  
  // Geometric operations
  final dual = mv1.dual();
  final reversed = mv1.reversion();
  final conjugate = mv1.conjugation();
  
  // Type checking
  print(mv1.isScalar()); 
  print(mv1.isVector());
  
  // Norm calculation
  final norm = mv1.norm();
  norm.fold(
    () => print('Norm is not a scalar'),
    (value) => print('Norm: $value')
  );
}
```

## API Reference

### Multivector

**Constructors:**
- `Multivector({s, o, e1, e2, O, oe1, oe2, oO, e12, e1O, e2O, oe12, oe1O, oe2O, e12O, oe12O})` - Create with named parameters
- `Multivector.zero()` - Create zero multivector

**Operations:**
- `+`, `-` - Addition and subtraction
- `*` - Geometric product
- `^` - Wedge product
- `<`, `>` - Left and right contractions
- `|` - Dot product (returns scalar)

**Geometric Operations:**
- `dual()` - Returns the dual
- `involution()` - Returns the involution
- `reversion()` - Returns the reversion
- `conjugation()` - Returns the conjugation
- `norm()` - Returns Option<double> norm

**Type Checking:**
- `isZero()` - Check if multivector is zero
- `isScalar()` - Check if multivector is scalar
- `isVector()` - Check if multivector is vector
- `isPoint()` - Check if multivector represents a point
- `isCircle()` - Check if multivector represents a circle

**Utility:**
- `scalarDivide(double)` - Divide by scalar
- `reflection(Multivector)` - Compute reflection