import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/route/authentication.dart';

final router =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World!'))
      ..mount('/authen', authenticationRouter.call);
