import 'package:objectbox/objectbox.dart';

@Entity()
class UserEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  @Unique()
  String username;

  String password;
  String? alias;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  UserEntity({
    required this.username,
    required this.password,
    this.alias,
    required this.createdAt,
    required this.updatedAt,
  });
}
