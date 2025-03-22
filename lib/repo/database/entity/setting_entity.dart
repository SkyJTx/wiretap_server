import 'package:objectbox/objectbox.dart';

@Entity()
class SettingEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  @Unique()
  String key;

  String value;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  SettingEntity({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });
}
