import '../../core/log/deep_log.dart';
import '../../domain/models/device_imei.dart';
import '../../domain/models/device_protocol.dart';
import '../../domain/models/gps_message.dart';
import '../protocols/encode_context.dart';
import '../protocols/protocol_encoder.dart';
import '../protocols/protocol_registry.dart';
import 'socket_transport.dart';

class TransmitterConfig {
  const TransmitterConfig({
    required this.host,
    required this.port,
    required this.deviceId,
    this.protocol = DeviceProtocol.osmand,
    this.transport = TransportType.tcp,
  });

  final String host;
  final int port;
  final String deviceId;
  final DeviceProtocol protocol;
  final TransportType transport;

  String get normalizedImei => DeviceImei.normalize(deviceId);
}

/// Codifica (protocolo industrial) y envía por TCP o UDP.
class PositionTransmitter {
  PositionTransmitter({
    required TransmitterConfig config,
    SocketTransport? transport,
    DeepLog? log,
  })  : config = config,
        _transport = transport ?? SocketTransport(log: log),
        _log = log ?? DeepLog.instance;

  TransmitterConfig config;
  final SocketTransport _transport;
  final DeepLog _log;
  ProtocolEncoder? _cachedEncoder;
  DeviceProtocol? _cachedProtocol;

  void updateConfig(TransmitterConfig newConfig) {
    config = newConfig;
    if (_cachedProtocol != newConfig.protocol) {
      _cachedEncoder = null;
      _cachedProtocol = null;
    }
  }

  ProtocolEncoder get _encoder {
    if (_cachedEncoder == null || _cachedProtocol != config.protocol) {
      _cachedEncoder = ProtocolRegistry.encoderFor(config.protocol);
      _cachedProtocol = config.protocol;
    }
    return _cachedEncoder!;
  }

  Future<bool> sendPosition({
    required double lat,
    required double lon,
    required DateTime timestamp,
    double? speedKmh,
    double? bearing,
    double? accuracyM,
    bool valid = true,
  }) async {
    if (!config.protocol.implemented) {
      _log.w('Protocolo ${config.protocol.label} no implementado');
      return false;
    }

    final imei = config.normalizedImei;
    if (!DeviceImei.isValid(imei)) {
      _log.e('IMEI/ID inválido: $imei');
      return false;
    }

    try {
      final ctx = EncodeContext(
        message: GpsMessage(
          deviceId: imei,
          lat: lat,
          lon: lon,
          timestamp: timestamp,
          speedKmh: speedKmh,
          bearing: bearing,
          accuracyM: accuracyM,
          valid: valid,
        ),
        host: config.host,
        port: config.port,
        transport: config.transport,
      );
      final payload = _encoder.encode(ctx);
      return _transport.send(
        payload: payload,
        host: config.host,
        port: config.port,
        transport: config.transport,
      );
    } on UnimplementedError catch (e) {
      _log.w('$e');
      return false;
    } catch (e) {
      _log.e('Encode/send: $e');
      return false;
    }
  }

  Future<bool> ping() => _transport.ping(
        host: config.host,
        port: config.port,
        transport: config.transport,
      );
}
