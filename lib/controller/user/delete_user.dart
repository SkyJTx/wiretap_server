import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/response.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/user/user_repo.dart';

Future<Response> deleteUserById(Request req) async {
  late final UserEntity requester;
  late final int id;

  try {
    requester = req.context['user'] as UserEntity;
    id = int.parse(req.params['id']!);
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to get user from request',
      code: 'FAILED_TO_GET_USER_FROM_REQUEST',
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
  late final int userCount;
  try {
    adminCount = await UserRepo().getUserCount(UserEntity_.isAdmin.equals(true));
    userCount = await UserRepo().getUserCount();
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to get user count',
      code: 'FAILED_TO_GET_USER_COUNT',
    ).toResponse();
  }

  if (adminCount < 2 && requester.isAdmin) {
    return ErrorBase(
      statusCode: 403,
      message: 'Must have a remaining admin',
      code: 'CANNOT_REMOVE_LAST_ADMIN',
    ).toResponse();
  }

  if (userCount < 2) {
    return ErrorBase(
      statusCode: 403,
      message: 'Must have a remaining user',
      code: 'CANNOT_REMOVE_LAST_USER',
    ).toResponse();
  }

  try {
    await UserRepo().deleteUserById(id);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to delete user',
      code: 'FAILED_TO_DELETE_USER',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'User deleted', data: null).toJson(),
    headers: jsonHeader,
  );
}
