import 'package:flutter/material.dart';

import '../../core/bootstrap/app_services.dart';
import '../../core/config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceIdCtrl = TextEditingController();
  final _hostCtrl = TextEditingController(text: AppConfig.defaultHost);
  final _httpPortCtrl = TextEditingController(text: '${AppConfig.defaultPort}');
  final _tcpPortCtrl = TextEditingController(text: '${AppConfig.defaultPort}');
  final _udpPortCtrl = TextEditingController(text: '${AppConfig.defaultPort}');
  bool _blackBox = false;
  bool _http = true;
  bool _tcp = false;
  bool _udp = false;
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
    _httpPortCtrl.text = '${prefs.getInt(AppConfig.prefPort) ?? AppConfig.defaultPort}';
    _tcpPortCtrl.text = '${prefs.getInt(AppConfig.prefTcpPort) ?? AppConfig.defaultPort}';
    _udpPortCtrl.text = '${prefs.getInt(AppConfig.prefUdpPort) ?? AppConfig.defaultPort}';
    _blackBox = prefs.getBool(AppConfig.prefBlackBox) ?? false;
    _http = prefs.getBool(AppConfig.prefHttpEnabled) ?? true;
    _tcp = prefs.getBool(AppConfig.prefTcpEnabled) ?? false;
    _udp = prefs.getBool(AppConfig.prefUdpEnabled) ?? false;
    _autoStart = prefs.getBool(AppConfig.prefTracking) ?? false;
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _hostCtrl.dispose();
    _httpPortCtrl.dispose();
    _tcpPortCtrl.dispose();
    _udpPortCtrl.dispose();
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
    if (!_http && !_tcp && !_udp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa al menos un canal: HTTP, TCP o UDP')),
      );
      return;
    }

    await AppServices.instance.saveConnectionSettings(
      host: _hostCtrl.text.trim(),
      httpPort: int.tryParse(_httpPortCtrl.text) ?? AppConfig.defaultPort,
      tcpPort: int.tryParse(_tcpPortCtrl.text) ?? AppConfig.defaultPort,
      udpPort: int.tryParse(_udpPortCtrl.text) ?? AppConfig.defaultPort,
      deviceId: deviceId,
      httpEnabled: _http,
      tcpEnabled: _tcp,
      udpEnabled: _udp,
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
                      hintText: 'Ej. 123456789012345',
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
                    'Servidor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _httpPortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puerto HTTP (OsmAnd)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('HTTP (OsmAnd)'),
                  subtitle: const Text('GET estándar Traccar puerto 5055'),
                  value: _http,
                  onChanged: (v) => setState(() => _http = v),
                ),
                SwitchListTile(
                  title: const Text('TCP'),
                  subtitle: const Text('Mismo paquete GET por socket TCP'),
                  value: _tcp,
                  onChanged: (v) => setState(() => _tcp = v),
                ),
                if (_tcp)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _tcpPortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puerto TCP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('UDP'),
                  subtitle: const Text('Misma query por datagrama UDP'),
                  value: _udp,
                  onChanged: (v) => setState(() => _udp = v),
                ),
                if (_udp)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _udpPortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puerto UDP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Modo Caja Negra'),
            subtitle: const Text('Envía lote al confirmar parada'),
            value: _blackBox,
            onChanged: (v) async {
              await AppServices.instance.setBlackBox(v);
              setState(() => _blackBox = v);
            },
          ),
          SwitchListTile(
            title: const Text('Iniciar rastreo al abrir app'),
            subtitle: const Text('Servicio GPS automático con notificación'),
            value: _autoStart,
            onChanged: (v) => setState(() => _autoStart = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('Guardar configuración'),
          ),
          const SizedBox(height: 24),
          Text(AppConfig.companyName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Versión ${AppConfig.appVersion} · Build ${AppConfig.buildDate}'),
        ],
      ),
    );
  }
}
