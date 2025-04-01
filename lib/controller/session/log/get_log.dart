import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/log.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/log_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getLatestLog(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final LogEntity logEntity;
  try {
    logEntity = await SessionRepo().getLatestLog(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get log message');
  }

  return Response.ok(
    Data(
      message: 'Latest log message retrieved',
      data: Log.fromEntity(logEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getAllLog(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final List<LogEntity> logEntities;
  try {
    logEntities = await SessionRepo().getAllLog(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get log messages');
  }

  return Response.ok(
    Data(
      message: 'All log messages retrieved',
      data: logEntities.map((e) => Log.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}
