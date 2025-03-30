import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketController {
  final WebSocketChannel webSocket;
  final String? subprotocol;
  final StreamController<dynamic> inputController = StreamController<String>.broadcast();
  final StreamController<dynamic> outputController = StreamController<String>.broadcast();
  final StreamController<dynamic> errorController = StreamController<String>.broadcast();
  final StreamController<String> closeController = StreamController<String>.broadcast();

  StreamSubscription<dynamic>? _inputSubscription;
  StreamSubscription<dynamic>? _outputSubscription;
  StreamSubscription<dynamic>? _errorSubscription;
  StreamSubscription<String>? _closeSubscription;

  WebSocketController(this.webSocket, this.subprotocol) {
    final sink = webSocket.sink;
    _inputSubscription = inputController.stream.listen((message) {
      sink.add(message);
    });

    _outputSubscription = webSocket.stream.listen(
      (message) {
        outputController.add(message);
      },
      onError: (error) {
        errorController.add(error);
      },
      onDone: () {
        closeController.add('WebSocket closed');
      },
    );

    _errorSubscription = errorController.stream.listen((error) {
      sink.addError(error);
    });

    _closeSubscription = closeController.stream.listen((message) async {
      print(message);
      await close();
    });
  }

  Future<void> close() async {
    await Future.wait<void>([
      if (_inputSubscription != null) _inputSubscription!.cancel(),
      if (_outputSubscription != null)  _outputSubscription!.cancel(),
      if (_errorSubscription != null)  _errorSubscription!.cancel(),
      if (_closeSubscription != null)  _closeSubscription!.cancel(),
      webSocket.sink.close(),
    ]);
  }
}

class WebsocketRepo {
  WebsocketRepo.createInstance();

  static WebsocketRepo? _instance;

  factory WebsocketRepo() {
    _instance ??= WebsocketRepo.createInstance();
    return _instance!;
  }

  final websocket = <WebSocketController>[];

  void addWebSocket(WebSocketChannel webSocket) {
    final controller = WebSocketController(webSocket, null);
    websocket.add(controller);
  }

  void removeWebSocket(WebSocketChannel webSocket) {
    for (var controller in websocket) {
      if (controller.webSocket == webSocket) {
        controller.close();
        break;
      }
    }
  }

  void sendMessageToAll(dynamic message) {
    final jsonMessage = jsonEncode(message);
    for (var controller in websocket) {
      controller.inputController.add(jsonMessage);
    }
  }

  List<StreamSubscription<dynamic>> listenAll(void Function(dynamic message) listener) {
    return websocket.map((controller) {
      return controller.outputController.stream.listen(listener);
    }).toList();
  }
}
