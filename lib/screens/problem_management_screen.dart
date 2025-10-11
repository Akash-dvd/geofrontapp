import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
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
            child: ListView.builder(
              controller: _scrollController,
              itemCount: problems.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= problems.length) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: isLoadingMore
                        ? const CircularProgressIndicator()
                        : const SizedBox.shrink(),
                  );
                }

                final problem = problems[index];
                return ProblemListItem(
                  problem: problem,
                  onTap: () => _navigateToDetails(context, problem),
                  onEdit: () => _navigateToEdit(context, problem),
                  onDelete: () => _showDeleteDialog(context, problem),
                );
              },
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

/// Individual problem list item widget with thumbnail
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
    final fileService = DirectusFileService(baseUrl: 'http://192.168.1.3:8055');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image
            if (problem.thumbnailId != null)
              Image.network(
                fileService.getFileUrl(
                  problem.thumbnailId!,
                  width: 800,
                  height: 400,
                  fit: 'cover',
                  quality: 80,
                ),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),

            // Problem details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          problem.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;
                            case 'delete':
                              onDelete();
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
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    problem.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
          ],
        ),
      ),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
}
