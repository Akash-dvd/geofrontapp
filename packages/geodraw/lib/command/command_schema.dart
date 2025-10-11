/// Unified command schema and type validation system
library;

import '../models/geometry_object.dart';
import '../models/canvas_object.dart';
import '../models/simple/geo_point.dart'
    show GeoPoint, GeoPointer, GeoMidpoint, GeoInvPoint;
import '../models/simple/geo_line.dart'
    show
        GeoLine,
        GeoLine2P,
        GeoPerpendicularBisector,
        GeoPerpendicularLine,
        GeoParallelLine;
import '../models/simple/geo_circle.dart'
    show GeoCircle, GeoCircle2P, GeoCircle3P, GeoInvCircle;
import '../tools/tool.dart';

/// Represents a type constraint for command arguments
class TypeConstraint {
  /// Allowed types (union of types)
  final Set<Type> allowedTypes;

  /// Human-readable description
  final String description;

  /// Whether this argument is optional
  final bool isOptional;

  const TypeConstraint({
    required this.allowedTypes,
    required this.description,
    this.isOptional = false,
  });

  /// Check if a runtime type satisfies this constraint
  bool accepts(Type runtimeType) {
    // Check if the type or any of its supertypes are in allowedTypes
    return allowedTypes.any(
      (allowedType) => _isSubtypeOf(runtimeType, allowedType),
    );
  }

  /// Check if testType is a subtype of superType
  bool _isSubtypeOf(Type testType, Type superType) {
    // Direct match
    if (testType == superType) return true;

    // Use the class tree to check inheritance
    return ClassTree.isSubtypeOf(testType, superType);
  }

  /// Common type constraints
  static const point = TypeConstraint(
    allowedTypes: {GeoPoint},
    description: 'Any point',
  );

  static const line = TypeConstraint(
    allowedTypes: {GeoLine},
    description: 'Any line',
  );

  static const circle = TypeConstraint(
    allowedTypes: {GeoCircle},
    description: 'Any circle',
  );

  static const geometry = TypeConstraint(
    allowedTypes: {GeometryObject},
    description: 'Any geometry object',
  );

  static const simpleGeometry = TypeConstraint(
    allowedTypes: {GeoPoint, GeoLine, GeoCircle},
    description: 'Point, line, or circle',
  );
}

/// Defines the schema for a command (what arguments it expects)
class CommandSchema {
  /// The command type
  final ToolType commandType;

  /// List of argument constraints (in order)
  final List<TypeConstraint> argumentTypes;

  /// Human-readable description
  final String description;

  /// Whether this command creates a new object
  final bool createsObject;

  const CommandSchema({
    required this.commandType,
    required this.argumentTypes,
    required this.description,
    this.createsObject = true,
  });

  /// Validate a list of arguments against this schema
  ValidationResult validate(List<dynamic> arguments) {
    final errors = <String>[];

    // Check argument count
    final requiredArgs = argumentTypes.where((t) => !t.isOptional).length;
    if (arguments.length < requiredArgs) {
      errors.add(
        'Expected at least $requiredArgs arguments, got ${arguments.length}',
      );
      return ValidationResult(isValid: false, errors: errors);
    }

    if (arguments.length > argumentTypes.length) {
      errors.add(
        'Expected at most ${argumentTypes.length} arguments, got ${arguments.length}',
      );
      return ValidationResult(isValid: false, errors: errors);
    }

    // Check each argument type
    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final constraint = argumentTypes[i];

      // Special cases for non-object types
      if (arg is num || arg is String || arg is bool) {
        // Primitive types are always accepted (coordinates, labels, etc.)
        continue;
      }

      if (arg is GeometryObject) {
        if (!constraint.accepts(arg.runtimeType)) {
          errors.add(
            'Argument ${i + 1}: Expected ${constraint.description}, '
            'got ${arg.runtimeType}',
          );
        }
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Check if this command can accept another argument
  bool canAcceptMore(List<dynamic> currentArgs) {
    return currentArgs.length < argumentTypes.length;
  }

  /// Get the type constraint for the next argument
  TypeConstraint? getNextArgumentType(List<dynamic> currentArgs) {
    if (currentArgs.length >= argumentTypes.length) {
      return null;
    }
    return argumentTypes[currentArgs.length];
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.success() {
    return ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.failure(String error) {
    return ValidationResult(isValid: false, errors: [error]);
  }
}

/// Registry of all command schemas
class CommandSchemaRegistry {
  static final Map<ToolType, CommandSchema> _schemas = {
    ToolType.point: CommandSchema(
      commandType: ToolType.point,
      argumentTypes: [
        // x, y coordinates (handled as primitives)
      ],
      description: 'Create a free point at coordinates',
      createsObject: true,
    ),

    ToolType.line: CommandSchema(
      commandType: ToolType.line,
      argumentTypes: [TypeConstraint.point, TypeConstraint.point],
      description: 'Create a line through two points',
      createsObject: true,
    ),

    ToolType.circle: CommandSchema(
      commandType: ToolType.circle,
      argumentTypes: [
        TypeConstraint.point, // center
        TypeConstraint.point, // point on circle
      ],
      description: 'Create a circle with center and point on circumference',
      createsObject: true,
    ),

    ToolType.circleThreePoints: CommandSchema(
      commandType: ToolType.circleThreePoints,
      argumentTypes: [
        TypeConstraint.point,
        TypeConstraint.point,
        TypeConstraint.point,
      ],
      description: 'Create a circle through three points',
      createsObject: true,
    ),

    ToolType.midpoint: CommandSchema(
      commandType: ToolType.midpoint,
      argumentTypes: [TypeConstraint.point, TypeConstraint.point],
      description: 'Create midpoint between two points',
      createsObject: true,
    ),

    ToolType.perpendicular: CommandSchema(
      commandType: ToolType.perpendicular,
      argumentTypes: [TypeConstraint.line, TypeConstraint.point],
      description: 'Create perpendicular line through point',
      createsObject: true,
    ),

    ToolType.parallel: CommandSchema(
      commandType: ToolType.parallel,
      argumentTypes: [TypeConstraint.line, TypeConstraint.point],
      description: 'Create parallel line through point',
      createsObject: true,
    ),

    ToolType.perpBisector: CommandSchema(
      commandType: ToolType.perpBisector,
      argumentTypes: [TypeConstraint.point, TypeConstraint.point],
      description: 'Create perpendicular bisector of segment',
      createsObject: true,
    ),

    ToolType.intersection: CommandSchema(
      commandType: ToolType.intersection,
      argumentTypes: [
        TypeConstraint.simpleGeometry,
        TypeConstraint.simpleGeometry,
      ],
      description: 'Find intersection points of two objects',
      createsObject: true,
    ),

    ToolType.select: CommandSchema(
      commandType: ToolType.select,
      argumentTypes: [TypeConstraint.geometry],
      description: 'Select an object',
      createsObject: false,
    ),
  };

  /// Get schema for a command type
  static CommandSchema? getSchema(ToolType type) {
    return _schemas[type];
  }

  /// Validate arguments for a command
  static ValidationResult validate(ToolType type, List<dynamic> arguments) {
    final schema = _schemas[type];
    if (schema == null) {
      return ValidationResult.failure('Unknown command type: $type');
    }
    return schema.validate(arguments);
  }

  /// Get all available commands
  static List<ToolType> get allCommands => _schemas.keys.toList();
}

/// Class hierarchy tree for runtime type checking
class ClassTree {
  /// Map of type to its parent types (for inheritance checking)
  static final Map<Type, Set<Type>> _inheritance = {
    // Canvas hierarchy
    CanvasObject: {Object},
    GeometryObject: {CanvasObject, Object},

    // Point hierarchy
    GeoPoint: {GeometryObject, CanvasObject, Object},
    GeoPointer: {GeoPoint, GeometryObject, CanvasObject, Object},
    GeoMidpoint: {GeoPoint, GeometryObject, CanvasObject, Object},
    GeoInvPoint: {GeoPoint, GeometryObject, CanvasObject, Object},

    // Line hierarchy
    GeoLine: {GeometryObject, CanvasObject, Object},
    GeoLine2P: {GeoLine, GeometryObject, CanvasObject, Object},
    GeoPerpendicularBisector: {GeoLine, GeometryObject, CanvasObject, Object},
    GeoPerpendicularLine: {GeoLine, GeometryObject, CanvasObject, Object},
    GeoParallelLine: {GeoLine, GeometryObject, CanvasObject, Object},

    // Circle hierarchy
    GeoCircle: {GeometryObject, CanvasObject, Object},
    GeoCircle2P: {GeoCircle, GeometryObject, CanvasObject, Object},
    GeoCircle3P: {GeoCircle, GeometryObject, CanvasObject, Object},
    GeoInvCircle: {GeoCircle, GeometryObject, CanvasObject, Object},
  };

  /// Check if testType is a subtype of superType
  static bool isSubtypeOf(Type testType, Type superType) {
    if (testType == superType) return true;

    final supertypes = _inheritance[testType];
    if (supertypes == null) return false;

    return supertypes.contains(superType);
  }

  /// Get all supertypes of a type
  static Set<Type> getSupertypes(Type type) {
    return _inheritance[type] ?? {};
  }

  /// Get all subtypes of a type
  static Set<Type> getSubtypes(Type superType) {
    final subtypes = <Type>{};
    for (final entry in _inheritance.entries) {
      if (entry.value.contains(superType) && entry.key != superType) {
        subtypes.add(entry.key);
      }
    }
    return subtypes;
  }

  /// Register a new type in the hierarchy
  static void register(Type type, Set<Type> supertypes) {
    _inheritance[type] = supertypes;
  }
}
