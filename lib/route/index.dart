import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/controller/token/verify_access.dart' as token;
import 'package:wiretap_server/route/authentication.dart';
import 'package:wiretap_server/route/session.dart';
import 'package:wiretap_server/route/user.dart';
import 'package:wiretap_server/route/ws.dart';

final router =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World!'))
      ..mount('/authen', authenticationRouter.call)
      ..mount('/user', userRouter.call)
      ..mount('/ws', wsRouter.call)
      ..mount(
        '/session',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(sessionRouter.call),
      )..mount('/test', testerRouter.call);

final testerRouter =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World! Your tester router is working!'))
      ..get('/get_available_port', (Request req) {
        return Response.ok(availableSerialPort);
      });
