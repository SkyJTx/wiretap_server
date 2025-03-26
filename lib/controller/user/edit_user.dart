import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
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
    return badRequest;
  }

  if (requester.id != id && !requester.isAdmin) {
    return permissionDenied;
  }

  late final int adminCount;
  try {
    adminCount = await UserRepo().getUserCount(UserEntity_.isAdmin.equals(true));
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get user count');
  }

  if (adminCount < 2 && isAdmin == false) {
    return ErrorType.stateRequirementAreNotMet.toResponse('Must have a remaining admin');
  }

  late final UserEntity user;
  try {
    user = await UserRepo().editUser(id, username: username, alias: alias, isAdmin: isAdmin);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to edit user');
  }

  return Response.ok(
    Data(message: 'User edited successfully', data: UserSafe.fromEntity(user).toMap()).toJson(),
    headers: jsonHeader,
  );
}
