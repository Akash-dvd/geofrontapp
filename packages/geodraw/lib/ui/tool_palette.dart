import 'package:flutter/material.dart';

import '../tools/tool.dart';
import '../tools/tool_catalog.dart';
import '../tools/tool_manager.dart';

/// Widget for selecting and managing construction tools, grouped by level.
class ToolPalette extends StatefulWidget {
  final ToolManager toolManager;
  final ValueChanged<ToolType> onToolSelected;
  final Axis direction;

  const ToolPalette({
    super.key,
    required this.toolManager,
    required this.onToolSelected,
    this.direction = Axis.vertical,
  });

  @override
  State<ToolPalette> createState() => _ToolPaletteState();
}

class _ToolPaletteState extends State<ToolPalette> {
  ToolPaletteLevel _level = ToolPaletteLevel.level1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = toolGroupsForLevel(_level);

    final paletteContent = <Widget>[
      _LevelSelector(
        selectedLevel: _level,
        onChanged: (level) => setState(() => _level = level),
      ),
      const SizedBox(height: 12),
      for (final group in groups)
        _ToolCategoryPanel(
          group: group,
          toolManager: widget.toolManager,
          direction: widget.direction,
          onToolSelected: widget.onToolSelected,
        ),
      const SizedBox(height: 8),
      Text(
        'Level ${_level.index + 1} • ${groups.length} categories',
        style: theme.textTheme.labelSmall,
      ),
    ];

    if (widget.direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paletteContent,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paletteContent,
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final ToolPaletteLevel selectedLevel;
  final ValueChanged<ToolPaletteLevel> onChanged;

  const _LevelSelector({required this.selectedLevel, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Level 1', 'Level 2', 'Level 3'];
    final selectedIndex = selectedLevel.index;
    return ToggleButtons(
      isSelected: List.generate(
        ToolPaletteLevel.values.length,
        (index) => index == selectedIndex,
      ),
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minWidth: 88, minHeight: 36),
      onPressed: (index) => onChanged(ToolPaletteLevel.values[index]),
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label),
          ),
      ],
    );
  }
}

class _ToolCategoryPanel extends StatelessWidget {
  final ToolCategoryGroup group;
  final ToolManager toolManager;
  final Axis direction;
  final ValueChanged<ToolType> onToolSelected;

  const _ToolCategoryPanel({
    required this.group,
    required this.toolManager,
    required this.direction,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wrapDirection = direction == Axis.vertical
        ? Axis.horizontal
        : Axis.vertical;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            direction: wrapDirection,
            children: [
              for (final entry in group.tools)
                _ToolButton(
                  entry: entry,
                  isActive:
                      entry.toolType != null &&
                      toolManager.activeToolType == entry.toolType,
                  enabled:
                      entry.toolType != null &&
                      entry.implemented &&
                      toolManager.isToolAvailable(entry.toolType!),
                  onPressed: entry.toolType != null
                      ? () => onToolSelected(entry.toolType!)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final ToolCatalogEntry entry;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.entry,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooltipParts = <String>[entry.label];
    if (entry.command != null) {
      tooltipParts.add(entry.command!);
    }
    if (!enabled) {
      tooltipParts.add('Planned');
    }

    final tooltip = tooltipParts.join(' • ');

    final foreground = isActive
        ? theme.colorScheme.primary
        : enabled
        ? Colors.grey[800]
        : Colors.grey;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            minimumSize: const Size(72, 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(entry.icon, size: 24, color: foreground),
              const SizedBox(height: 4),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
