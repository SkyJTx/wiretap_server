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
        token.verifyAccessByToken(token.VerificationType.accessToken).call(authen.logout),
      )
      ..post(
        '/refresh',
        token.verifyAccessByToken(token.VerificationType.refreshToken).call(authen.refresh),
      );
