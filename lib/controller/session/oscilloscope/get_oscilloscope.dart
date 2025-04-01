import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/oscilloscope.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/oscilloscope_msg_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getLatestOscilloscopeMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final OscilloscopeMsgEntity oscilloscopeMsgEntity;
  try {
    oscilloscopeMsgEntity = await SessionRepo().getLatestOscilloscopeMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get Oscilloscope message');
  }

  return Response.ok(
    Data(
      message: 'Latest Oscilloscope message retrieved',
      data: OscilloscopeMsg.fromEntity(oscilloscopeMsgEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getAllOscilloscopeMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final List<OscilloscopeMsgEntity> oscilloscopeMsgEntities;
  try {
    oscilloscopeMsgEntities = await SessionRepo().getAllOscilloscopeMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get Oscilloscope messages');
  }

  return Response.ok(
    Data(
      message: 'All Oscilloscope messages retrieved',
      data: oscilloscopeMsgEntities.map((e) => OscilloscopeMsg.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}
