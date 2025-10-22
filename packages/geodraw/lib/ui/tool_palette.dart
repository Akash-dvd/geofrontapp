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

    final bool isHorizontal = widget.direction == Axis.horizontal;

    final Widget scrollable = isHorizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paletteContent,
              ),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: paletteContent,
            ),
          );

    final Color background = theme.colorScheme.surfaceContainerHighest.withOpacity(0.92);

    return Material(
      elevation: 4,
      color: background,
      child: ConstrainedBox(
        constraints: isHorizontal
            ? const BoxConstraints(minHeight: 180)
            : const BoxConstraints(minWidth: 220),
        child: scrollable,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          const spacing = 6.0;
          const desiredMinTileWidth = 96.0;

          final availableWidth = maxWidth.isFinite && maxWidth > 0
              ? maxWidth
              : desiredMinTileWidth;

          int columns = (availableWidth / (desiredMinTileWidth + spacing))
              .floor();
          if (columns < 1) {
            columns = 1;
          } else if (columns > 6) {
            columns = 6;
          }

          final totalSpacing = spacing * (columns - 1);
          final rawTileWidth = (availableWidth - totalSpacing) / columns;
          double tileWidth = rawTileWidth;
          if (availableWidth >= 80 && tileWidth < 80) {
            tileWidth = 80;
          }
          if (tileWidth > 140) {
            tileWidth = 140;
          }
          if (tileWidth > availableWidth) {
            tileWidth = availableWidth;
          }
          if (tileWidth < 56) {
            tileWidth = availableWidth; // avoid zero/negative when very narrow
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                direction: wrapDirection,
                children: [
                  for (final entry in group.tools)
                    SizedBox(
                      width: tileWidth,
                      child: _ToolButton(
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
                    ),
                ],
              ),
            ],
          );
        },
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

    final Color accent = theme.colorScheme.secondary;
    final Color fallbackAccent = Colors.deepOrange.shade400;
    final Color activeColor = accent.opacity == 0 ? fallbackAccent : accent;
    final Color disabledColor = activeColor.withOpacity(0.35);
    final Color hoverColor = activeColor.withOpacity(0.12);

    final Color iconColor = isActive
        ? Colors.white
        : enabled
        ? activeColor.withOpacity(0.9)
        : disabledColor;

    final Color borderColor = isActive
        ? activeColor
        : enabled
        ? activeColor.withOpacity(0.55)
        : disabledColor;

    final Color backgroundColor = isActive
        ? activeColor
        : enabled
        ? hoverColor
        : activeColor.withOpacity(0.06);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? activeColor.withOpacity(0.1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.1),
                  ),
                  child: Icon(entry.icon, size: 26, color: iconColor),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: (theme.textTheme.labelSmall ?? const TextStyle())
                      .copyWith(
                        color: iconColor,
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                  child: Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
