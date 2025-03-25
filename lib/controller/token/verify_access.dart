import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/authen/authen_repo.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/user/user_repo.dart';

enum VerificationType { accessToken, refreshToken }

Middleware verifyAccessByToken(VerificationType verificationType, {bool requireAdmin = false}) {
  return (Handler innerHandler) {
    return (Request request) async {
      late final String bearerToken;
      try {
        bearerToken = request.headers['Authorization']!.split(' ')[1];
      } catch (e) {
        return ErrorBase(
          statusCode: 400,
          message: 'Invalid Authorization header',
          code: 'INVALID_AUTHORIZATION_HEADER',
        ).toResponse();
      }

      late final String requesterUsername;
      try {
        requesterUsername = switch (verificationType) {
          VerificationType.accessToken => AuthenRepo().decodeAccessToken(bearerToken)['username']!,
          VerificationType.refreshToken =>
            AuthenRepo().decodeRefreshToken(bearerToken)['username']!,
        };
      } catch (e) {
        return switch (verificationType) {
          VerificationType.accessToken => ErrorBase(
            statusCode: 401,
            message: 'Invalid access token',
            code: 'INVALID_ACCESS_TOKEN',
          ),
          VerificationType.refreshToken => ErrorBase(
            statusCode: 401,
            message: 'Invalid refresh token',
            code: 'INVALID_REFRESH_TOKEN',
          ),
        }.toResponse();
      }

      late final UserEntity requester;
      try {
        requester = await UserRepo().getUserByUsername(requesterUsername);
      } catch (e) {
        return ErrorBase(
          statusCode: 500,
          message: 'Failed to get requester',
          code: 'FAILED_TO_GET_REQUESTER',
        ).toResponse();
      }

      if (requireAdmin && !requester.isAdmin) {
        return ErrorBase(
          statusCode: 403,
          message: 'This request requires admin privilege',
          code: 'REQUESTER_NOT_ADMIN',
        ).toResponse();
      }

      final bool isTokenAcquired =
          requester.token.target != null &&
          switch (verificationType) {
            VerificationType.accessToken => requester.token.target!.accessToken == bearerToken,
            VerificationType.refreshToken => requester.token.target!.refreshToken == bearerToken,
          };
      if (!isTokenAcquired) {
        return switch (verificationType) {
          VerificationType.accessToken => ErrorBase(
            statusCode: 401,
            message: 'Invalid access token',
            code: 'INVALID_ACCESS_TOKEN',
          ),
          VerificationType.refreshToken => ErrorBase(
            statusCode: 401,
            message: 'Invalid refresh token',
            code: 'INVALID_REFRESH_TOKEN',
          ),
        }.toResponse();
      }

      request = request.change(context: {'user': requester});

      return await innerHandler(request);
    };
  };
}
