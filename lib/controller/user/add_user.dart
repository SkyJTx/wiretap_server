import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/user.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/constant/response.dart' as response;
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
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid request body',
      code: 'INVALID_REQUEST_BODY',
    ).toResponse();
  }

  late final UserEntity user;
  try {
    user = await UserRepo().addUser(username, password, alias: alias, isAdmin: isAdmin ?? false);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to add user',
      code: 'FAILED_TO_ADD_USER',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'User added successfully', data: UserSafe.fromEntity(user).toMap()).toJson(),
    headers: response.jsonHeader,
  );
}
