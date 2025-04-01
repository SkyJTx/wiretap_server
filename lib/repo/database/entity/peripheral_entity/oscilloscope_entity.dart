import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/constant/oscilloscope/oscilloscope.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/oscilloscope_msg_entity.dart';

@Entity()
class OscilloscopeEntity {
  @Id()
  int id = 0;

  String? ip;

  int? port;

  bool isEnabled;

  int? activeDecodeMode;

  int? activeDecodeFormat;

  @Transient()
  OscilloscopeDecodeMode? get activeDecodeModeEnum {
    if (activeDecodeMode == null) return null;
    return OscilloscopeDecodeMode.values[activeDecodeMode!];
  }

  @Transient()
  OscilloscopeDecodeFormat? get activeDecodeFormatEnum {
    if (activeDecodeFormat == null) return null;
    return OscilloscopeDecodeFormat.values[activeDecodeFormat!];
  }

  @Transient()
  bool get appropriate {
    if (isEnabled) {
      if (ip == null || port == null) return false;
    }
    return true;
  }

  @Transient()
  OscilloscopeDecodeMode? get decodeModeEnum {
    if (activeDecodeMode == null) return null;
    return OscilloscopeDecodeMode.values[activeDecodeMode!];
  }

  @Transient()
  OscilloscopeDecodeFormat? get decodeFormatEnum {
    if (activeDecodeFormat == null) return null;
    return OscilloscopeDecodeFormat.values[activeDecodeFormat!];
  }

  @Backlink('oscilloscopeEntity')
  final oscilloscopeMsgEntities = ToMany<OscilloscopeMsgEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  OscilloscopeEntity({
    this.ip,
    this.port,
    required this.isEnabled,
    this.activeDecodeMode,
    this.activeDecodeFormat,
    required this.createdAt,
    required this.updatedAt,
  });
}
