import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/constant/oscilloscope/oscilloscope.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/oscilloscope_entity.dart';

@Entity()
class OscilloscopeMsgEntity {
  @Id()
  int id = 0;

  bool isDecodeEnabled;

  int? decodeMode;

  int? decodeFormat;

  @Transient()
  OscilloscopeDecodeMode? get decodeModeEnum {
    if (decodeMode == null) return null;
    return OscilloscopeDecodeMode.values[decodeMode!];
  }

  @Transient()
  OscilloscopeDecodeFormat? get decodeFormatEnum {
    if (decodeFormat == null) return null;
    return OscilloscopeDecodeFormat.values[decodeFormat!];
  }

  String imageFilePath;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  final oscilloscopeEntity = ToOne<OscilloscopeEntity>();

  OscilloscopeMsgEntity({
    required this.isDecodeEnabled,
    required this.decodeMode,
    required this.decodeFormat,
    required this.imageFilePath,
    required this.createdAt,
  });
}
