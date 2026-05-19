import 'encode_context.dart';

/// Codifica posición al formato del fabricante para envío TCP/UDP.
abstract class ProtocolEncoder {
  String get protocolName;

  List<int> encode(EncodeContext context);
}
