
import 'package:objectbox/objectbox.dart';

@Entity()
class TokenEntity {
  @Id()
  int id = 0;

  @Index(type: IndexType.value)
  @Unique()
  String accessToken;

  @Index(type: IndexType.value)
  @Unique()
  String refreshToken;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  TokenEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
    required this.updatedAt,
  });
}