import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../data/local/track_repository.dart';
import '../../data/remote/position_transmitter.dart';
import '../../domain/models/raw_gps_point.dart';
import '../../domain/models/track_record.dart';
import '../../domain/models/tracker_state.dart';
import '../config/app_config.dart';
import '../geo/geo_engine.dart';
import '../geo/geo_math.dart';
import '../log/deep_log.dart';
import '../queue/queue_supervisor.dart';
import '../tracking/background_tracking_service.dart';

class TrackingOrchestrator {
  TrackingOrchestrator({
    required TrackRepository repository,
    required PositionTransmitter transmitter,
    required QueueSupervisor supervisor,
    GeoEngine? geoEngine,
    DeepLog? log,
  })  : _repository = repository,
        _transmitter = transmitter,
        _supervisor = supervisor,
        _geo = geoEngine ?? GeoEngine(log: log),
        _log = log ?? DeepLog.instance;

  final TrackRepository _repository;
  final PositionTransmitter _transmitter;
  final QueueSupervisor _supervisor;
  final GeoEngine _geo;
  final DeepLog _log;
  final _background = BackgroundTrackingService.instance;

  StreamSubscription<Position>? _positionSub;
  Timer? _transmitTimer;
  Timer? _heartbeatTimer;
  bool _blackBoxMode = false;
  bool _running = false;

  TrackerState get state => _geo.state;
  bool get isRunning => _running;

  void setBlackBoxMode(bool enabled) {
    _blackBoxMode = enabled;
    _log.i('BlackBox mode: $enabled');
  }

  Future<bool> start() async {
    if (_running) return true;

    final bgOk = await _background.start();
    if (!bgOk) return false;

  // Permiso "siempre" recomendado para pantalla apagada
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _log.e('Location permission denied');
      await _background.stop();
      return false;
    }

    _running = true;
    _supervisor.start();
    _scheduleTransmit();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(AppConfig.heartbeatInterval, (_) {
      unawaited(_sendHeartbeat());
    });

    final settings = _background.locationSettings();
    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object e) => _log.e('GPS stream error: $e'),
    );

    _log.i('Tracking started (foreground service)');
    return true;
  }

  Future<void> stop() async {
    _running = false;
    await _positionSub?.cancel();
    _positionSub = null;
    _transmitTimer?.cancel();
    _heartbeatTimer?.cancel();
    _supervisor.stop();
    await _background.stop();
    _log.i('Tracking stopped');
  }

  void _onPosition(Position position) {
    final raw = RawGpsPoint(
      timestamp: position.timestamp,
      lat: position.latitude,
      lon: position.longitude,
      accuracyM: position.accuracy,
      speedMps: position.speed >= 0 ? position.speed : null,
      headingDeg: position.heading >= 0 ? position.heading : null,
    );

    final result = _geo.process(raw);
    if (!result.accepted) return;

    final lat = result.outputLat!;
    final lon = result.outputLon!;
    final speedKmh =
        raw.speedMps != null ? mpsToKmh(raw.speedMps!) : null;

    unawaited(
      _repository.insert(
        timestamp: raw.timestamp,
        lat: lat,
        lon: lon,
        label: result.label,
        sent: false,
        speedKmh: speedKmh,
        accuracyM: raw.accuracyM,
      ),
    );

    _log.d(
      '${result.label} lat=$lat lon=$lon acc=${raw.accuracyM.toStringAsFixed(0)}m',
    );

    if (result.tripEnded && _blackBoxMode) {
      unawaited(_flushBlackBox());
    }

    if (!_blackBoxMode && result.state == TrackerState.movimiento) {
      unawaited(_transmitLatest());
    }
  }

  void _scheduleTransmit() {
    _transmitTimer?.cancel();
    final interval = _geo.state == TrackerState.movimiento
        ? AppConfig.moveInterval
        : AppConfig.restInterval;
    _transmitTimer = Timer(interval, () async {
      if (!_running) return;
      if (!_blackBoxMode) {
        final pending = await _repository.getPending();
        if (pending.isNotEmpty) {
          await _transmitRecord(pending.last);
        }
      }
      _scheduleTransmit();
    });
  }

  Future<void> _transmitLatest() async {
    final pending = await _repository.getPending();
    if (pending.isEmpty) return;
    await _transmitRecord(pending.last);
  }

  Future<void> _transmitRecord(TrackRecord record) async {
    final ok = await _transmitter.sendPosition(
      lat: record.lat,
      lon: record.lon,
      timestamp: record.timestamp,
      speedKmh: record.speedKmh,
      accuracyM: record.accuracyM,
    );
    if (ok) {
      await _repository.markSent(record.id);
      _log.i('RT sent #${record.id}');
    } else {
      _log.w('RT failed #${record.id}, queued red');
    }
  }

  Future<void> _flushBlackBox() async {
    _log.i('BlackBox: flushing batch on trip end');
    await _supervisor.drainQueue();
  }

  Future<void> _sendHeartbeat() async {
    if (_geo.anchorLat == null || _geo.anchorLon == null) return;
    final ok = await _transmitter.sendPosition(
      lat: _geo.anchorLat!,
      lon: _geo.anchorLon!,
      timestamp: DateTime.now(),
      valid: true,
    );
    _log.i('Heartbeat ${ok ? "OK" : "FAIL"}');
  }

  Future<void> sendSos() async {
    final pos = await Geolocator.getCurrentPosition();
    final ok = await _transmitter.sendPosition(
      lat: pos.latitude,
      lon: pos.longitude,
      timestamp: DateTime.now(),
      speedKmh: pos.speed >= 0 ? mpsToKmh(pos.speed) : null,
      accuracyM: pos.accuracy,
    );
    _log.i('SOS ${ok ? "sent" : "failed"}');
  }
}
