import 'dart:async';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:libserialport/libserialport.dart';
import 'package:wiretap_server/constant/constant.dart';

class SerialRepo {
  static List<String> get name => SerialPort.availablePorts;

  late final SerialPort port;
  late final SerialPortReader reader;

  final outputController = StreamController<Uint8List>.broadcast();
  late final StreamSubscription<Uint8List>? _outputSubscription;

  SerialRepo({
    String? name,
    int baudRate = 115200,
    int bits = 8,
    int parity = 0,
    int stopBits = 1,
  }) {
    port = SerialPort(name ?? SerialPort.availablePorts.first);
    reader = SerialPortReader(port);
    port.config.baudRate = 115200;
    port.config.bits = 8;
    port.config.parity = 0;
    port.config.stopBits = 1;
    if (!port.openReadWrite()) {
      throw ErrorType.internalServerError.addMessage(
        'Failed to open port "${port.name ?? name ?? 'Unknown'}"',
      );
    }
    _outputSubscription = reader.stream.listen(
      (Uint8List data) {
        outputController.add(data);
      },
      onError: (error) {
        outputController.addError(error);
      },
      onDone: () {
        outputController.close();
        _outputSubscription?.cancel();
        _outputSubscription = null;
      },
    );
  }

  void write(dynamic data) {
    if (port.isOpen) {
      final byte = switch (data) {
        Uint8List u => u,
        String s => Uint8List.fromList(s.codeUnits),
        List<int> l => Uint8List.fromList(l),
        _ => Uint8List.fromList(data.toString().codeUnits),
      };
      port.write(byte);
    } else {
      throw ErrorType.internalServerError.addMessage('Port is not open');
    }
  }

  Future<Uint8List> writeAndRead(dynamic data) {
    if (port.isOpen) {
      final byte = switch (data) {
        Uint8List u => u,
        String s => Uint8List.fromList(s.codeUnits),
        List<int> l => Uint8List.fromList(l),
        _ => Uint8List.fromList(data.toString().codeUnits),
      };
      final completer = Completer<Uint8List>();
      final subscription = outputController.stream.listen(
        (Uint8List data) {
          completer.complete(data);
        },
        onError: (error) {
          completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError('Stream closed before completion');
          }
        },
      );
      port.write(byte);
      return completer.future.whenComplete(() {
        subscription.cancel();
      });
    } else {
      throw ErrorType.internalServerError.addMessage('Port is not open');
    }
  }

  void close() {
    port.close();
    _outputSubscription?.cancel();
    _outputSubscription = null;
  }

  void dispose() {
    port.dispose();
    outputController.close();
    _outputSubscription?.cancel();
    _outputSubscription = null;
  }
}
