/// JSON codec for encoding and decoding geometric constructions
library;

export 'encoder.dart';
export 'decoder.dart';

import 'encoder.dart';
import 'decoder.dart';
import '../core/dag/dag_manager.dart';

/// Main codec class combining encoder and decoder
class GeoDrawCodec {
  final GeoDrawEncoder encoder;
  final GeoDrawDecoder decoder;

  GeoDrawCodec()
      : encoder = GeoDrawEncoder(),
        decoder = GeoDrawDecoder();

  /// Encode DAG to JSON map
  Map<String, dynamic> encode(DAGManager dag) => encoder.encode(dag);

  /// Encode DAG to JSON string
  String encodeToJson(DAGManager dag, {bool pretty = true}) =>
      encoder.encodeToJson(dag, pretty: pretty);

  /// Decode JSON map to DAG
  DAGManager decode(Map<String, dynamic> json) => decoder.decode(json);

  /// Decode JSON string to DAG
  DAGManager decodeFromJson(String jsonString) =>
      decoder.decodeFromJson(jsonString);

  /// Test round-trip encoding/decoding
  bool testRoundTrip(DAGManager original) {
    try {
      final json = encodeToJson(original);
      final restored = decodeFromJson(json);
      return original.nodeCount == restored.nodeCount;
    } catch (e) {
      return false;
    }
  }
}
