import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/constant/constant.dart';

Future<Response> logout(Request req) async {
  late final UserEntity user;
  try {
    user = req.context['user'] as UserEntity;
  } catch (e) {
    return failedToGetUserFromRequest;
  }

  try {
    await AuthenRepo().logout(user.username);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to logout');
  }

  return Response.ok(
    Data(message: 'Logout successfully', data: null).toJson(),
    headers: jsonHeader,
  );
}
