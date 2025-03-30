import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:wiretap_server/constant/oscilloscope/oscilloscope.dart';

class ChannelData extends Equatable {
  final Channel channel;
  final bool state;
  final double probeScale;
  final double voltsPerDiv;
  final double offset;
  final Coupling coupling;

  const ChannelData({
    required this.channel,
    required this.state,
    required this.probeScale,
    required this.voltsPerDiv,
    required this.offset,
    required this.coupling,
  });

  ChannelData copyWith({
    Channel? channel,
    bool? state,
    double? probeScale,
    double? voltsPerDiv,
    double? offset,
    Coupling? coupling,
  }) {
    return ChannelData(
      channel: channel ?? this.channel,
      state: state ?? this.state,
      probeScale: probeScale ?? this.probeScale,
      voltsPerDiv: voltsPerDiv ?? this.voltsPerDiv,
      offset: offset ?? this.offset,
      coupling: coupling ?? this.coupling,
    );
  }

  factory ChannelData.fromJson(Map<String, Object?> json) {
    return ChannelData(
      channel: json['channel'] as Channel,
      state: json['state'] as bool,
      probeScale: json['probeScale'] as double,
      voltsPerDiv: json['voltsPerDiv'] as double,
      offset: json['offset'] as double,
      coupling: json['coupling'] as Coupling,
    );
  }

  factory ChannelData.fromJsonString(String json) {
    return ChannelData.fromJson(
      jsonDecode(json) as Map<String, Object?>
    );
  }

  Map<String, Object?> toJson() {
    return {
      'channel': channel,
      'state': state,
      'probeScale': probeScale,
      'voltsPerDiv': voltsPerDiv,
      'offset': offset,
      'coupling': coupling,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  List<Object?> get props => [
        channel,
        state,
        probeScale,
        voltsPerDiv,
        offset,
        coupling,
      ];
}

extension ChannelDatas on List<ChannelData> {
  List<Map<String, Object?>> toJson() {
    return map((e) => e.toJson()).toList();
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static List<ChannelData> fromJson(List<Map<String, Object?>> json) {
    return json.map((e) => ChannelData.fromJson(e)).toList();
  }

  static List<ChannelData> fromJsonString(String json) {
    return fromJson(
      jsonDecode(json) as List<Map<String, Object?>>,
    );
  }
}
