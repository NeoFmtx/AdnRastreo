/// IMEI / uniqueId compatible con Traccar y protocolos industriales.
class DeviceImei {
  DeviceImei._();

  /// Solo dígitos (15 típico). Si el usuario usa ID alfanumérico, se conserva limpio.
  static String normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10 && digitsOnly.length <= 20) {
      return digitsOnly;
    }
    return trimmed.replaceAll(RegExp(r'[^\w\-]'), '');
  }

  static bool isValid(String imei) {
    final n = normalize(imei);
    if (n.isEmpty) return false;
    if (RegExp(r'^\d{10,20}$').hasMatch(n)) return true;
    return n.length >= 3;
  }
}
