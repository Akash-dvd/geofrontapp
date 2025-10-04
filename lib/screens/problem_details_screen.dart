import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../models/problem.dart';
import '../services/geodraw_navigation_service.dart';
import 'problem_form_screen.dart';

/// Screen to display detailed view of a problem
class ProblemDetailsScreen extends StatefulWidget {
  const ProblemDetailsScreen({
    super.key,
    required this.problemId,
  });

  final String problemId;

  @override
  State<ProblemDetailsScreen> createState() => _ProblemDetailsScreenState();
}

class _ProblemDetailsScreenState extends State<ProblemDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProblemBloc>().add(FetchProblemById(id: widget.problemId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          BlocBuilder<ProblemBloc, ProblemState>(
            builder: (context, state) {
              if (state is ProblemDetailsLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _navigateToEdit(context, state.problem);
                        break;
                      case 'delete':
                        _showDeleteDialog(context, state.problem);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
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
            // Navigate back after successful delete
            if (state.message.contains('deleted')) {
              Navigator.of(context).pop();
            }
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
          if (state is ProblemLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProblemError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading problem',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProblemBloc>().add(
                            FetchProblemById(id: widget.problemId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProblemDetailsLoaded) {
            return _buildProblemDetails(context, state.problem);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<ProblemBloc, ProblemState>(
        builder: (context, state) {
          if (state is ProblemDetailsLoaded) {
            return FloatingActionButton(
              onPressed: () => _navigateToGeoDraw(context, state.problem),
              tooltip: 'Open in GeoDraw',
              child: const Icon(Icons.draw),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProblemDetails(BuildContext context, Problem problem) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            problem.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Difficulty and Category chips
          Row(
            children: [
              _buildChip(
                problem.difficulty.displayName,
                _getDifficultyColor(problem.difficulty),
              ),
              const SizedBox(width: 8),
              _buildChip(
                problem.category.displayName,
                Colors.blue[100]!,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          _buildSection(
            context,
            'Description',
            problem.description,
          ),

          // Geometry Data (if available)
          if (problem.geometryData != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Geometry Data',
              'Contains geometric configuration data',
              trailing: ElevatedButton.icon(
                onPressed: () => _navigateToGeoDraw(context, problem),
                icon: const Icon(Icons.visibility),
                label: const Text('View in GeoDraw'),
              ),
            ),
          ],

          // Solution (if available)
          if (problem.solution != null) ...[
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Solution',
              problem.solution!,
            ),
          ],

          const SizedBox(height: 24),

          // Metadata
          _buildMetadataSection(context, problem),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content, {
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (trailing != null) trailing,
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
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context, Problem problem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metadata',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
          child: Column(
            children: [
              _buildMetadataRow('ID', problem.id),
              const SizedBox(height: 8),
              _buildMetadataRow('Created', _formatDate(problem.createdAt)),
              const SizedBox(height: 8),
              _buildMetadataRow('Updated', _formatDate(problem.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getDifficultyColor(ProblemDifficulty difficulty) {
    switch (difficulty) {
      case ProblemDifficulty.beginner:
        return Colors.green[100]!;
      case ProblemDifficulty.intermediate:
        return Colors.yellow[100]!;
      case ProblemDifficulty.advanced:
        return Colors.orange[100]!;
      case ProblemDifficulty.expert:
        return Colors.red[100]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(BuildContext context, Problem problem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProblemFormScreen(problem: problem),
      ),
    );
  }

  void _navigateToGeoDraw(BuildContext context, Problem problem) {
    GeoDrawNavigationService.navigateToView(context, problem);
  }

  void _showDeleteDialog(BuildContext context, Problem problem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Problem'),
          content: Text('Are you sure you want to delete "${problem.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ProblemBloc>().add(DeleteProblem(id: problem.id));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}