import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/controller/user/user.dart' as user;
import 'package:wiretap_server/controller/token/token.dart' as token;

final userRouter =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World! Your user router is working!'))
      ..get(
        '/self',
        token.verifyAccessByToken(token.VerificationType.accessToken).call(user.getSelf),
      )
      ..get(
        '/search',
        token.verifyAccessByToken(token.VerificationType.accessToken).call(user.getUsers),
      )
      ..get(
        '/<id>',
        token.verifyAccessByToken(token.VerificationType.accessToken).call(user.getUserById),
      )
      
      ..post(
        '/',
        token
            .verifyAccessByToken(token.VerificationType.accessToken, requireAdmin: true)
            .call(user.addUser),
      )
      ..put(
        '/<id>',
        token.verifyAccessByToken(token.VerificationType.accessToken).call(user.editUser),
      )
      ..delete(
        '/<id>',
        token.verifyAccessByToken(token.VerificationType.accessToken).call(user.deleteUserById),
      );
