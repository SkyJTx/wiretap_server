import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/i2c.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/i2c_msg_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getLatestI2cMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final I2cMsgEntity i2cMsgEntity;
  try {
    i2cMsgEntity = await SessionRepo().getLatestI2cMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return Response.internalServerError(body: 'Failed to get I2C message');
  }

  return Response.ok(
    Data(
      message: 'Latest I2C message retrieved',
      data: I2cMsg.fromEntity(i2cMsgEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getAllI2cMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final List<I2cMsgEntity> i2cMsgEntities;
  try {
    i2cMsgEntities = await SessionRepo().getAllI2cMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return Response.internalServerError(body: 'Failed to get I2C messages');
  }

  return Response.ok(
    Data(
      message: 'All I2C messages retrieved',
      data: i2cMsgEntities.map((e) => I2cMsg.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}