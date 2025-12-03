import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ai/ai_adapter.dart';
import '../ai/ai_service.dart';
import '../cli/cli.dart';
import '../core/dag/dag_manager.dart';
import '../tools/tool.dart';
import '../tools/tool_manager.dart';
import 'object_browser.dart';
import 'tool_palette.dart';
import 'unified_prompt_panel.dart';

/// Combined side panel for GeoDraw that switches between tools and objects.
class GeoDrawSidePanel extends StatefulWidget {
  final DAGManager dagManager;
  final ToolManager toolManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final ValueChanged<ToolType> onToolSelected;
  final ValueChanged<String>? onDeleteObject;
  final UnifiedCLIExecutor? cliExecutor;
  final AIService? aiService;
  final AIAdapter? aiAdapter;
  final VoidCallback? onPromptConstructionComplete;
  final double expandedWidth;
  final double collapsedWidth;
  final double minExpandedWidth;
  final double maxExpandedWidth;
  final double promptHeight;
  final double resizeHandleWidth;

  const GeoDrawSidePanel({
    super.key,
    required this.dagManager,
    required this.toolManager,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onToolSelected,
    this.onDeleteObject,
    this.cliExecutor,
    this.aiService,
    this.aiAdapter,
    this.onPromptConstructionComplete,
  this.expandedWidth = 416,
    this.collapsedWidth = 72,
  this.minExpandedWidth = 338,
  this.maxExpandedWidth = 572,
    this.promptHeight = 200,
    this.resizeHandleWidth = 10,
  })  : assert(expandedWidth > collapsedWidth),
        assert(minExpandedWidth <= maxExpandedWidth);

  @override
  State<GeoDrawSidePanel> createState() => _GeoDrawSidePanelState();
}

enum _GeoDrawPanelView { tools, objects, algebra }

class _GeoDrawSidePanelState extends State<GeoDrawSidePanel> {
  bool _isExpanded = true;
  _GeoDrawPanelView _view = _GeoDrawPanelView.tools;
  late double _currentWidth;

  @override
  void initState() {
    super.initState();
    _currentWidth = _clampWidth(widget.expandedWidth);
  }

  @override
  void didUpdateWidget(covariant GeoDrawSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandedWidth != oldWidget.expandedWidth ||
        widget.minExpandedWidth != oldWidget.minExpandedWidth ||
        widget.maxExpandedWidth != oldWidget.maxExpandedWidth) {
      final baseline = widget.expandedWidth != oldWidget.expandedWidth
          ? widget.expandedWidth
          : _currentWidth;
      _currentWidth = _clampWidth(baseline);
    }
  }

  double _clampWidth(double value) {
    var width = value;
    if (width < widget.minExpandedWidth) {
      width = widget.minExpandedWidth;
    } else if (width > widget.maxExpandedWidth) {
      width = widget.maxExpandedWidth;
    }
    return width;
  }

  void _handleResize(double delta) {
    if (!_isExpanded || delta == 0) return;
    setState(() {
      _currentWidth = _clampWidth(_currentWidth + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = _isExpanded ? _currentWidth : widget.collapsedWidth;
    final background = theme.colorScheme.surfaceContainerHighest
        .withOpacity(_isExpanded ? 0.96 : 0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(1, 0),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRail(theme),
          if (_isExpanded)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _view == _GeoDrawPanelView.tools
                          ? KeyedSubtree(
                              key: const ValueKey('_tools_panel'),
                              child: _buildTools(),
                            )
                          : _view == _GeoDrawPanelView.objects
                              ? KeyedSubtree(
                                  key: const ValueKey('_objects_panel'),
                                  child: _buildObjects(theme),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('_algebra_panel'),
                                  child: _buildAlgebra(theme),
                                ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isExpanded)
            _buildResizeHandle(theme),
        ],
      ),
    );
  }

  Widget _buildRail(ThemeData theme) {
    return Container(
      width: widget.collapsedWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Tooltip(
            message: _isExpanded ? 'Collapse panel' : 'Expand panel',
            child: IconButton(
              icon: AnimatedRotation(
                turns: _isExpanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_double_arrow_left, size: 20),
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          const SizedBox(height: 18),
          _PanelToggleButton(
            icon: Icons.build,
            label: 'Tools',
            isActive: _view == _GeoDrawPanelView.tools,
            onTap: () => setState(() {
              _view = _GeoDrawPanelView.tools;
              _isExpanded = true;
            }),
          ),
          const SizedBox(height: 12),
          _PanelToggleButton(
            icon: Icons.list_alt,
            label: 'Objects',
            isActive: _view == _GeoDrawPanelView.objects,
            onTap: () => setState(() {
              _view = _GeoDrawPanelView.objects;
              _isExpanded = true;
            }),
          ),
          const SizedBox(height: 12),
          _PanelToggleButton(
            icon: Icons.functions,
            label: 'Algebra',
            isActive: _view == _GeoDrawPanelView.algebra,
            onTap: () => setState(() {
              _view = _GeoDrawPanelView.algebra;
              _isExpanded = true;
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final title = _view == _GeoDrawPanelView.tools
        ? 'Tools'
        : _view == _GeoDrawPanelView.objects
            ? 'Objects'
            : 'Algebra';
    final subtitle = _view == _GeoDrawPanelView.tools
        ? 'Choose a construction tool'
        : _view == _GeoDrawPanelView.objects
            ? '${widget.dagManager.nodeCount} elements'
            : 'Non-commutative computer algebraic system';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTools() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ToolPalette(
        toolManager: widget.toolManager,
        onToolSelected: widget.onToolSelected,
        direction: Axis.vertical,
        embedded: true,
      ),
    );
  }

  Widget _buildObjects(ThemeData theme) {
    final hasPrompt =
        widget.cliExecutor != null &&
        widget.aiService != null &&
        widget.aiAdapter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ObjectBrowser(
            dagManager: widget.dagManager,
            selectedIds: widget.selectedIds,
            onSelectionChanged: widget.onSelectionChanged,
            onDeleteRequested: widget.onDeleteObject,
          ),
        ),
        if (hasPrompt) ...[
          const Divider(height: 1),
          SizedBox(
            height: widget.promptHeight,
            child: UnifiedPromptPanel(
              dagManager: widget.dagManager,
              cliExecutor: widget.cliExecutor,
              aiService: widget.aiService,
              aiAdapter: widget.aiAdapter,
              onConstructionComplete: widget.onPromptConstructionComplete,
              height: widget.promptHeight,
            ),
          ),
        ],
        if (!hasPrompt)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Object details are shown here. Switch to Tools for construction.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlgebra(ThemeData theme) {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 2, // -90 degrees counter-clockwise
        child: Text(
          'NON commutative computer algebraic system',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResizeHandle(ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => _handleResize(details.delta.dx),
        child: Container(
          width: widget.resizeHandleWidth,
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

class _PanelToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PanelToggleButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isActive ? activeColor : inactiveColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
