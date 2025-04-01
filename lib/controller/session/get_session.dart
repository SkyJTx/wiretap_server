import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/session.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getSessionById(Request req) async {
  final sessionId = int.tryParse(req.url.queryParameters['sessionId'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final SessionEntity sessionEntity;
  try {
    sessionEntity = await SessionRepo().getSession(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get session');
  }

  return Response.ok(
    Data(
      message: 'Session $sessionId retrieved',
      data: Session.fromEntity(sessionEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getSessionByName(Request req) async {
  final sessionName = req.url.queryParameters['sessionName'];
  if (sessionName == null || sessionName.isEmpty) {
    return ErrorType.badRequest.toResponse('Session name is required');
  }

  late final SessionEntity sessionEntity;
  try {
    sessionEntity = await SessionRepo().getSessionByName(sessionName);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get session');
  }

  return Response.ok(
    Data(
      message: 'Session $sessionName retrieved',
      data: Session.fromEntity(sessionEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getSessions(Request req) async {
  final page = int.tryParse(req.url.queryParameters['page'] ?? '');
  final limit = int.tryParse(req.url.queryParameters['sessionPerPage'] ?? '') ?? 1;
  final searchParam = req.url.queryParameters['searchParam'];
  
  if (page == null || page < 1) {
    return ErrorType.badRequest.toResponse('Page number is required and must be greater than 0');
  }
  if (limit < 1) {
    return ErrorType.badRequest.toResponse('Session per page must be greater than 0');
  }
  if (searchParam != null && searchParam.isEmpty) {
    return ErrorType.badRequest.toResponse('Search parameter cannot be empty');
  }

  late final List<SessionEntity> sessionEntities;
  try {
    sessionEntities = await SessionRepo().getSessions(
      limit,
      page,
      searchParam: searchParam,
    );
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get sessions');
  }

  return Response.ok(
    Data(
      message: 'Sessions retrieved',
      data: sessionEntities.map((e) => Session.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}