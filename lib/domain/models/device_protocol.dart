/// Protocolos de hardware emulados (independientes del transporte).
enum DeviceProtocol {
  osmand('OsmAnd', true),
  tk103('TK103', true),
  tk106('TK106', true),
  concox('Concox', false),
  gnss('GNSS', false),
  teltonika('Teltonika', false);

  const DeviceProtocol(this.label, this.implemented);

  final String label;
  final bool implemented;

  static DeviceProtocol fromKey(String? key) {
    return DeviceProtocol.values.firstWhere(
      (p) => p.name == key,
      orElse: () => DeviceProtocol.osmand,
    );
  }
}

/// Capa de transporte: el usuario elige TCP o UDP (no HTTP).
enum TransportType {
  tcp('TCP'),
  udp('UDP');

  const TransportType(this.label);
  final String label;

  static TransportType fromKey(String? key) {
    return TransportType.values.firstWhere(
      (t) => t.name == key,
      orElse: () => TransportType.tcp,
    );
  }
}
