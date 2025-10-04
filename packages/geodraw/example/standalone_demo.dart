/// Standalone GeoDraw Demo
/// This demonstrates the core GeoDraw features without Flutter UI dependencies
library;

import 'dart:async';
import 'package:geodraw/src/dag/dag_manager.dart';
import 'package:geodraw/src/models/geo_point.dart';
import 'package:geodraw/src/models/geo_line.dart';
import 'package:geodraw/src/models/geo_circle.dart';
import 'package:geodraw/src/codec/json_codec.dart';
import 'package:geodraw/src/cli/command_parser.dart';
import 'package:geodraw/src/cli/command_executor.dart';

void main() async {
  print('=== GeoDraw Package Demo ===\n');

  // 1. CLI System Demo
  print('1. CLI SYSTEM DEMO');
  print('-' * 40);
  await cliDemo();

  print('\n');

  // 2. Codec System Demo
  print('2. CODEC SYSTEM DEMO');
  print('-' * 40);
  codecDemo();

  print('\n');

  // 3. Complete Construction Demo
  print('3. COMPLETE CONSTRUCTION DEMO');
  print('-' * 40);
  await completeDemo();
}

/// Demonstrate CLI system
Future<void> cliDemo() async {
  final dag = DAGManager();
  final executor = CommandExecutor(dagManager: dag);
  final parser = CommandParser();

  print('Creating construction via CLI commands...\n');

  // Create points
  var result = await executor.execute(parser.parse('point(0, 0, A)')!);
  print('> point(0, 0, A)');
  print('  ${result.message}\n');

  result = await executor.execute(parser.parse('point(10, 0, B)')!);
  print('> point(10, 0, B)');
  print('  ${result.message}\n');

  result = await executor.execute(parser.parse('point(5, 8, C)')!);
  print('> point(5, 8, C)');
  print('  ${result.message}\n');

  // Create line
  result = await executor.execute(parser.parse('line(A, B)')!);
  print('> line(A, B)');
  print('  ${result.message}\n');

  // Create circle
  result = await executor.execute(parser.parse('circle(A, B)')!);
  print('> circle(A, B)');
  print('  ${result.message}\n');

  // Create midpoint
  result = await executor.execute(parser.parse('midpoint(A, B, M)')!);
  print('> midpoint(A, B, M)');
  print('  ${result.message}\n');

  // List objects
  result = await executor.execute(parser.parse('list')!);
  print('> list');
  print('  ${result.message}\n');

  // Show history
  print('Command history:');
  for (final cmd in executor.history.recentCommands.reversed) {
    print('  - $cmd');
  }
}

/// Demonstrate codec system
void codecDemo() {
  print('Creating construction and serializing to JSON...\n');

  final dag = DAGManager();

  // Create a triangle
  final p1 = GeoPointer(id: 'p1', label: 'A', x: 0, y: 0);
  final p2 = GeoPointer(id: 'p2', label: 'B', x: 10, y: 0);
  final p3 = GeoPointer(id: 'p3', label: 'C', x: 5, y: 8);

  dag.addObject(p1, []);
  dag.addObject(p2, []);
  dag.addObject(p3, []);

  final line1 = GeoLine2P.fromPoints(id: 'l1', label: 'AB', p1: p1, p2: p2);
  final line2 = GeoLine2P.fromPoints(id: 'l2', label: 'BC', p1: p2, p2: p3);
  final line3 = GeoLine2P.fromPoints(id: 'l3', label: 'CA', p1: p3, p2: p1);

  dag.addObject(line1, ['p1', 'p2']);
  dag.addObject(line2, ['p2', 'p3']);
  dag.addObject(line3, ['p3', 'p1']);

  // Encode to JSON
  final codec = GeoDrawCodec();
  final jsonString = codec.encodeToJson(dag, pretty: true);

  print('JSON Output (first 500 chars):');
  print(jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length));
  print('...\n');

  // Decode back
  print('Decoding JSON back to DAG...');
  final restoredDag = codec.decodeFromJson(jsonString);
  print('Restored ${restoredDag.nodeCount} objects successfully!\n');

  // Verify
  print('Verification:');
  print('  Original objects: ${dag.nodeCount}');
  print('  Restored objects: ${restoredDag.nodeCount}');
  print('  Match: ${dag.nodeCount == restoredDag.nodeCount ? "✓" : "✗"}');
}

/// Complete demonstration combining all features
Future<void> completeDemo() async {
  print('Building a triangle with circumcircle...\n');

  final dag = DAGManager();
  final executor = CommandExecutor(dagManager: dag);
  final parser = CommandParser();

  // Create triangle vertices
  await executor.execute(parser.parse('point(0, 0, A)')!);
  await executor.execute(parser.parse('point(10, 0, B)')!);
  await executor.execute(parser.parse('point(5, 8, C)')!);

  // Create triangle sides
  await executor.execute(parser.parse('line(A, B, AB)')!);
  await executor.execute(parser.parse('line(B, C, BC)')!);
  await executor.execute(parser.parse('line(C, A, CA)')!);

  // Create midpoints
  await executor.execute(parser.parse('midpoint(A, B, M1)')!);
  await executor.execute(parser.parse('midpoint(B, C, M2)')!);
  await executor.execute(parser.parse('midpoint(C, A, M3)')!);

  print('Construction completed!\n');

  // Show statistics
  print('Statistics:');
  print('  Total objects: ${dag.nodeCount}');
  print('  Free objects: ${dag.nodes.values.where((n) => n.isFree).length}');
  print('  Dependent objects: ${dag.nodes.values.where((n) => !n.isFree).length}');
  print('  Max depth: ${dag.nodes.values.map((n) => n.depth).reduce((a, b) => a > b ? a : b)}');

  print('\nObject tree:');
  final sorted = dag.topologicalSort();
  for (final node in sorted) {
    final indent = '  ' * node.depth;
    final deps = node.parentIds.isEmpty ? '' : ' (depends on: ${node.parentIds.join(", ")})';
    print('$indent${node.object.label} [${node.object.runtimeType}]$deps');
  }

  // Save construction
  print('\nSaving construction to JSON...');
  final codec = GeoDrawCodec();
  final json = codec.encodeToJson(dag);
  print('Saved! (${json.length} bytes)');

  // Demonstrate history
  print('\nCommand history (last 5):');
  for (final cmd in executor.history.recentCommands.take(5)) {
    print('  - $cmd');
  }

  print('\nDemo complete! ✓');
}
