import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';

final router =
    Router()
      ..get('/', (Request req) => Response.ok('Hello, World!'))
      ..get('/echo', (Request req) => Response.ok(''))
      ..get('/echo/', (Request req) => Response.ok(''))
      ..get('/echo/<message>', (Request req) => Response.ok(req.params['message'] ?? ''))
      ..get('/user', (Request req) async {
        final store = DatabaseRepo().store;
        final userBox = store.box<UserEntity>();
        final users = userBox.getAll();
        return Response.ok(
          jsonEncode([
            for (final user in users)
              {
                'id': user.id,
                'username': user.username,
                'password': user.password,
                'alias': user.alias,
                'createdAt': user.createdAt.toIso8601String(),
                'updatedAt': user.updatedAt.toIso8601String(),
              },
          ]),
          headers: {'content-type': 'application/json'},
        );
      });
