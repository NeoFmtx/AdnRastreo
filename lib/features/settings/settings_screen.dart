import 'package:flutter/material.dart';

import '../../core/bootstrap/app_services.dart';
import '../../core/config/app_config.dart';
import '../../domain/models/device_protocol.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceIdCtrl = TextEditingController();
  final _hostCtrl = TextEditingController(text: AppConfig.defaultHost);
  final _portCtrl = TextEditingController(text: '${AppConfig.defaultPort}');
  DeviceProtocol _protocol = DeviceProtocol.osmand;
  TransportType _transport = TransportType.tcp;
  bool _blackBox = false;
  bool _autoStart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final prefs = AppServices.instance.prefs;
    _deviceIdCtrl.text =
        prefs.getString(AppConfig.prefDeviceId) ?? AppServices.instance.deviceId;
    _hostCtrl.text = prefs.getString(AppConfig.prefHost) ?? AppConfig.defaultHost;
    _portCtrl.text = '${prefs.getInt(AppConfig.prefPort) ?? AppConfig.defaultPort}';
    _protocol = DeviceProtocol.fromKey(prefs.getString(AppConfig.prefProtocol));
    _transport = TransportType.fromKey(prefs.getString(AppConfig.prefTransport));
    _blackBox = prefs.getBool(AppConfig.prefBlackBox) ?? false;
    _autoStart = prefs.getBool(AppConfig.prefTracking) ?? false;
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final deviceId = _deviceIdCtrl.text.trim();
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El ID del dispositivo no puede estar vacío')),
      );
      return;
    }

    if (!_protocol.implemented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Protocolo ${_protocol.label} en desarrollo. Elige OsmAnd o TK103/106.',
          ),
        ),
      );
      return;
    }

    await AppServices.instance.saveConnectionSettings(
      host: _hostCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text) ?? AppConfig.defaultPort,
      deviceId: deviceId,
      protocol: _protocol,
      transport: _transport,
    );
    await AppServices.instance.setTrackingEnabled(_autoStart);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dispositivo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deviceIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID (IMEI / Traccar)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protocolo de emulación',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Independiente del transporte (TCP/UDP)',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DeviceProtocol>(
                    initialValue: _protocol,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: DeviceProtocol.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.implemented
                                  ? p.label
                                  : '${p.label} (próximamente)',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _protocol = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transporte',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TransportType>(
                    segments: const [
                      ButtonSegment(
                        value: TransportType.tcp,
                        label: Text('TCP'),
                        icon: Icon(Icons.cable),
                      ),
                      ButtonSegment(
                        value: TransportType.udp,
                        label: Text('UDP'),
                        icon: Icon(Icons.wifi_tethering),
                      ),
                    ],
                    selected: {_transport},
                    onSelectionChanged: (s) =>
                        setState(() => _transport = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Host del servidor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Puerto ${_transport.label}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Modo Caja Negra'),
            value: _blackBox,
            onChanged: (v) async {
              await AppServices.instance.setBlackBox(v);
              setState(() => _blackBox = v);
            },
          ),
          SwitchListTile(
            title: const Text('Iniciar rastreo al abrir app'),
            value: _autoStart,
            onChanged: (v) => setState(() => _autoStart = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('Guardar configuración'),
          ),
          const SizedBox(height: 24),
          const Text(
            AppConfig.companyName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Versión ${AppConfig.appVersion}'),
        ],
      ),
    );
  }
}
