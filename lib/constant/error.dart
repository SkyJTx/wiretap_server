import 'package:shelf/shelf.dart';
import 'package:wiretap_server/data_model/error_base.dart';

enum ErrorType {
  invalidRequest(code: 'INVALID_REQUEST', statusCode: 400),
  badRequest(code: 'BAD_REQUEST', statusCode: 400),
  invalidAuthorizationHeader(code: 'INVALID_AUTHORIZATION_HEADER', statusCode: 400),
  unauthorized(code: 'UNAUTHORIZED', statusCode: 401),
  stateRequirementAreNotMet(code: 'STATE_REQUIREMENT_ARE_NOT_MET', statusCode: 400),
  permissionDenied(code: 'PERMISSION_DENIED', statusCode: 403),
  internalServerError(code: 'INTERNAL_SERVER_ERROR', statusCode: 500);

  const ErrorType({required this.code, required this.statusCode});

  final String code;
  final int statusCode;

  ErrorBase addMessage(String message) => ErrorBase(
        statusCode: statusCode,
        message: message,
        code: code,
      );
  
  Response toResponse(String message) => addMessage(message).toResponse();
}

Response get badRequest => ErrorType.badRequest.toResponse(
  'Bad parameters, body, or query',
);

Response get failedToGetUserFromRequest => ErrorType.internalServerError.toResponse(
  'Failed to get user from request',
);

Response get invalidAuthorizationHeader => ErrorType.invalidAuthorizationHeader.toResponse(
  'Invalid authorization header',
);

Response get invalidAccessToken => ErrorType.unauthorized.toResponse(
  'Invalid access token',
);

Response get invalidRefreshToken => ErrorType.unauthorized.toResponse(
  'Invalid refresh token',
);

Response get adminPrivilegeRequired => ErrorType.permissionDenied.toResponse(
  'This request requires admin privilege',
);

Response get permissionDenied => ErrorType.permissionDenied.toResponse(
  'Permission denied',
);

Response get unknownError => ErrorType.internalServerError.toResponse(
  'Unknown error',
);
