import 'package:objectbox/objectbox.dart';

@Entity()
class LoginEntity {
  @Id(assignable: true)
  int id = 0;

  String username;
  String password;

  LoginEntity({required this.username, required this.password});
}
