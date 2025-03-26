import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/constant.dart';
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
        return invalidAuthorizationHeader;
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
          VerificationType.accessToken => invalidAccessToken,
          VerificationType.refreshToken => invalidRefreshToken,
        };
      }

      late final UserEntity requester;
      try {
        requester = await UserRepo().getUserByUsername(requesterUsername);
      } catch (e) {
        return ErrorType.internalServerError.toResponse('Failed to get user by username');
      }

      if (requireAdmin && !requester.isAdmin) {
        return adminPrivilegeRequired;
      }

      final bool isTokenAcquired =
          requester.token.target != null &&
          switch (verificationType) {
            VerificationType.accessToken => requester.token.target!.accessToken == bearerToken,
            VerificationType.refreshToken => requester.token.target!.refreshToken == bearerToken,
          };
      if (!isTokenAcquired) {
        return switch (verificationType) {
          VerificationType.accessToken => invalidAccessToken,
          VerificationType.refreshToken => invalidRefreshToken,
        };
      }

      request = request.change(context: {'user': requester});

      return await innerHandler(request);
    };
  };
}
