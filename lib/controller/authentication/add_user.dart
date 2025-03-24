import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/error/error_base.dart';
import 'package:wiretap_server/repo/login/authenication_repo.dart';

Future<Response> addUser(Request req) async {
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

  late final String requesterUsername;
  try {
    {'username': requesterUsername} = AuthenticationRepo().decodeAccessToken(bearerAccessToken);
  } catch (e) {
    return ErrorBase(
      statusCode: 401,
      message: 'Invalid access token',
      code: 'INVALID_ACCESS_TOKEN',
    ).toResponse();
  }

  late final bool requesterIsAdmin;
  try {
    requesterIsAdmin = await AuthenticationRepo().isAdmin(requesterUsername);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to check if requester is admin',
      code: 'FAILED_TO_CHECK_IF_REQUESTER_IS_ADMIN',
    ).toResponse();
  }

  if (!requesterIsAdmin) {
    return ErrorBase(
      statusCode: 403,
      message: 'Requester is not an admin',
      code: 'REQUESTER_NOT_ADMIN',
    ).toResponse();
  }

  late final String username;
  late final String password;
  String? alias;
  bool? isAdmin;
  try {
    final body = jsonDecode(
      await req.readAsString(),
    );
    username = body['username'] as String;
    password = body['password'] as String;
    alias = body['alias'] as String?;
    isAdmin = body['isAdmin'] as bool?;
  } catch (e, s) {
    print('$e\n$s');
    return ErrorBase(
      statusCode: 400,
      message: 'Invalid request body',
      code: 'INVALID_REQUEST_BODY',
    ).toResponse();
  }

  late final UserEntity user;
  try {
    user = await AuthenticationRepo().addUser(username, password, alias: alias, isAdmin: isAdmin ?? false);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorBase(
      statusCode: 500,
      message: 'Failed to add user',
      code: 'FAILED_TO_ADD_USER',
    ).toResponse();
  }

  return Response.ok(
    jsonEncode({
      'message': 'User added',
      'data': {
        'username': user.username,
        'alias': user.alias,
        'isAdmin': user.isAdmin,
        'createdAt': user.createdAt.toIso8601String(),
        'updatedAt': user.updatedAt.toIso8601String(),
        'lastLoginAt': user.lastLoginAt?.toIso8601String(),
      },
    }),
  );
}
