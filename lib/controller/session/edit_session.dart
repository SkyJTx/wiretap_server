import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/session.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> editSession(Request req) async {
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  late String? name;
  late bool? enableI2c;
  late bool? enableSpi;
  late bool? enableModbus;
  late bool? enableOscilloscope;
  late String? ip;
  late int? port;
  late int? activeDecodeMode;
  late int? activeDecodeFormat;
  try {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    name = data['name'] as String?;
    enableI2c = data['enableI2c'] as bool?;
    enableSpi = data['enableSpi'] as bool?;
    enableModbus = data['enableModbus'] as bool?;
    enableOscilloscope = data['enableOscilloscope'] as bool?;
    ip = data['ip'] as String?;
    port = data['port'] as int?;
    activeDecodeMode = OscilloscopeDecodeMode.tryParse(data['activeDecodeMode'] as String? ?? '')?.index;
    activeDecodeFormat = OscilloscopeDecodeFormat.tryParse(data['activeDecodeFormat'] as String? ?? '')?.index;
  } catch (e) {
    return ErrorType.badRequest.toResponse('Invalid request body');
  }

  late final SessionEntity sessionEntity;
  try {
    sessionEntity = await SessionRepo().editSession(
      id,
      name: name,
      enableI2c: enableI2c,
      enableSpi: enableSpi,
      enableModbus: enableModbus,
      enableOscilloscope: enableOscilloscope,
      ip: ip,
      port: port,
      activeDecodeMode: activeDecodeMode,
      activeDecodeFormat: activeDecodeFormat,
    );
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to edit session');
  }

  return Response.ok(
    Data(
      message: 'Session $id edited',
      data: Session.fromEntity(sessionEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}
