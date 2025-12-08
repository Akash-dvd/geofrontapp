import 'package:flutter/material.dart';

import '../core/dag/dag_manager.dart';
import '../models/geometry_object.dart';
import '../models/complex/complex_geometry_object.dart';
import 'object_settings_panel.dart';

/// Browser widget for viewing and managing geometric objects
class ObjectBrowser extends StatefulWidget {
  final DAGManager dagManager;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<String>? onDeleteRequested;
  final double width;

  const ObjectBrowser({
    super.key,
    required this.dagManager,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.onDeleteRequested,
    this.width = 250,
  });

  @override
  State<ObjectBrowser> createState() => _ObjectBrowserState();
}

class _ObjectBrowserState extends State<ObjectBrowser> {
  final Set<String> _expandedIds = {};
  GeometryObject? _editingObject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = colorScheme.outlineVariant.withOpacity(0.35);
    final panelColor = colorScheme.surfaceContainerHighest.withOpacity(0.92);
    final headerColor = colorScheme.surface;
    final headerBorder = BorderSide(color: outlineColor, width: 1);
    // Sort by construction order (when objects were added to DAG)
    // Use creationOrder instead of lastModified so visibility changes don't reorder the list
    final sortedNodes = widget.dagManager.nodes.values
        .where((node) => node.object is GeometryObject)
        .toList()
      ..sort((a, b) => a.creationOrder.compareTo(b.creationOrder));

    void handleEdit(GeometryObject object) {
      // Check if settings panel is already open by checking the route stack
      final navigator = Navigator.of(context);
      final currentRoute = ModalRoute.of(context);
      if (currentRoute?.settings.name == 'settings_panel') {
        return; // Already showing settings panel
      }
      
      // Open settings panel as full-screen overlay
      navigator.push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.3),
          settings: const RouteSettings(name: 'settings_panel'),
          pageBuilder: (context, animation, secondaryAnimation) {
            return SettingsPanelOverlay(
              object: object,
              dagManager: widget.dagManager,
              onObjectUpdated: (updatedObject) {
                widget.dagManager.updateObject(
                  updatedObject.id,
                  updatedObject,
                );
        setState(() {});
              },
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            );
          },
        ),
      );
    }

    void handleVisibilityToggle(GeometryObject object) {
      // Check if this is a container type
      // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so this covers both
      if (object is UnionGeometryObjectList) {
        final oldVisibility = object.visible;
        final newVisibility = !oldVisibility;
        
        // Update container visibility
        var updated = object.copyWith(visible: newVisibility);
        
        // Update all children whose visibility matches the old container visibility
        // (they were following the container)
        final updatedObjects = object.elements.map((child) {
          // If child visibility matches old container visibility, update it
          if (child.visible == oldVisibility) {
            return child.copyWith(visible: newVisibility);
          }
          // Otherwise, child has been individually overridden, keep it as is
          return child;
        }).toList();
        
        // Update container with new children list
        // All UnionGeometryObjectList types (including GenSimpleGeometryObjectList) now support elementsAny parameter in copyWith
        updated = (object as dynamic).copyWith(
          visible: newVisibility,
          elementsAny: updatedObjects,
        ) as GeometryObject;
        
        widget.dagManager.updateObject(object.id, updated);
      } else {
        // Regular object - simple visibility toggle
        final updated = object.copyWith(visible: !object.visible);
        widget.dagManager.updateObject(object.id, updated);
      }
      
      setState(() {});
    }

    return Stack(
      children: [
        Container(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(left: BorderSide(color: outlineColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: headerBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Objects (${widget.dagManager.nodeCount})',
                  style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Object list
          Expanded(
            child: sortedNodes.isEmpty
                ? Center(
                    child: Text(
                      'No objects',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ) ??
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedNodes.length,
                    itemBuilder: (context, index) {
                      final node = sortedNodes[index];
                      final geometry = node.object as GeometryObject;
                      final isExpanded = _expandedIds.contains(node.id);
                      final hasChildren = _hasExpandableChildren(geometry);
                      
                      return Column(
                        children: [
                          _ObjectListTile(
                            node: node,
                            object: geometry,
                            isSelected: widget.selectedIds.contains(node.id),
                            isExpanded: isExpanded,
                            hasChildren: hasChildren,
                            onToggleExpansion: hasChildren
                                ? () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedIds.remove(node.id);
                                      } else {
                                        _expandedIds.add(node.id);
                                      }
                                    });
                                  }
                                : null,
                            onToggleVisibility: () => handleVisibilityToggle(geometry),
                            onTap: () {
                              widget.onSelectionChanged?.call({node.id});
                            },
                            onDelete: () {
                              widget.onDeleteRequested?.call(node.id);
                            },
                            onEdit: () => handleEdit(geometry),
                          ),
                          if (isExpanded && hasChildren)
                            ..._buildChildrenItems(geometry, node.id, handleEdit),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
        ),
        // Settings panel overlay - covers entire screen, positioned on right
        if (_editingObject != null)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.3),
              child: Stack(
                      children: [
                  // Backdrop that closes panel on tap
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingObject = null;
                      });
                    },
                    child: Container(color: Colors.transparent),
                            ),
                  // Settings panel on the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: ObjectSettingsPanel(
                      object: _editingObject!,
                      dagManager: widget.dagManager,
                      onObjectUpdated: (updatedObject) {
                        widget.dagManager.updateObject(
                          updatedObject.id,
                          updatedObject,
                        );
                        setState(() {});
                      },
                      onClose: () {
                        setState(() {
                          _editingObject = null;
                        });
                      },
                    ),
                    ),
                  ],
                ),
              ),
                ),
              ],
            );
  }


  bool _hasExpandableChildren(GeometryObject object) {
    // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so this covers both
    if (object is UnionGeometryObjectList) {
      return object.elements.isNotEmpty;
    }
    return false;
  }

  List<Widget> _buildChildrenItems(
    GeometryObject parent,
    String parentId,
    void Function(GeometryObject) handleEdit,
  ) {
    final children = <Widget>[];
    
    // Get fresh parent reference from DAG manager to ensure we have latest state
    final currentParent = widget.dagManager.getObject(parentId);
    if (currentParent is! GeometryObject) {
      return children; // Parent not found or wrong type
    }
    
    // Note: GenSimpleGeometryObjectList extends UnionGeometryObjectList, so this covers both
    if (currentParent is UnionGeometryObjectList) {
      for (int i = 0; i < currentParent.elements.length; i++) {
        final element = currentParent.elements[i];
        final elementId = element.id;
        children.add(
          Container(
            margin: const EdgeInsets.only(left: 32),
            child: _ObjectListTile(
              node: _ElementNode(elementId, element),
              object: element,
              isSelected: widget.selectedIds.contains(elementId),
              isExpanded: false,
              hasChildren: false,
              onToggleExpansion: null,
              onToggleVisibility: () {
                // Get fresh parent reference from DAG manager
                final freshParent = widget.dagManager.getObject(parentId);
                if (freshParent is! UnionGeometryObjectList) return;
                
                // Toggle individual child visibility
                final updatedElements = freshParent.elements.map((child) {
                  if (child.id == elementId) {
                    return child.copyWith(visible: !child.visible);
                  }
                  return child;
                }).toList();
                
                // Update container with updated child
                // All UnionGeometryObjectList types (including GenSimpleGeometryObjectList) now support elementsAny parameter
                final updated = (freshParent as dynamic).copyWith(
                  elementsAny: updatedElements,
                ) as GeometryObject;
                widget.dagManager.updateObject(parentId, updated);
                setState(() {});
              },
              onTap: () {
                widget.onSelectionChanged?.call({elementId});
              },
              onDelete: () {
                // Cannot delete individual elements
              },
              onEdit: () {
                // Edit parent instead
                handleEdit(currentParent);
              },
            ),
          ),
        );
      }
    }
    
    return children;
  }
}

/// Dummy node for elements (not in DAG)
class _ElementNode {
  final String id;
  final GeometryObject object;
  
  _ElementNode(this.id, this.object);
  
  int get depth => 0;
  bool get isFree => false;
  List<String> get parentIds => [];
  List<String> get childIds => [];
}

class _ObjectListTile extends StatelessWidget {
  final node;
  final GeometryObject object;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback? onToggleExpansion;
  final VoidCallback onToggleVisibility;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ObjectListTile({
    required this.node,
    required this.object,
    required this.isSelected,
    this.isExpanded = false,
    this.hasChildren = false,
    this.onToggleExpansion,
    required this.onToggleVisibility,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outlineColor = colorScheme.outlineVariant.withOpacity(0.3);
    final selectionColor =
        isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent;
    final iconAccent = colorScheme.primary;
    final secondaryIcon = colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: selectionColor,
        border: Border(bottom: BorderSide(color: outlineColor, width: 1)),
      ),
      child: ListTile(
        dense: true,
        leading: Tooltip(
          message: object.visible ? 'Click to hide' : 'Click to show',
          waitDuration: const Duration(milliseconds: 250),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleVisibility,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
                    color: object.visible
                        ? object.style.strokeColor.withOpacity(0.22)
                        : Colors.transparent,
            shape: BoxShape.circle,
                    border: Border.all(
                      color: object.style.strokeColor.withOpacity(
                        object.visible ? 1 : 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                  child: object.visible
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.visibility_off,
                          size: 14,
                          color: secondaryIcon,
                        ),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                onTap: onToggleExpansion,
                child: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // In new system: element.id == element.label (display label)
                      // For containers: object.label is the container label (e.g., SL1, SL2)
                      // For elements: object.id is the display label (e.g., A, B, a, b)
                      object.label.isNotEmpty ? object.label : object.id,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ) ??
                          TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    Text(
                      '${object.runtimeType.toString().replaceAll('Geo', '')}${node is _ElementNode ? '' : ' • Depth: ${node.depth}'}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.isFree)
              Tooltip(
                message: 'Free object',
                child: Icon(Icons.lock_open, size: 14, color: iconAccent),
              )
            else
              Tooltip(
                message: '${node.parentIds.length} dependencies',
                child: Icon(Icons.link, size: 14, color: secondaryIcon),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              color: secondaryIcon,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              color: theme.colorScheme.error,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: null,
      ),
    );
  }
}

/// Full-screen overlay for settings panel
class SettingsPanelOverlay extends StatelessWidget {
  final GeometryObject object;
  final DAGManager dagManager;
  final ValueChanged<GeometryObject> onObjectUpdated;

  const SettingsPanelOverlay({
    required this.object,
    required this.dagManager,
    required this.onObjectUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop that closes panel on tap
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          // Settings panel on the right
          Align(
            alignment: Alignment.centerRight,
            child: ObjectSettingsPanel(
              object: object,
              dagManager: dagManager,
              onObjectUpdated: (updatedObject) {
                onObjectUpdated(updatedObject);
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
