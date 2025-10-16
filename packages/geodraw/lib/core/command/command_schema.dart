/// Unified command schema and type validation system
library;

import 'type_hierarchy.dart';
import '../../models/geometry_object.dart';

/// High level categories of argument values supported by the command system
enum ValueCategory { geometry, numeric, text, boolean, any }

/// Represents a type constraint for an individual argument position
class TypeConstraint {
  final ValueCategory category;
  final Set<Type> allowedTypes;
  final Set<String> allowedTypeLabels;
  final String description;
  final bool isOptional;

  const TypeConstraint._internal({
    required this.category,
    required this.allowedTypes,
    required this.allowedTypeLabels,
    required this.description,
    required this.isOptional,
  });

  factory TypeConstraint.geometry({
    required Set<Type> allowedTypes,
    Set<String> allowedTypeLabels = const {},
    String? description,
    bool optional = false,
  }) {
    final desc =
        description ??
        (allowedTypes.isEmpty && allowedTypeLabels.isEmpty
            ? 'Geometry object'
            : _describeTypes(allowedTypes, allowedTypeLabels));
    return TypeConstraint._internal(
      category: ValueCategory.geometry,
      allowedTypes: allowedTypes,
      allowedTypeLabels: allowedTypeLabels,
      description: desc,
      isOptional: optional,
    );
  }

  factory TypeConstraint.numeric({
    String description = 'Number',
    bool optional = false,
  }) {
    return TypeConstraint._internal(
      category: ValueCategory.numeric,
      allowedTypes: const {},
      allowedTypeLabels: const {},
      description: description,
      isOptional: optional,
    );
  }

  factory TypeConstraint.text({
    String description = 'Text',
    bool optional = false,
  }) {
    return TypeConstraint._internal(
      category: ValueCategory.text,
      allowedTypes: const {},
      allowedTypeLabels: const {},
      description: description,
      isOptional: optional,
    );
  }

  factory TypeConstraint.boolean({
    String description = 'Boolean',
    bool optional = false,
  }) {
    return TypeConstraint._internal(
      category: ValueCategory.boolean,
      allowedTypes: const {},
      allowedTypeLabels: const {},
      description: description,
      isOptional: optional,
    );
  }

  factory TypeConstraint.any({
    String description = 'Any value',
    bool optional = false,
  }) {
    return TypeConstraint._internal(
      category: ValueCategory.any,
      allowedTypes: const {},
      allowedTypeLabels: const {},
      description: description,
      isOptional: optional,
    );
  }

  static String _describeTypes(Set<Type> runtimeTypes, Set<String> typeLabels) {
    final parts = <String>[];
    parts.addAll(runtimeTypes.map((type) => type.toString()));
    parts.addAll(typeLabels);
    if (parts.isEmpty) return 'Geometry object';
    if (parts.length == 1) return parts.first;
    return parts.join(' / ');
  }

  /// Check if the supplied [value] satisfies this constraint
  bool accepts(dynamic value) {
    switch (category) {
      case ValueCategory.geometry:
        if (value is! GeometryObject) return false;
        if (allowedTypes.isEmpty && allowedTypeLabels.isEmpty) {
          return true;
        }
        final runtimeType = value.runtimeType;
        for (final type in allowedTypes) {
          if (TypeHierarchy.instance.isSubtypeOf(runtimeType, type)) {
            return true;
          }
        }
        if (allowedTypeLabels.contains(value.type)) {
          return true;
        }
        return false;
      case ValueCategory.numeric:
        return value is num;
      case ValueCategory.text:
        return value is String;
      case ValueCategory.boolean:
        return value is bool;
      case ValueCategory.any:
        return true;
    }
  }
}

/// Defines the schema for a command (argument expectations, metadata)
class CommandSchema {
  final List<TypeConstraint> argumentTypes;
  final String description;
  final bool createsObject;
  final String? category;
  final List<String> argumentHints;

  const CommandSchema({
    required this.argumentTypes,
    required this.description,
    this.createsObject = true,
    this.category,
    this.argumentHints = const [],
  });

  /// Validate a full argument list
  ValidationResult validate(List<dynamic> args) {
    final errors = <String>[];

    final requiredCount = argumentTypes.where((t) => !t.isOptional).length;
    if (args.length < requiredCount) {
      errors.add(
        'Expected at least $requiredCount arguments, got ${args.length}',
      );
      return ValidationResult(isValid: false, errors: errors);
    }

    if (args.length > argumentTypes.length) {
      errors.add(
        'Expected at most ${argumentTypes.length} arguments, got ${args.length}',
      );
      return ValidationResult(isValid: false, errors: errors);
    }

    for (var i = 0; i < args.length; i++) {
      final constraint = argumentTypes[i];
      final value = args[i];
      if (!constraint.accepts(value)) {
        errors.add(
          'Argument ${i + 1}: expected ${constraint.description}, got ${value.runtimeType}',
        );
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Determine if another argument can be accepted sequentially
  bool canAcceptMore(List<dynamic> currentArgs) {
    return currentArgs.length < argumentTypes.length;
  }

  /// Returns the type constraint for the next argument position
  TypeConstraint? nextConstraint(List<dynamic> currentArgs) {
    if (currentArgs.length >= argumentTypes.length) return null;
    return argumentTypes[currentArgs.length];
  }

  /// Provide human readable description for the next argument
  String describeNext(List<dynamic> currentArgs) {
    final constraint = nextConstraint(currentArgs);
    if (constraint == null) {
      return 'Command complete';
    }
    if (argumentHints.isNotEmpty && currentArgs.length < argumentHints.length) {
      return argumentHints[currentArgs.length];
    }
    return 'Select ${constraint.description}';
  }
}

/// Result of schema validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.success() =>
      ValidationResult(isValid: true, errors: const []);

  factory ValidationResult.failure(String error) =>
      ValidationResult(isValid: false, errors: [error]);
}
