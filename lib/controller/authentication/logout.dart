import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/repo/error/error_base.dart';
import 'package:wiretap_server/repo/login/authenication_repo.dart';

Future<Response> logout(Request req) async {
  late final String bearerAccessToken;
  try {
    bearerAccessToken = req.headers['Authorization']!.split(' ')[1];
  } catch (e) {
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid Authorization header',
      code: 'INVALID_AUTHORIZATION_HEADER',
    ).toResponse();
  }

  print(bearerAccessToken);

  late final String username;
  try {
    {'username': username} = AuthenticationRepo().decodeAccessToken(bearerAccessToken);
  } catch (e) {
    return ErrorBase(
      statusCode: 401,
      message: 'Invalid access token',
      code: 'INVALID_ACCESS_TOKEN',
    ).toResponse();
  }

  try {
    await AuthenticationRepo().logout(username);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to logout',
      code: 'FAILED_TO_LOGOUT',
    ).toResponse();
  }

  return Response.ok(jsonEncode({'message': 'Logged out'}));
}
