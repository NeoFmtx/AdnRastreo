import 'dart:async';

import '../../data/local/track_repository.dart';
import '../../data/remote/position_transmitter.dart';
import '../config/app_config.dart';
import '../log/deep_log.dart';

class QueueSupervisor {
  QueueSupervisor({
    required TrackRepository repository,
    required PositionTransmitter transmitter,
    DeepLog? log,
  })  : _repository = repository,
        _transmitter = transmitter,
        _log = log ?? DeepLog.instance;

  final TrackRepository _repository;
  final PositionTransmitter _transmitter;
  final DeepLog _log;
  Timer? _timer;
  bool _draining = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConfig.queueSupervisorInterval, (_) {
      unawaited(_tick());
    });
    _log.i('Queue supervisor started (30s interval)');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    final pending = await _repository.pendingCount();
    if (pending == 0) return;
    _log.d('Queue: $pending pending records');
    final reachable = await _transmitter.ping();
    if (!reachable) {
      _log.w('Server unreachable, keeping queue');
      return;
    }
    await drainQueue();
  }

  Future<int> drainQueue() async {
    if (_draining) return 0;
    _draining = true;
    var sent = 0;
    try {
      final pending = await _repository.getPending();
      for (final record in pending) {
        final ok = await _transmitter.sendPosition(
          lat: record.lat,
          lon: record.lon,
          timestamp: record.timestamp,
          speedKmh: record.speedKmh,
          accuracyM: record.accuracyM,
        );
        if (!ok) {
          _log.w('ACK failed for record #${record.id}');
          break;
        }
        await _repository.markSent(record.id);
        sent++;
        _log.i('ACK record #${record.id} sent');
      }
    } finally {
      _draining = false;
    }
    return sent;
  }
}
