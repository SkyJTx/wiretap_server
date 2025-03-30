import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/spi_msg_entity.dart';

@Entity()
class SpiEntity {
  @Id()
  int id = 0;

  bool isEnabled;

  @Backlink('spiEntity')
  final spiMsgEntities = ToMany<SpiMsgEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  SpiEntity({
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
}