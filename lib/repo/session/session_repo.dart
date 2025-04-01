import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:wiretap_server/component/task.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/data_model/serial/serial_data.dart';
import 'package:wiretap_server/data_model/session/i2c.dart';
import 'package:wiretap_server/data_model/session/log.dart';
import 'package:wiretap_server/data_model/session/modbus.dart';
import 'package:wiretap_server/data_model/session/oscilloscope.dart';
import 'package:wiretap_server/data_model/session/spi.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/i2c_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/modbus_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/oscilloscope_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/spi_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/i2c_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/modbus_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/oscilloscope_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/spi_entity.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/log_entity.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';
import 'package:wiretap_server/repo/notification/mail_repo.dart';
import 'package:wiretap_server/repo/oscilloscope/oscilloscope_api_provider.dart';
import 'package:wiretap_server/repo/serial/serial_repo.dart';
import 'package:wiretap_server/repo/websocket/websocket_repo.dart';

class SessionRepo {
  StreamController<Map<String, dynamic>>? _inputController;
  StreamController<String>? _outputController;
  StreamController<ErrorBase>? _errorController;
  StreamController<bool>? _pollingController;
  StreamController<Map<String, dynamic>> get inputController {
    final result = _inputController;
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    return result;
  }

  StreamController<String> get outputController {
    final result = _outputController;
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    return result;
  }

  StreamController<ErrorBase> get errorController {
    final result = _errorController;
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    return result;
  }

  StreamController<bool> get pollingController {
    final result = _pollingController;
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    return result;
  }

  static const timeout = Duration(seconds: 10);
  static String oscilloscopeMsgFilePath(int sessionId) => 'public/oscilloscope/$sessionId';
  void keepAliveFunction() async {
    if (_isPolling) {
      _keepAlive?.cancel();
      final now = DateTime.now().toUtc();
      MailRepo().sendMail(
        MailRepo().createMessage(
          'WireTap Error Notification',
          'Serial port is not responding at ${now.year}/${now.month}/${now.day} ${now.hour}:${now.minute}:${now.second} (UTC+0). Please check the WireTap Notifier.',
        ),
      );
      await stopPolling();
    }
  }

  ReceivePort? _errorSendPort;
  ReceivePort? _exitReceivePort;
  ReceivePort? _isolateTerminateSendPort;
  StreamSubscription<Map<String, dynamic>>? _inputSub;
  StreamSubscription<dynamic>? _receiveSub;
  StreamSubscription<String>? _outputSub;
  StreamSubscription<dynamic>? _errorSub;
  StreamSubscription<dynamic>? _isolateTerminationSub;
  Completer<void>? _isolateTerminationCompleter;
  Task? _serialPolling;
  int? _sessionId;
  Timer? _keepAlive;
  bool _isPolling = false;

  bool get isPolling => _isPolling;
  int get sessionId {
    final result = _sessionId;
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    return result;
  }

  Future<SessionEntity> get session {
    return DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, sessionId) {
      final session = store.box<SessionEntity>().get(sessionId);
      if (session == null) {
        throw ErrorType.internalServerError.addMessage('Session not found');
      }
      return session;
    }, sessionId);
  }

  SessionRepo.createInstance();

  static SessionRepo? _instance;

  factory SessionRepo() {
    _instance ??= SessionRepo.createInstance();
    return _instance!;
  }

  final wsRepo = WebsocketRepo.createInstance();

  Future<void> _handleSerialData(String jsonString) async {
    if (!_isPolling) return;
    final data = SerialData.fromJson(jsonString);
    SessionEntity session = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      params,
    ) {
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(params);
      if (session == null) {
        throw ErrorType.internalServerError.addMessage('Session not found');
      }
      return session;
    }, sessionId);

    if (data.type == 'SPI' && session.spi.target?.isEnabled == true) {
      final splittedData = data.data.split(';');
      final mosi = splittedData[0];
      final miso = splittedData[1];

      final msg = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
        final [mosi as String, miso as String, sessionId as int] = params;
        final sessionBox = store.box<SessionEntity>();
        final spiBox = store.box<SpiEntity>();

        final session = sessionBox.get(sessionId);
        if (session == null) {
          throw ErrorType.internalServerError.addMessage('Session not found');
        }

        final spiEntity = session.spi.target;
        if (spiEntity == null) {
          throw ErrorType.internalServerError.addMessage('Session is invalid state');
        }

        final spiMsgEntity = SpiMsgEntity(
          mosi: mosi,
          miso: miso,
          createdAt: DateTime.now().toUtc(),
        );
        spiEntity.spiMsgEntities.add(spiMsgEntity);
        final id = spiBox.put(spiEntity);
        return spiBox.get(id);
      }, [mosi, miso, sessionId]);
      wsRepo.sendMessageToAll(
        Data(
          message: 'SPI',
          data: SpiMsg.fromEntity(msg!.spiMsgEntities.sortedBy((e) => e.createdAt).last).toMap(),
        ).toJson(),
      );
    }
    if (data.type == 'I2C' && session.i2c.target?.isEnabled == true) {
      final isWriteMode = data.data[8] == '0';
      final isTenBit = data.data.substring(1, 6) == '11110';
      late final String stringAddr;
      late final String realData;
      if (isTenBit) {
        stringAddr = data.data.substring(6, 8) + data.data.substring(10, 18);
        final rawData = data.data.substring(19);
        final skipBits = [for (int i = 0; i < rawData.length; i += 9) rawData.substring(i, i + 8)];
        realData = skipBits.join('');
      } else {
        stringAddr = data.data.substring(1, 8);
        final rawData = data.data.substring(10);
        final skipBits = [for (int i = 0; i < rawData.length; i += 9) rawData.substring(i, i + 8)];
        realData = skipBits.join('');
      }

      final address = int.parse(stringAddr, radix: 2);

      final msg = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
        final [
          address as int,
          isTenBitAddressing as bool,
          isWriteMode as bool,
          data as String,
          sessionId as int,
        ] = params;
        final sessionBox = store.box<SessionEntity>();
        final i2cBox = store.box<I2cEntity>();

        final session = sessionBox.get(sessionId);
        if (session == null) {
          throw ErrorType.internalServerError.addMessage('Session not found');
        }

        final i2cEntity = session.i2c.target;
        if (i2cEntity == null) {
          throw ErrorType.internalServerError.addMessage('Session is invalid state');
        }

        final i2cMsgEntity = I2cMsgEntity(
          address: address,
          isTenBitAddressing: isTenBitAddressing,
          isWriteMode: isWriteMode,
          data: data,
          createdAt: DateTime.now().toUtc(),
        );
        i2cEntity.i2cMsgEntities.add(i2cMsgEntity);
        final id = i2cBox.put(i2cEntity);
        return i2cBox.get(id);
      }, [address, isTenBit, isWriteMode, realData, sessionId]);
      wsRepo.sendMessageToAll(
        Data(
          message: 'I2C',
          data: I2cMsg.fromEntity(msg!.i2cMsgEntities.sortedBy((e) => e.createdAt).last).toMap(),
        ).toJson(),
      );
    }
    if (data.type == 'Modbus' && session.modbus.target?.isEnabled == true) {
      final splittedData = data.data.split(';');
      final tx = splittedData[0];
      final rx = splittedData[1];
      final address = int.parse(tx.substring(0, 8), radix: 2);
      final functionCode = int.parse(tx.substring(8, 16), radix: 2);
      final startingAddress = int.parse(tx.substring(16, 32), radix: 2);
      final quantityOfRegisters = int.parse(tx.substring(32, 48), radix: 2);
      final queryCRC = int.parse(tx.substring(48, 64).split('').reversed.join(''), radix: 2);
      final byteCount = int.parse(rx.substring(16, 24), radix: 2);
      final realData = rx.substring(24, 24 + (byteCount * 8));
      final responseCRC = int.parse(
        rx.substring(24 + (byteCount * 8), 24 + (byteCount * 8) + 16).split('').reversed.join(''),
        radix: 2,
      );

      final msg = await DatabaseRepo().store.runInTransactionAsync(
        TxMode.write,
        (store, params) {
          final [
            address as int,
            functionCode as int,
            startingAddress as int,
            quantityOfRegisters as int,
            dataLength as int,
            data as String,
            queryCRC as int,
            responseCRC as int,
            sessionId as int,
          ] = params;
          final sessionBox = store.box<SessionEntity>();
          final modbusBox = store.box<ModbusEntity>();

          final session = sessionBox.get(sessionId);
          if (session == null) {
            throw ErrorType.internalServerError.addMessage('Session not found');
          }

          final modbusEntity = session.modbus.target;
          if (modbusEntity == null) {
            throw ErrorType.internalServerError.addMessage('Session is invalid state');
          }

          final modbusMsgEntity = ModbusMsgEntity(
            address: address,
            functionCode: functionCode,
            startingAddress: startingAddress,
            quantity: quantityOfRegisters,
            dataLength: dataLength,
            data: data,
            queryCRC: queryCRC,
            responseCRC: responseCRC,
            createdAt: DateTime.now().toUtc(),
          );
          modbusEntity.modbusMsgEntities.add(modbusMsgEntity);
          final id = modbusBox.put(modbusEntity);
          return modbusBox.get(id);
        },
        [
          address,
          functionCode,
          startingAddress,
          quantityOfRegisters,
          byteCount,
          realData,
          queryCRC,
          responseCRC,
          sessionId,
        ],
      );
      wsRepo.sendMessageToAll(
        Data(
          message: 'Modbus',
          data:
              ModbusMsg.fromEntity(
                msg!.modbusMsgEntities.sortedBy((e) => e.createdAt).last,
              ).toMap(),
        ).toJson(),
      );
    }
    if (data.type == 'Keep Alive' && data.data == 'Pong') {
      _keepAlive?.cancel();
      _keepAlive = Timer(SessionRepo.timeout, keepAliveFunction);
    }

    session = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final [jsonString as String, sessionId as int] = params;
      final data = SerialData.fromJson(jsonString);
      final logEntity = LogEntity(
        type: data.type,
        data: data.data,
        createdAt: DateTime.now().toUtc(),
      );
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.internalServerError.addMessage('Session not found');
      }
      session.logs.add(logEntity);
      return sessionBox.get(sessionBox.put(session))!;
    }, [jsonString, sessionId]);
    wsRepo.sendMessageToAll(
      Data(
        message: 'Serial',
        data: Log.fromEntity(session.logs.sortedBy((e) => e.createdAt).last).toMap(),
      ).toJson(),
    );

    if (session.oscilloscope.target?.isEnabled == true) {
      final result = await DatabaseRepo().store.runInTransaction(TxMode.write, () async {
        final store = DatabaseRepo().store;
        final rawType = data.type;

        final sessionBox = store.box<SessionEntity>();
        final oscilloscopeBox = store.box<OscilloscopeEntity>();
        final oscilloscopeMsgEntityBox = store.box<OscilloscopeMsgEntity>();

        final session = sessionBox.get(sessionId);
        if (session == null) {
          throw ErrorType.internalServerError.addMessage('Session not found');
        }

        final oscilloscopeEntity = session.oscilloscope.target;
        if (oscilloscopeEntity == null) {
          throw ErrorType.internalServerError.addMessage('Session is invalid state');
        }

        final type = OscilloscopeDecodeMode.tryParse(rawType);

        final date = DateTime.now().toUtc();
        final oscilloscopeMsgEntity = OscilloscopeMsgEntity(
          isDecodeEnabled: type != null,
          decodeMode: type?.index,
          decodeFormat: type != null ? OscilloscopeDecodeFormat.hex.index : null,
          imageFilePath: '',
          createdAt: date,
        );
        oscilloscopeEntity.oscilloscopeMsgEntities.add(oscilloscopeMsgEntity);
        oscilloscopeBox.put(oscilloscopeEntity);
        final newSession = sessionBox.get(sessionId);
        final realOscilloscopeMsgEntity =
            oscilloscopeMsgEntityBox
                .query(OscilloscopeMsgEntity_.createdAt.equalsDate(date))
                .build()
                .findFirst();
        if (realOscilloscopeMsgEntity == null) {
          throw ErrorType.internalServerError.addMessage('Failed to create oscilloscope message');
        }

        final isAppropriate = oscilloscopeEntity.appropriate;
        if (!isAppropriate) {
          throw ErrorType.internalServerError.addMessage(
            'Oscilloscope is not in appropriate state',
          );
        }
        final ip = oscilloscopeEntity.ip!;
        final port = oscilloscopeEntity.port!;
        final oscilloscopeApiProvider = OscilloscopeApiProvider(ip: ip, port: port);
        await oscilloscopeApiProvider.connect();
        final picture = await oscilloscopeApiProvider.capture();
        final path =
            '${SessionRepo.oscilloscopeMsgFilePath(newSession!.id)}/${realOscilloscopeMsgEntity.id}.png';
        final file = File(path);
        await file.create(recursive: true);
        await file.writeAsBytes(picture);

        realOscilloscopeMsgEntity.imageFilePath = path;
        final id = oscilloscopeMsgEntityBox.put(realOscilloscopeMsgEntity);

        oscilloscopeApiProvider.runWithOutReturning(setOscilloscopeModeCommand(Mode.CLEAR));
        oscilloscopeApiProvider.runWithOutReturning(setOscilloscopeModeCommand(Mode.SINGLE));
        await oscilloscopeApiProvider.disconnect();

        final resultOscilloscopeMsgEntity = oscilloscopeMsgEntityBox.get(id);
        return OscilloscopeMsg(
          id: resultOscilloscopeMsgEntity!.id,
          isDecodeEnabled: resultOscilloscopeMsgEntity.isDecodeEnabled,
          decodeMode: type != null ? rawType : null,
          decodeFormat: type != null ? OscilloscopeDecodeFormat.hex.name : null,
          imageFilePath: resultOscilloscopeMsgEntity.imageFilePath,
          createdAt: resultOscilloscopeMsgEntity.createdAt,
        ).toMap();
      });
      wsRepo.sendMessageToAll(Data(message: 'Oscilloscope', data: result).toJson());
    }
  }

  Future<SessionEntity> startPolling({
    String? serialPortName,
    required SessionEntity session,
  }) async {
    if (_isPolling) {
      throw ErrorType.internalServerError.addMessage('Session already exist');
    }
    serialPortName ??= defaultSerialPort;
    _sessionId = session.id;
    _isolateTerminationCompleter = Completer();
    _inputController = StreamController.broadcast();
    _outputController = StreamController.broadcast();
    _errorController = StreamController.broadcast();
    _pollingController = StreamController.broadcast();
    _serialPolling = Task((receivePort, sendPort) async {
      final serialInput = StreamController<String>.broadcast();
      final serialPortNameCompleter = Completer<String>();
      final errorSendPortCompleter = Completer<SendPort>();
      final exitReceivePortCompleter = Completer<ReceivePort>();
      final isolateTerminateSendPortCompleter = Completer<SendPort>();
      final terminateCompleter = Completer<bool>();

      final receiveSub = receivePort.listen((message) {
        if (message is Map<String, dynamic> &&
            message['serialPort'] is String &&
            message['errorSendPort'] is SendPort &&
            message['exitReceivePort'] is ReceivePort &&
            message['isolateTerminateSendPort'] is SendPort) {
          serialPortNameCompleter.complete(message['serialPort']);
          errorSendPortCompleter.complete(message['errorSendPort']);
          exitReceivePortCompleter.complete(message['exitReceivePort']);
          isolateTerminateSendPortCompleter.complete(message['isolateTerminateSendPort']);
        } else if (message is Map<String, dynamic> &&
            message['command'] is String &&
            message['target'] == 'serial') {
          final command = message['command'];
          serialInput.add(command);
        }
      });

      final serialPortName = await serialPortNameCompleter.future;
      final errorSendPort = await errorSendPortCompleter.future;
      final exitReceivePort = await exitReceivePortCompleter.future;
      final isolateTerminateSendPort = await isolateTerminateSendPortCompleter.future;

      final exitReceiveSub = exitReceivePort.listen((message) {
        terminateCompleter.complete(true);
      });

      SerialRepo? serialRepo;
      StreamSubscription<Uint8List>? serialSub;
      StreamSubscription<String>? inputSub;
      try {
        serialRepo = SerialRepo(name: serialPortName);
        serialSub = serialRepo.outputController.stream.listen((data) {
          sendPort.send(String.fromCharCodes(data));
        });
        inputSub = serialInput.stream.listen((message) async {
          serialRepo?.write(message);
        });
      } catch (e) {
        errorSendPort.send('Serial port cannot be opened: $serialPortName');
        terminateCompleter.complete(true);
      }
      final pingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        serialInput.add(SerialData(type: 'Keep Alive', data: 'Ping').toJson());
      });
      await terminateCompleter.future;
      pingTimer.cancel();
      await receiveSub.cancel();
      await serialSub?.cancel();
      await inputSub?.cancel();
      serialRepo?.close();
      exitReceiveSub.cancel();
      exitReceivePort.close();
      isolateTerminateSendPort.send(null);
    });

    _errorSendPort = ReceivePort();
    _exitReceivePort = ReceivePort();
    _isolateTerminateSendPort = ReceivePort();

    await _serialPolling!.create();
    await _serialPolling!.start();

    _inputSub = _inputController!.stream.listen((message) {
      _serialPolling?.send(message);
    });
    _receiveSub = _serialPolling!.receiver.stream.listen((message) {
      if (message is String) {
        _outputController?.add(message);
      }
    });
    _outputSub = _outputController!.stream.listen((message) {
      _handleSerialData(message);
    });
    _errorSub = _errorSendPort!.listen((message) {
      if (message is String) {
        _errorController!.add(ErrorType.internalServerError.addMessage(message));
      }
    });
    _isolateTerminationSub = _isolateTerminateSendPort!.listen((message) {
      _isolateTerminationCompleter!.complete();
    });

    _serialPolling!.send({
      'serialPort': serialPortName,
      'errorSendPort': _errorSendPort!.sendPort,
      'exitReceivePort': _exitReceivePort!,
      'isolateTerminateSendPort': _isolateTerminateSendPort!.sendPort,
    });

    _isPolling = true;
    _pollingController!.add(true);

    final isEnabled = session.oscilloscope.target!.isEnabled;
    final isAppropriate = session.oscilloscope.target!.appropriate;
    if (isEnabled && isAppropriate) {
      await OscilloscopeApiProvider.template(
        session.oscilloscope.target!.ip!,
        session.oscilloscope.target!.port!,
        (provider) {
          if (session.oscilloscope.target!.decodeModeEnum != null) {
            provider.runWithOutReturning(
              setDecodeModeCommand(
                OscilloscopeDecoder.one,
                session.oscilloscope.target!.decodeModeEnum!,
              ),
            );
          }
          if (session.oscilloscope.target!.decodeFormatEnum != null) {
            provider.runWithOutReturning(
              setDecodeFormatCommand(
                OscilloscopeDecoder.one,
                session.oscilloscope.target!.decodeFormatEnum!,
              ),
            );
          }
          provider.runWithOutReturning(setOscilloscopeModeCommand(Mode.CLEAR));
          provider.runWithOutReturning(setOscilloscopeModeCommand(Mode.SINGLE));
        },
      );
    }

    final newSession = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (
      store,
      params,
    ) {
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.internalServerError.addMessage('Session not found');
      }
      session.isRunning = true;
      session.startedAt = DateTime.now().toUtc();
      session.lastUsedAt = DateTime.now().toUtc();
      session.updatedAt = DateTime.now().toUtc();
      final id = sessionBox.put(session);
      return sessionBox.get(id);
    }, [sessionId]);

    _keepAlive = Timer(SessionRepo.timeout, keepAliveFunction);

    if (newSession == null) {
      throw ErrorType.internalServerError.addMessage('Failed to create session');
    }

    return newSession;
  }

  Future<SessionEntity> stopPolling() async {
    if (!_isPolling) {
      throw ErrorType.internalServerError.addMessage('No session');
    }
    await wsRepo.removeAllWebSocket();
    _exitReceivePort!.sendPort.send(true);
    await _isolateTerminationCompleter!.future;
    _keepAlive?.cancel();
    await _inputSub!.cancel();
    await _receiveSub!.cancel();
    await _outputSub!.cancel();
    await _errorSub!.cancel();
    await _isolateTerminationSub!.cancel();
    await _serialPolling!.stop();
    await _inputController!.close();
    await _outputController!.close();
    await _errorController!.close();
    await _pollingController!.close();
    _errorSendPort!.close();
    _exitReceivePort!.close();
    _isolateTerminateSendPort!.close();

    _inputController = null;
    _outputController = null;
    _errorController = null;
    _pollingController = null;
    _errorSendPort = null;
    _exitReceivePort = null;
    _isolateTerminateSendPort = null;
    _inputSub = null;
    _receiveSub = null;
    _outputSub = null;
    _errorSub = null;
    _isolateTerminationSub = null;
    _isolateTerminationCompleter = null;
    _serialPolling = null;
    _sessionId = null;
    _keepAlive = null;

    final session = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.internalServerError.addMessage('Session not found');
      }
      session.isRunning = false;
      session.stoppedAt = DateTime.now().toUtc();
      session.updatedAt = DateTime.now().toUtc();
      final id = sessionBox.put(session);
      return sessionBox.get(id);
    }, [sessionId]);

    _isPolling = false;

    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to stop session');
    }

    return session;
  }

  Future<SessionEntity> createSession(String name) async {
    final session = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (
      store,
      serialPortName,
    ) {
      final sessionBox = DatabaseRepo().store.box<SessionEntity>();
      final session = SessionEntity(
        name: name,
        isRunning: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      final i2cEntity = I2cEntity(
        isEnabled: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      final spiEntity = SpiEntity(
        isEnabled: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      final modbusEntity = ModbusEntity(
        isEnabled: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      final oscilloscopeEntity = OscilloscopeEntity(
        isEnabled: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      session.i2c.target = i2cEntity;
      session.spi.target = spiEntity;
      session.modbus.target = modbusEntity;
      session.oscilloscope.target = oscilloscopeEntity;
      final sessionId = sessionBox.put(session);
      return sessionBox.get(sessionId);
    }, [name]);
    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to create session');
    }
    return session;
  }

  Future<SessionEntity> getSession(int id) async {
    final session = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      return sessionBox.get(id);
    }, [id]);
    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to get session');
    }
    return session;
  }

  Future<SessionEntity> getSessionByName(String name) async {
    final session = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      final [name] = params;
      return sessionBox.query(SessionEntity_.name.equals(name)).build().findFirst();
    }, [name]);
    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to get session');
    }
    return session;
  }

  Future<List<SessionEntity>> getSessions(
    int sessionPerPage,
    int page, {
    String? searchParam,
  }) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      final [sessionPerPage as int, page as int, searchParam as String?] = params;
      final query =
          sessionBox
              .query(
                searchParam?.replaceAll(' ', '').isEmpty ?? true
                    ? null
                    : SessionEntity_.name.contains(searchParam!),
              )
              .build();

      if (sessionPerPage < 1) {
        throw ErrorType.invalidRequest.addMessage('Session per page must not be less than 1');
      }
      if (page < 1) {
        throw ErrorType.invalidRequest.addMessage('Page must not be less than 1');
      }
      query.offset = (sessionPerPage * (page - 1));
      query.limit = sessionPerPage;
      return query.find();
    }, [sessionPerPage, page, searchParam]);
  }

  Future<List<SpiMsgEntity>> getAllSpiMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final spiMsgs = session.spi.target?.spiMsgEntities.sortedBy((e) => e.createdAt);
      if (spiMsgs == null) {
        throw ErrorType.badRequest.addMessage('No SPI messages found');
      }
      return spiMsgs;
    }, [sessionId]);
  }

  Future<List<I2cMsgEntity>> getAllI2cMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final i2cMsgs = session.i2c.target?.i2cMsgEntities.sortedBy((e) => e.createdAt);
      if (i2cMsgs == null) {
        throw ErrorType.badRequest.addMessage('No I2C messages found');
      }
      return i2cMsgs;
    }, [sessionId]);
  }

  Future<List<ModbusMsgEntity>> getAllModbusMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final modbusMsgs = session.modbus.target?.modbusMsgEntities.sortedBy((e) => e.createdAt);
      if (modbusMsgs == null) {
        throw ErrorType.badRequest.addMessage('No Modbus messages found');
      }
      return modbusMsgs;
    }, [sessionId]);
  }

  Future<List<OscilloscopeMsgEntity>> getAllOscilloscopeMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final oscilloscopeMsgs = session.oscilloscope.target?.oscilloscopeMsgEntities.sortedBy(
        (e) => e.createdAt,
      );
      if (oscilloscopeMsgs == null) {
        throw ErrorType.badRequest.addMessage('No Oscilloscope messages found');
      }
      return oscilloscopeMsgs;
    }, [sessionId]);
  }

  Future<List<LogEntity>> getAllLog(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final logs = session.logs.sortedBy((e) => e.createdAt);
      if (logs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No logs found');
      }
      return logs;
    }, [sessionId]);
  }

  Future<SpiMsgEntity> getLatestSpiMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final spiMsgs = session.spi.target?.spiMsgEntities.sortedBy((e) => e.createdAt);
      if (spiMsgs == null || spiMsgs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No SPI messages found');
      }
      final spiMsg = spiMsgs.last;
      return spiMsg;
    }, [sessionId]);
  }

  Future<I2cMsgEntity> getLatestI2cMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final i2cMsgs = session.i2c.target?.i2cMsgEntities.sortedBy((e) => e.createdAt);
      if (i2cMsgs == null || i2cMsgs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No I2C messages found');
      }
      final i2cMsg = i2cMsgs.last;
      return i2cMsg;
    }, [sessionId]);
  }

  Future<ModbusMsgEntity> getLatestModbusMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final modbusMsgs = session.modbus.target?.modbusMsgEntities.sortedBy((e) => e.createdAt);
      if (modbusMsgs == null || modbusMsgs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No Modbus messages found');
      }
      final modbusMsg = modbusMsgs.last;
      return modbusMsg;
    }, [sessionId]);
  }

  Future<OscilloscopeMsgEntity> getLatestOscilloscopeMsg(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final oscilloscopeMsgs = session.oscilloscope.target?.oscilloscopeMsgEntities.sortedBy(
        (e) => e.createdAt,
      );
      if (oscilloscopeMsgs == null || oscilloscopeMsgs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No Oscilloscope messages found');
      }
      final oscilloscopeMsg = oscilloscopeMsgs.last;
      return oscilloscopeMsg;
    }, [sessionId]);
  }

  Future<LogEntity> getLatestLog(int sessionId) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final [sessionId] = params;
      final sessionBox = store.box<SessionEntity>();
      final session = sessionBox.get(sessionId);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final logs = session.logs.sortedBy((e) => e.createdAt);
      if (logs.isEmpty) {
        throw ErrorType.badRequest.addMessage('No logs found');
      }
      final log = logs.last;
      return log;
    }, [sessionId]);
  }

  Future<SessionEntity> editSession(
    int id, {
    String? name,
    bool? enableI2c,
    bool? enableSpi,
    bool? enableModbus,
    bool? enableOscilloscope,
    String? ip,
    int? port,
    int? activeDecodeMode,
    int? activeDecodeFormat,
  }) async {
    final session = await DatabaseRepo().store.runInTransactionAsync(
      TxMode.write,
      (store, params) {
        final [
          id as int,
          name as String?,
          enableI2c as bool?,
          enableSpi as bool?,
          enableModbus as bool?,
          enableOscilloscope as bool?,
          ip as String?,
          port as int?,
        ] = params;
        final sessionBox = DatabaseRepo().store.box<SessionEntity>();
        final session = sessionBox.get(id);
        if (session == null) {
          throw ErrorType.badRequest.addMessage('Session not found');
        }
        if ([enableI2c, enableSpi, enableModbus].where((e) => e == true).length > 1) {
          throw ErrorType.badRequest.addMessage('Only one peripheral can be enabled at a time');
        }
        if (enableI2c == true) {
          session.spi.target?.isEnabled = false;
          session.modbus.target?.isEnabled = false;
        } else if (enableSpi == true) {
          session.i2c.target?.isEnabled = false;
          session.modbus.target?.isEnabled = false;
        } else if (enableModbus == true) {
          session.i2c.target?.isEnabled = false;
          session.spi.target?.isEnabled = false;
        }
        if (enableI2c != null) {
          session.i2c.target?.isEnabled = enableI2c;
        }
        if (enableSpi != null) {
          session.spi.target?.isEnabled = enableSpi;
        }
        if (enableModbus != null) {
          session.modbus.target?.isEnabled = enableModbus;
        }

        final checkEnableOscilloscopeIsAppropriate = () {
          final oscilloscopeEntityIsEnabled = session.oscilloscope.target?.isEnabled;
          if (oscilloscopeEntityIsEnabled == null) {
            return enableOscilloscope == true && ip != null && port != null;
          }
          return true;
        }();
        if (checkEnableOscilloscopeIsAppropriate) {
          session.oscilloscope.target?.isEnabled = enableOscilloscope!;
          session.oscilloscope.target?.ip = ip!;
          session.oscilloscope.target?.port = port!;
        }
        if (activeDecodeMode != null) {
          session.oscilloscope.target?.activeDecodeMode = activeDecodeMode;
        }
        if (activeDecodeFormat != null) {
          session.oscilloscope.target?.activeDecodeFormat = activeDecodeFormat;
        }
        if (name != null) {
          session.name = name;
        }

        session.updatedAt = DateTime.now().toUtc();

        return sessionBox.get(sessionBox.put(session));
      },
      [
        id,
        name,
        enableI2c,
        enableSpi,
        enableModbus,
        ip,
        port,
        activeDecodeMode,
        activeDecodeFormat,
      ],
    );
    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to edit session');
    }

    if (session.id == sessionId) {
      if (enableI2c == true) {
        _serialPolling?.send({
          'command': SerialData(type: 'I2C', data: 'Enable').toJson(),
          'target': 'serial',
        });
      } else if (enableSpi == true) {
        _serialPolling?.send({
          'command': SerialData(type: 'SPI', data: 'Enable').toJson(),
          'target': 'serial',
        });
      } else if (enableModbus == true) {
        _serialPolling?.send({
          'command': SerialData(type: 'Modbus', data: 'Enable').toJson(),
          'target': 'serial',
        });
      }

      final isEnabled = session.oscilloscope.target!.isEnabled;
      final isAppropriate = session.oscilloscope.target!.appropriate;
      if (isEnabled && isAppropriate) {
        await OscilloscopeApiProvider.template(
          session.oscilloscope.target!.ip!,
          session.oscilloscope.target!.port!,
          (provider) {
            if (session.oscilloscope.target!.decodeModeEnum != null) {
              provider.runWithOutReturning(
                setDecodeModeCommand(
                  OscilloscopeDecoder.one,
                  session.oscilloscope.target!.decodeModeEnum!,
                ),
              );
            }
            if (session.oscilloscope.target!.decodeFormatEnum != null) {
              provider.runWithOutReturning(
                setDecodeFormatCommand(
                  OscilloscopeDecoder.one,
                  session.oscilloscope.target!.decodeFormatEnum!,
                ),
              );
            }
            provider.runWithOutReturning(setOscilloscopeModeCommand(Mode.CLEAR));
            provider.runWithOutReturning(setOscilloscopeModeCommand(Mode.SINGLE));
          },
        );
      }
    }

    return session;
  }

  Future<List<bool>> deleteSession(int id) async {
    if (id == sessionId) {
      await stopPolling();
    }

    final result = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      final logBox = store.box<LogEntity>();
      final i2cBox = store.box<I2cEntity>();
      final spiBox = store.box<SpiEntity>();
      final modbusBox = store.box<ModbusEntity>();
      final oscilloscopeBox = store.box<OscilloscopeEntity>();
      final i2cMsgBox = store.box<I2cMsgEntity>();
      final spiMsgBox = store.box<SpiMsgEntity>();
      final modbusMsgBox = store.box<ModbusMsgEntity>();
      final oscilloscopeMsgBox = store.box<OscilloscopeMsgEntity>();
      final [id] = params;

      final session = sessionBox.get(id);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      final successList = <bool>[];
      final logs = session.logs;
      for (final log in logs) {
        logBox.remove(log.id);
      }
      if (session.i2c.target != null) {
        final i2c = session.i2c.target!;
        for (var i2cMsg in i2c.i2cMsgEntities) {
          successList.add(i2cMsgBox.remove(i2cMsg.id));
        }
        successList.add(i2cBox.remove(i2c.id));
      }
      if (session.spi.target != null) {
        final spi = session.spi.target!;
        for (var spiMsg in spi.spiMsgEntities) {
          successList.add(spiMsgBox.remove(spiMsg.id));
        }
        successList.add(spiBox.remove(spi.id));
      }
      if (session.modbus.target != null) {
        final modbus = session.modbus.target!;
        for (var modbusMsg in modbus.modbusMsgEntities) {
          successList.add(modbusMsgBox.remove(modbusMsg.id));
        }
        successList.add(modbusBox.remove(modbus.id));
      }
      if (session.oscilloscope.target != null) {
        final oscilloscope = session.oscilloscope.target!;
        for (var oscilloscopeMsg in oscilloscope.oscilloscopeMsgEntities) {
          successList.add(oscilloscopeMsgBox.remove(oscilloscopeMsg.id));
        }
        successList.add(oscilloscopeBox.remove(oscilloscope.id));
      }
      successList.add(sessionBox.remove(id));
      return successList;
    }, [id]);

    return result;
  }
}
