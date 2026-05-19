import 'encode_context.dart';
import 'protocol_encoder.dart';
import 'traccar_framing.dart';

/// OsmAnd en Traccar: parámetros id/lat/lon/timestamp; sobre TCP va enmarcado en HTTP GET.
class OsmandEncoder implements ProtocolEncoder {
  @override
  String get protocolName => 'OsmAnd';

  @override
  List<int> encode(EncodeContext context) =>
      TraccarFraming.encodeOsmandForTraccar(context);
}
