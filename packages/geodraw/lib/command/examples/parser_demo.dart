/// Demo showing CommandParser now outputs ToolType directly
library;

import '../../dag/dag_manager.dart';
import '../command_parser.dart';

void main() {
  final dag = DAGManager();
  final parser = CommandParser(dag);

  print('=== CommandParser with ToolType Demo ===\n');

  // Test various commands
  final testCommands = [
    'point(0, 0)',
    'line(A, B)',
    'circle(center, radius)',
    'perp(line1, point1)', // Alias
    'para(line1, point1)', // Alias
    'perpbis(A, B)', // Alias
    'mid(A, B)', // Alias
    'intersection(line1, line2)',
    'invalidcommand(x, y)', // Should have null toolType
  ];

  for (final cmdString in testCommands) {
    final command = parser.parse(cmdString);

    if (command == null) {
      print('❌ Failed to parse: $cmdString');
      continue;
    }

    print('Input:    "$cmdString"');
    print('Name:     ${command.name}');
    print('ToolType: ${command.toolType}');
    print('Args:     ${command.arguments}');

    if (command.toolType == null) {
      print('⚠️  Unknown command - will be rejected by adapter');
    } else {
      print('✓  Valid command - ready for execution');
    }
    print('');
  }

  // Show the benefit
  print('=== Benefits ===');
  print('✓ Parser validates command names immediately');
  print('✓ CLIAdapter gets ToolType directly (no redundant mapping)');
  print('✓ Invalid commands caught early with better error messages');
  print('✓ Type safety with enum instead of strings');
}
