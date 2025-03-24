import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';

@Entity()
class UserEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  @Unique()
  String username;

  String password;

  ToOne<TokenEntity> token = ToOne<TokenEntity>();

  String? alias;

  bool isAdmin;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime? lastLoginAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  UserEntity({
    required this.username,
    required this.password,
    this.alias,
    this.isAdmin = false,
    required this.createdAt,
    this.lastLoginAt,
    required this.updatedAt,
  });
}
