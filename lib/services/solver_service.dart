import 'package:graphql_flutter/graphql_flutter.dart';

/// Service for interacting with the Python Solver GraphQL API
/// 
/// The solver provides:
/// - Constraint solving and validation
/// - Proof generation (scalar and object proofs)
/// - AI-powered command generation from natural language
class SolverService {
  final GraphQLClient _client;

  SolverService({String? endpoint}) 
      : _client = GraphQLClient(
          link: HttpLink(endpoint ?? 'http://192.168.1.3:5000/graphql'),
          cache: GraphQLCache(),
        );

  /// Solve geometric constraints and generate proofs
  /// 
  /// Returns a [SolverResult] containing:
  /// - success: whether all constraints were satisfied
  /// - scalarProof: algebraic/numerical proof in Markdown
  /// - objectProof: geometric proof in Markdown
  /// - constraintResults: detailed results for each constraint
  Future<SolverResult> solveConstraints({
    required Map<String, dynamic> constructionData,
    Map<String, dynamic>? scalarConstraints,
    Map<String, dynamic>? objectConstraints,
    required String proofGoal,
  }) async {
    const String mutation = '''
      mutation SolveConstraints(\$input: SolverInput!) {
        solveConstraints(input: \$input) {
          success
          errorMessage
          errorType
          scalarProof
          objectProof
          constraintResults {
            id
            type
            satisfied
            actualValue
            expectedValue
            tolerance
            explanation
          }
          constructionSteps {
            stepNumber
            command
            description
            theoremApplied
            justification
          }
          computationTime
        }
      }
    ''';

    final variables = {
      'input': {
        'constructionData': constructionData,
        'scalarConstraints': scalarConstraints,
        'objectConstraints': objectConstraints,
        'proofGoal': proofGoal,
      },
    };

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        return SolverResult(
          success: false,
          errorMessage: result.exception.toString(),
        );
      }

      final data = result.data?['solveConstraints'];
      if (data == null) {
        return SolverResult(
          success: false,
          errorMessage: 'No data returned from solver',
        );
      }

      return SolverResult.fromJson(data);
    } catch (e) {
      return SolverResult(
        success: false,
        errorMessage: 'Failed to connect to solver: $e',
      );
    }
  }

  /// Generate CLI commands from natural language description
  /// 
  /// Example: "Create an equilateral triangle with side length 100"
  /// Returns a list of CLI commands to execute
  Future<AIGenerateResult> generateCommands({
    required String description,
    Map<String, dynamic>? context,
    int? maxCommands,
  }) async {
    const String mutation = '''
      mutation GenerateCommands(\$input: AIGenerateInput!) {
        generateCommands(input: \$input) {
          success
          errorMessage
          commands
          explanation
          confidence
          alternatives {
            commands
            explanation
            confidence
          }
        }
      }
    ''';

    final variables = {
      'input': {
        'description': description,
        if (context != null) 'context': context,
        if (maxCommands != null) 'maxCommands': maxCommands,
      },
    };

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        return AIGenerateResult(
          success: false,
          errorMessage: result.exception.toString(),
          commands: [],
          explanation: '',
          confidence: 0.0,
        );
      }

      final data = result.data?['generateCommands'];
      if (data == null) {
        return AIGenerateResult(
          success: false,
          errorMessage: 'No data returned from AI service',
          commands: [],
          explanation: '',
          confidence: 0.0,
        );
      }

      return AIGenerateResult.fromJson(data);
    } catch (e) {
      return AIGenerateResult(
        success: false,
        errorMessage: 'Failed to connect to AI service: $e',
        commands: [],
        explanation: '',
        confidence: 0.0,
      );
    }
  }

  /// Validate CLI commands without executing them
  Future<ValidationResult> validateCommands(List<String> commands) async {
    const String mutation = '''
      mutation ValidateCommands(\$commands: [String!]!) {
        validateCommands(commands: \$commands) {
          valid
          errors {
            command
            line
            message
            category
          }
          warnings {
            command
            line
            message
          }
        }
      }
    ''';

    final variables = {'commands': commands};

    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: variables,
        ),
      );

      if (result.hasException) {
        return ValidationResult(
          valid: false,
          errors: [
            CommandError(
              command: '',
              line: 0,
              message: result.exception.toString(),
              category: 'SYNTAX_ERROR',
            ),
          ],
        );
      }

      final data = result.data?['validateCommands'];
      if (data == null) {
        return ValidationResult(
          valid: false,
          errors: [
            CommandError(
              command: '',
              line: 0,
              message: 'No data returned from validator',
              category: 'SYNTAX_ERROR',
            ),
          ],
        );
      }

      return ValidationResult.fromJson(data);
    } catch (e) {
      return ValidationResult(
        valid: false,
        errors: [
          CommandError(
            command: '',
            line: 0,
            message: 'Failed to connect to validator: $e',
            category: 'SYNTAX_ERROR',
          ),
        ],
      );
    }
  }

  /// Check if solver service is online
  Future<SolverStatus?> checkStatus() async {
    const String query = '''
      query {
        solverStatus {
          online
          version
          uptime
          requestCount
        }
      }
    ''';

    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        return null;
      }

      final data = result.data?['solverStatus'];
      if (data == null) {
        return null;
      }

      return SolverStatus.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
// Data Models
// ============================================================================

class SolverResult {
  final bool success;
  final String? errorMessage;
  final String? errorType;
  final Map<String, dynamic>? scalarProof;
  final Map<String, dynamic>? objectProof;
  final List<ConstraintResult> constraintResults;
  final List<ConstructionStep> constructionSteps;
  final double? computationTime;

  SolverResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.scalarProof,
    this.objectProof,
    List<ConstraintResult>? constraintResults,
    List<ConstructionStep>? constructionSteps,
    this.computationTime,
  })  : constraintResults = constraintResults ?? [],
        constructionSteps = constructionSteps ?? [];

  factory SolverResult.fromJson(Map<String, dynamic> json) {
    return SolverResult(
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      errorType: json['errorType'] as String?,
      scalarProof: json['scalarProof'] as Map<String, dynamic>?,
      objectProof: json['objectProof'] as Map<String, dynamic>?,
      constraintResults: (json['constraintResults'] as List<dynamic>?)
              ?.map((e) => ConstraintResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      constructionSteps: (json['constructionSteps'] as List<dynamic>?)
              ?.map((e) => ConstructionStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      computationTime: (json['computationTime'] as num?)?.toDouble(),
    );
  }
}

class ConstraintResult {
  final String id;
  final String type;
  final bool satisfied;
  final double? actualValue;
  final double? expectedValue;
  final double? tolerance;
  final String explanation;

  ConstraintResult({
    required this.id,
    required this.type,
    required this.satisfied,
    this.actualValue,
    this.expectedValue,
    this.tolerance,
    required this.explanation,
  });

  factory ConstraintResult.fromJson(Map<String, dynamic> json) {
    return ConstraintResult(
      id: json['id'] as String,
      type: json['type'] as String,
      satisfied: json['satisfied'] as bool,
      actualValue: (json['actualValue'] as num?)?.toDouble(),
      expectedValue: (json['expectedValue'] as num?)?.toDouble(),
      tolerance: (json['tolerance'] as num?)?.toDouble(),
      explanation: json['explanation'] as String,
    );
  }
}

class ConstructionStep {
  final int stepNumber;
  final String command;
  final String description;
  final String? theoremApplied;
  final String justification;

  ConstructionStep({
    required this.stepNumber,
    required this.command,
    required this.description,
    this.theoremApplied,
    required this.justification,
  });

  factory ConstructionStep.fromJson(Map<String, dynamic> json) {
    return ConstructionStep(
      stepNumber: json['stepNumber'] as int,
      command: json['command'] as String,
      description: json['description'] as String,
      theoremApplied: json['theoremApplied'] as String?,
      justification: json['justification'] as String,
    );
  }
}

class AIGenerateResult {
  final bool success;
  final String? errorMessage;
  final List<String> commands;
  final String explanation;
  final double confidence;
  final List<AIAlternative> alternatives;

  AIGenerateResult({
    required this.success,
    this.errorMessage,
    required this.commands,
    required this.explanation,
    required this.confidence,
    List<AIAlternative>? alternatives,
  }) : alternatives = alternatives ?? [];

  factory AIGenerateResult.fromJson(Map<String, dynamic> json) {
    return AIGenerateResult(
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      commands: (json['commands'] as List<dynamic>).cast<String>(),
      explanation: json['explanation'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => AIAlternative.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AIAlternative {
  final List<String> commands;
  final String explanation;
  final double confidence;

  AIAlternative({
    required this.commands,
    required this.explanation,
    required this.confidence,
  });

  factory AIAlternative.fromJson(Map<String, dynamic> json) {
    return AIAlternative(
      commands: (json['commands'] as List<dynamic>).cast<String>(),
      explanation: json['explanation'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class ValidationResult {
  final bool valid;
  final List<CommandError> errors;
  final List<CommandWarning> warnings;

  ValidationResult({
    required this.valid,
    List<CommandError>? errors,
    List<CommandWarning>? warnings,
  })  : errors = errors ?? [],
        warnings = warnings ?? [];

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] as bool,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => CommandError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => CommandWarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CommandError {
  final String command;
  final int line;
  final String message;
  final String category;

  CommandError({
    required this.command,
    required this.line,
    required this.message,
    required this.category,
  });

  factory CommandError.fromJson(Map<String, dynamic> json) {
    return CommandError(
      command: json['command'] as String,
      line: json['line'] as int,
      message: json['message'] as String,
      category: json['category'] as String,
    );
  }
}

class CommandWarning {
  final String command;
  final int line;
  final String message;

  CommandWarning({
    required this.command,
    required this.line,
    required this.message,
  });

  factory CommandWarning.fromJson(Map<String, dynamic> json) {
    return CommandWarning(
      command: json['command'] as String,
      line: json['line'] as int,
      message: json['message'] as String,
    );
  }
}

class SolverStatus {
  final bool online;
  final String version;
  final int uptime;
  final int requestCount;

  SolverStatus({
    required this.online,
    required this.version,
    required this.uptime,
    required this.requestCount,
  });

  factory SolverStatus.fromJson(Map<String, dynamic> json) {
    return SolverStatus(
      online: json['online'] as bool,
      version: json['version'] as String,
      uptime: json['uptime'] as int,
      requestCount: json['requestCount'] as int,
    );
  }
}
