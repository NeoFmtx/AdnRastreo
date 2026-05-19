import 'encode_context.dart';
import 'protocol_encoder.dart';
import 'tk103_encoder.dart';

class Tk106Encoder implements ProtocolEncoder {
  final _tk103 = Tk103Encoder();

  @override
  String get protocolName => 'TK106';

  @override
  List<int> encode(EncodeContext context) => _tk103.encode(context);
}
