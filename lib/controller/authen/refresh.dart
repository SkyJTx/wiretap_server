import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/token.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/constant/constant.dart';

Future<Response> refresh(Request req) async {
  late final UserEntity user;
  try {
    user = req.context['user'] as UserEntity;
  } catch (e) {
    return failedToGetUserFromRequest;
  }

  late final TokenEntity newToken;
  try {
    newToken = await AuthenRepo().refreshToken(user);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to refresh token');
  }

  return Response.ok(
    Data(message: 'Login successfully', data: Token.fromEntity(newToken).toMap()).toJson(),
    headers: jsonHeader,
  );
}
