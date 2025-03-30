import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:wiretap_server/constant/oscilloscope/oscilloscope.dart';

class TriggerData extends Equatable {
  final Channel channel;
  final EdgeType edge;
  final double level;

  const TriggerData({
    required this.channel,
    required this.edge,
    required this.level,
  });

  TriggerData copyWith({
    Channel? channel,
    EdgeType? edge,
    double? level,
  }) {
    return TriggerData(
      channel: channel ?? this.channel,
      edge: edge ?? this.edge,
      level: level ?? this.level,
    );
  }

  factory TriggerData.fromJson(Map<String, Object?> json) {
    return TriggerData(
      channel: json['channel'] as Channel,
      edge: json['edge'] as EdgeType,
      level: json['level'] as double,
    );
  }

  factory TriggerData.fromJsonString(String json) {
    return TriggerData.fromJson(
      jsonDecode(json) as Map<String, Object?>,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'channel': channel,
      'edge': edge,
      'level': level,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  List<Object?> get props => [
        channel,
        edge,
        level,
      ];
}
