import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/session/session.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> createSession(Request req) async {
  late final String sessionName;
  try {
    final body = await req.readAsString();
    sessionName = jsonDecode(body)['name'] as String;
  } catch (e) {
    return ErrorType.badRequest.toResponse('Invalid request body');
  }

  if (sessionName.isEmpty) {
    return ErrorType.badRequest.toResponse('Session name cannot be empty');
  }

  late final SessionEntity sessionEntity;
  try {
    sessionEntity = await SessionRepo().createSession(sessionName);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to create session');
  }

  return Response.ok(
    Data(
      message: 'Session ${sessionEntity.id} created',
      data: Session.fromEntity(sessionEntity).toMap(),
    ).toJson(),
    headers: jsonHeader,
  );
}
