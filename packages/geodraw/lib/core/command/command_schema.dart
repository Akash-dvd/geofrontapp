/// Unified command schema and type validation system
library;

import '../../models/type_hierarchy.dart';
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

  static String _mergeDescriptions(Iterable<TypeConstraint> constraints) {
    final unique = <String>{};
    for (final constraint in constraints) {
      unique.add(constraint.description);
    }
    return unique.join(' / ');
  }

  factory TypeConstraint.union(
    Iterable<TypeConstraint> constraints, {
    String? description,
  }) {
    final list = constraints.toList(growable: false);
    if (list.isEmpty) {
      throw ArgumentError('Cannot create union of empty constraint list');
    }

    final allOptional = list.every((constraint) => constraint.isOptional);
    final categories = list.map((constraint) => constraint.category).toSet();
    final resolvedDescription =
        description ??
        _mergeDescriptions(list.where((c) => c.description.isNotEmpty));

    if (categories.length == 1) {
      switch (categories.first) {
        case ValueCategory.geometry:
          final combinedTypes = <Type>{};
          final combinedLabels = <String>{};
          for (final constraint in list) {
            combinedTypes.addAll(constraint.allowedTypes);
            combinedLabels.addAll(constraint.allowedTypeLabels);
          }
          final desc = resolvedDescription.isNotEmpty
              ? resolvedDescription
              : _describeTypes(combinedTypes, combinedLabels);
          return TypeConstraint.geometry(
            allowedTypes: combinedTypes,
            allowedTypeLabels: combinedLabels,
            description: desc,
            optional: allOptional,
          );
        case ValueCategory.numeric:
          return TypeConstraint.numeric(
            description: resolvedDescription.isNotEmpty
                ? resolvedDescription
                : 'Number',
            optional: allOptional,
          );
        case ValueCategory.text:
          return TypeConstraint.text(
            description: resolvedDescription.isNotEmpty
                ? resolvedDescription
                : 'Text',
            optional: allOptional,
          );
        case ValueCategory.boolean:
          return TypeConstraint.boolean(
            description: resolvedDescription.isNotEmpty
                ? resolvedDescription
                : 'Boolean',
            optional: allOptional,
          );
        case ValueCategory.any:
          return TypeConstraint.any(
            description: resolvedDescription.isNotEmpty
                ? resolvedDescription
                : 'Any value',
            optional: allOptional,
          );
      }
    }

    return TypeConstraint.any(
      description: resolvedDescription.isNotEmpty
          ? resolvedDescription
          : 'Any allowed value',
      optional: allOptional,
    );
  }

  /// Check if the supplied [value] satisfies this constraint
  bool accepts(dynamic value) {
    switch (category) {
      case ValueCategory.geometry:
        if (value is GeometryObject) {
          return _matchesGeometryType(value.runtimeType, value.type);
        }
        if (value is Type) {
          return _matchesGeometryType(value, null);
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

  bool _matchesGeometryType(Type candidate, String? explicitLabel) {
    if (allowedTypes.isEmpty && allowedTypeLabels.isEmpty) {
      return true;
    }

    for (final type in allowedTypes) {
      if (TypeHierarchy.instance.isSubtypeOf(candidate, type)) {
        return true;
      }
    }

    if (allowedTypeLabels.isEmpty) {
      return false;
    }

    final label = explicitLabel ?? candidate.toString();
    return allowedTypeLabels.contains(label);
  }
}

/// Defines the schema for a command (argument expectations, metadata).
///
/// Schemas can declare a single ordered list of [TypeConstraint]s via
/// [argumentTypes] or multiple alternative argument patterns via the
/// [patterns] parameter. When multiple patterns are provided, validation and
/// sequential collection will succeed if the supplied arguments satisfy any of
/// the allowed sequences.
class CommandSchema {
  final List<List<TypeConstraint>> argumentPatterns;
  final String description;
  final bool createsObject;
  final String? category;
  final List<String> argumentHints;
  final List<TypeConstraint> _primaryPattern;

  List<TypeConstraint> get argumentTypes => _primaryPattern;

  CommandSchema({
    List<TypeConstraint>? argumentTypes,
    List<List<TypeConstraint>> patterns = const [],
    required this.description,
    this.createsObject = true,
    this.category,
    this.argumentHints = const [],
  }) : assert(
         argumentTypes == null || patterns.isEmpty,
         'Provide either argumentTypes or patterns, not both.',
       ),
       _primaryPattern = List.unmodifiable(
         patterns.isNotEmpty
             ? patterns.first.cast<TypeConstraint>()
             : (argumentTypes ?? const <TypeConstraint>[]),
       ),
       argumentPatterns = patterns.isNotEmpty
           ? List.unmodifiable(
               patterns
                   .map(
                     (pattern) => List<TypeConstraint>.unmodifiable(
                       pattern.cast<TypeConstraint>(),
                     ),
                   )
                   .toList(growable: false),
             )
           : argumentTypes != null
           ? List.unmodifiable(<List<TypeConstraint>>[
               List.unmodifiable(argumentTypes),
             ])
           : const <List<TypeConstraint>>[];

  /// Validate a full argument list
  ValidationResult validate(List<dynamic> args) {
    if (argumentPatterns.isEmpty) {
      if (args.isEmpty) {
        return ValidationResult.success(null);
      }
      return ValidationResult.failure(
        'No arguments expected, but received ${args.length}',
      );
    }

    // Track which pattern matched
    for (int i = 0; i < argumentPatterns.length; i++) {
      if (_matchesPatternExactly(args, argumentPatterns[i])) {
        return ValidationResult.success(i);
      }
    }

    final expected = argumentPatterns.map(_patternDescription).join(' | ');

    return ValidationResult(
      isValid: false,
      errors: [
        'Arguments did not match any allowed pattern. Expected one of: $expected.',
      ],
    );
  }

  /// Determine if another argument can be accepted sequentially
  bool canAcceptMore(List<dynamic> currentArgs) {
    if (argumentPatterns.isEmpty) {
      return false;
    }
    for (final pattern in argumentPatterns) {
      if (!_matchesPatternPrefix(currentArgs, pattern)) {
        continue;
      }
      if (currentArgs.length < pattern.length) {
        return true;
      }
    }
    return false;
  }

  /// Returns the type constraint for the next argument position
  TypeConstraint? nextConstraint(List<dynamic> currentArgs) {
    if (argumentPatterns.isEmpty) {
      return null;
    }

    final candidates = <TypeConstraint>[];

    for (final pattern in argumentPatterns) {
      if (!_matchesPatternPrefix(currentArgs, pattern)) {
        continue;
      }
      if (currentArgs.length >= pattern.length) {
        continue;
      }
      candidates.add(pattern[currentArgs.length]);
    }

    if (candidates.isEmpty) {
      return null;
    }
    if (candidates.length == 1) {
      return candidates.first;
    }
    return TypeConstraint.union(candidates);
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

  bool matchesPrefix(List<dynamic> args) {
    if (argumentPatterns.isEmpty) {
      return args.isEmpty;
    }
    return argumentPatterns.any(
      (pattern) => _matchesPatternPrefix(args, pattern),
    );
  }

  bool isSatisfied(List<dynamic> args) {
    if (argumentPatterns.isEmpty) {
      return args.isEmpty;
    }
    return argumentPatterns.any(
      (pattern) => _matchesPatternExactly(args, pattern),
    );
  }

  bool _matchesPatternPrefix(List<dynamic> args, List<TypeConstraint> pattern) {
    if (args.length > pattern.length) {
      return false;
    }
    for (var i = 0; i < args.length; i++) {
      if (!pattern[i].accepts(args[i])) {
        return false;
      }
    }
    return true;
  }

  bool _matchesPatternExactly(
    List<dynamic> args,
    List<TypeConstraint> pattern,
  ) {
    if (!_matchesPatternPrefix(args, pattern)) {
      return false;
    }

    if (args.length == pattern.length) {
      return true;
    }

    for (var i = args.length; i < pattern.length; i++) {
      if (!pattern[i].isOptional) {
        return false;
      }
    }
    return true;
  }

  String _patternDescription(List<TypeConstraint> pattern) {
    if (pattern.isEmpty) {
      return '(no arguments)';
    }
    return pattern
        .map(
          (constraint) => constraint.isOptional
              ? '[${constraint.description}]'
              : constraint.description,
        )
        .join(', ');
  }
}

/// Result of schema validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  /// Index of the pattern that matched (if validation succeeded)
  final int? matchedPatternIndex;

  ValidationResult({
    required this.isValid,
    required this.errors,
    this.matchedPatternIndex,
  });

  factory ValidationResult.success([int? patternIndex]) =>
      ValidationResult(
        isValid: true,
        errors: const [],
        matchedPatternIndex: patternIndex,
      );

  factory ValidationResult.failure(String error) =>
      ValidationResult(
        isValid: false,
        errors: [error],
        matchedPatternIndex: null,
      );
}
