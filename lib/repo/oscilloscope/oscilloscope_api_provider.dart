import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/oscilloscope/channel_data.dart';
import 'package:wiretap_server/data_model/oscilloscope/trigger_data.dart';

class OscilloscopeApiProvider {
  Socket? _socket;
  Stream<Uint8List>? _broadcastStream;
  Completer<bool> _connectedCompleter = Completer<bool>();
  final String ip;
  final int port;

  OscilloscopeApiProvider({
    required this.ip,
    required this.port,
  });

  static FutureOr<T> template<T>(String ip, int port, FutureOr<T> Function(OscilloscopeApiProvider provider) function) async {
    final oscilloscope = OscilloscopeApiProvider(ip: ip, port: port);
    
    try {
      await oscilloscope.connect();
      return await function(oscilloscope);
    } finally {
      await oscilloscope.disconnect();
    }
  }

  bool get isConnected {
    return _connectedCompleter.isCompleted;
  }

  Future<bool> get connected {
    return _connectedCompleter.future;
  }

  Socket get socket {
    if (_socket == null || !isConnected) throw Exception('Not connected to oscilloscope');
    return _socket!;
  }

  Stream<Uint8List> get broadcastStream {
    if (_broadcastStream == null) throw Exception('Broadcast stream is null');
    return _broadcastStream!;
  }

  Future<void> connect({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (isConnected) return;

    _socket = await Socket.connect(ip, port, timeout: timeout);
    _broadcastStream = _socket!.asBroadcastStream();

    _connectedCompleter.complete(true);
  }

  Future<void> disconnect() async {
    if (!isConnected) return;
    _broadcastStream = null;
    await _socket!.close();
    _socket = null;

    _connectedCompleter = Completer<bool>();
  }

  Future<Uint8List> capture({
    bool color = true,
    bool invert = false,
    CaptureFormat format = CaptureFormat.PNG,
  }) async {
    final result = await run(
      ':DISP:DATA? ${color.stringSwitch},${invert.stringSwitch},${format.string}',
      removeNewLine: false,
    );
    return result.sublist(11);
  }

  Future<ChannelData> getEachChannelData(Channel channel) async {
    final state = await getChannelData<bool>(channel, ChannelEnum.state);
    final probeScale = await getChannelData<double>(channel, ChannelEnum.probeScale);
    final voltsPerDiv = await getChannelData<double>(channel, ChannelEnum.voltsPerDiv);
    final offset = await getChannelData<double>(channel, ChannelEnum.offset);
    final coupling = await getChannelData<Coupling>(channel, ChannelEnum.coupling);

    return ChannelData(
      channel: channel,
      state: state,
      probeScale: probeScale,
      voltsPerDiv: voltsPerDiv,
      offset: offset,
      coupling: coupling,
    );
  }

  Future<List<ChannelData>> getAllChannelsData() async {
    return [
      for (final channel in Channel.values) await getEachChannelData(channel)
    ];
  }

  Future<TriggerData> getAllTriggerData() async {
    return TriggerData(
      channel: await getTriggerChannel(),
      edge: await getTriggerEdgeType(),
      level: await getTriggerLevel(),
    );
  }

  Future<T> getChannelData<T>(Channel channel, ChannelEnum data) async {
    final result = await run(':CHAN${channel.number}:${data.string}?');
    return data.deserialize<T>(String.fromCharCodes(result));
  }

  Future<double> getTimebase() async {
    final result = await run(':TIM:MAIN:SCAL?');
    return OscilloscopeData.timePerDiv.deserialize<double>(String.fromCharCodes(result));
  }

  Future<Channel> getTriggerChannel() async {
    final result = await run(':TRIG:EDGE:SOUR?');
    return OscilloscopeData.channel.deserialize<Channel>(String.fromCharCodes(result));
  }

  Future<EdgeType> getTriggerEdgeType() async {
    final result = await run(':TRIG:EDGE:SLOP?');
    return OscilloscopeData.triggerEdgeType.deserialize<EdgeType>(String.fromCharCodes(result));
  }

  Future<double> getTriggerLevel() async {
    final result = await run(':TRIG:EDGE:LEV?');
    return OscilloscopeData.triggerLevel.deserialize<double>(String.fromCharCodes(result));
  }

  Future<void> setMode(Mode mode) async {
    await run(':${mode.string}');
  }

  Future<void> setChannel(
    Channel channel, {
    bool state = true,
    int? probeScale,
    double? voltsPerDiv,
    double? offset,
    Coupling? coupling,
  }) async {
    await run(':CHAN${channel.number}:DISP ${state.stringSwitch}');
    if (!state) return;

    if (probeScale != null) {
      await run(':CHAN${channel.number}:PROB $probeScale');
    }

    if (voltsPerDiv != null) {
      await run(':CHAN${channel.number}:SCAL ${voltsPerDiv.toStringAsFixed(1)}');
    }

    if (offset != null) {
      await run(':CHAN${channel.number}:OFFS ${offset.toStringAsFixed(1)}');
    }

    if (coupling != null) {
      await run(':CHAN${channel.number}:COUP ${coupling.string}');
    }
  }

  Future<void> setTimebase({
    double timePerDiv = 0.001,
  }) async {
    final tpd =
        timePerDiv < 0 ? timePerDiv.toStringAsExponential(1) : timePerDiv.toStringAsFixed(1);
    await run(':TIM:MAIN:SCAL $tpd');
  }

  Future<void> setTrigger(
    Channel channel, {
    EdgeType? edge = EdgeType.POS,
    double? level,
  }) async {
    await run(':TRIG:MODE EDGE');
    await run(':TRIG:EDGE:SOUR CHAN${channel.number}');

    if (edge != null) {
      await run(':TRIG:EDGE:SLOP ${edge.string}');
    }

    if (level != null) {
      await run(':TRIG:EDGE:LEV $level');
    }
  }

  void runWithOutReturning(String command) {
    if (!isConnected) {
      throw ErrorType.internalServerError.addMessage('Not connected to oscilloscope');
    }
    socket.writeln(command);
  }

  Future<Uint8List> run(
    String command, {
    bool isWriteMode = true,
    bool removeNewLine = true,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<Uint8List>();
    final timeoutTimer = Timer(timeout, () {
      completer.completeError(ErrorType);
    });
    if (!isConnected) throw ErrorType.internalServerError.addMessage('Not connected to oscilloscope');

    socket.writeln(command);

    BytesBuilder respData = BytesBuilder();

    final sub = broadcastStream.listen((data) {
      final strData = String.fromCharCodes(data);
      respData.add(data);
      if (strData.endsWith('\n') || strData.endsWith('\r')) {
        if (removeNewLine) {
          final respByteList = respData.toBytes().toList();
          final noLastByte = respByteList.sublist(0, respByteList.length - 1);

          completer.complete(Uint8List.fromList(noLastByte));
        } else {
          completer.complete(respData.toBytes());
        }
      }
    });

    return await completer.future.whenComplete(() async {
      await sub.cancel();
      timeoutTimer.cancel();
      if (isWriteMode) {
        await socket.flush();
      }
    });
  }
}
