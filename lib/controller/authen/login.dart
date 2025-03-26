import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/token.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';

Future<Response> login(Request req) async {
  late final String body;
  try {
    body = await req.readAsString();
  } catch (e) {
    return failedToGetUserFromRequest;
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

  late final TokenEntity token;
  try {
    token = await AuthenRepo().login(username, password);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to login',
      code: 'FAILED_TO_LOGIN',
    ).toResponse();
  }

  return Response.ok(
    Data(message: 'Login successfully', data: Token.fromEntity(token).toMap()).toJson(),
    headers: jsonHeader,
  );
}
