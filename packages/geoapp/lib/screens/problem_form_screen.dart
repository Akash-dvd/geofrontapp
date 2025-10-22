import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geodraw/geodraw.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../config/build_flags.dart';
import '../config/env_config.dart';
import '../models/problem.dart';
import '../services/directus_file_service.dart';
import '../services/supabase_file_service.dart';
import '../utils/canvas_capture.dart';
import '../services/app_services.dart';

/// Screen for creating and editing problems with a GeoDraw-first workflow.
class ProblemFormScreen extends StatefulWidget {
  const ProblemFormScreen({super.key, this.problem});

  final Problem? problem;

  bool get isEditing => problem != null;

  @override
  State<ProblemFormScreen> createState() => _ProblemFormScreenState();
}

class _ProblemFormScreenState extends State<ProblemFormScreen> {
  late DAGManager _dagManager;
  late ToolManager _toolManager;
  late UnifiedCLIExecutor _commandExecutor;
  late AIService _aiService;
  final Set<String> _selectedIds = {};

  ProblemMetadata? _metadata;
  bool _isAuthenticated = false;
  String? _userEmail;
  StreamSubscription<String?>? _authSubscription;
  bool _isSavingThumbnail = false;
  String? _thumbnailPendingDeletion;
  double _paletteWidth = 330;
  static const double _minPaletteWidth = 220;
  static const double _paletteHandleWidth = 12;
  static const double _minCanvasWidth = 360;

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
      onToolStateChanged: (_) => setState(() {}),
    );

    _commandExecutor = UnifiedCLIExecutor(dagManager: _dagManager);

    final aiEndpoint = EnvConfig.edgeLlmEndpoint;
    _aiService = AIService(
      config: AIServiceConfig.production(aiEndpoint),
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
        solution: existing.solution,
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
          final isBusy =
              state is ProblemOperationInProgress || _isSavingThumbnail;

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
        final showSidePanel = constraints.maxWidth > 960;
        final sidePanelWidth = showSidePanel ? 320.0 : 280.0;

        final maxPaletteSpace = constraints.maxWidth -
            sidePanelWidth -
            _paletteHandleWidth -
            _minCanvasWidth;

        final maxAllowedPaletteWidth = math.max(
          _minPaletteWidth,
          math.min(
            constraints.maxWidth * 0.65,
            maxPaletteSpace,
          ),
        );

        final minAllowedPaletteWidth = math.min(
          _minPaletteWidth,
          maxAllowedPaletteWidth,
        );

        final clampedPaletteWidth = _paletteWidth.clamp(
          minAllowedPaletteWidth,
          maxAllowedPaletteWidth,
        );

        if (clampedPaletteWidth != _paletteWidth) {
          _paletteWidth = clampedPaletteWidth;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _paletteWidth,
              child: ToolPalette(
                toolManager: _toolManager,
                onToolSelected: (tool) {
                  setState(() {
                    _toolManager.selectTool(tool);
                  });
                },
              ),
            ),
            _PaletteResizeHandle(
              width: _paletteHandleWidth,
              onDrag: (delta) {
                if (delta == 0) return;
                setState(() {
                  final newWidth = (_paletteWidth + delta).clamp(
                    minAllowedPaletteWidth,
                    maxAllowedPaletteWidth,
                  );
                  _paletteWidth = newWidth;
                });
              },
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: GeoDrawCanvas(
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
                  showGrid: true,
                ),
              ),
            ),
            SizedBox(
              width: sidePanelWidth,
              child: Column(
                children: [
                  Expanded(
                    child: ObjectBrowser(
                      dagManager: _dagManager,
                      selectedIds: _selectedIds,
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedIds
                            ..clear()
                            ..addAll(selection);
                        });
                      },
                    ),
                  ),
                  if (_metadata != null) ...[
                    const SizedBox(height: 12),
                    _MetadataPreviewCard(
                      metadata: _metadata,
                      onEdit: _openMetadataSheet,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: UnifiedPromptPanel(
                      dagManager: _dagManager,
                      cliExecutor: _commandExecutor,
                      aiService: _aiService,
                      aiAdapter: AIAdapter(dagManager: _dagManager),
                      onConstructionComplete: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final totalObjects = _dagManager.topologicalSort().length;

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
          const Spacer(),
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

    final metadata = await _requireMetadata();
    if (!mounted) return;
    if (metadata == null) return;

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
          geometryData: geometryData,
          solution: metadata.solution,
          thumbnailId: thumbnailId ?? widget.problem!.thumbnailId,
        ),
      );
    } else {
      bloc.add(
        CreateProblem(
          title: metadata.title,
          description: metadata.description,
          difficulty: metadata.difficulty,
          category: metadata.category,
          geometryData: geometryData,
          solution: metadata.solution,
          thumbnailId: thumbnailId,
        ),
      );
      _thumbnailPendingDeletion = null;
    }
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

    final didSignIn = await showDialog<bool>(
          context: context,
          builder: (context) => const _SignInDialog(),
        ) ??
        false;

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

class _PaletteResizeHandle extends StatelessWidget {
  const _PaletteResizeHandle({required this.width, required this.onDrag});

  final double width;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: width,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 2,
              height: 48,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProblemMetadata {
  const ProblemMetadata({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    this.solution,
  });

  final String title;
  final String description;
  final ProblemDifficulty difficulty;
  final ProblemCategory category;
  final String? solution;
}

class _MetadataPreviewCard extends StatelessWidget {
  const _MetadataPreviewCard({required this.metadata, required this.onEdit});

  final ProblemMetadata? metadata;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metadata == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metadata!.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit details',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              metadata!.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipLabel(
                  icon: Icons.emoji_objects_outlined,
                  label: metadata!.difficulty.displayName,
                ),
                _ChipLabel(
                  icon: Icons.category_outlined,
                  label: metadata!.category.displayName,
                ),
              ],
            ),
            if (metadata!.solution != null && metadata!.solution!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  metadata!.solution!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
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
  const ProblemMetadataSheet(
      {super.key, this.initial, required this.isEditing});

  final ProblemMetadata? initial;
  final bool isEditing;

  @override
  State<ProblemMetadataSheet> createState() => _ProblemMetadataSheetState();
}

class _ProblemMetadataSheetState extends State<ProblemMetadataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _solutionController;
  late ProblemDifficulty _difficulty;
  late ProblemCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
    _solutionController =
        TextEditingController(text: widget.initial?.solution ?? '');
    _difficulty = widget.initial?.difficulty ?? ProblemDifficulty.beginner;
    _category = widget.initial?.category ?? ProblemCategory.geometry;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _solutionController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final metadata = ProblemMetadata(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      difficulty: _difficulty,
      category: _category,
      solution: _solutionController.text.trim().isEmpty
          ? null
          : _solutionController.text.trim(),
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
