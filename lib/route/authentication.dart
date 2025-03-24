import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/controller/authentication/authentication.dart' as authen;

final authenticationRouter =
    Router()
      ..get(
        '/',
        (Request req) => Response.ok('Hello, World! Your authentication router is working!'),
      )
      ..post('/login', authen.login)
      ..post('/logout', authen.logout)
      ..post('/refresh', authen.refresh)
      ..post('/add_user', authen.addUser);
