import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Describes the expected input for a solver command argument.
class SolverArgumentDescriptor extends Equatable {
  const SolverArgumentDescriptor({
    required this.label,
    required this.inputType,
    this.hint,
  });

  final String label;
  final SolverArgumentInputType inputType;
  final String? hint;

  @override
  List<Object?> get props => [label, inputType, hint];
}

/// Supported argument input primitives.
enum SolverArgumentInputType {
  point,
  line,
  circle,
  object,
  length,
  angle,
  ratio,
  value,
  area,
  polygon,
  text,
}

/// Describes a solver command that can be attached to a problem.
class SolverCommandDescriptor extends Equatable {
  const SolverCommandDescriptor({
    required this.id,
    required this.label,
    required this.arguments,
    this.description,
  });

  final String id;
  final String label;
  final List<SolverArgumentDescriptor> arguments;
  final String? description;

  @override
  List<Object?> get props => [id, label, description, arguments];
}

/// Represents a single solver command entry persisted with a problem.
class SolverCommandEntry extends Equatable {
  const SolverCommandEntry({
    required this.command,
    required this.arguments,
  });

  final String command;
  final List<String> arguments;

  SolverCommandEntry copyWith({
    String? command,
    List<String>? arguments,
  }) {
    return SolverCommandEntry(
      command: command ?? this.command,
      arguments: arguments ?? this.arguments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'arguments': arguments,
    };
  }

  static SolverCommandEntry fromJson(Map<String, dynamic> json) {
    final args = (json['arguments'] as List?)
            ?.map((value) => value?.toString() ?? '')
            .toList(growable: false) ??
        const <String>[];
    return SolverCommandEntry(
      command: json['command']?.toString() ?? 'command',
      arguments: args,
    );
  }

  @override
  List<Object?> get props => [command, arguments];
}

/// Collection wrapper for command entries with helpers to serialize and merge.
class SolverCommandSet extends Equatable {
  const SolverCommandSet({
    this.entries = const <SolverCommandEntry>[],
  });

  final List<SolverCommandEntry> entries;

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  SolverCommandSet copyWith({List<SolverCommandEntry>? entries}) {
    return SolverCommandSet(entries: entries ?? this.entries);
  }

  SolverCommandSet add(SolverCommandEntry entry) {
    return SolverCommandSet(entries: [...entries, entry]);
  }

  SolverCommandSet replace(int index, SolverCommandEntry entry) {
    final buffer = [...entries];
    buffer[index] = entry;
    return SolverCommandSet(entries: buffer);
  }

  SolverCommandSet removeAt(int index) {
    final buffer = [...entries]..removeAt(index);
    return SolverCommandSet(entries: buffer);
  }

  Map<String, dynamic>? toJson() {
    if (entries.isEmpty) {
      return null;
    }
    return {
      'commands': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  String? toJsonString({bool pretty = false}) {
    final jsonMap = toJson();
    if (jsonMap == null) {
      return null;
    }

    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(jsonMap);
  }

  Map<String, dynamic>? toDynamicPayload() => toJson();

  static SolverCommandSet fromEntries(List<SolverCommandEntry> entries) {
    return SolverCommandSet(entries: List.unmodifiable(entries));
  }

  static SolverCommandSet fromJsonString(String? raw) {
    if (raw == null) {
      return const SolverCommandSet();
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const SolverCommandSet();
    }

    try {
      final decoded = jsonDecode(trimmed);
      return fromDynamic(decoded);
    } catch (_) {
      return SolverCommandSet(entries: [
        SolverCommandEntry(
          command: 'text',
          arguments: [trimmed],
        ),
      ]);
    }
  }

  static SolverCommandSet fromDynamic(dynamic value) {
    if (value == null) {
      return const SolverCommandSet();
    }

    if (value is SolverCommandSet) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      final commands = value['commands'];
      if (commands is List) {
        final entries = commands
            .whereType<Map>()
            .map((item) => SolverCommandEntry.fromJson(
                  item.map((key, dynamic v) => MapEntry(key.toString(), v)),
                ))
            .toList();
        return SolverCommandSet(entries: entries);
      }

      // Treat any other map as a single payload argument.
      final jsonPayload = jsonEncode(value);
      return SolverCommandSet(entries: [
        SolverCommandEntry(
          command: 'payload',
          arguments: [jsonPayload],
        ),
      ]);
    }

    if (value is Map) {
      return fromDynamic(value.map((key, dynamic v) => MapEntry(key.toString(), v)));
    }

    if (value is List) {
      final entries = value
          .whereType<Map>()
          .map((item) => SolverCommandEntry.fromJson(
                item.map((key, dynamic v) => MapEntry(key.toString(), v)),
              ))
          .toList();
      if (entries.isEmpty) {
        final payload = jsonEncode(value);
        return SolverCommandSet(entries: [
          SolverCommandEntry(command: 'payload', arguments: [payload]),
        ]);
      }
      return SolverCommandSet(entries: entries);
    }

    return SolverCommandSet(entries: [
      SolverCommandEntry(command: 'value', arguments: [value.toString()]),
    ]);
  }

  static SolverCommandSet fromSolverPayload(dynamic value) {
    if (value == null) {
      return const SolverCommandSet();
    }

    if (value is Map && (value['commands'] is List || value['command'] != null)) {
      return fromDynamic(value);
    }

    if (value is List) {
      final entries = <SolverCommandEntry>[];
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map<String, dynamic>) {
          entries.add(
            SolverCommandEntry(
              command: item['command']?.toString() ?? 'step_${i + 1}',
              arguments: [jsonEncode(item)],
            ),
          );
        } else {
          entries.add(
            SolverCommandEntry(
              command: 'step_${i + 1}',
              arguments: [item.toString()],
            ),
          );
        }
      }
      return SolverCommandSet(entries: entries);
    }

    if (value is Map<String, dynamic>) {
      final payload = jsonEncode(value);
      return SolverCommandSet(entries: [
        SolverCommandEntry(command: 'payload', arguments: [payload]),
      ]);
    }

    return SolverCommandSet(entries: [
      SolverCommandEntry(command: 'payload', arguments: [value.toString()]),
    ]);
  }

  @override
  List<Object?> get props => [entries];
}

/// Catalog of available solver commands organized by usage category.
class SolverCommandCatalog {
  static final Map<String, SolverCommandDescriptor> _registry = {
    for (final descriptor in [
      ...scalarConstraints,
      ...objectConstraints,
      ...scalarProofGoals,
      ...objectProofGoals,
    ])
      descriptor.id: descriptor,
  };

  static SolverCommandDescriptor? byId(String id) => _registry[id];

  /// Scalar constraint commands catalogue.
  static const List<SolverCommandDescriptor> scalarConstraints = [
    SolverCommandDescriptor(
      id: 'EqualLength',
      label: 'Equal Length',
      description: 'Distance(AB) = Distance(CD)',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First segment',
          inputType: SolverArgumentInputType.object,
          hint: 'e.g. AB',
        ),
        SolverArgumentDescriptor(
          label: 'Second segment',
          inputType: SolverArgumentInputType.object,
          hint: 'e.g. CD',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedLength',
      label: 'Fixed Length',
      description: 'Segment length equals given value',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Segment',
          inputType: SolverArgumentInputType.object,
          hint: 'e.g. AB',
        ),
        SolverArgumentDescriptor(
          label: 'Length',
          inputType: SolverArgumentInputType.length,
          hint: 'numeric value',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualAngle',
      label: 'Equal Angle',
      description: 'Two angles are equal',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First angle',
          inputType: SolverArgumentInputType.angle,
          hint: 'e.g. ∠ABC',
        ),
        SolverArgumentDescriptor(
          label: 'Second angle',
          inputType: SolverArgumentInputType.angle,
          hint: 'e.g. ∠DEF',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedAngle',
      label: 'Fixed Angle',
      description: 'Angle equals a constant',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Angle',
          inputType: SolverArgumentInputType.angle,
        ),
        SolverArgumentDescriptor(
          label: 'Measure',
          inputType: SolverArgumentInputType.value,
          hint: 'degrees/radians',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProportionalLengths',
      label: 'Proportional Lengths',
      description: 'AB / CD = ratio',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First segment',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Second segment',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Ratio',
          inputType: SolverArgumentInputType.ratio,
          hint: 'numeric ratio',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualArea',
      label: 'Equal Area',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First region',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Second region',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedArea',
      label: 'Fixed Area',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Region',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Area',
          inputType: SolverArgumentInputType.area,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualRadius',
      label: 'Equal Radius',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First circle',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Second circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedRadius',
      label: 'Fixed Radius',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Radius',
          inputType: SolverArgumentInputType.length,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualSlope',
      label: 'Equal Slope',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First line',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Second line',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedSlope',
      label: 'Fixed Slope',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Slope',
          inputType: SolverArgumentInputType.value,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualDistance',
      label: 'Equal Distance',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First distance',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Second distance',
          inputType: SolverArgumentInputType.object,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'FixedDistance',
      label: 'Fixed Distance',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Distance',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Value',
          inputType: SolverArgumentInputType.length,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualPerimeter',
      label: 'Equal Perimeter',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First polygon',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Second polygon',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'EqualCircumference',
      label: 'Equal Circumference',
      arguments: [
        SolverArgumentDescriptor(
          label: 'First circle',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Second circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
  ];

  /// Object constraint commands catalogue.
  static const List<SolverCommandDescriptor> objectConstraints = [
    SolverCommandDescriptor(
      id: 'AreCollinear',
      label: 'Are Collinear',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point A',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Point B',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Point C',
          inputType: SolverArgumentInputType.point,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreConcurrent',
      label: 'Are Concurrent',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 3',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreParallel',
      label: 'Are Parallel',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ArePerpendicular',
      label: 'Are Perpendicular',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreTangentialLineCircle',
      label: 'Line Tangent To Circle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreTangentialCircles',
      label: 'Circles Tangential',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Circle 1',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Circle 2',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreConcentric',
      label: 'Are Concentric',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Circle 1',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Circle 2',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsOnLine',
      label: 'Point On Line',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Line',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsOnCircle',
      label: 'Point On Circle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsOnPolygon',
      label: 'Point On Polygon',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Polygon',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsInsidePolygon',
      label: 'Point Inside Polygon',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Polygon',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsOnArc',
      label: 'Point On Arc',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Arc',
          inputType: SolverArgumentInputType.object,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsReflection',
      label: 'Reflection Across Line',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Reflected point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Original point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Mirror line',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsInversion',
      label: 'Inversion In Circle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Inverted point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Original point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreSimilarTriangles',
      label: 'Triangles Similar',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Triangle 1',
          inputType: SolverArgumentInputType.polygon,
          hint: 'e.g. △ABC',
        ),
        SolverArgumentDescriptor(
          label: 'Triangle 2',
          inputType: SolverArgumentInputType.polygon,
          hint: 'e.g. △DEF',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreCongruentTriangles',
      label: 'Triangles Congruent',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Triangle 1',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Triangle 2',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreSymmetric',
      label: 'Objects Symmetric',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Object 1',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Object 2',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Axis',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreCyclic',
      label: 'Points Are Cyclic',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Cyclic points',
          inputType: SolverArgumentInputType.text,
          hint: 'comma separated',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'AreEquidistant',
      label: 'Points Equidistant From Q',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Points',
          inputType: SolverArgumentInputType.text,
          hint: 'comma separated',
        ),
        SolverArgumentDescriptor(
          label: 'Reference point',
          inputType: SolverArgumentInputType.point,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'IsBisector',
      label: 'Line Bisects Angle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Angle',
          inputType: SolverArgumentInputType.angle,
        ),
      ],
    ),
  ];

  /// Scalar proof goal templates.
  static const List<SolverCommandDescriptor> scalarProofGoals = [
    SolverCommandDescriptor(
      id: 'ProveEqualLength',
      label: 'Prove Equal Length',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Segment 1',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Segment 2',
          inputType: SolverArgumentInputType.object,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveEqualAngle',
      label: 'Prove Equal Angle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Angle 1',
          inputType: SolverArgumentInputType.angle,
        ),
        SolverArgumentDescriptor(
          label: 'Angle 2',
          inputType: SolverArgumentInputType.angle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProvePerpendicularity',
      label: 'Prove Perpendicularity',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveParallelism',
      label: 'Prove Parallelism',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveRatio',
      label: 'Prove Ratio',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Segment 1',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Segment 2',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Ratio',
          inputType: SolverArgumentInputType.ratio,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveFixedDistance',
      label: 'Prove Fixed Distance',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Points',
          inputType: SolverArgumentInputType.object,
          hint: 'e.g. AB',
        ),
        SolverArgumentDescriptor(
          label: 'Distance',
          inputType: SolverArgumentInputType.length,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveEqualArea',
      label: 'Prove Equal Area',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Region 1',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Region 2',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveAreaRelation',
      label: 'Prove Area Relation',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Region 1',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Region 2',
          inputType: SolverArgumentInputType.polygon,
        ),
        SolverArgumentDescriptor(
          label: 'Ratio',
          inputType: SolverArgumentInputType.ratio,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveCircleRadius',
      label: 'Prove Circle Radius',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
        SolverArgumentDescriptor(
          label: 'Radius',
          inputType: SolverArgumentInputType.length,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveEqualSlope',
      label: 'Prove Equal Slope',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
  ];

  /// Object proof goal templates.
  static const List<SolverCommandDescriptor> objectProofGoals = [
    SolverCommandDescriptor(
      id: 'ProveCollinear',
      label: 'Prove Collinear',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point A',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Point B',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Point C',
          inputType: SolverArgumentInputType.point,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveConcurrent',
      label: 'Prove Concurrent',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 3',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProvePerpendicular',
      label: 'Prove Perpendicular',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveParallel',
      label: 'Prove Parallel',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line 1',
          inputType: SolverArgumentInputType.line,
        ),
        SolverArgumentDescriptor(
          label: 'Line 2',
          inputType: SolverArgumentInputType.line,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveOnCircle',
      label: 'Prove Point On Circle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Point',
          inputType: SolverArgumentInputType.point,
        ),
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveTangency',
      label: 'Prove Tangency',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Line or circle',
          inputType: SolverArgumentInputType.object,
        ),
        SolverArgumentDescriptor(
          label: 'Circle',
          inputType: SolverArgumentInputType.circle,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveConcyclic',
      label: 'Prove Concyclic Points',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Points',
          inputType: SolverArgumentInputType.text,
          hint: 'comma separated',
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveEquilateral',
      label: 'Prove Equilateral Triangle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Triangle',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveIsosceles',
      label: 'Prove Isosceles Triangle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Triangle',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveRectangle',
      label: 'Prove Rectangle',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Quadrilateral',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveSquare',
      label: 'Prove Square',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Quadrilateral',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveRhombus',
      label: 'Prove Rhombus',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Quadrilateral',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProveCyclicQuadrilateral',
      label: 'Prove Cyclic Quadrilateral',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Quadrilateral',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
    SolverCommandDescriptor(
      id: 'ProvePolygonRegular',
      label: 'Prove Regular Polygon',
      arguments: [
        SolverArgumentDescriptor(
          label: 'Polygon',
          inputType: SolverArgumentInputType.polygon,
        ),
      ],
    ),
  ];
}
