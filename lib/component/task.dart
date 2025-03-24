import 'dart:async';
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

    sendPort.send(receivePort.sendPort);
    await runner(receivePort, sendPort);
  }

  static Future<Result> run<Args, Result>(
    FutureOr<Result> Function(Args args) runner,
    Args args,
  ) async {
    final resultCompleter = Completer<Result>();
    final task = Task((receivePort, sendPort) async {
      final runnerCompleter = Completer<FutureOr<Result> Function(Args args)>();
      final argsCompleter = Completer<Args>();
      receivePort.listen((message) async {
        if (message is Args) {
          argsCompleter.complete(message);
        } else if (message is FutureOr<Result> Function(Args args)) {
          runnerCompleter.complete(message);
        }
      });

      final args = await argsCompleter.future;
      final runner = await runnerCompleter.future;

      final result = await runner(args);

      sendPort.send(result);
    });

    await task.create();
    await task.start();
    task.receiver.listen((message) {
      if (message is Result) {
        resultCompleter.complete(message);
      }
    });
    task.send(args);
    await Future.delayed(Duration.zero);
    task.send(runner);

    return resultCompleter.future;
  }

  Future<void> create() async {
    _isolate = await Isolate.spawn<List<dynamic>>(_task, [
      _mainIsolateceivePort.sendPort,
      runner,
    ], paused: true);
  }

  Future<void> start() async {
    final Completer<SendPort> senderCompleter = Completer<SendPort>();
    _receiverSubscription = _mainIsolateceivePort.listen((message) {
      if (message is SendPort && !senderCompleter.isCompleted) {
        senderCompleter.complete(message);
      } else {
        _receiverController.add(message);
      }
    });

    _isolate!.resume(_isolate!.pauseCapability!);
    _isolateSendPort = await senderCompleter.future;

    _senderSubscription = _senderController.stream.listen((message) {
      _isolateSendPort?.send(message);
    });
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
