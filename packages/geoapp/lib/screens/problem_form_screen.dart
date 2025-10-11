import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geodraw/geodraw.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../models/problem.dart';
import '../services/geodraw_navigation_service.dart';
import '../services/directus_file_service.dart';
import '../utils/canvas_capture.dart';

/// Screen for creating and editing problems
class ProblemFormScreen extends StatefulWidget {
  const ProblemFormScreen({super.key, this.problem});

  final Problem? problem;

  bool get isEditing => problem != null;

  @override
  State<ProblemFormScreen> createState() => _ProblemFormScreenState();
}

class _ProblemFormScreenState extends State<ProblemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _solutionController = TextEditingController();

  ProblemDifficulty _selectedDifficulty = ProblemDifficulty.beginner;
  ProblemCategory _selectedCategory = ProblemCategory.geometry;
  Map<String, dynamic>? _geometryData;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isEditing) {
      final problem = widget.problem!;
      _titleController.text = problem.title;
      _descriptionController.text = problem.description;
      _solutionController.text = problem.solution ?? '';
      _selectedDifficulty = problem.difficulty;
      _selectedCategory = problem.category;
      _geometryData = problem.geometryData;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Problem' : 'Create Problem'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveProblem,
            child: Text(
              widget.isEditing ? 'UPDATE' : 'CREATE',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ProblemBloc, ProblemState>(
        listener: (context, state) {
          if (state is ProblemOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is ProblemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProblemOperationInProgress;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter problem title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Enter problem description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Difficulty dropdown
                      DropdownButtonFormField<ProblemDifficulty>(
                        initialValue: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
                        items: ProblemDifficulty.values.map((difficulty) {
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(difficulty),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(difficulty.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (difficulty) {
                                if (difficulty != null) {
                                  setState(() {
                                    _selectedDifficulty = difficulty;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<ProblemCategory>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ProblemCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (category) {
                                if (category != null) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Geometry Data section
                      _buildGeometryDataSection(isLoading),
                      const SizedBox(height: 16),

                      // Solution field
                      TextFormField(
                        controller: _solutionController,
                        decoration: const InputDecoration(
                          labelText: 'Solution (Optional)',
                          hintText: 'Enter problem solution',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 6,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('CANCEL'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _saveProblem,
                              child: Text(
                                widget.isEditing ? 'UPDATE' : 'CREATE',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeometryDataSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Geometry Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: isLoading ? null : _openGeoDraw,
              icon: const Icon(Icons.draw),
              label: const Text('Open GeoDraw'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            _geometryData != null
                ? 'Geometry data loaded (${_geometryData!.keys.length} properties)'
                : 'No geometry data. Use GeoDraw to create geometric constructions.',
            style: TextStyle(
              color: _geometryData != null ? Colors.black : Colors.grey[600],
              fontStyle: _geometryData != null
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(ProblemDifficulty difficulty) {
    switch (difficulty) {
      case ProblemDifficulty.beginner:
        return Colors.green;
      case ProblemDifficulty.intermediate:
        return Colors.yellow[700]!;
      case ProblemDifficulty.advanced:
        return Colors.orange;
      case ProblemDifficulty.expert:
        return Colors.red;
    }
  }

  void _openGeoDraw() async {
    Map<String, dynamic>? geometryData;

    if (widget.isEditing && widget.problem!.geometryData != null) {
      // Edit existing geometry
      geometryData = await GeoDrawNavigationService.navigateToEdit(
        context,
        widget.problem!,
      );
    } else {
      // Create new geometry
      geometryData = await GeoDrawNavigationService.navigateToCreate(context);
    }

    if (geometryData != null) {
      setState(() {
        _geometryData = geometryData;
      });
    }
  }

  /// Capture canvas thumbnail and upload to Directus
  Future<String?> _captureThumbnail(Map<String, dynamic> geometryData) async {
    try {
      // Decode geometry data to DAGManager
      final decoder = GeoDrawDecoder();
      final dagManager = decoder.decode(geometryData);

      // Log canvas state
      final sortedNodes = dagManager.topologicalSort();
      print('DEBUG: Found ${sortedNodes.length} objects in DAG');

      final hasVisibleObjects = sortedNodes.any((node) => node.object.visible);
      print('DEBUG: Has visible objects: $hasVisibleObjects');

      // Capture canvas as PNG even if empty (800x600 thumbnail)
      print('DEBUG: Starting canvas capture...');
      final imageBytes = await CanvasCapture.captureAsPng(
        dagManager: dagManager,
        width: 800,
        height: 600,
        backgroundColor: Colors.white,
        showGrid: false, // Clean thumbnail without grid
      );

      if (imageBytes == null) {
        print('ERROR: Failed to capture canvas image - imageBytes is null');
        return null;
      }

      print('DEBUG: Canvas captured successfully, ${imageBytes.length} bytes');

      // Upload to Directus
      print('DEBUG: Uploading to Directus...');
      final fileService = DirectusFileService(
        baseUrl: 'http://192.168.1.3:8055',
      );

      final fileId = await fileService.uploadImage(
        imageBytes: imageBytes,
        filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.png',
        title: 'Problem Thumbnail',
      );

      if (fileId == null) {
        print('ERROR: Directus upload failed - fileId is null');
        return null;
      }

      print('DEBUG: Upload successful, fileId: $fileId');
      return fileId;
    } catch (e) {
      print('Error capturing thumbnail: $e');
      return null;
    }
  }

  void _saveProblem() async {
    print('DEBUG: _saveProblem called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final solution = _solutionController.text.trim().isNotEmpty
        ? _solutionController.text.trim()
        : null;

    print('DEBUG: Title: $title, Description: $description');
    print('DEBUG: Geometry data exists: ${_geometryData != null}');

    // Capture thumbnail if geometry data exists
    String? thumbnailId;
    if (_geometryData != null) {
      print('DEBUG: Capturing thumbnail for geometry data');
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      thumbnailId = await _captureThumbnail(_geometryData!);
      print('DEBUG: Thumbnail capture complete, ID: $thumbnailId');

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (thumbnailId == null) {
        // Show error but continue without thumbnail
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to capture thumbnail, saving without image',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    if (widget.isEditing) {
      print(
        'DEBUG: Dispatching UpdateProblem event with thumbnailId: $thumbnailId',
      );
      context.read<ProblemBloc>().add(
        UpdateProblem(
          id: widget.problem!.id,
          title: title,
          description: description,
          difficulty: _selectedDifficulty,
          category: _selectedCategory,
          geometryData: _geometryData,
          solution: solution,
          thumbnailId: thumbnailId,
        ),
      );
    } else {
      print(
        'DEBUG: Dispatching CreateProblem event with thumbnailId: $thumbnailId',
      );
      context.read<ProblemBloc>().add(
        CreateProblem(
          title: title,
          description: description,
          difficulty: _selectedDifficulty,
          category: _selectedCategory,
          geometryData: _geometryData,
          solution: solution,
          thumbnailId: thumbnailId,
        ),
      );
    }
  }
}
