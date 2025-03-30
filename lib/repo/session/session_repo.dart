import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';
import 'package:wiretap_server/component/task.dart';
import 'package:wiretap_server/constant/error.dart';
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
import 'package:wiretap_server/repo/oscilloscope/oscilloscope_repo.dart';
import 'package:wiretap_server/repo/serial/serial_repo.dart';
import 'package:wiretap_server/repo/websocket/websocket_repo.dart';

class SessionRepo {
  SessionRepo.createInstance();

  static SessionRepo? _instance;

  factory SessionRepo() {
    _instance ??= SessionRepo.createInstance();
    return _instance!;
  }

  final Task _serialPolling = Task((receivePort, sendPort) async {
    final serialPortNameCompleter = Completer<String>();
    final errorSendPortCompleter = Completer<SendPort>();
    final exitReceivePortCompleter = Completer<ReceivePort>();
    final isolateTerminateSendPortCompleter = Completer<SendPort>();
    final terminateCompleter = Completer<bool>();

    receivePort.listen((message) {
      if (message is Map<String, dynamic> &&
          message['serialPort'] is String &&
          message['errorSendPort'] is SendPort &&
          message['exitReceivePort'] is ReceivePort &&
          message['isolateTerminateSendPort'] is SendPort) {
        serialPortNameCompleter.complete(message['serialPort']);
        errorSendPortCompleter.complete(message['errorSendPort']);
        exitReceivePortCompleter.complete(message['exitReceivePort']);
        isolateTerminateSendPortCompleter.complete(message['isolateTerminateSendPort']);
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
    try {
      serialRepo = SerialRepo(name: serialPortName);
      serialSub = serialRepo.outputController.stream.listen((data) {
        sendPort.send(data);
      });
    } catch (e) {
      errorSendPort.send('Serial port cannot be opened: $serialPortName');
      terminateCompleter.complete(true);
    }

    await terminateCompleter.future;
    await serialSub?.cancel();
    serialRepo?.close();
    exitReceiveSub.cancel();
    exitReceivePort.close();
    isolateTerminateSendPort.send(null);
  });

  final wsRepo = WebsocketRepo.createInstance();

  String? ip;
  int? port;
  int? sessionId;
  SessionEntity? get session {
    if (sessionId == null) return null;
    return DatabaseRepo().store.box<SessionEntity>().get(sessionId!);
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

  Future<SessionEntity> editSession(int id, {String? name}) async {
    final session = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final sessionBox = store.box<SessionEntity>();
      final [id as int, name as String?] = params;
      final session = sessionBox.get(id);
      if (session == null) {
        throw ErrorType.badRequest.addMessage('Session not found');
      }
      if (name != null) {
        session.name = name;
        session.updatedAt = DateTime.now().toUtc();
      }
      final realId = sessionBox.put(session);
      return sessionBox.get(realId);
    }, [id, name]);
    if (session == null) {
      throw ErrorType.internalServerError.addMessage('Failed to edit session');
    }
    return session;
  }

  Future<List<bool>> deleteSession(int id) async {
    return DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
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
  }
}
