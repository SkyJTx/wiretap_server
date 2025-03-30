import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/modbus_msg_entity.dart';

@Entity()
class ModbusEntity {
  @Id()
  int id = 0;

  bool isEnabled;

  @Backlink('modbusEntity')
  final modbusMsgEntities = ToMany<ModbusMsgEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  ModbusEntity({
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
}
