import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/modbus.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/modbus_msg_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getLatestModbusMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final ModbusMsgEntity modbusMsgEntity;
  try {
    modbusMsgEntity = await SessionRepo().getLatestModbusMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get Modbus message');
  }

  return Response.ok(
    Data(
      message: 'Latest Modbus message retrieved',
      data: ModbusMsg.fromEntity(modbusMsgEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getAllModbusMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final List<ModbusMsgEntity> modbusMsgEntities;
  try {
    modbusMsgEntities = await SessionRepo().getAllModbusMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get Modbus messages');
  }

  return Response.ok(
    Data(
      message: 'All Modbus messages retrieved',
      data: modbusMsgEntities.map((e) => ModbusMsg.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}
