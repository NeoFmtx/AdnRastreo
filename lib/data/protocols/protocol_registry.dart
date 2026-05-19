import '../../domain/models/device_protocol.dart';
import 'concox_encoder.dart';
import 'gnss_encoder.dart';
import 'osmand_encoder.dart';
import 'protocol_encoder.dart';
import 'teltonika_encoder.dart';
import 'tk103_encoder.dart';
import 'tk106_encoder.dart';

class ProtocolRegistry {
  static ProtocolEncoder encoderFor(DeviceProtocol protocol) {
    switch (protocol) {
      case DeviceProtocol.osmand:
        return OsmandEncoder();
      case DeviceProtocol.tk103:
        return Tk103Encoder();
      case DeviceProtocol.tk106:
        return Tk106Encoder();
      case DeviceProtocol.concox:
        return ConcoxEncoder();
      case DeviceProtocol.gnss:
        return GnssEncoder();
      case DeviceProtocol.teltonika:
        return TeltonikaEncoder();
    }
  }
}
