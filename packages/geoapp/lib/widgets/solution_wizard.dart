import 'package:flutter/material.dart';
import 'package:geodraw/geodraw.dart';

import '../services/solver_service.dart';

/// Wizard-style solution viewer with step-by-step navigation
class SolutionWizard extends StatefulWidget {
  const SolutionWizard({
    super.key,
    required this.problemDagManager,
    required this.problemToolManager,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.solutionSteps,
    this.onClose,
  });

  final DAGManager problemDagManager;
  final ToolManager problemToolManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final List<SolverSolutionStep> solutionSteps;
  final VoidCallback? onClose;

  @override
  State<SolutionWizard> createState() => _SolutionWizardState();
}

class _SolutionWizardState extends State<SolutionWizard> {
  late final PageController _pageController;
  late final List<_SolutionPage> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _buildPages();
  }

  List<_SolutionPage> _buildPages() {
    final pages = <_SolutionPage>[
      // First page: Original problem canvas
      _SolutionPage(
        title: 'Problem Setup',
        description: 'Initial geometric construction',
        dagManager: widget.problemDagManager,
        toolManager: widget.problemToolManager,
        isProblemSetup: true,
      ),
    ];

    // Decode each solution step
    final decoder = GeoDrawDecoder();
    for (var i = 0; i < widget.solutionSteps.length; i++) {
      final step = widget.solutionSteps[i];
      final geometry = step.geometryAsMap();

      DAGManager? stepDag;
      if (geometry != null) {
        try {
          stepDag = decoder.decode(Map<String, dynamic>.from(geometry));
        } catch (error) {
          debugPrint('Failed to decode solution step $i: $error');
        }
      }

      pages.add(
        _SolutionPage(
          title: 'Step ${i + 1}',
          description: step.description,
          dagManager: stepDag ?? DAGManager(),
          toolManager: ToolManager(dagManager: stepDag ?? DAGManager()),
          isProblemSetup: false,
          hasGeometry: stepDag != null,
        ),
      );
    }

    return pages;
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _pages.length - 1;

    return Column(
      children: [
        // Header with navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Close button
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close solution viewer',
                  onPressed: widget.onClose,
                ),
              const SizedBox(width: 8),
              
              // Page indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pages[_currentPage].title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Step $_currentPage of ${_pages.length - 1}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _currentPage / (_pages.length - 1),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Navigation buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Previous step',
                    onPressed: isFirstPage ? null : _previousPage,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Next step',
                    onPressed: isLastPage ? null : _nextPage,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Page content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _SolutionPageView(
                page: page,
                selectedIds: page.isProblemSetup ? widget.selectedIds : const {},
                onSelectionChanged: page.isProblemSetup
                    ? widget.onSelectionChanged
                    : null,
              );
            },
          ),
        ),

        // Footer with keyboard hints
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_arrow_left,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                'Use arrow keys or buttons to navigate',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _SolutionPage {
  const _SolutionPage({
    required this.title,
    required this.description,
    required this.dagManager,
    required this.toolManager,
    required this.isProblemSetup,
    this.hasGeometry = true,
  });

  final String title;
  final String description;
  final DAGManager dagManager;
  final ToolManager toolManager;
  final bool isProblemSetup;
  final bool hasGeometry;
}

class _SolutionPageView extends StatelessWidget {
  const _SolutionPageView({
    required this.page,
    required this.selectedIds,
    this.onSelectionChanged,
  });

  final _SolutionPage page;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Canvas - takes 2/3 of the width
        Expanded(
          flex: 2,
          child: Container(
            color: theme.colorScheme.surface,
            child: GeoDrawCanvas(
              dagManager: page.dagManager,
              toolManager: page.toolManager,
              selectedIds: selectedIds,
              onSelectionChanged: onSelectionChanged,
              showGrid: true,
            ),
          ),
        ),

        // Description panel - takes 1/3 of the width
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                left: BorderSide(
                  color: theme.dividerColor,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: page.isProblemSetup
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    page.isProblemSetup ? 'PROBLEM' : 'SOLUTION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: page.isProblemSetup
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  page.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description - scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!page.hasGeometry && !page.isProblemSetup)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Geometry data missing for this step',
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),
                        
                        if (!page.isProblemSetup) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Object count info
                          _InfoRow(
                            icon: Icons.account_tree,
                            label: 'Objects',
                            value: '${page.dagManager.topologicalSort().length}',
                          ),
                          const SizedBox(height: 8),
                          
                          _InfoRow(
                            icon: Icons.visibility,
                            label: 'Visible',
                            value: '${page.dagManager.topologicalSort().where((n) => n.object.visible).length}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

