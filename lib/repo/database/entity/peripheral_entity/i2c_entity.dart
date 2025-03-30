import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/i2c_msg_entity.dart';

@Entity()
class I2cEntity {
  @Id()
  int id = 0;

  bool isEnabled;

  @Backlink('i2cEntity')
  final i2cMsgEntities = ToMany<I2cMsgEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  I2cEntity({
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
}
