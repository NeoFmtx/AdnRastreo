import 'encode_context.dart';
import 'protocol_encoder.dart';

class UnimplementedEncoder implements ProtocolEncoder {
  UnimplementedEncoder(this._name);

  final String _name;

  @override
  String get protocolName => _name;

  @override
  List<int> encode(EncodeContext context) {
    throw UnimplementedError('Protocolo $_name en desarrollo');
  }
}
