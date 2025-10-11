import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../config/app_theme.dart';
import '../models/problem.dart';
import '../services/directus_file_service.dart';
import 'problem_details_screen.dart';
import 'problem_form_screen.dart';

/// Front Page Problem Management screen with CRUD functionality
/// Follows constitutional UI layer principles
class ProblemManagementScreen extends StatefulWidget {
  const ProblemManagementScreen({super.key});

  @override
  State<ProblemManagementScreen> createState() =>
      _ProblemManagementScreenState();
}

class _ProblemManagementScreenState extends State<ProblemManagementScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch initial problems
    context.read<ProblemBloc>().add(const FetchProblems());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProblemBloc>().add(const LoadMoreProblems());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProblemBloc>().add(
                const FetchProblems(refresh: true),
              );
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

          if (state is ProblemError && state.currentProblems == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading problems',
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
                        const FetchProblems(refresh: true),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final problems = _getProblemsFromState(state);
          final hasMore = _getHasMoreFromState(state);
          final isLoadingMore = state is ProblemLoadingMore;

          if (problems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No problems found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first problem to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProblemBloc>().add(
                const FetchProblems(refresh: true),
              );
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 400,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= problems.length) {
                        return null;
                      }

                      final problem = problems[index];
                      return ProblemCard(
                        problem: problem,
                        onTap: () => _navigateToDetails(context, problem),
                        onEdit: () => _navigateToEdit(context, problem),
                        onDelete: () => _showDeleteDialog(context, problem),
                      );
                    }, childCount: problems.length),
                  ),
                ),
                if (hasMore)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        tooltip: 'Create Problem',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Problem> _getProblemsFromState(ProblemState state) {
    if (state is ProblemLoaded) return state.problems;
    if (state is ProblemLoadingMore) return state.currentProblems;
    if (state is ProblemOperationSuccess) return state.problems;
    if (state is ProblemError && state.currentProblems != null) {
      return state.currentProblems!;
    }
    return [];
  }

  bool _getHasMoreFromState(ProblemState state) {
    if (state is ProblemLoaded) return state.hasMore;
    if (state is ProblemOperationSuccess) return state.hasMore;
    return false;
  }

  void _navigateToDetails(BuildContext context, Problem problem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProblemDetailsScreen(problemId: problem.id),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProblemFormScreen()));
  }

  void _navigateToEdit(BuildContext context, Problem problem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProblemFormScreen(problem: problem),
      ),
    );
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

/// Individual problem card widget using Material Design patterns (DEPRECATED - Use ProblemCard instead)
class ProblemListItem extends StatelessWidget {
  const ProblemListItem({
    super.key,
    required this.problem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Problem problem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Delegate to the new ProblemCard widget
    return ProblemCard(
      problem: problem,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

/// Simple Material Design card for problems
class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Problem problem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fileService = DirectusFileService(baseUrl: 'http://192.168.1.3:8055');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Image with fixed height
            SizedBox(
              height: 240,
              width: double.infinity,
              child: problem.thumbnailId != null
                  ? Image.network(
                      fileService.getFileUrl(
                        problem.thumbnailId!,
                        width: 300,
                        height: 200,
                        fit: 'cover',
                        quality: 80,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: Text(
                      problem.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildSimpleChip(
                        problem.difficulty.displayName,
                        _getDifficultyColor(problem.difficulty),
                      ),
                      _buildSimpleChip(
                        problem.category.displayName,
                        AppTheme.getCategoryColor(Theme.of(context).brightness),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons - tight layout with no bottom padding
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getDifficultyColor(ProblemDifficulty difficulty) {
    switch (difficulty) {
      case ProblemDifficulty.beginner:
        return AppTheme.beginnerColor;
      case ProblemDifficulty.intermediate:
        return AppTheme.intermediateColor;
      case ProblemDifficulty.advanced:
        return AppTheme.advancedColor;
      case ProblemDifficulty.expert:
        return AppTheme.expertColor;
    }
  }
}
