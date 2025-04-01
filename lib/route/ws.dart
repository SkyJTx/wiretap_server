import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wiretap_server/repo/session/session_repo.dart';

final wsRouter = Router()
  ..get('/', webSocketHandler((WebSocketChannel webSocket, String? subprotocol) {
    SessionRepo().wsRepo.addWebSocket(webSocket);
  }))..get('/echo', webSocketHandler((WebSocketChannel webSocket, String? subprotocol) {
    webSocket.stream.listen((message) {
      webSocket.sink.add(message);
    });

    webSocket.sink.add('echo: $subprotocol');
    webSocket.sink.add('Subscribe to the channel: $subprotocol');
  }));
