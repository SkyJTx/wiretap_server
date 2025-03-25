import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/constant/response.dart' as response;

Future<Response> logout(Request req) async {
  late final UserEntity user;
  try {
    user = req.context['user'] as UserEntity;
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to get user from request',
      code: 'FAILED_TO_GET_USER_FROM_REQUEST',
    ).toResponse();
  }

  try {
    await AuthenRepo().logout(user.username);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to logout',
      code: 'FAILED_TO_LOGOUT',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'Logout successfully', data: null).toJson(),
    headers: response.jsonHeader,
  );
}
