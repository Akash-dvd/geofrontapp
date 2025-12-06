import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geodraw/geodraw.dart';
import 'package:geodraw/ui/parameter_input_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../config/build_flags.dart';
import '../config/env_config.dart';
import '../models/problem.dart';
import '../models/solver_command_catalog.dart';
import '../services/directus_file_service.dart';
import '../services/supabase_file_service.dart';
import '../utils/canvas_capture.dart';
import '../services/app_services.dart';
import '../services/solver_service.dart';
import '../widgets/solver_command_editor.dart';
import '../widgets/solution_wizard.dart';

/// Screen for creating and editing problems with a GeoDraw-first workflow.
class ProblemFormScreen extends StatefulWidget {
  const ProblemFormScreen({super.key, this.problem});

  final Problem? problem;

  bool get isEditing => problem != null;

  @override
  State<ProblemFormScreen> createState() => _ProblemFormScreenState();
}

/// Presents the shared sign-in dialog used across GeoApp experiences.
Future<bool> showGeoAppSignInDialog(BuildContext context) async {
  final didSignIn = await showDialog<bool>(
    context: context,
    builder: (context) => const _SignInDialog(),
  );
  return didSignIn ?? false;
}

class _ProblemFormScreenState extends State<ProblemFormScreen> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;
  late UnifiedCLIExecutor _commandExecutor;
  late AIService _aiService;
  late AIAdapter _aiAdapter;
  late SolverService _solverService;
  final Set<String> _selectedIds = {};

  ProblemMetadata? _metadata;
  SolverResult? _lastSolverResult;
  bool _isAuthenticated = false;
  String? _userEmail;
  StreamSubscription<String?>? _authSubscription;
  bool _isSavingThumbnail = false;
  bool _isSolving = false;
  String? _thumbnailPendingDeletion;

  String? _canonicalizeJsonString(String? raw) {
    if (raw == null) {
      return null;
    }

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return trimmed;
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: error ? theme.colorScheme.errorContainer : null,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _handleDeleteObject(String id) async {
    final node = _dagManager.getNode(id);
    if (node == null) {
      return;
    }

    final hasChildren = node.childIds.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(hasChildren ? 'Delete object and dependents?' : 'Delete object?'),
        content: Text(
          hasChildren
              ? 'Removing this object will also delete ${node.childIds.length} dependent items. Continue?'
              : 'Remove the selected object from the construction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(hasChildren ? 'Delete all' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        _dagManager.deleteObject(id, cascade: hasChildren);
        _selectedIds.remove(id);
      });
      _showSnack('Object deleted.');
    } catch (error) {
      _showSnack('Failed to delete object: $error', error: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeGeoDraw();
    _initializeMetadata();
    _initializeAuthState();
  }

  void _initializeGeoDraw() {
    if (widget.problem?.geometryData != null) {
      try {
        final decoder = GeoDrawDecoder();
        _dagManager = decoder.decodeFromStorage(
          widget.problem!.geometryData!,
        );
      } catch (error) {
        debugPrint('Failed to decode geometry data: $error');
        _dagManager = DAGManager();
      }
    } else {
      _dagManager = DAGManager();
    }

    _toolManager = ToolManager(
      dagManager: _dagManager,
      onObjectCreated: (_, __) => setState(() {}),
      onObjectSelected: (objectId) {
        // Update selection for both select tool and staged selection tools
        setState(() {
          if (objectId.isEmpty) {
            // Empty string means clear selection
            _selectedIds.clear();
          } else {
            // Add to selection set for visual feedback
            _selectedIds.add(objectId);
          }
        });
      },
      onToolStateChanged: (_) => setState(() {}),
      onParameterRequest: (title, parameters) async {
        return await showParameterInputDialog(context, title, parameters);
      },
    );

    _commandExecutor = UnifiedCLIExecutor(dagManager: _dagManager);

    final aiEndpoint = EnvConfig.edgeLlmEndpoint;
    _aiService = AIService(
      config: AIServiceConfig.production(aiEndpoint),
    );
    _aiAdapter = AIAdapter(dagManager: _dagManager);

    _solverService = SolverService(
      endpoint: BuildFlags.useDirectus ? null : EnvConfig.edgeSolverEndpoint,
      directLanAccess: BuildFlags.useDirectus,
    );
  }

  void _initializeMetadata() {
    if (widget.problem != null) {
      final existing = widget.problem!;
      _metadata = ProblemMetadata(
        title: existing.title,
        description: existing.description,
        difficulty: existing.difficulty,
        category: existing.category,
        status: existing.status,
        solution: existing.solution,
        scalarConstraints: _canonicalizeJsonString(
          existing.scalarConstraints,
        ),
        objectConstraints: _canonicalizeJsonString(
          existing.objectConstraints,
        ),
        scalarProof: existing.scalarProof,
        objectProof: existing.objectProof,
        proofGoal: null,
        autoRunSolverOnSave: false,
      );
    }
  }

  void _initializeAuthState() {
    try {
      final authProvider = AppServices.auth;
      _isAuthenticated = authProvider.isAuthenticated;
      _userEmail =
          authProvider.currentUserEmail ?? authProvider.currentUserDisplayName;

      _authSubscription = authProvider.authStateChanges.listen((_) {
        if (!mounted) return;
        setState(() {
          _isAuthenticated = authProvider.isAuthenticated;
          _userEmail = authProvider.currentUserEmail ??
              authProvider.currentUserDisplayName;
        });
      });
    } catch (error) {
      debugPrint('Auth services unavailable: $error');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Geometry Problem' : 'New Geometry Problem',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _AuthStatusChip(
            isAuthenticated: _isAuthenticated,
            userLabel: _userEmail,
            onSignInRequest: _handleSignIn,
            onSignOut:
                widget.isEditing ? null : () => unawaited(_handleSignOut()),
          ),
          IconButton(
            tooltip: _metadata == null
                ? 'Add problem details'
                : 'Edit problem details',
            icon: const Icon(Icons.description_outlined),
            onPressed: _openMetadataSheet,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton(
              onPressed: _handleSave,
              child: Text(widget.isEditing ? 'Update' : 'Save'),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ProblemBloc, ProblemState>(
        listener: (context, state) {
          if (state is ProblemOperationSuccess) {
            unawaited(_cleanupReplacedThumbnailIfNeeded());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          }

          if (state is ProblemError) {
            _thumbnailPendingDeletion = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isBusy = state is ProblemOperationInProgress ||
              _isSavingThumbnail ||
              _isSolving;

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(child: _buildWorkspace()),
                  _buildBottomBar(context),
                ],
              ),
              if (isBusy)
                ColoredBox(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final solutionSteps =
            _lastSolverResult?.solutionSteps ?? const <SolverSolutionStep>[];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GeoDrawSidePanel(
              dagManager: _dagManager,
              toolManager: _toolManager,
              selectedIds: _selectedIds,
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedIds
                    ..clear()
                    ..addAll(selection);
                });
              },
              onToolSelected: (tool) {
                setState(() {
                  _toolManager.selectTool(tool);
                });
              },
              onDeleteObject: (id) {
                _handleDeleteObject(id);
              },
              cliExecutor: _commandExecutor,
              aiService: _aiService,
              aiAdapter: _aiAdapter,
              onPromptConstructionComplete: () => setState(() {}),
            ),
            Expanded(
              child: _CanvasAndSolutions(
                dagManager: _dagManager,
                toolManager: _toolManager,
                selectedIds: _selectedIds,
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedIds
                      ..clear()
                      ..addAll(selection);
                  });
                },
                solutionSteps: solutionSteps,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final allNodes = _dagManager.topologicalSort();
    final totalObjects = allNodes.length;
    final infinityNodes = allNodes.where((node) => node.object is GeoInf).toList();
    final infinityCount = infinityNodes.length;
    final infinityObjects = infinityNodes
        .map((node) => node.object as GeoInf)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$totalObjects construction nodes',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: _openMetadataSheet,
            icon: const Icon(Icons.manage_history_outlined),
            label: Text(_metadata == null ? 'Add details' : 'Review details'),
          ),
          // Display GeoInf count and details (after "Add details")
          if (infinityCount > 0) ...[
            const SizedBox(width: 24),
            // Flame icon for infinity
            const Icon(
              Icons.local_fire_department,
              size: 18,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(width: 8),
            Text(
              '$infinityCount point${infinityCount > 1 ? 's' : ''} at infinity',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
            // Show labels of infinity points
            if (infinityObjects.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '(${infinityObjects.map((obj) => obj.label.isNotEmpty ? obj.label : obj.id).join(', ')})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _isSolving ? null : _handleSolverPush,
            icon: _isSolving
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science_outlined),
            label: const Text('Run solver'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.cloud_upload_outlined),
            label:
                Text(widget.isEditing ? 'Update Problem' : 'Publish Problem'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!await _ensureAuthenticated()) {
      return;
    }

    var metadata = await _requireMetadata();
    if (!mounted) return;
    if (metadata == null) return;

    if (metadata.autoRunSolverOnSave && !_isSolving) {
      final solved = await _runSolver(triggerSource: 'SAVE');
      if (!mounted) return;
      if (!solved) {
        return;
      }
      metadata = _metadata;
      if (metadata == null) {
        return;
      }
    }

    final encoder = GeoDrawEncoder();
    final geometryData = encoder.encodeForStorage(
      _dagManager,
      base64: false,
      pretty: false,
    );

    String? thumbnailId;
    if (_hasVisibleObjects()) {
      thumbnailId = await _captureThumbnail();
      if (!mounted) return;
      if (thumbnailId == null) {
        _showThumbnailWarning();
      }
    }

    final bloc = context.read<ProblemBloc>();

    if (widget.isEditing) {
      _planThumbnailCleanup(newThumbnailId: thumbnailId);
      bloc.add(
        UpdateProblem(
          id: widget.problem!.id,
          title: metadata.title,
          description: metadata.description,
          difficulty: metadata.difficulty,
          category: metadata.category,
          status: metadata.status,
          geometryData: geometryData,
          solution: metadata.solution,
          thumbnailId: thumbnailId ?? widget.problem!.thumbnailId,
          scalarConstraints: metadata.scalarConstraints,
          objectConstraints: metadata.objectConstraints,
          scalarProof: metadata.scalarProof,
          objectProof: metadata.objectProof,
        ),
      );
    } else {
      bloc.add(
        CreateProblem(
          title: metadata.title,
          description: metadata.description,
          difficulty: metadata.difficulty,
          category: metadata.category,
          status: metadata.status,
          geometryData: geometryData,
          solution: metadata.solution,
          thumbnailId: thumbnailId,
          scalarConstraints: metadata.scalarConstraints,
          objectConstraints: metadata.objectConstraints,
          scalarProof: metadata.scalarProof,
          objectProof: metadata.objectProof,
        ),
      );
      _thumbnailPendingDeletion = null;
    }
  }

  Future<void> _handleSolverPush() async {
    if (_isSolving) return;
    await _runSolver();
  }

  Future<bool> _runSolver({String triggerSource = 'manual'}) async {
    var metadata = _metadata;
    if (metadata == null) {
      metadata = await _requireMetadata();
      if (!mounted) return false;
      if (metadata == null) {
        return false;
      }
    }

    var proofGoal = metadata.proofGoal?.trim();
    if (proofGoal == null || proofGoal.isEmpty) {
      proofGoal = metadata.title.trim();
    }

    if (proofGoal.isEmpty) {
      _showSnack(
        'Add a proof goal before running the solver.',
        error: true,
      );
      return false;
    }

    Map<String, dynamic>? scalarConstraints;
    if (metadata.scalarConstraints != null &&
        metadata.scalarConstraints!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata.scalarConstraints!);
        if (decoded is Map<String, dynamic>) {
          scalarConstraints = decoded;
        } else if (decoded is Map) {
          scalarConstraints = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException(
            'Scalar constraints must be a JSON object',
          );
        }
      } catch (error) {
        _showSnack(
          'Scalar constraints JSON is invalid: $error',
          error: true,
        );
        return false;
      }
    }

    Map<String, dynamic>? objectConstraints;
    if (metadata.objectConstraints != null &&
        metadata.objectConstraints!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata.objectConstraints!);
        if (decoded is Map<String, dynamic>) {
          objectConstraints = decoded;
        } else if (decoded is Map) {
          objectConstraints = Map<String, dynamic>.from(decoded);
        } else {
          throw const FormatException(
            'Object constraints must be a JSON object',
          );
        }
      } catch (error) {
        _showSnack(
          'Object constraints JSON is invalid: $error',
          error: true,
        );
        return false;
      }
    }

    final constructionData = GeoDrawEncoder().encode(_dagManager);

    setState(() {
      _isSolving = true;
    });

    final result = await _solverService.solveConstraints(
      constructionData: constructionData,
      scalarConstraints: scalarConstraints,
      objectConstraints: objectConstraints,
      proofGoal: proofGoal,
    );

    debugPrint('Solver response success=${result.success} '
        'steps=${result.solutionSteps.length} '
        'objectProof=${result.objectProof}');

    if (!mounted) {
      return result.success;
    }

    setState(() {
      _isSolving = false;
      _lastSolverResult = result;
    });

    if (!result.success) {
      final message = result.errorMessage ??
          'Solver failed to complete. Check constraints and try again.';
      _showSnack(message, error: true);
      return false;
    }

    final scalarProofSet =
        SolverCommandSet.fromSolverPayload(result.scalarProof);
    final objectProofSet =
        SolverCommandSet.fromSolverPayload(result.objectProof);
    final scalarProofJson = scalarProofSet.isNotEmpty
        ? scalarProofSet.toJsonString(pretty: true)
        : metadata.scalarProof;
    final objectProofJson = objectProofSet.isNotEmpty
        ? objectProofSet.toJsonString(pretty: true)
        : metadata.objectProof;

    final updatedMetadata = metadata.copyWith(
      scalarConstraints: _canonicalizeJsonString(metadata.scalarConstraints),
      objectConstraints: _canonicalizeJsonString(metadata.objectConstraints),
      scalarProof: scalarProofJson,
      objectProof: objectProofJson,
      proofGoal: proofGoal,
    );

    setState(() {
      _metadata = updatedMetadata;
    });

    final sourceDescription =
        triggerSource == 'save' ? 'before saving' : 'via solver action';
    _showSnack('Solver completed $sourceDescription.');

    return true;
  }

  Future<bool> _ensureAuthenticated() async {
    try {
      final auth = AppServices.auth;
      if (auth.isAuthenticated) {
        return true;
      }
    } catch (error) {
      debugPrint('Auth services unavailable: $error');
    }

    final didSignIn = await showGeoAppSignInDialog(context);

    if (didSignIn) {
      try {
        await AppServices.refreshDataProvider();
      } catch (error) {
        debugPrint('Failed to refresh data provider: $error');
      }
    }

    return didSignIn;
  }

  Future<ProblemMetadata?> _requireMetadata() async {
    if (_metadata != null) {
      return _metadata;
    }

    return await _openMetadataSheet();
  }

  Future<ProblemMetadata?> _openMetadataSheet() async {
    final metadata = await showModalBottomSheet<ProblemMetadata>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: ProblemMetadataSheet(
            initial: _metadata,
            isEditing: widget.isEditing,
            dagManager: _dagManager,
          ),
        );
      },
    );

    if (metadata != null) {
      setState(() => _metadata = metadata);
    }

    return metadata;
  }

  Future<void> _handleSignIn() async {
    final success = await _ensureAuthenticated();
    if (!mounted) return;
    if (success) {
      final auth = AppServices.auth;
      final label = auth.currentUserEmail ?? auth.currentUserDisplayName;
      final message = label != null && label.isNotEmpty
          ? 'Signed in as $label'
          : 'Signed in';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AppServices.auth.signOut();
      await AppServices.refreshDataProvider();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $error')),
      );
    }
  }

  Future<String?> _captureThumbnail() async {
    try {
      setState(() => _isSavingThumbnail = true);

      final imageBytes = await CanvasCapture.captureAsPng(
        dagManager: _dagManager,
        width: 800,
        height: 600,
        backgroundColor: Colors.white,
        showGrid: false,
      );

      if (imageBytes == null) {
        return null;
      }

      if (BuildFlags.useDirectus) {
        // Local mode: Upload to Directus
        final fileService = DirectusFileService(
          baseUrl: EnvConfig.directusUrl,
        );
        return await fileService.uploadImage(
          imageBytes: imageBytes,
          filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
          title: 'Problem Thumbnail',
        );
      } else {
        final userId = AppServices.auth.currentUserId;
        if (userId == null || userId.isEmpty) {
          debugPrint('WARNING: No Supabase user ID available for upload');
          return null;
        }

        final problemId = widget.problem?.id ??
            'draft_${DateTime.now().millisecondsSinceEpoch}';

        final supabaseService = SupabaseFileService(
          supabaseUrl: EnvConfig.supabaseUrl,
          supabaseAnonKey: EnvConfig.supabaseAnonKey,
        );

        return await supabaseService.uploadThumbnail(
          bytes: imageBytes,
          problemId: problemId,
          userId: userId,
          filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Error capturing thumbnail: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      if (mounted) {
        setState(() => _isSavingThumbnail = false);
      }
    }
  }

  bool _hasVisibleObjects() {
    final nodes = _dagManager.topologicalSort();
    return nodes.any((node) => node.object.visible);
  }

  void _showThumbnailWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Unable to capture thumbnail. Continue anyway.')),
    );
  }

  void _planThumbnailCleanup({String? newThumbnailId}) {
    if (!widget.isEditing) {
      _thumbnailPendingDeletion = null;
      return;
    }
    if (BuildFlags.useDirectus) {
      _thumbnailPendingDeletion = null;
      return;
    }
    final previousThumbnail = widget.problem?.thumbnailId;
    if (previousThumbnail == null || previousThumbnail.isEmpty) {
      _thumbnailPendingDeletion = null;
      return;
    }
    if (newThumbnailId == null || newThumbnailId.isEmpty) {
      _thumbnailPendingDeletion = null;
      return;
    }
    if (newThumbnailId == previousThumbnail) {
      _thumbnailPendingDeletion = null;
      return;
    }
    _thumbnailPendingDeletion = previousThumbnail;
  }

  Future<void> _cleanupReplacedThumbnailIfNeeded() async {
    final storagePath = _thumbnailPendingDeletion;
    _thumbnailPendingDeletion = null;
    if (storagePath == null || storagePath.isEmpty) {
      return;
    }
    if (BuildFlags.useDirectus) {
      return;
    }

    final supabaseUrl = EnvConfig.supabaseUrl;
    final supabaseAnonKey = EnvConfig.supabaseAnonKey;
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint(
        'Skipping Supabase thumbnail cleanup: missing configuration values.',
      );
      return;
    }

    final supabaseService = SupabaseFileService(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );

    final didDelete = await supabaseService.deleteFile(storagePath);
    if (!didDelete) {
      debugPrint('Failed to delete Supabase thumbnail at $storagePath');
    }
  }
}

class ProblemMetadata {
  const ProblemMetadata({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.status = ProblemStatus.draft,
    this.solution,
    this.scalarConstraints,
    this.objectConstraints,
    this.scalarProof,
    this.objectProof,
    this.proofGoal,
    this.autoRunSolverOnSave = false,
  });

  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final ProblemStatus status;
  final String? solution;
  final String? scalarConstraints;
  final String? objectConstraints;
  final String? scalarProof;
  final String? objectProof;
  final String? proofGoal;
  final bool autoRunSolverOnSave;

  ProblemMetadata copyWith({
    String? title,
    String? description,
    ProblemDifficulty? difficulty,
    ProblemCategory? category,
  ProblemStatus? status,
    String? solution,
    String? scalarConstraints,
    String? objectConstraints,
    String? scalarProof,
    String? objectProof,
    String? proofGoal,
    bool? autoRunSolverOnSave,
  }) {
    return ProblemMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
  status: status ?? this.status,
      solution: solution ?? this.solution,
      scalarConstraints: scalarConstraints ?? this.scalarConstraints,
      objectConstraints: objectConstraints ?? this.objectConstraints,
      scalarProof: scalarProof ?? this.scalarProof,
      objectProof: objectProof ?? this.objectProof,
      proofGoal: proofGoal ?? this.proofGoal,
      autoRunSolverOnSave: autoRunSolverOnSave ?? this.autoRunSolverOnSave,
    );
  }
}

class _CanvasAndSolutions extends StatefulWidget {
  const _CanvasAndSolutions({
    required this.dagManager,
    required this.toolManager,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.solutionSteps,
  });

  final DAGManager dagManager;
  final ToolManager toolManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final List<SolverSolutionStep> solutionSteps;

  @override
  State<_CanvasAndSolutions> createState() => _CanvasAndSolutionsState();
}

class _CanvasAndSolutionsState extends State<_CanvasAndSolutions> {
  bool _showWizard = false;

  @override
  void didUpdateWidget(_CanvasAndSolutions oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-show wizard when solutions arrive
    if (widget.solutionSteps.isNotEmpty && oldWidget.solutionSteps.isEmpty) {
      setState(() {
        _showWizard = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSolutions = widget.solutionSteps.isNotEmpty;

    // Show wizard mode if solutions exist and wizard is enabled
    if (hasSolutions && _showWizard) {
      return SolutionWizard(
        problemDagManager: widget.dagManager,
        problemToolManager: widget.toolManager,
        selectedIds: widget.selectedIds,
        onSelectionChanged: widget.onSelectionChanged,
        solutionSteps: widget.solutionSteps,
        onClose: () {
          setState(() {
            _showWizard = false;
          });
        },
      );
    }

    // Regular canvas view
    final canvas = Container(
      color: theme.colorScheme.surface,
      child: GeoDrawCanvas(
        dagManager: widget.dagManager,
        toolManager: widget.toolManager,
        selectedIds: widget.selectedIds,
        onSelectionChanged: widget.onSelectionChanged,
        showGrid: true,
      ),
    );

    if (!hasSolutions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: canvas)],
      );
    }

    // Show canvas with option to open wizard
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: canvas)],
        ),
        
        // Floating button to open wizard
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _showWizard = true;
              });
            },
            icon: const Icon(Icons.auto_stories),
            label: const Text('View Solution Steps'),
            tooltip: 'Open step-by-step solution wizard',
          ),
        ),
      ],
    );
  }
}

class _SolutionStepsList extends StatefulWidget {
  const _SolutionStepsList({required this.steps});

  final List<SolverSolutionStep> steps;

  @override
  State<_SolutionStepsList> createState() => _SolutionStepsListState();
}

class _SolutionStepsListState extends State<_SolutionStepsList> {
  late List<_SolutionStepPresentation> _presentations;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _presentations = _generatePresentations();
  }

  @override
  void didUpdateWidget(covariant _SolutionStepsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.steps, oldWidget.steps)) {
      setState(() {
        _presentations = _generatePresentations();
      });
    }
  }

  List<_SolutionStepPresentation> _generatePresentations() {
    final decoder = GeoDrawDecoder();
    return widget.steps.map((step) {
      final geometry = step.geometryAsMap();
      if (geometry == null) {
        debugPrint('Solver step ${step.description} missing geometry payload');
        return _SolutionStepPresentation(
          step: step,
          dagManager: DAGManager(),
          hasGeometry: false,
        );
      }

      try {
        final dag = decoder.decode(Map<String, dynamic>.from(geometry));
        return _SolutionStepPresentation(
          step: step,
          dagManager: dag,
          hasGeometry: true,
        );
      } catch (error) {
        debugPrint('Failed to decode solver solution: $error');
        debugPrint('Raw geometry payload: $geometry');
        return _SolutionStepPresentation(
          step: step,
          dagManager: DAGManager(),
          hasGeometry: false,
        );
      }
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_presentations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        physics: const ClampingScrollPhysics(),
        itemCount: _presentations.length,
        itemBuilder: (context, index) {
          final presentation = _presentations[index];
          return _SolutionStepCard(
            key: ValueKey('solution-step-$index'),
            index: index,
            step: presentation.step,
            dagManager: presentation.dagManager,
            hasGeometry: presentation.hasGeometry,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _SolutionStepPresentation {
  const _SolutionStepPresentation({
    required this.step,
    required this.dagManager,
    required this.hasGeometry,
  });

  final SolverSolutionStep step;
  final DAGManager dagManager;
  final bool hasGeometry;
}

class _SolutionStepCard extends StatelessWidget {
  const _SolutionStepCard({
    super.key,
    required this.index,
    required this.step,
    required this.dagManager,
    required this.hasGeometry,
  });

  final int index;
  final SolverSolutionStep step;
  final DAGManager dagManager;
  final bool hasGeometry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolManager = ToolManager(dagManager: dagManager);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${index + 1}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: theme.textTheme.bodyMedium,
            ),
            if (step.references.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: step.references
                      .map(
                        (ref) => Chip(
                          label: Text(ref),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasGeometry
                    ? IgnorePointer(
                        child: GeoDrawCanvas(
                          dagManager: dagManager,
                          toolManager: toolManager,
                          selectedIds: const {},
                          showGrid: true,
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Text(
                          'No geometry returned for this step yet.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthStatusChip extends StatelessWidget {
  const _AuthStatusChip({
    required this.isAuthenticated,
    required this.onSignInRequest,
    this.onSignOut,
    this.userLabel,
  });

  final bool isAuthenticated;
  final VoidCallback onSignInRequest;
  final VoidCallback? onSignOut;
  final String? userLabel;

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      final labelText = userLabel != null && userLabel!.isNotEmpty
          ? 'Signed in as ${userLabel!}'
          : 'Signed in';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: labelText,
          child: ActionChip(
            avatar: const Icon(Icons.verified_user, size: 18),
            label: Text(
              labelText,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: onSignOut,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OutlinedButton.icon(
        onPressed: onSignInRequest,
        icon: const Icon(Icons.login, size: 18),
        label: const Text('Sign in to save'),
      ),
    );
  }
}

class ProblemMetadataSheet extends StatefulWidget {
  const ProblemMetadataSheet({
    super.key,
    this.initial,
    required this.isEditing,
    required this.dagManager,
  });

  final ProblemMetadata? initial;
  final bool isEditing;
  final DAGManager dagManager;

  @override
  State<ProblemMetadataSheet> createState() => _ProblemMetadataSheetState();
}

class _ProblemMetadataSheetState extends State<ProblemMetadataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _solutionController;
  late final TextEditingController _proofGoalController;
  late ProblemDifficulty _difficulty;
  late ProblemCategory _category;
  late ProblemStatus _status;
  late bool _autoRunSolver;
  late SolverCommandSet _scalarConstraintSet;
  late SolverCommandSet _objectConstraintSet;
  late SolverCommandSet _scalarProofSet;
  late SolverCommandSet _objectProofSet;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
    _solutionController =
        TextEditingController(text: widget.initial?.solution ?? '');
    _proofGoalController = TextEditingController(
      text: widget.initial?.proofGoal ?? '',
    );
    _scalarConstraintSet = SolverCommandSet.fromJsonString(
      widget.initial?.scalarConstraints,
    );
    _objectConstraintSet = SolverCommandSet.fromJsonString(
      widget.initial?.objectConstraints,
    );
    _scalarProofSet = SolverCommandSet.fromJsonString(
      widget.initial?.scalarProof,
    );
    _objectProofSet = SolverCommandSet.fromJsonString(
      widget.initial?.objectProof,
    );
    _difficulty = widget.initial?.difficulty ?? ProblemDifficulty.beginner;
    _category = widget.initial?.category ?? ProblemCategory.geometry;
  _status = widget.initial?.status ?? ProblemStatus.draft;
    _autoRunSolver = widget.initial?.autoRunSolverOnSave ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _solutionController.dispose();
    _proofGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isEditing
                    ? 'Update problem details'
                    : 'Describe your problem',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Title', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. Construct an equilateral triangle ABC',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }
                            if (value.trim().length < 4) {
                              return 'Title must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('What should someone know before trying this?',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText:
                                'Provide context, goals, and any givens that are important.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            if (value.trim().length < 12) {
                              return 'Please add a little more detail.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text('Visibility', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SegmentedButton<ProblemStatus>(
                          segments: const [
                            ButtonSegment(
                              value: ProblemStatus.draft,
                              label: Text('Draft'),
                            ),
                            ButtonSegment(
                              value: ProblemStatus.published,
                              label: Text('Published'),
                            ),
                          ],
                          selected: {_status},
                          onSelectionChanged: (selection) {
                            setState(() => _status = selection.first);
                          },
                        ),
                        const SizedBox(height: 24),
                        Text('Difficulty', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: ProblemDifficulty.values.map((difficulty) {
                            final isSelected = _difficulty == difficulty;
                            return ChoiceChip(
                              label: Text(difficulty.displayName),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _difficulty = difficulty);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Focus Area', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: ProblemCategory.values.map((category) {
                            final isSelected = _category == category;
                            return FilterChip(
                              label: Text(category.displayName),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _category = category);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Solution (optional)',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _solutionController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText:
                                'Add hints or a full solution if you already have one.',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Divider(color: theme.dividerColor.withOpacity(0.4)),
                        const SizedBox(height: 24),
                        Text('Solver configuration',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _proofGoalController,
                          decoration: const InputDecoration(
                            labelText: 'Proof goal',
                            hintText: 'e.g. Triangle ABC is equilateral',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SolverCommandListEditor(
                          title: 'Scalar constraints',
                          emptyLabel:
                              'Define scalar relationships your solver should satisfy.',
                          catalog: SolverCommandCatalog.scalarConstraints,
                          value: _scalarConstraintSet,
                          dagManager: widget.dagManager,
                          onChanged: (set) {
                            setState(() => _scalarConstraintSet = set);
                          },
                        ),
                        const SizedBox(height: 16),
                        SolverCommandListEditor(
                          title: 'Object constraints',
                          emptyLabel:
                              'Add geometric relationships between constructed objects.',
                          catalog: SolverCommandCatalog.objectConstraints,
                          value: _objectConstraintSet,
                          dagManager: widget.dagManager,
                          onChanged: (set) {
                            setState(() => _objectConstraintSet = set);
                          },
                        ),
                        const SizedBox(height: 16),
                        SolverCommandListEditor(
                          title: 'Scalar proof goals',
                          emptyLabel:
                              'No scalar proof commands yet. Add one to guide the solver.',
                          catalog: SolverCommandCatalog.scalarProofGoals,
                          value: _scalarProofSet,
                          dagManager: widget.dagManager,
                          onChanged: (set) {
                            setState(() => _scalarProofSet = set);
                          },
                        ),
                        const SizedBox(height: 16),
                        SolverCommandListEditor(
                          title: 'Object proof goals',
                          emptyLabel:
                              'No object proof commands yet. Add one to guide the solver.',
                          catalog: SolverCommandCatalog.objectProofGoals,
                          value: _objectProofSet,
                          dagManager: widget.dagManager,
                          onChanged: (set) {
                            setState(() => _objectProofSet = set);
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _autoRunSolver,
                          onChanged: (value) {
                            setState(() => _autoRunSolver = value);
                          },
                          title: const Text('Run solver automatically on save'),
                          subtitle: const Text(
                            'If enabled, the solver worker runs before saving to sync proofs.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(widget.isEditing ? 'Update' : 'Save details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _trimToNull(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scalarConstraintsJson =
        _scalarConstraintSet.toJsonString(pretty: true);
    final objectConstraintsJson =
        _objectConstraintSet.toJsonString(pretty: true);
    final scalarProofJson = _scalarProofSet.toJsonString(pretty: true);
    final objectProofJson = _objectProofSet.toJsonString(pretty: true);

    final metadata = ProblemMetadata(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _difficulty,
      category: _category,
      status: _status,
      solution: _solutionController.text.trim().isEmpty
          ? null
          : _solutionController.text.trim(),
      scalarConstraints: scalarConstraintsJson,
      objectConstraints: objectConstraintsJson,
      scalarProof: scalarProofJson,
      objectProof: objectProofJson,
      proofGoal: _trimToNull(_proofGoalController.text),
      autoRunSolverOnSave: _autoRunSolver,
    );

    Navigator.of(context).pop(metadata);
  }
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog();

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

enum _AuthMode { signIn, register }

enum _AuthAction { none, email, google, github, reset }

class _SignInDialogState extends State<_SignInDialog> {
  static const String _rememberEmailKey = 'geoapp_last_email';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  _AuthAction _activeAction = _AuthAction.none;
  bool _rememberMe = true;
  String? _errorMessage;

  bool get _isBusy => _activeAction != _AuthAction.none;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_rememberEmailKey);
      if (savedEmail != null && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (error) {
      debugPrint('Unable to load saved email: $error');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Authenticate to continue'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in to sync problems across devices. Sessions persist automatically; "Remember me" only stores your email for quick access.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                      value: _AuthMode.signIn, label: Text('Sign in')),
                  ButtonSegment(
                      value: _AuthMode.register, label: Text('Register')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _mode = selection.first;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
                enabled: !_isBusy,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Email is required';
                  }
                  if (!trimmed.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: _mode == _AuthMode.signIn
                      ? 'Password'
                      : 'Create password',
                  hintText: '••••••••',
                ),
                enabled: !_isBusy,
                obscureText: true,
                validator: (value) {
                  final input = value ?? '';
                  if (input.isEmpty) {
                    return 'Password is required';
                  }
                  if (input.length < 6) {
                    return 'Must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _rememberMe,
                dense: true,
                onChanged: _isBusy
                    ? null
                    : (value) {
                        setState(() => _rememberMe = value ?? true);
                      },
                title: const Text('Remember my email on this device'),
              ),
              if (_mode == _AuthMode.signIn)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed:
                        _isBusy ? null : () => _handlePasswordReset(context),
                    child: const Text('Forgot password?'),
                  ),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBusy ? null : () => _handleEmailSubmit(context),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: _buildButtonChild(
                    label: _mode == _AuthMode.signIn
                        ? 'Sign in with email'
                        : 'Create account',
                    action: _AuthAction.email,
                    icon: Icons.mail_outline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _isBusy ? null : () => _handleGoogleSignIn(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _buildButtonChild(
                    label: 'Continue with Google',
                    action: _AuthAction.google,
                    icon: Icons.g_translate,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _isBusy ? null : () => _handleGithubSignIn(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _buildButtonChild(
                    label: 'Continue with GitHub',
                    action: _AuthAction.github,
                    icon: Icons.code,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildButtonChild({
    required String label,
    required _AuthAction action,
    IconData? icon,
  }) {
    final isLoading = _activeAction == action;
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _handleEmailSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _activeAction = _AuthAction.email;
      _errorMessage = null;
    });

    try {
      final auth = AppServices.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_mode == _AuthMode.signIn) {
        await auth.signInWithEmailAndPassword(email, password);
      } else {
        await auth.createUserWithEmailAndPassword(email, password);
      }

      await _persistRememberPreference();
      await AppServices.refreshDataProvider();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _activeAction = _AuthAction.none);
      }
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _activeAction = _AuthAction.google;
      _errorMessage = null;
    });

    try {
      await AppServices.auth.signInWithGoogle();
      await AppServices.refreshDataProvider();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _activeAction = _AuthAction.none);
      }
    }
  }

  Future<void> _handleGithubSignIn(BuildContext context) async {
    setState(() {
      _activeAction = _AuthAction.github;
      _errorMessage = null;
    });

    try {
      await AppServices.auth.signInWithGithub();
      await AppServices.refreshDataProvider();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _activeAction = _AuthAction.none);
      }
    }
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() =>
          _errorMessage = 'Enter your email to receive reset instructions.');
      return;
    }

    setState(() {
      _activeAction = _AuthAction.reset;
      _errorMessage = null;
    });

    try {
      await AppServices.auth.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _activeAction = _AuthAction.none);
      }
    }
  }

  Future<void> _persistRememberPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_rememberEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_rememberEmailKey);
      }
    } catch (error) {
      debugPrint('Unable to persist remember-me preference: $error');
    }
  }
}
