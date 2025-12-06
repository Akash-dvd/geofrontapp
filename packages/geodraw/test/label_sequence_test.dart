import 'package:flutter_test/flutter_test.dart';
import 'package:geodraw/geodraw.dart';
import 'package:geodraw/core/label_manager.dart';

void main() {
  group('Label Sequence Tests', () {
    test('lowercase labels follow correct sequence: a-z, then aa-az, ba-bz, etc.', () {
      final dag = DAGManager();
      
      // Create 30 objects to exhaust single letters and start double letters
      final labels = <String>[];
      for (int i = 0; i < 30; i++) {
        final label = LabelManager.getNextAvailableLabel(
          dag,
          GeometryObjectType.line,
        );
        labels.add(label);
        
        // Create a dummy object with this label to mark it as used
        final point = GeoPointer(
          id: label,
          label: label,
          x: i.toDouble(),
          y: i.toDouble(),
        );
        dag.addObject(point, []);
      }
      
      // First 26 should be single letters a-z
      expect(labels[0], equals('a'));
      expect(labels[25], equals('z'));
      
      // Next should be double letters starting with 'a'
      expect(labels[26], equals('aa'));
      expect(labels[27], equals('ab'));
      expect(labels[28], equals('ac'));
      expect(labels[29], equals('ad'));
      
      // Verify no triple letters yet
      for (final label in labels) {
        expect(label.length, lessThanOrEqualTo(2), 
          reason: 'Label $label should not be triple letter yet');
      }
    });
    
    test('lowercase labels continue correctly through all double letters', () {
      final dag = DAGManager();
      
      // Create enough objects to go through all single and double letters
      final labels = <String>[];
      for (int i = 0; i < 100; i++) {
        final label = LabelManager.getNextAvailableLabel(
          dag,
          GeometryObjectType.line,
        );
        labels.add(label);
        
        // Create a dummy object with this label to mark it as used
        final point = GeoPointer(
          id: label,
          label: label,
          x: i.toDouble(),
          y: i.toDouble(),
        );
        dag.addObject(point, []);
      }
      
      // Verify sequence: a-z (26), then aa-az (26), then ba-bz (26), then ca-cz (26)
      expect(labels[0], equals('a'));
      expect(labels[25], equals('z'));
      expect(labels[26], equals('aa'));
      expect(labels[51], equals('az'));  // 26 single + 26 double starting with 'a'
      expect(labels[52], equals('ba'));  // Should start with 'b'
      expect(labels[77], equals('bz'));  // 26 single + 26 double 'a' + 26 double 'b'
      expect(labels[78], equals('ca'));  // Should start with 'c'
      
      // Verify no triple letters until all double letters are exhausted
      for (int i = 0; i < 26 + 26 * 26; i++) {
        if (i < labels.length) {
          expect(labels[i].length, lessThanOrEqualTo(2),
            reason: 'Label ${labels[i]} at index $i should not be triple letter');
        }
      }
    });
  });
}

