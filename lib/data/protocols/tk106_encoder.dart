import '../../domain/models/gps_message.dart';
import 'protocol_encoder.dart';
import 'tk103_encoder.dart';

/// TK106 compatible con formato texto similar a TK103.
class Tk106Encoder implements ProtocolEncoder {
  final _delegate = Tk103Encoder();

  @override
  String get protocolName => 'TK106';

  @override
  List<int> encode(GpsMessage message) => _delegate.encode(message);
}
