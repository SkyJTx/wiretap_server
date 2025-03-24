import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/repo/error/error_base.dart';
import 'package:wiretap_server/repo/login/authenication_repo.dart';

Future<Response> login(Request req) async {
  late final String body;
  try {
    body = await req.readAsString();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to read request body',
      code: 'FAILED_TO_READ_REQUEST_BODY',
    ).toResponse();
  }

  late final String username;
  late final String password;
  try {
    {'username': username, 'password': password} = jsonDecode(body) as Map<String, dynamic>;
  } catch (e) {
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid request body',
      code: 'INVALID_REQUEST_BODY',
    ).toResponse();
  }

  late final String accessToken;
  late final String refreshToken;
  try {
    [accessToken, refreshToken] = await AuthenticationRepo().login(username, password);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to login',
      code: 'FAILED_TO_LOGIN',
    ).toResponse();
  }

  return Response.ok(jsonEncode({'accessToken': accessToken, 'refreshToken': refreshToken}));
}