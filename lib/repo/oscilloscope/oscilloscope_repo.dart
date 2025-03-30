import 'dart:async';
import 'dart:isolate';

import 'package:wiretap_server/component/task.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/oscilloscope/oscilloscope_api_provider.dart';

class OscilloscopeRepo {
  final StreamController<String> _inputController = StreamController<String>.broadcast();
  final StreamController<dynamic> _outputController = StreamController<dynamic>.broadcast();
  final StreamController<ErrorBase> _errorController = StreamController<ErrorBase>.broadcast();
  final StreamController<bool> _closeController = StreamController<bool>.broadcast();
  final ReceivePort _errorReceivePort = ReceivePort();
  final ReceivePort _exitReceivePort = ReceivePort();
  final ReceivePort _isolateTerminateReceivePort = ReceivePort();

  StreamSubscription<String>? _inputSubscription;
  StreamSubscription<dynamic>? _outputSubscription;
  StreamSubscription<dynamic>? _errorSubscription;
  StreamSubscription<dynamic>? _isolateTerminateSubscription;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _task = Task((receivePort, sendPort) async {
    final inputController = StreamController<String>.broadcast();
    final errorSendPortCompleter = Completer<SendPort>();
    final exitReceivePortCompleter = Completer<ReceivePort>();
    final isolateTerminateSendPortCompleter = Completer<SendPort>();
    final apiProviderCompleter = Completer<OscilloscopeApiProvider>();
    final terminateCompleter = Completer<void>();

    final receiveSub = receivePort.listen((message) {
      if (message is String) {
        inputController.add(message);
      } else if (message is Map<String, dynamic> &&
          message['ip'] is String &&
          message['port'] is int &&
          message['errorSendPort'] is SendPort &&
          message['exitReceivePort'] is ReceivePort &&
          message['isolateTerminateSendPort'] is SendPort) {
        final {
          'ip': ip,
          'port': port,
          'errorSendPort': errorSendPort,
          'exitReceivePort': exitReceivePort,
          'isolateTerminateSendPort': isolateTerminateSendPort,
        } = message;
        apiProviderCompleter.complete(OscilloscopeApiProvider(ip: ip, port: port));
        errorSendPortCompleter.complete(errorSendPort);
        exitReceivePortCompleter.complete(exitReceivePort);
        isolateTerminateSendPortCompleter.complete(isolateTerminateSendPort);
      }
    });

    final apiProvider = await apiProviderCompleter.future;
    final errorSendPort = await errorSendPortCompleter.future;
    final exitReceivePort = await exitReceivePortCompleter.future;
    final isolateTerminateSendPort = await isolateTerminateSendPortCompleter.future;

    await apiProvider.connect();
    final exitSub = exitReceivePort.listen((message) async {
      terminateCompleter.complete();
    });
    final inputSub = inputController.stream.listen((message) async {
      receiveSub.pause();
      try {
        sendPort.send(await apiProvider.run(message));
      } on ErrorBase catch (e) {
        errorSendPort.send(e.message);
      } catch (e) {
        errorSendPort.send(e.toString());
      }
      receiveSub.resume();
    });

    await terminateCompleter.future;
    await inputSub.cancel();
    await exitSub.cancel();
    await receiveSub.cancel();
    await apiProvider.disconnect();
    await inputController.close();

    isolateTerminateSendPort.send(true);
  });

  late String _ip;
  late int _port;
  String get ip => _ip;
  int get port => _port;

  OscilloscopeRepo();

  Future<void> connect(String ip, int port) async {
    if (_isConnected) {
      throw ErrorType.internalServerError.addMessage('Isolate is already connected');
    }
    _ip = ip;
    _port = port;
    await _task.create();

    _inputSubscription = _inputController.stream.listen((message) {
      _task.send(message);
    });
    _outputSubscription = _task.receiver.stream.listen((message) {
      _outputController.add(message);
    });
    _errorSubscription = _errorReceivePort.listen((message) {
      _errorController.add(ErrorType.internalServerError.addMessage(message.toString()));
    });
    _isolateTerminateSubscription = _isolateTerminateReceivePort.listen((message) {
      if (message is bool && message) {
        _closeController.add(true);
      }
    });

    await _task.start();

    _task.send({
      'ip': ip,
      'port': port,
      'errorSendPort': _errorReceivePort.sendPort,
      'exitReceivePort': _exitReceivePort,
      'isolateTerminateSendPort': _isolateTerminateReceivePort.sendPort,
    });

    _isConnected = true;
  }

  void sendCommand(String command) async {
    if (!_isConnected) {
      throw ErrorType.internalServerError.addMessage('Isolate is closed');
    }
    _inputController.add(command);
  }

  Future<T> send<T>(
    String message, {
    FutureOr<T> Function(dynamic message)? converter,
  }) async {
    if (!_isConnected) {
      throw ErrorType.internalServerError.addMessage('Isolate is closed');
    }
    final completer = Completer<T>();
    final sub = _outputController.stream.listen((message) async {
      if (converter != null) {
        final convertedMessage = await converter(message);
        completer.complete(convertedMessage);
      } else if (message is T) {
        completer.complete(message);
      } else {
        completer.completeError(ErrorType.internalServerError.addMessage('Invalid message type'));
      }
    });
    _inputController.add(message);
    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  Future<void> close() async {
    final completelyCloseCompleter = Completer<void>();
    _exitReceivePort.sendPort.send(true);
    final exitSub = _closeController.stream.listen((message) async {
      if (message) {
        completelyCloseCompleter.complete();
      } else {
        throw ErrorType.internalServerError.addMessage('Isolate not terminated');
      }
    });
    await completelyCloseCompleter.future;
    await exitSub.cancel();
    await _inputSubscription?.cancel();
    await _outputSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _isolateTerminateSubscription?.cancel();
    await Future.wait([
      _inputController.close(),
      _outputController.close(),
      _errorController.close(),
      _closeController.close(),
    ]);
    _errorReceivePort.close();
    _exitReceivePort.close();
    _isolateTerminateReceivePort.close();
    await _task.stop();
  }
}
