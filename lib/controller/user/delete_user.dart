import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
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
    return ErrorType.internalServerError.toResponse('Failed to get user from request');
  }

  if (requester.id != id && !requester.isAdmin) {
    return permissionDenied;
  }

  late final int adminCount;
  late final int userCount;
  try {
    adminCount = await UserRepo().getUserCount(UserEntity_.isAdmin.equals(true));
    userCount = await UserRepo().getUserCount();
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get user count');
  }

  if (adminCount < 2 && requester.isAdmin) {
    return ErrorType.stateRequirementAreNotMet.toResponse('Must have a remaining admin');
  }

  if (userCount < 2) {
    return ErrorType.stateRequirementAreNotMet.toResponse('Cannot remove last user');
  }

  try {
    await UserRepo().deleteUserById(id);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to delete user');
  }

  return Response.ok(Data(message: 'User deleted', data: null).toJson(), headers: jsonHeader);
}
