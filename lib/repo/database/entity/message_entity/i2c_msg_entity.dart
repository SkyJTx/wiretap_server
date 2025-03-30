import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/i2c_entity.dart';

@Entity()
class I2cMsgEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  int address;

  bool isTenBitAddressing;

  bool isWriteMode;

  String data;

  final i2cEntity = ToOne<I2cEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  I2cMsgEntity({
    required this.address,
    required this.isTenBitAddressing,
    required this.isWriteMode,
    required this.data,
    required this.createdAt,
  });
}
