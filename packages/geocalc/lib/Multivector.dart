// import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';

part 'util.dart';
part 'definitions.dart';

/// Represents a Multivector for geometric algebra operations.
class Multivector extends Equatable {
  final Float64List components;

  Multivector({
    double s = 0.0,
    double o = 0.0,
    double e1 = 0.0,
    double e2 = 0.0,
    double O = 0.0,
    double oe1 = 0.0,
    double oe2 = 0.0,
    double oO = 0.0,
    double e12 = 0.0,
    double e1O = 0.0,
    double e2O = 0.0,
    double oe12 = 0.0,
    double oe1O = 0.0,
    double oe2O = 0.0,
    double e12O = 0.0,
    double oe12O = 0.0,
  }) : components = Float64List(16) {
    components[0] = s;
    components[1] = o;
    components[2] = e1;
    components[3] = e2;
    components[4] = O;
    components[5] = oe1;
    components[6] = oe2;
    components[7] = oO;
    components[8] = e12;
    components[9] = e1O;
    components[10] = e2O;
    components[11] = oe12;
    components[12] = oe1O;
    components[13] = oe2O;
    components[14] = e12O;
    components[15] = oe12O;
  }

  /// Creates a zero multivector (all components = 0)
  factory Multivector.zero() {
    return Multivector();
  }

  /// Creates a multivector from a list of components
  factory Multivector.fromList(List<double> list) {
    if (list.length != 16) {
      throw ArgumentError('List must have exactly 16 components');
    }
    return Multivector(
      s: list[0],
      o: list[1],
      e1: list[2],
      e2: list[3],
      O: list[4],
      oe1: list[5],
      oe2: list[6],
      oO: list[7],
      e12: list[8],
      e1O: list[9],
      e2O: list[10],
      oe12: list[11],
      oe1O: list[12],
      oe2O: list[13],
      e12O: list[14],
      oe12O: list[15],
    );
  }

  // Named getters for each element
  double get s => components[0];
  double get o => components[1];
  double get e1 => components[2];
  double get e2 => components[3];
  double get O => components[4];
  double get oe1 => components[5];
  double get oe2 => components[6];
  double get oO => components[7];
  double get e12 => components[8];
  double get e1O => components[9];
  double get e2O => components[10];
  double get oe12 => components[11];
  double get oe1O => components[12];
  double get oe2O => components[13];
  double get e12O => components[14];
  double get oe12O => components[15];

  /// Returns the number of components in the multivector.
  int get length => components.length;

  /// Adds another multivector to this one.
  Multivector operator +(Multivector other) {
    return Multivector.fromList(
      List.generate(
        components.length,
        (i) => components[i] + other.components[i],
      ),
    );
  }

  /// Subtracts another multivector from this one.
  Multivector operator -(Multivector other) {
    return Multivector.fromList(
      List.generate(
        components.length,
        (i) => components[i] - other.components[i],
      ),
    );
  }

  /// Element-wise multiplication
  Multivector operator *(Multivector other) {
    return Multivector(
      s:
          -O * other.o -
          other.O * o -
          e1O * other.oe1 -
          other.e1O * oe1 +
          e1 * other.e1 +
          e12O * other.oe12 +
          other.e12O * oe12 -
          e12 * other.e12 -
          e2O * other.oe2 -
          other.e2O * oe2 +
          e2 * other.e2 +
          oO * other.oO +
          oe1O * other.oe1O -
          oe12O * other.oe12O +
          oe2O * other.oe2O +
          s * other.s,
      o:
          -e1 * other.oe1 +
          other.e1 * oe1 -
          e12 * other.oe12 -
          other.e12 * oe12 -
          e2 * other.oe2 +
          other.e2 * oe2 -
          oO * other.o +
          other.oO * o +
          o * other.s +
          other.o * s -
          oe1O * other.oe1 -
          other.oe1O * oe1 +
          oe12O * other.oe12 -
          other.oe12O * oe12 -
          oe2O * other.oe2 -
          other.oe2O * oe2,
      e1:
          -O * other.oe1 +
          other.O * oe1 -
          e1O * other.o +
          other.e1O * o +
          e1 * other.s +
          other.e1 * s -
          e12O * other.oe2 -
          other.e12O * oe2 +
          e12 * other.e2 -
          other.e12 * e2 +
          e2O * other.oe12 +
          other.e2O * oe12 -
          oO * other.oe1O -
          other.oO * oe1O -
          oe12O * other.oe2O +
          other.oe12O * oe2O,
      e2:
          -O * other.oe2 +
          other.O * oe2 -
          e1O * other.oe12 -
          other.e1O * oe12 +
          e1 * other.e12 -
          other.e1 * e12 +
          e12O * other.oe1 +
          other.e12O * oe1 -
          e2O * other.o +
          other.e2O * o +
          e2 * other.s +
          other.e2 * s -
          oO * other.oe2O -
          other.oO * oe2O -
          oe1O * other.oe12O +
          other.oe1O * oe12O,
      O:
          -O * other.oO +
          O * other.s +
          other.O * oO +
          other.O * s -
          e1O * other.e1 -
          e1O * other.oe1O +
          other.e1O * e1 -
          other.e1O * oe1O -
          e12O * other.e12 +
          e12O * other.oe12O -
          other.e12O * e12 -
          other.e12O * oe12O -
          e2O * other.e2 -
          e2O * other.oe2O +
          other.e2O * e2 -
          other.e2O * oe2O,
      oe1:
          -e1 * other.o +
          other.e1 * o +
          e12 * other.oe2 -
          other.e12 * oe2 +
          e2 * other.oe12 +
          other.e2 * oe12 -
          oO * other.oe1 +
          other.oO * oe1 -
          o * other.oe1O -
          other.o * oe1O +
          oe1 * other.s +
          other.oe1 * s -
          oe12O * other.oe2 -
          other.oe12O * oe2 -
          oe12 * other.oe2O +
          other.oe12 * oe2O,
      oe2:
          -e1 * other.oe12 -
          other.e1 * oe12 -
          e12 * other.oe1 +
          other.e12 * oe1 -
          e2 * other.o +
          other.e2 * o -
          oO * other.oe2 +
          other.oO * oe2 -
          o * other.oe2O -
          other.o * oe2O -
          oe1O * other.oe12 +
          other.oe1O * oe12 +
          oe1 * other.oe12O +
          other.oe1 * oe12O +
          oe2 * other.s +
          other.oe2 * s,
      oO:
          -O * other.o +
          other.O * o -
          e1O * other.oe1 +
          other.e1O * oe1 -
          e1 * other.oe1O -
          other.e1 * oe1O +
          e12O * other.oe12 -
          other.e12O * oe12 -
          e12 * other.oe12O -
          other.e12 * oe12O -
          e2O * other.oe2 +
          other.e2O * oe2 -
          e2 * other.oe2O -
          other.e2 * oe2O +
          oO * other.s +
          other.oO * s,
      e12:
          -O * other.oe12 -
          other.O * oe12 -
          e1O * other.oe2 +
          other.e1O * oe2 +
          e1 * other.e2 -
          other.e1 * e2 -
          e12O * other.o -
          other.e12O * o +
          e12 * other.s +
          other.e12 * s +
          e2O * other.oe1 -
          other.e2O * oe1 +
          oO * other.oe12O +
          other.oO * oe12O +
          oe1O * other.oe2O -
          other.oe1O * oe2O,
      e1O:
          -O * other.e1 -
          O * other.oe1O +
          other.O * e1 -
          other.O * oe1O -
          e1O * other.oO +
          e1O * other.s +
          other.e1O * oO +
          other.e1O * s -
          e12O * other.e2 -
          e12O * other.oe2O -
          other.e12O * e2 +
          other.e12O * oe2O +
          e12 * other.e2O -
          other.e12 * e2O +
          e2O * other.oe12O +
          other.e2O * oe12O,
      e2O:
          -O * other.e2 -
          O * other.oe2O +
          other.O * e2 -
          other.O * oe2O +
          e1O * other.e12 -
          e1O * other.oe12O -
          other.e1O * e12 -
          other.e1O * oe12O +
          e1 * other.e12O +
          other.e1 * e12O +
          e12O * other.oe1O -
          other.e12O * oe1O -
          e2O * other.oO +
          e2O * other.s +
          other.e2O * oO +
          other.e2O * s,
      oe12:
          -e1 * other.oe2 -
          other.e1 * oe2 +
          e12 * other.o +
          other.e12 * o +
          e2 * other.oe1 +
          other.e2 * oe1 -
          oO * other.oe12 +
          other.oO * oe12 +
          o * other.oe12O -
          other.o * oe12O -
          oe1O * other.oe2 +
          other.oe1O * oe2 -
          oe1 * other.oe2O +
          other.oe1 * oe2O +
          oe12 * other.s +
          other.oe12 * s,
      oe1O:
          O * other.oe1 +
          other.O * oe1 +
          e1O * other.o +
          other.e1O * o -
          e1 * other.oO -
          other.e1 * oO +
          e12O * other.oe2 -
          other.e12O * oe2 +
          e12 * other.oe2O -
          other.e12 * oe2O -
          e2O * other.oe12 +
          other.e2O * oe12 +
          e2 * other.oe12O -
          other.e2 * oe12O +
          oe1O * other.s +
          other.oe1O * s,
      oe2O:
          O * other.oe2 +
          other.O * oe2 +
          e1O * other.oe12 -
          other.e1O * oe12 -
          e1 * other.oe12O +
          other.e1 * oe12O -
          e12O * other.oe1 +
          other.e12O * oe1 -
          e12 * other.oe1O +
          other.e12 * oe1O +
          e2O * other.o +
          other.e2O * o -
          e2 * other.oO -
          other.e2 * oO +
          oe2O * other.s +
          other.oe2O * s,
      e12O:
          O * other.e12 -
          O * other.oe12O +
          other.O * e12 +
          other.O * oe12O -
          e1O * other.e2 -
          e1O * other.oe2O -
          other.e1O * e2 +
          other.e1O * oe2O +
          e1 * other.e2O +
          other.e1 * e2O -
          e12O * other.oO +
          e12O * other.s +
          other.e12O * oO +
          other.e12O * s +
          e2O * other.oe1O -
          other.e2O * oe1O,
      oe12O:
          -O * other.oe12 +
          other.O * oe12 -
          e1O * other.oe2 -
          other.e1O * oe2 -
          e1 * other.oe2O +
          other.e1 * oe2O -
          e12O * other.o +
          other.e12O * o +
          e12 * other.oO +
          other.e12 * oO +
          e2O * other.oe1 +
          other.e2O * oe1 +
          e2 * other.oe1O -
          other.e2 * oe1O +
          oe12O * other.s +
          other.oe12O * s,
    );
  }

  /// Element-wise bitwise XOR (for integer values only)
  Multivector operator ^(Multivector other) {
    return Multivector(
      s: s * other.s,
      o: o * other.s + other.o * s,
      e1: e1 * other.s + other.e1 * s,
      e2: e2 * other.s + other.e2 * s,
      O: O * other.s + other.O * s,
      oe1: -e1 * other.o + other.e1 * o + oe1 * other.s + other.oe1 * s,
      oe2: -e2 * other.o + other.e2 * o + oe2 * other.s + other.oe2 * s,
      oO: -O * other.o + other.O * o + oO * other.s + other.oO * s,
      e12: e1 * other.e2 - other.e1 * e2 + e12 * other.s + other.e12 * s,
      e1O: -O * other.e1 + other.O * e1 + e1O * other.s + other.e1O * s,
      e2O: -O * other.e2 + other.O * e2 + e2O * other.s + other.e2O * s,
      oe12:
          -e1 * other.oe2 -
          other.e1 * oe2 +
          e12 * other.o +
          other.e12 * o +
          e2 * other.oe1 +
          other.e2 * oe1 +
          oe12 * other.s +
          other.oe12 * s,
      oe1O:
          O * other.oe1 +
          other.O * oe1 +
          e1O * other.o +
          other.e1O * o -
          e1 * other.oO -
          other.e1 * oO +
          oe1O * other.s +
          other.oe1O * s,
      oe2O:
          O * other.oe2 +
          other.O * oe2 +
          e2O * other.o +
          other.e2O * o -
          e2 * other.oO -
          other.e2 * oO +
          oe2O * other.s +
          other.oe2O * s,
      e12O:
          O * other.e12 +
          other.O * e12 -
          e1O * other.e2 -
          other.e1O * e2 +
          e1 * other.e2O +
          other.e1 * e2O +
          e12O * other.s +
          other.e12O * s,
      oe12O:
          -O * other.oe12 +
          other.O * oe12 -
          e1O * other.oe2 -
          other.e1O * oe2 -
          e1 * other.oe2O +
          other.e1 * oe2O -
          e12O * other.o +
          other.e12O * o +
          e12 * other.oO +
          other.e12 * oO +
          e2O * other.oe1 +
          other.e2O * oe1 +
          e2 * other.oe1O -
          other.e2 * oe1O +
          oe12O * other.s +
          other.oe12O * s,
    );
  }

  /// Element-wise less than comparison (returns 1.0 if less, else 0.0)
  Multivector operator <(Multivector other) {
    return Multivector(
      s:
          -O * other.o -
          other.O * o -
          e1O * other.oe1 -
          other.e1O * oe1 +
          e1 * other.e1 +
          e12O * other.oe12 +
          other.e12O * oe12 -
          e12 * other.e12 -
          e2O * other.oe2 -
          other.e2O * oe2 +
          e2 * other.e2 +
          oO * other.oO +
          oe1O * other.oe1O -
          oe12O * other.oe12O +
          oe2O * other.oe2O +
          s * other.s,
      o:
          -e1 * other.oe1 -
          e12 * other.oe12 -
          e2 * other.oe2 +
          other.oO * o +
          other.o * s -
          other.oe1O * oe1 -
          other.oe12O * oe12 -
          other.oe2O * oe2,
      e1:
          -O * other.oe1 +
          other.e1O * o +
          other.e1 * s -
          other.e12O * oe2 -
          other.e12 * e2 +
          e2O * other.oe12 -
          oO * other.oe1O +
          other.oe12O * oe2O,
      e2:
          -O * other.oe2 -
          e1O * other.oe12 +
          e1 * other.e12 +
          other.e12O * oe1 +
          other.e2O * o +
          other.e2 * s -
          oO * other.oe2O -
          oe1O * other.oe12O,
      O:
          -O * other.oO +
          other.O * s -
          e1O * other.oe1O +
          other.e1O * e1 +
          e12O * other.oe12O -
          other.e12O * e12 -
          e2O * other.oe2O +
          other.e2O * e2,
      oe1: e2 * other.oe12 - o * other.oe1O + other.oe1 * s - other.oe12O * oe2,
      oe2:
          -e1 * other.oe12 - o * other.oe2O + oe1 * other.oe12O + other.oe2 * s,
      oO: -e1 * other.oe1O - e12 * other.oe12O - e2 * other.oe2O + other.oO * s,
      e12: -O * other.oe12 - other.e12O * o + other.e12 * s + oO * other.oe12O,
      e1O:
          -O * other.oe1O + other.e1O * s - other.e12O * e2 + e2O * other.oe12O,
      e2O:
          -O * other.oe2O - e1O * other.oe12O + e1 * other.e12O + other.e2O * s,
      oe12: o * other.oe12O + other.oe12 * s,
      oe1O: e2 * other.oe12O + other.oe1O * s,
      oe2O: -e1 * other.oe12O + other.oe2O * s,
      e12O: -O * other.oe12O + other.e12O * s,
      oe12O: other.oe12O * s,
    );
  }

  /// Element-wise greater than comparison (returns 1.0 if greater, else 0.0)
  Multivector operator >(Multivector other) {
    return Multivector(
      s:
          -O * other.o -
          other.O * o -
          e1O * other.oe1 -
          other.e1O * oe1 +
          e1 * other.e1 +
          e12O * other.oe12 +
          other.e12O * oe12 -
          e12 * other.e12 -
          e2O * other.oe2 -
          other.e2O * oe2 +
          e2 * other.e2 +
          oO * other.oO +
          oe1O * other.oe1O -
          oe12O * other.oe12O +
          oe2O * other.oe2O +
          s * other.s,
      o:
          other.e1 * oe1 -
          other.e12 * oe12 +
          other.e2 * oe2 -
          oO * other.o +
          o * other.s -
          oe1O * other.oe1 +
          oe12O * other.oe12 -
          oe2O * other.oe2,
      e1:
          other.O * oe1 -
          e1O * other.o +
          e1 * other.s -
          e12O * other.oe2 +
          e12 * other.e2 +
          other.e2O * oe12 -
          other.oO * oe1O -
          oe12O * other.oe2O,
      e2:
          other.O * oe2 -
          other.e1O * oe12 -
          other.e1 * e12 +
          e12O * other.oe1 -
          e2O * other.o +
          e2 * other.s -
          other.oO * oe2O +
          other.oe1O * oe12O,
      O:
          O * other.s +
          other.O * oO -
          e1O * other.e1 -
          other.e1O * oe1O -
          e12O * other.e12 -
          other.e12O * oe12O -
          e2O * other.e2 -
          other.e2O * oe2O,
      oe1: other.e2 * oe12 - other.o * oe1O + oe1 * other.s - oe12O * other.oe2,
      oe2:
          -other.e1 * oe12 - other.o * oe2O + other.oe1 * oe12O + oe2 * other.s,
      oO: -other.e1 * oe1O - other.e12 * oe12O - other.e2 * oe2O + oO * other.s,
      e12: -other.O * oe12 - e12O * other.o + e12 * other.s + other.oO * oe12O,
      e1O:
          -other.O * oe1O + e1O * other.s - e12O * other.e2 + other.e2O * oe12O,
      e2O:
          -other.O * oe2O - other.e1O * oe12O + other.e1 * e12O + e2O * other.s,
      oe12: -other.o * oe12O + oe12 * other.s,
      oe1O: -other.e2 * oe12O + oe1O * other.s,
      oe2O: other.e1 * oe12O + oe2O * other.s,
      e12O: other.O * oe12O + e12O * other.s,
      oe12O: oe12O * other.s,
    );
  }

  /// Dot product (returns a double)
  Multivector operator |(Multivector other) {
    return Multivector(
      s:
          -O * other.o -
          other.O * o -
          e1O * other.oe1 -
          other.e1O * oe1 +
          e1 * other.e1 +
          e12O * other.oe12 +
          other.e12O * oe12 -
          e12 * other.e12 -
          e2O * other.oe2 -
          other.e2O * oe2 +
          e2 * other.e2 +
          oO * other.oO +
          oe1O * other.oe1O -
          oe12O * other.oe12O +
          oe2O * other.oe2O,
      o:
          -e1 * other.oe1 +
          other.e1 * oe1 -
          e12 * other.oe12 -
          other.e12 * oe12 -
          e2 * other.oe2 +
          other.e2 * oe2 -
          oO * other.o +
          other.oO * o -
          oe1O * other.oe1 -
          other.oe1O * oe1 +
          oe12O * other.oe12 -
          other.oe12O * oe12 -
          oe2O * other.oe2 -
          other.oe2O * oe2,
      e1:
          -O * other.oe1 +
          other.O * oe1 -
          e1O * other.o +
          other.e1O * o -
          e12O * other.oe2 -
          other.e12O * oe2 +
          e12 * other.e2 -
          other.e12 * e2 +
          e2O * other.oe12 +
          other.e2O * oe12 -
          oO * other.oe1O -
          other.oO * oe1O -
          oe12O * other.oe2O +
          other.oe12O * oe2O,
      e2:
          -O * other.oe2 +
          other.O * oe2 -
          e1O * other.oe12 -
          other.e1O * oe12 +
          e1 * other.e12 -
          other.e1 * e12 +
          e12O * other.oe1 +
          other.e12O * oe1 -
          e2O * other.o +
          other.e2O * o -
          oO * other.oe2O -
          other.oO * oe2O -
          oe1O * other.oe12O +
          other.oe1O * oe12O,
      O:
          -O * other.oO +
          other.O * oO -
          e1O * other.e1 -
          e1O * other.oe1O +
          other.e1O * e1 -
          other.e1O * oe1O -
          e12O * other.e12 +
          e12O * other.oe12O -
          other.e12O * e12 -
          other.e12O * oe12O -
          e2O * other.e2 -
          e2O * other.oe2O +
          other.e2O * e2 -
          other.e2O * oe2O,
      oe1:
          e2 * other.oe12 +
          other.e2 * oe12 -
          o * other.oe1O -
          other.o * oe1O -
          oe12O * other.oe2 -
          other.oe12O * oe2,
      oe2:
          -e1 * other.oe12 -
          other.e1 * oe12 -
          o * other.oe2O -
          other.o * oe2O +
          oe1 * other.oe12O +
          other.oe1 * oe12O,
      oO:
          -e1 * other.oe1O -
          other.e1 * oe1O -
          e12 * other.oe12O -
          other.e12 * oe12O -
          e2 * other.oe2O -
          other.e2 * oe2O,
      e12:
          -O * other.oe12 -
          other.O * oe12 -
          e12O * other.o -
          other.e12O * o +
          oO * other.oe12O +
          other.oO * oe12O,
      e1O:
          -O * other.oe1O -
          other.O * oe1O -
          e12O * other.e2 -
          other.e12O * e2 +
          e2O * other.oe12O +
          other.e2O * oe12O,
      e2O:
          -O * other.oe1O -
          other.O * oe1O -
          e12O * other.e2 -
          other.e12O * e2 +
          e2O * other.oe12O +
          other.e2O * oe12O,
      oe12: o * other.oe12O - other.o * oe12O,
      oe1O: e2 * other.oe12O - other.e2 * oe12O,
      oe2O: -e1 * other.oe12O + other.e1 * oe12O,
      e12O: -O * other.oe12O + other.O * oe12O,
      oe12O: 0,
    );
  }

  /// Returns the dual of this multivector
  Multivector dual() {
    return Multivector(
      s: -oe12O,
      o: -oe12,
      e1: oe2O,
      e2: -oe1O,
      O: e12O,
      oe1: -oe2,
      oe2: oe1,
      oO: -e12,
      e12: oO,
      e1O: e2O,
      e2O: -e1O,
      oe12: o,
      oe1O: e2,
      oe2O: -e1,
      e12O: -O,
      oe12O: s,
    );
  }

  /// Returns the involution of this multivector
  Multivector involution() {
    return Multivector(
      s: s,
      o: -o,
      e1: -e1,
      e2: -e2,
      O: -O,
      oe1: oe1,
      oe2: oe2,
      oO: oO,
      e12: e12,
      e1O: e1O,
      e2O: e2O,
      oe12: -oe12,
      oe1O: -oe1O,
      oe2O: -oe2O,
      e12O: -e12O,
      oe12O: oe12O,
    );
  }

  /// Returns the reversion of this multivector
  Multivector reversion() {
    return Multivector(
      s: s,
      o: o,
      e1: e1,
      e2: e2,
      O: O,
      oe1: -oe1,
      oe2: -oe2,
      oO: -oO,
      e12: -e12,
      e1O: -e1O,
      e2O: -e2O,
      oe12: -oe12,
      oe1O: -oe1O,
      oe2O: -oe2O,
      e12O: -e12O,
      oe12O: oe12O,
    );
  }

  /// Returns the conjugation of this multivector
  Multivector conjugation() {
    return Multivector(
      s: s,
      o: -o,
      e1: -e1,
      e2: -e2,
      O: -O,
      oe1: -oe1,
      oe2: -oe2,
      oO: -oO,
      e12: -e12,
      e1O: -e1O,
      e2O: -e2O,
      oe12: oe12,
      oe1O: oe1O,
      oe2O: oe2O,
      e12O: e12O,
      oe12O: oe12O,
    );
  }

  /// Returns the norm as Option<double>
  /// Returns Some(double) if the product is a scalar, None otherwise
  Option<double> norm() {
    final product = this | this;
    if (product.isScalar()) {
      return Some(product.s);
    }
    return const None();
  }

  @override
  List<Object?> get props => components;

  @override
  String toString() => 'Multivector($components)';
}
