import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/i2c_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/modbus_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/oscilloscope_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/spi_entity.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/log_entity.dart';

@Entity()
class SessionEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  @Unique()
  String name;

  bool isRunning;

  @Backlink('sessionEntity')
  final logs = ToMany<LogEntity>();

  final i2c = ToOne<I2cEntity>();

  final spi = ToOne<SpiEntity>();

  final modbus = ToOne<ModbusEntity>();

  final oscilloscope = ToOne<OscilloscopeEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  @Property(type: PropertyType.dateNano)
  DateTime? lastUsedAt;

  @Property(type: PropertyType.dateNano)
  DateTime? stoppedAt;

  @Property(type: PropertyType.dateNano)
  DateTime? startedAt;

  SessionEntity({
    required this.name,
    required this.isRunning,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.stoppedAt,
    this.startedAt,
  });
}
