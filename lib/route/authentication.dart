import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/controller/authen/authen.dart' as authen;
import 'package:wiretap_server/controller/token/token.dart' as token;

final authenticationRouter =
    Router()
      ..get(
        '/',
        (Request req) => Response.ok('Hello, World! Your authentication router is working!'),
      )
      ..post('/login', authen.login)
      ..post(
        '/logout',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(authen.logout),
      )
      ..post(
        '/refresh',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.refreshToken))
            .addHandler(authen.refresh),
      );
