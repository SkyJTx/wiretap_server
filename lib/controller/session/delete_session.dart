import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

Future<Response> deleteSession(Request req) async {
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) {
    return ErrorType.badRequest.toResponse('Session ID is required');
  }

  try {
    await SessionRepo().deleteSession(id);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } on Response catch (e) {
    return e;
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to delete session');
  }

  return Response.ok(
    Data(message: 'Session $id deleted', data: null).toJson(),
    headers: jsonHeader,
  );
}
