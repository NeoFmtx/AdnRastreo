import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bootstrap/app_services.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/tracker_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _orchestrator = AppServices.instance.orchestrator;
  bool _holding = false;
  double _holdProgress = 0;

  Future<void> _toggleTracking() async {
    if (_orchestrator.isRunning) {
      await _orchestrator.stop();
      await AppServices.instance.setTrackingEnabled(false);
    } else {
      final ok = await _orchestrator.start();
      if (ok) {
        await AppServices.instance.setTrackingEnabled(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo iniciar. Revisa permisos de ubicación y notificaciones.',
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _orchestrator.state;
    final running = _orchestrator.isRunning;
    final prefs = AppServices.instance.prefs;
    final host = prefs.getString(AppConfig.prefHost) ?? AppConfig.defaultHost;
    final channels = <String>[
      if (prefs.getBool(AppConfig.prefHttpEnabled) ?? true) 'HTTP',
      if (prefs.getBool(AppConfig.prefTcpEnabled) ?? false) 'TCP',
      if (prefs.getBool(AppConfig.prefUdpEnabled) ?? false) 'UDP',
    ].join(', ');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AdnRastreo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            _StatusCard(
              state: state,
              running: running,
              deviceId: AppServices.instance.deviceId,
              serverLine: '$host · $channels',
            ),
            if (running)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Notificación activa: el rastreo continúa con pantalla apagada',
                  style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                ),
              ),
            const Spacer(),
            Center(
              child: GestureDetector(
                onLongPressStart: (_) => _startHold(),
                onLongPressEnd: (_) => _cancelHold(),
                onLongPressCancel: _cancelHold,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _holdProgress,
                        strokeWidth: 6,
                        color: Colors.redAccent,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFB71C1C),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mantén 3 segundos para SOS',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _toggleTracking,
              icon: Icon(running ? Icons.stop : Icons.play_arrow),
              label: Text(running ? 'Detener rastreo' : 'Iniciar rastreo'),
            ),
          ],
        ),
      ),
    );
  }

  void _startHold() {
    setState(() {
      _holding = true;
      _holdProgress = 0;
    });
    HapticFeedback.mediumImpact();
    _animateHold();
  }

  Future<void> _animateHold() async {
    const steps = 30;
    for (var i = 1; i <= steps; i++) {
      if (!_holding) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!_holding) return;
      setState(() => _holdProgress = i / steps);
    }
    if (_holding) {
      HapticFeedback.heavyImpact();
      await _orchestrator.sendSos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS enviado')),
        );
      }
      _cancelHold();
    }
  }

  void _cancelHold() {
    if (!_holding) return;
    setState(() {
      _holding = false;
      _holdProgress = 0;
    });
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.running,
    required this.deviceId,
    required this.serverLine,
  });

  final TrackerState state;
  final bool running;
  final String deviceId;
  final String serverLine;

  @override
  Widget build(BuildContext context) {
    final isMoving = state == TrackerState.movimiento;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMoving ? Icons.directions_run : Icons.pause_circle,
                  color: isMoving ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  isMoving ? 'MOVIMIENTO' : 'PARADO',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  running ? Icons.notifications_active : Icons.notifications_off,
                  color: running ? Colors.greenAccent : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('ID: $deviceId', style: const TextStyle(fontSize: 12)),
            Text(
              serverLine,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
