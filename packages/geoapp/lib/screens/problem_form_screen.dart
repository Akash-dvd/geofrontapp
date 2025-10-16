import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geodraw/geodraw.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../config/build_flags.dart';
import '../config/env_config.dart';
import '../models/problem.dart';
import '../services/directus_file_service.dart';
import '../utils/canvas_capture.dart';

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
  bool _isSavingThumbnail = false;
  double _paletteWidth = 330;
  static const double _minPaletteWidth = 220;
  static const double _paletteHandleWidth = 12;
  static const double _minCanvasWidth = 360;

  @override
  void initState() {
    super.initState();
    _initializeGeoDraw();
    _initializeMetadata();
  }

  void _initializeGeoDraw() {
    if (widget.problem?.geometryData != null) {
      try {
        final decoder = GeoDrawDecoder();
        _dagManager = decoder.decode(widget.problem!.geometryData!);
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
    _aiService = AIService(config: AIServiceConfig.development());
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
      _isAuthenticated = true;
    }
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
            onSignInRequest: _handleSignIn,
            onSignOut: widget.isEditing ? null : _handleSignOut,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          }

          if (state is ProblemError) {
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
                  const SizedBox(height: 12),
                  _MetadataPreviewCard(
                    metadata: _metadata,
                    onEdit: _openMetadataSheet,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: UnifiedPromptPanel(
                      dagManager: _dagManager,
                      cliExecutor: _commandExecutor,
                      aiService: _aiService,
                      aiAdapter: AIAdapter(dagManager: _dagManager),
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
    final geometryData = encoder.encode(_dagManager);

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
    }
  }

  Future<bool> _ensureAuthenticated() async {
    if (_isAuthenticated) {
      return true;
    }

    final didSignIn = await showDialog<bool>(
          context: context,
          builder: (context) => const _SignInDialog(),
        ) ??
        false;

    if (didSignIn) {
      setState(() => _isAuthenticated = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in (demo placeholder)')),
      );
    }
  }

  void _handleSignOut() {
    setState(() {
      _isAuthenticated = false;
    });
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
        // Cloud mode: Upload to Supabase
        // TODO: Implement Supabase file upload
        debugPrint('WARNING: Supabase file upload not yet implemented');
        return null;
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: metadata == null
            ? const SizedBox.shrink()
            : Column(
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
                  if (metadata!.solution != null &&
                      metadata!.solution!.isNotEmpty)
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
  });

  final bool isAuthenticated;
  final VoidCallback onSignInRequest;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ActionChip(
          avatar: const Icon(Icons.verified_user, size: 18),
          label: const Text('Signed in'),
          onPressed: onSignOut,
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

class _SignInDialogState extends State<_SignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

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
      title: const Text('Sign in to save'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication is required before we can store your work. '
              'Firebase integration is pending; this dialog is a placeholder.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: '••••••••',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
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
              onChanged: (value) {
                setState(() => _rememberMe = value ?? true);
              },
              title: const Text('Remember me on this device'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(true);
  }
}
