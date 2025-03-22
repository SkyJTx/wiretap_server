import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final router =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World!'))
      ..get('/echo', (Request req) => Response.ok(''))
      ..get('/echo/', (Request req) => Response.ok(''))
      ..get('/echo/<message>', (Request req) => Response.ok(req.params['message'] ?? ''));
