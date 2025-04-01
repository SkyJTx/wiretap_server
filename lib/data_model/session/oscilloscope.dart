// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/oscilloscope_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/oscilloscope_entity.dart';

class Oscilloscope {
  final int id;
  final String? ip;
  final int? port;
  final bool isEnabled;
  final String? activeDecodeMode;
  final String? activeDecodeFormat;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OscilloscopeMsg> oscilloscopeMsgEntities;

  Oscilloscope({
    required this.id,
    this.ip,
    this.port,
    required this.isEnabled,
    this.activeDecodeMode,
    this.activeDecodeFormat,
    required this.createdAt,
    required this.updatedAt,
    List<OscilloscopeMsg>? oscilloscopeMsgEntities,
  }) : oscilloscopeMsgEntities = oscilloscopeMsgEntities ?? [];

  Oscilloscope copyWith({
    int? id,
    String? ip,
    int? port,
    bool? isEnabled,
    String? activeDecodeMode,
    String? activeDecodeFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OscilloscopeMsg>? oscilloscopeMsgEntities,
  }) {
    return Oscilloscope(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isEnabled: isEnabled ?? this.isEnabled,
      activeDecodeMode: activeDecodeMode ?? this.activeDecodeMode,
      activeDecodeFormat: activeDecodeFormat ?? this.activeDecodeFormat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      oscilloscopeMsgEntities: oscilloscopeMsgEntities ?? this.oscilloscopeMsgEntities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ip': ip,
      'port': port,
      'isEnabled': isEnabled,
      'activeDecodeMode': activeDecodeMode,
      'activeDecodeFormat': activeDecodeFormat,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'oscilloscopeMsgEntities': oscilloscopeMsgEntities.map((x) => x.toMap()).toList(),
    };
  }

  factory Oscilloscope.fromMap(Map<String, dynamic> map) {
    return Oscilloscope(
      id: map['id'] as int,
      ip: map['ip'] != null ? map['ip'] as String : null,
      port: map['port'] != null ? map['port'] as int : null,
      isEnabled: map['isEnabled'] as bool,
      activeDecodeMode: map['activeDecodeMode'] != null ? map['activeDecodeMode'] as String : null,
      activeDecodeFormat:
          map['activeDecodeFormat'] != null ? map['activeDecodeFormat'] as String : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      oscilloscopeMsgEntities: List<OscilloscopeMsg>.from(
        (map['oscilloscopeMsgEntities'] as List<int>).map<OscilloscopeMsg>(
          (x) => OscilloscopeMsg.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory Oscilloscope.fromEntity(OscilloscopeEntity entity) {
    return Oscilloscope(
      id: entity.id,
      ip: entity.ip,
      port: entity.port,
      isEnabled: entity.isEnabled,
      activeDecodeMode: entity.activeDecodeModeEnum?.convertToWireTapSessionEntity(),
      activeDecodeFormat: entity.activeDecodeFormatEnum?.command,
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
      oscilloscopeMsgEntities:
          entity.oscilloscopeMsgEntities.map((e) => OscilloscopeMsg.fromEntity(e)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Oscilloscope.fromJson(String source) =>
      Oscilloscope.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Oscilloscope(id: $id, ip: $ip, port: $port, isEnabled: $isEnabled, activeDecodeMode: $activeDecodeMode, activeDecodeFormat: $activeDecodeFormat, createdAt: $createdAt, updatedAt: $updatedAt, oscilloscopeMsgEntities: $oscilloscopeMsgEntities)';
  }

  @override
  bool operator ==(covariant Oscilloscope other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.ip == ip &&
        other.port == port &&
        other.isEnabled == isEnabled &&
        other.activeDecodeMode == activeDecodeMode &&
        other.activeDecodeFormat == activeDecodeFormat &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.oscilloscopeMsgEntities, oscilloscopeMsgEntities);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ip.hashCode ^
        port.hashCode ^
        isEnabled.hashCode ^
        activeDecodeMode.hashCode ^
        activeDecodeFormat.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        oscilloscopeMsgEntities.hashCode;
  }
}

class OscilloscopeMsg {
  final int id;
  final bool isDecodeEnabled;
  final String? decodeMode;
  final String? decodeFormat;
  final String? imageFilePath;
  final DateTime? createdAt;

  OscilloscopeMsg({
    required this.id,
    required this.isDecodeEnabled,
    this.decodeMode,
    this.decodeFormat,
    this.imageFilePath,
    this.createdAt,
  });

  OscilloscopeMsg copyWith({
    int? id,
    bool? isDecodeEnabled,
    String? decodeMode,
    String? decodeFormat,
    String? imageFilePath,
    DateTime? createdAt,
  }) {
    return OscilloscopeMsg(
      id: id ?? this.id,
      isDecodeEnabled: isDecodeEnabled ?? this.isDecodeEnabled,
      decodeMode: decodeMode ?? this.decodeMode,
      decodeFormat: decodeFormat ?? this.decodeFormat,
      imageFilePath: imageFilePath ?? this.imageFilePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'isDecodeEnabled': isDecodeEnabled,
      'decodeMode': decodeMode,
      'decodeFormat': decodeFormat,
      'imageFilePath': imageFilePath,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  factory OscilloscopeMsg.fromMap(Map<String, dynamic> map) {
    return OscilloscopeMsg(
      id: map['id'] as int,
      isDecodeEnabled: map['isDecodeEnabled'] as bool,
      decodeMode: map['decodeMode'] != null ? map['decodeMode'] as String : null,
      decodeFormat: map['decodeFormat'] != null ? map['decodeFormat'] as String : null,
      imageFilePath: map['imageFilePath'] != null ? map['imageFilePath'] as String : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
    );
  }

  factory OscilloscopeMsg.fromEntity(OscilloscopeMsgEntity entity) {
    return OscilloscopeMsg(
      id: entity.id,
      isDecodeEnabled: entity.isDecodeEnabled,
      decodeMode: entity.decodeModeEnum?.convertToWireTapSessionEntity(),
      decodeFormat: entity.decodeFormatEnum?.command,
      imageFilePath: entity.imageFilePath,
      createdAt: entity.createdAt.toUtc(),
    );
  }

  String toJson() => json.encode(toMap());

  factory OscilloscopeMsg.fromJson(String source) =>
      OscilloscopeMsg.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OscilloscopeMsg(id: $id, isDecodeEnabled: $isDecodeEnabled, decodeMode: $decodeMode, decodeFormat: $decodeFormat, imageFilePath: $imageFilePath, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant OscilloscopeMsg other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.isDecodeEnabled == isDecodeEnabled &&
        other.decodeMode == decodeMode &&
        other.decodeFormat == decodeFormat &&
        other.imageFilePath == imageFilePath &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        isDecodeEnabled.hashCode ^
        decodeMode.hashCode ^
        decodeFormat.hashCode ^
        imageFilePath.hashCode ^
        createdAt.hashCode;
  }
}
