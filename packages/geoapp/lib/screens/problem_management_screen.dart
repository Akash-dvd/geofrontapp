import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:designsystem/designsystem.dart';

import '../bloc/problem_bloc.dart';
import '../bloc/problem_event.dart';
import '../bloc/problem_state.dart';
import '../config/build_flags.dart';
import '../config/env_config.dart';
import '../models/problem.dart';
import '../services/app_services.dart';
import '../services/directus_file_service.dart';
import '../services/supabase_file_service.dart';
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
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _currentUserId;
  StreamSubscription<String?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAuthState();
    _fetchInitialProblems(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authSubscription?.cancel();
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

  void _initializeAuthState() {
    try {
      final auth = AppServices.auth;
      _isAuthenticated = auth.isAuthenticated;
      _userEmail = auth.currentUserEmail ?? auth.currentUserDisplayName;
      _currentUserId = auth.currentUserId;
      _authSubscription = auth.authStateChanges.listen((_) {
        _handleAuthStateChange();
      });
    } catch (error) {
      debugPrint('Auth services unavailable: $error');
    }
  }

  void _handleAuthStateChange() {
    try {
      final auth = AppServices.auth;
      final wasAuthenticated = _isAuthenticated;
      final nextIsAuthenticated = auth.isAuthenticated;
      final label = auth.currentUserEmail ?? auth.currentUserDisplayName;
      final nextUserId = auth.currentUserId;
      if (!mounted) {
        return;
      }
      setState(() {
        _isAuthenticated = nextIsAuthenticated;
        _userEmail = label;
        _currentUserId = nextUserId;
      });
      if (nextIsAuthenticated != wasAuthenticated) {
        unawaited(AppServices.refreshDataProvider());
        _fetchInitialProblems(refresh: true);
      }
    } catch (error) {
      debugPrint('Auth state update failed: $error');
    }
  }

  void _fetchInitialProblems({bool refresh = true}) {
    context.read<ProblemBloc>().add(
          FetchProblems(refresh: refresh, start: 0),
        );
  }

  Future<void> _handleSignIn() async {
    final didSignIn = await showGeoAppSignInDialog(context);
    if (!didSignIn) {
      return;
    }
    try {
      await AppServices.refreshDataProvider();
    } catch (error) {
      debugPrint('Failed to refresh data provider: $error');
    }
    final auth = AppServices.auth;
    final label = auth.currentUserEmail ?? auth.currentUserDisplayName;
    if (!mounted) {
      return;
    }
    setState(() {
      _isAuthenticated = auth.isAuthenticated;
      _userEmail = label;
      _currentUserId = auth.currentUserId;
    });
    _fetchInitialProblems(refresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label != null && label.isNotEmpty
              ? 'Signed in as $label'
              : 'Signed in',
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await AppServices.auth.signOut();
      await AppServices.refreshDataProvider();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $error')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isAuthenticated = false;
      _userEmail = null;
      _currentUserId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: _isAuthenticated
        ? (_userEmail != null && _userEmail!.isNotEmpty
          ? 'Signed in as ${_userEmail!} (sign out)'
          : 'Sign out')
                : 'Sign in',
            icon: Icon(_isAuthenticated ? Icons.logout : Icons.login),
            onPressed: _isAuthenticated ? _handleSignOut : _handleSignIn,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _fetchInitialProblems(refresh: true),
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
          final problems = _getProblemsFromState(state);
          final hasMore = _getHasMoreFromState(state);
          final isLoadingMore = state is ProblemLoadingMore;
          final isInitialLoading = state is ProblemLoading && problems.isEmpty;

          if (state is ProblemError && problems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading problems',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _fetchInitialProblems(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final personalProblems = _currentUserId == null
              ? <Problem>[]
              : problems
                  .where((problem) => problem.ownerId == _currentUserId)
                  .toList();

          final publishedProblems = problems.where((problem) {
            if (!problem.status.isPublished) {
              return false;
            }
            if (_currentUserId == null) {
              return true;
            }
            if (problem.ownerId == null) {
              return true;
            }
            return problem.ownerId != _currentUserId;
          }).toList();

          final slivers = <Widget>[
            _buildIntroSliver(context),
          ];

          if (_isAuthenticated) {
            slivers.addAll(
              _buildProblemSection(
                context: context,
                title: 'Your workspace',
                description:
                    'Draft and published problems saved under your account.',
                problems: personalProblems,
                canManage: _canManageProblem,
                emptyBuilder: _buildPersonalEmptyState,
              ),
            );
          }

          slivers.addAll(
            _buildProblemSection(
              context: context,
              title: 'Published library',
              description: _isAuthenticated
                  ? 'Community problems available to everyone.'
                  : 'Explore published problems and solver outputs without signing in.',
              problems: publishedProblems,
              canManage: _canManageProblem,
              emptyBuilder: (ctx) =>
                  _buildPublishedEmptyState(ctx, _isAuthenticated),
            ),
          );

          if (hasMore) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: isLoadingMore
                        ? const CircularProgressIndicator()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchInitialProblems(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: slivers,
            ),
          );
        },
      ),
      floatingActionButton: _buildFab(context),
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

  bool _canManageProblem(Problem problem) {
    if (_currentUserId == null) {
      return false;
    }
    return problem.ownerId == _currentUserId;
  }

  SliverToBoxAdapter _buildIntroSliver(BuildContext context) {
    final theme = Theme.of(context);
    if (_isAuthenticated) {
      final label = _userEmail ?? 'Signed in';
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $label',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review drafts in your workspace or publish problems for everyone to explore.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community geometry problems',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse published problems and solver outputs. Sign in to save drafts and publish your own.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in to contribute'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _fetchInitialProblems(refresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh published list'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProblemSection({
    required BuildContext context,
    required String title,
    String? description,
    required List<Problem> problems,
    required bool Function(Problem) canManage,
    required Widget Function(BuildContext) emptyBuilder,
  }) {
    final theme = Theme.of(context);
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    ];

    if (problems.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: emptyBuilder(context),
          ),
        ),
      );
    } else {
      slivers.add(
        _buildProblemGrid(problems: problems, canManage: canManage),
      );
    }

    return slivers;
  }

  SliverPadding _buildProblemGrid({
    required List<Problem> problems,
    required bool Function(Problem) canManage,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisExtent: 400,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= problems.length) {
              return null;
            }

            final problem = problems[index];
            final manage = canManage(problem);
            return ProblemCard(
              problem: problem,
              canEdit: manage,
              canDelete: manage,
              onTap: () => _navigateToDetails(context, problem),
              onEdit: () => _navigateToEdit(context, problem),
              onDelete: () => _showDeleteDialog(context, problem),
            );
          },
          childCount: problems.length,
        ),
      ),
    );
  }

  Widget _buildPersonalEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No problems in your workspace yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Draft a problem to capture geometry, solver constraints, and proofs in one place.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add),
              label: const Text('Create your first problem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedEmptyState(BuildContext context, bool isAuthenticated) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No published problems yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isAuthenticated
                  ? 'Publish one of your drafts from the metadata sheet to share it with everyone.'
                  : 'Check back soon—published problems will appear here once they are shared.',
              style: theme.textTheme.bodyMedium,
            ),
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _fetchInitialProblems(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh published list'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    if (_isAuthenticated) {
      return FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        tooltip: 'Create problem',
        child: const Icon(Icons.add),
      );
    }
    return FloatingActionButton(
      onPressed: _handleSignIn,
      tooltip: 'Sign in to contribute',
      child: const Icon(Icons.login),
    );
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
    this.canEdit = true,
    this.canDelete = true,
  });

  final Problem problem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
  final fileService = BuildFlags.useDirectus
    ? DirectusFileService(baseUrl: EnvConfig.directusUrl)
    : null;
  // Always create SupabaseFileService so we can resolve storage-path style
  // thumbnail IDs even when the app was compiled with Directus mode.
  final supabaseFileService = SupabaseFileService(
    supabaseUrl: EnvConfig.supabaseUrl,
    supabaseAnonKey: EnvConfig.supabaseAnonKey,
  );
    final imageUrl = _resolveThumbnailUrl(
      fileService: fileService,
      supabaseFileService: supabaseFileService,
    );

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
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
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
                      _buildSimpleChip(
                        problem.status.displayName,
                        problem.status.isPublished
                            ? Colors.green.withOpacity(0.6)
                            : Colors.orangeAccent.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons - tight layout with no bottom padding
            if (canEdit || canDelete)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit)
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
                    if (canDelete)
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

  String? _resolveThumbnailUrl({
    DirectusFileService? fileService,
    SupabaseFileService? supabaseFileService,
  }) {
    final thumbnailId = problem.thumbnailId;
    if (thumbnailId == null || thumbnailId.isEmpty) {
      return null;
    }

    // Heuristic: Supabase storage keys include a slash (userId/path...).
    // Prefer Supabase URL when the thumbnailId looks like a storage path.
    if (thumbnailId.contains('/')) {
      return supabaseFileService?.getPublicUrl(thumbnailId);
    }

    // Otherwise, if running in Directus mode and we have a Directus file id,
    // use DirectusFileService to build the URL.
    if (fileService != null && BuildFlags.useDirectus) {
      return fileService.getFileUrl(
        thumbnailId,
        width: 300,
        height: 200,
        fit: 'cover',
        quality: 80,
      );
    }

    // Fall back to Supabase public URL when in cloud mode or unknown format.
    return supabaseFileService?.getPublicUrl(thumbnailId);
  }
}
