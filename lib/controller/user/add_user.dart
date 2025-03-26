import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/user.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/repo/user/user_repo.dart';

Future<Response> addUser(Request req) async {
  late final String username;
  late final String password;
  String? alias;
  bool? isAdmin;
  try {
    final body = jsonDecode(await req.readAsString());
    username = body['username'] as String;
    password = body['password'] as String;
    alias = body['alias'] as String?;
    isAdmin = body['isAdmin'] as bool?;
  } catch (e) {
    return badRequest;
  }

  late final UserEntity user;
  try {
    user = await UserRepo().addUser(username, password, alias: alias, isAdmin: isAdmin ?? false);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to add user');
  }

  return Response.ok(
    Data(message: 'User added successfully', data: UserSafe.fromEntity(user).toMap()).toJson(),
    headers: jsonHeader,
  );
}
