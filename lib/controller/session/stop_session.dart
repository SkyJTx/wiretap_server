import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/session.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> stopSession(Request req) async {
  late final SessionEntity newSessionEntity;
  try {
    newSessionEntity = await SessionRepo().stopPolling();
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to start session');
  }

  return Response.ok(
    Data(message: 'Session started', data: Session.fromEntity(newSessionEntity).toMap()).toJson(),
    headers: jsonHeader,
  );
}
