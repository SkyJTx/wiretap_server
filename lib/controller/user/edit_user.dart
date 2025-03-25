import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/response.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/user.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/user/user_repo.dart';

Future<Response> editUser(Request req) async {
  late final UserEntity requester;
  late final int id;
  String? username;
  String? alias;
  bool? isAdmin;

  try {
    requester = req.context['user'] as UserEntity;
    final body = jsonDecode(await req.readAsString());
    id = int.parse(req.params['id']!);
    username = body['username'] as String?;
    alias = body['alias'] as String?;
    isAdmin = body['isAdmin'] as bool?;
  } catch (e) {
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid request body',
      code: 'INVALID_REQUEST_BODY',
    ).toResponse();
  }

  if (requester.id != id && !requester.isAdmin) {
    return ErrorBase(
      statusCode: 403,
      message: 'Permission denied',
      code: 'PERMISSION_DENIED',
    ).toResponse();
  }

  late final int adminCount;
  try {
    adminCount = await UserRepo().getUserCount(UserEntity_.isAdmin.equals(true));
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to get admin count',
      code: 'FAILED_TO_GET_ADMIN_COUNT',
    ).toResponse();
  }

  if (adminCount < 2 && isAdmin == false) {
    return ErrorBase(
      statusCode: 403,
      message: 'Must have a remaining admin',
      code: 'CANNOT_REMOVE_LAST_ADMIN',
    ).toResponse();
  }

  late final UserEntity user;
  try {
    user = await UserRepo().editUser(id, username: username, alias: alias, isAdmin: isAdmin);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to edit user',
      code: 'FAILED_TO_EDIT_USER',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'User edited successfully', data: UserSafe.fromEntity(user).toMap()).toJson(),
    headers: jsonHeader,
  );
}
