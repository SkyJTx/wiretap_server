import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/modbus_entity.dart';

@Entity()
class ModbusMsgEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  int address;

  int functionCode;

  int startingAddress;

  int quantity;

  int dataLength;

  String data;

  int queryCRC;

  int responseCRC;

  final modbusEntity = ToOne<ModbusEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  ModbusMsgEntity({
    required this.address,
    required this.functionCode,
    required this.startingAddress,
    required this.quantity,
    required this.dataLength,
    required this.data,
    required this.queryCRC,
    required this.responseCRC,
    required this.createdAt,
  });
}
