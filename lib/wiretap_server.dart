import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:wiretap_server/route/index.dart';

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

  App(this.address, this.port) :_handler = Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  Future<void> start() async {
    _server = await shelf_io.serve(_handler, address, port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}
