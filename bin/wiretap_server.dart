import 'dart:io';

import 'package:wiretap_server/dotenv.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/wiretap_server.dart';

void main(List<String> arguments) async {
  final ip = InternetAddress('127.0.0.1', type: InternetAddressType.IPv4);
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final app = App(ip, port);
  DatabaseRepo().init();
  await DatabaseRepo().storeReady;
  await app.start();
  print('Server started on http://${app.address.address}:${app.port}');
  print('Hello, World! Your server is working!');
  print('Press Ctrl+C to stop the server');
}
