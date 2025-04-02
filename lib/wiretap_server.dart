import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:wiretap_server/controller/token/verify_access.dart' as token;
import 'package:wiretap_server/route/index.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

class App {
  final InternetAddress address;
  final int port;
  final FutureOr<Response> Function(Request) _handler;
  HttpServer? _server;

  HttpServer get server {
    if (_server == null) {
      throw StateError('Server is not running');
    }
    return _server!;
  }

  static final overrideCorsHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    
  };

  App(this.address, this.port)
    : _handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(corsHeaders(headers: overrideCorsHeaders))
          .addHandler(
            Cascade()
                .add(
                  Pipeline().addHandler((req) {
                    if (req.url.path.startsWith('public')) {
                      var updatedRequest = req.change(path: 'public');
                      return Pipeline()
                          .addMiddleware(
                            token.verifyAccessByToken(token.VerificationType.accessToken),
                          )
                          .addHandler((req) {
                            return createStaticHandler('public')(req);
                          })(updatedRequest);
                    }
                    return Response.notFound('Not Found');
                  }),
                )
                .add(router.call)
                .handler,
          );

  Future<void> start() async {
    _server = await shelf_io.serve(_handler, address, port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}
