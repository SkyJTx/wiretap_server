import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/spi.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/spi_msg_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> getLatestSpiMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final SpiMsgEntity spiMsgEntity;
  try {
    spiMsgEntity = await SessionRepo().getLatestSpiMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get SPI message');
  }

  return Response.ok(
    Data(
      message: 'Latest SPI message retrieved',
      data: SpiMsg.fromEntity(spiMsgEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getAllSpiMsg(Request req) async {
  final sessionId = int.tryParse(req.params['id'] ?? '');
  if (sessionId == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late final List<SpiMsgEntity> spiMsgEntities;
  try {
    spiMsgEntities = await SessionRepo().getAllSpiMsg(sessionId);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get SPI messages');
  }

  return Response.ok(
    Data(
      message: 'All SPI messages retrieved',
      data: spiMsgEntities.map((e) => SpiMsg.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}