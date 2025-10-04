import 'package:flutter/material.dart';
import '../dag/dag_manager.dart';
import '../models/geometry_object.dart';

/// Browser widget for viewing and managing geometric objects
class ObjectBrowser extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sortedNodes = dagManager.topologicalSort();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          left: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Objects (${dagManager.nodeCount})',
                  style: const TextStyle(
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedNodes.length,
                    itemBuilder: (context, index) {
                      final node = sortedNodes[index];
                      return _ObjectListTile(
                        node: node,
                        isSelected: selectedIds.contains(node.id),
                        onTap: () {
                          onSelectionChanged?.call({node.id});
                        },
                        onDelete: () {
                          onDeleteRequested?.call(node.id);
                        },
                      );
                    },
                  ),
          ),

          // Footer with stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: 'Free objects',
                  value: sortedNodes.where((n) => n.isFree).length.toString(),
                ),
                _StatRow(
                  label: 'Dependent objects',
                  value: sortedNodes.where((n) => !n.isFree).length.toString(),
                ),
                _StatRow(
                  label: 'Max depth',
                  value: sortedNodes.isEmpty
                      ? '0'
                      : sortedNodes
                          .map((n) => n.depth)
                          .reduce((a, b) => a > b ? a : b)
                          .toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectListTile extends StatelessWidget {
  final node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ObjectListTile({
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final object = node.object as GeometryObject;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: object.color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: object.color, width: 2),
          ),
        ),
        title: Text(
          object.label.isEmpty ? object.id : object.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${object.runtimeType.toString().replaceAll('Geo', '')} • Depth: ${node.depth}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.isFree)
              Tooltip(
                message: 'Free object',
                child: Icon(Icons.lock_open, size: 14, color: Colors.green[700]),
              )
            else
              Tooltip(
                message: '${node.parentIds.length} dependencies',
                child: Icon(Icons.link, size: 14, color: Colors.grey[600]),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 16),
              color: Colors.red[400],
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
