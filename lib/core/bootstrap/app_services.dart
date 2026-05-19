import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../../data/local/track_repository.dart';
import '../../data/remote/position_transmitter.dart';
import '../../domain/models/device_imei.dart';
import '../../domain/models/device_protocol.dart';
import '../config/app_config.dart';
import '../queue/queue_supervisor.dart';
import '../transmission/tracking_orchestrator.dart';

class AppServices {
  AppServices._({
    required this.repository,
    required this.transmitter,
    required this.supervisor,
    required this.orchestrator,
    required this.prefs,
  });

  final TrackRepository repository;
  final PositionTransmitter transmitter;
  final QueueSupervisor supervisor;
  final TrackingOrchestrator orchestrator;
  final SharedPreferences prefs;

  static AppServices? _instance;
  static AppServices get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('AppServices not initialized');
    }
    return i;
  }

  static Future<AppServices> init() async {
    if (_instance != null) return _instance!;

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPrefs(prefs);

    var deviceId = prefs.getString(AppConfig.prefDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4().replaceAll('-', '').substring(0, 15);
      await prefs.setString(AppConfig.prefDeviceId, deviceId);
    }

    final transmitter = PositionTransmitter(config: _loadConfig(prefs));
    final db = await AppDatabase.open();
    final repository = TrackRepository(db);
    final supervisor = QueueSupervisor(
      repository: repository,
      transmitter: transmitter,
    );
    final orchestrator = TrackingOrchestrator(
      repository: repository,
      transmitter: transmitter,
      supervisor: supervisor,
    );

    orchestrator.setBlackBoxMode(prefs.getBool(AppConfig.prefBlackBox) ?? false);

    _instance = AppServices._(
      repository: repository,
      transmitter: transmitter,
      supervisor: supervisor,
      orchestrator: orchestrator,
      prefs: prefs,
    );
    return _instance!;
  }

  static Future<void> _migrateLegacyPrefs(SharedPreferences prefs) async {
    if (prefs.containsKey(AppConfig.prefProtocol)) return;

    final transport = (prefs.getBool(AppConfig.prefUdpEnabled) ?? false)
        ? TransportType.udp
        : TransportType.tcp;
    final port = prefs.getInt(AppConfig.prefTcpPort) ??
        prefs.getInt(AppConfig.prefUdpPort) ??
        prefs.getInt(AppConfig.prefPort) ??
        AppConfig.defaultPort;

    await prefs.setString(AppConfig.prefProtocol, DeviceProtocol.osmand.name);
    await prefs.setString(AppConfig.prefTransport, transport.name);
    await prefs.setInt(AppConfig.prefPort, port);
  }

  static TransmitterConfig _loadConfig(SharedPreferences prefs) =>
      TransmitterConfig(
        host: prefs.getString(AppConfig.prefHost) ?? AppConfig.defaultHost,
        port: prefs.getInt(AppConfig.prefPort) ?? AppConfig.defaultPort,
        deviceId: prefs.getString(AppConfig.prefDeviceId) ?? '',
        protocol: DeviceProtocol.fromKey(prefs.getString(AppConfig.prefProtocol)),
        transport: TransportType.fromKey(prefs.getString(AppConfig.prefTransport)),
      );

  void reloadTransmitter() {
    transmitter.updateConfig(_loadConfig(prefs));
  }

  String get deviceId =>
      prefs.getString(AppConfig.prefDeviceId) ?? 'unknown';

  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String deviceId,
    required DeviceProtocol protocol,
    required TransportType transport,
  }) async {
    await prefs.setString(AppConfig.prefHost, host);
    await prefs.setInt(AppConfig.prefPort, port);
    final imei = DeviceImei.normalize(deviceId);
    await prefs.setString(AppConfig.prefDeviceId, imei);
    await prefs.setString(AppConfig.prefProtocol, protocol.name);
    await prefs.setString(AppConfig.prefTransport, transport.name);
    reloadTransmitter();
  }

  Future<void> setBlackBox(bool value) async {
    await prefs.setBool(AppConfig.prefBlackBox, value);
    orchestrator.setBlackBoxMode(value);
  }

  Future<void> setTrackingEnabled(bool value) async {
    await prefs.setBool(AppConfig.prefTracking, value);
  }

  bool get trackingEnabled => prefs.getBool(AppConfig.prefTracking) ?? false;
}
