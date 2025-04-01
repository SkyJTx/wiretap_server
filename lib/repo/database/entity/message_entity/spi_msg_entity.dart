import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/spi_entity.dart';

@Entity()
class SpiMsgEntity {
  @Id()
  int id = 0;

  String mosi;

  String miso;

  final spiEntity = ToOne<SpiEntity>();

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  SpiMsgEntity({
    required this.mosi,
    required this.miso,
    required this.createdAt,
  });

  toMap() {}
}
