import '../../domain/models/gps_message.dart';
import 'protocol_encoder.dart';

/// Marcador para protocolos en desarrollo.
class UnimplementedEncoder implements ProtocolEncoder {
  UnimplementedEncoder(this._name);

  final String _name;

  @override
  String get protocolName => _name;

  @override
  List<int> encode(GpsMessage message) {
    throw UnimplementedError('Protocolo $_name en desarrollo');
  }
}
