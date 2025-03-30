import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';

@Entity()
class LogEntity {
  @Id()
  int id = 0;

  @Index()
  String protocol;

  String data;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  final sessionEntity = ToOne<SessionEntity>();

  LogEntity({
    required this.protocol,
    required this.data,
    required this.createdAt,
  });
}
