import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/controller/user/user.dart' as user;
import 'package:wiretap_server/controller/token/token.dart' as token;

final userRouter =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World! Your user router is working!'))
      ..get(
        '/self',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(user.getSelf),
      )
      ..get(
        '/search',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(user.getUsers),
      )
      ..get(
        '/<id>',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(user.getUserById),
      )
      ..post(
        '/',
        Pipeline()
            .addMiddleware(
              token.verifyAccessByToken(token.VerificationType.accessToken, requireAdmin: true),
            )
            .addHandler(user.addUser),
      )
      ..put(
        '/<id>',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(user.editUser),
      )
      ..delete(
        '/<id>',
        Pipeline()
            .addMiddleware(token.verifyAccessByToken(token.VerificationType.accessToken))
            .addHandler(user.deleteUserById),
      );
