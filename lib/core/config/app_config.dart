class AppConfig {
  static const String companyName = 'Onecore Software Ltd.';
  static const String appVersion = '1.0.2';
  static const String buildDate = '2026-05-19';

  static const String defaultHost = 'adnvycom.servehttp.com';
  static const int defaultPort = 5055;

  static const Duration moveInterval = Duration(seconds: 20);
  static const Duration restInterval = Duration(hours: 1);
  static const Duration queueSupervisorInterval = Duration(seconds: 30);
  static const Duration heartbeatInterval = Duration(hours: 1);

  static const String prefDeviceId = 'device_id';
  static const String prefHost = 'server_host';
  static const String prefPort = 'server_port';
  static const String prefProtocol = 'device_protocol';
  static const String prefTransport = 'transport_type';
  static const String prefBlackBox = 'blackbox_mode';
  static const String prefTracking = 'tracking_enabled';

  // Legacy (migración desde versión HTTP)
  static const String prefHttpEnabled = 'http_enabled';
  static const String prefTcpEnabled = 'tcp_enabled';
  static const String prefUdpEnabled = 'udp_enabled';
  static const String prefTcpPort = 'tcp_port';
  static const String prefUdpPort = 'udp_port';
}
