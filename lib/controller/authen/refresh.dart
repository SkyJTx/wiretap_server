import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/token.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/constant/response.dart' as response;

Future<Response> refresh(Request req) async {
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

  late final TokenEntity newToken;
  try {
    newToken = await AuthenRepo().refreshToken(user);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to refresh token',
      code: 'FAILED_TO_REFRESH_TOKEN',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'Login successfully', data: Token.fromEntity(newToken).toMap()).toJson(),
    headers: response.jsonHeader,
  );
}
