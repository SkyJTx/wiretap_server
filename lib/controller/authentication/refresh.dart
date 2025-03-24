import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/repo/error/error_base.dart';
import 'package:wiretap_server/repo/login/authenication_repo.dart';

Future<Response> refresh(Request req) async {
  late final String bearerRefreshToken;
  try {
    bearerRefreshToken = req.headers['Authorization']!.split(' ')[1];
  } catch (e) {
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid Authorization header',
      code: 'INVALID_AUTHORIZATION_HEADER',
    ).toResponse();
  }

  print(bearerRefreshToken);

  late final String newAccessToken;
  late final String newRefreshToken;
  try {
    [newAccessToken, newRefreshToken] = await AuthenticationRepo().refreshToken(bearerRefreshToken);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to refresh token',
      code: 'FAILED_TO_REFRESH_TOKEN',
    ).toResponse();
  }

  return Response.ok(jsonEncode({'accessToken': newAccessToken, 'refreshToken': newRefreshToken}));
}
