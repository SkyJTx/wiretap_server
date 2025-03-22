import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class Task {
  final StreamController _senderController = StreamController.broadcast();
  final StreamController _receiverController = StreamController.broadcast();
  final FutureOr<void> Function(ReceivePort isolateReceivePort, SendPort mainIsolatePort)? runner;

  late final ReceivePort _mainIsolateceivePort;
  SendPort? _isolateSendPort;

  Isolate? _isolate;
  StreamSubscription? _senderSubscription;
  StreamSubscription? _receiverSubscription;

  Task(this.runner) : _mainIsolateceivePort = ReceivePort();

  Stream get sender => _senderController.stream;
  Stream get receiver => _receiverController.stream;

  static FutureOr<void> _task(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final FutureOr<void> Function(ReceivePort isolateReceivePort, SendPort mainIsolatePort) runner =
        args[1];
    final ReceivePort receivePort = ReceivePort();
    final Completer<int> completer = Completer<int>();

    final sub = receivePort.listen((message) async {
      if (message is int) {
        completer.complete(message);
      }
    });

    sendPort.send(receivePort.sendPort);

    final status = await completer.future;
    await sub.cancel();

    if (status == HttpStatus.ok) {
      await runner(receivePort, sendPort);
    } else {
      receivePort.close();
    }
  }

  static Future<Result> run<Args, Result>(FutureOr<Result> Function(Args) runner, Args args) async {
    final resultCompleter = Completer<Result>();
    final task = Task((receivePort, sendPort) async {
      final Completer<Result> completer = Completer<Result>();
      final sub = receivePort.listen((message) async {
        if (message is Args) {
          completer.complete(await runner(message));
        }
      });

      sendPort.send(HttpStatus.ok);
      final result = await completer.future;
      sendPort.send(result);
      await sub.cancel();
    });

    final resultReceiverSub = task.receiver.listen((result) {
      if (result is Result) {
        resultCompleter.complete(result);
      }
    });

    await task.start();
    task.send(args);
    final result = await resultCompleter.future;
    await resultReceiverSub.cancel();
    await task.stop();

    return result;
  }

  Future<void> start() async {
    final Completer<SendPort> senderCompleter = Completer<SendPort>();
    final sub = _mainIsolateceivePort.listen((message) {
      if (message is SendPort) {
        senderCompleter.complete(message);
      }
    });

    _isolate = await Isolate.spawn(_task, [_mainIsolateceivePort.sendPort, runner]);
    _isolateSendPort = await senderCompleter.future;
    await sub.cancel();

    _receiverSubscription = _mainIsolateceivePort.listen((message) {
      _receiverController.add(message);
    });
    _senderSubscription = _senderController.stream.listen((message) {
      _isolateSendPort?.send(message);
    });

    _senderController.add(HttpStatus.ok);
  }

  void send<T>(T message) {
    _senderController.add(message);
  }

  Capability pauseIsolate() {
    final isolate = _isolate;
    if (isolate == null) {
      throw StateError('Isolate is not running');
    }
    return isolate.pause();
  }

  void pauseController() {
    _senderSubscription?.pause();
    _receiverSubscription?.pause();
  }

  void resumeIsolate(Capability capability) {
    final isolate = _isolate;
    if (isolate == null) {
      throw StateError('Isolate is not running');
    }
    isolate.resume(capability);
  }

  void resumeController() {
    _senderSubscription?.resume();
    _receiverSubscription?.resume();
  }

  Future<void> stop() async {
    _senderSubscription?.cancel();
    _receiverSubscription?.cancel();
    _mainIsolateceivePort.close();
    _isolate?.kill();
  }
}
