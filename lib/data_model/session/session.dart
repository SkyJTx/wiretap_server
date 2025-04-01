// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:wiretap_server/data_model/session/i2c.dart';
import 'package:wiretap_server/data_model/session/log.dart';
import 'package:wiretap_server/data_model/session/modbus.dart';
import 'package:wiretap_server/data_model/session/oscilloscope.dart';
import 'package:wiretap_server/data_model/session/spi.dart';
import 'package:wiretap_server/repo/database/entity/session_entity/session_entity.dart';

class Session {
  final int id;
  final String name;
  final bool isRunning;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final DateTime? stoppedAt;
  final DateTime? startedAt;
  final List<Log> logs;
  final I2c i2c;
  final Spi spi;
  final Modbus modbus;
  final Oscilloscope oscilloscope;

  Session({
    List<Log>? logs,
    required this.id,
    required this.name,
    required this.isRunning,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.stoppedAt,
    this.startedAt,
    required this.i2c,
    required this.spi,
    required this.modbus,
    required this.oscilloscope,
  }) : logs = logs ?? [];

  Session copyWith({
    int? id,
    String? name,
    bool? isRunning,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    DateTime? stoppedAt,
    DateTime? startedAt,
    List<Log>? logs,
    I2c? i2c,
    Spi? spi,
    Modbus? modbus,
    Oscilloscope? oscilloscope,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      isRunning: isRunning ?? this.isRunning,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      startedAt: startedAt ?? this.startedAt,
      logs: logs ?? this.logs,
      i2c: i2c ?? this.i2c,
      spi: spi ?? this.spi,
      modbus: modbus ?? this.modbus,
      oscilloscope: oscilloscope ?? this.oscilloscope,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'isRunning': isRunning,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt?.toUtc().toIso8601String(),
      'stoppedAt': stoppedAt?.toUtc().toIso8601String(),
      'startedAt': startedAt?.toUtc().toIso8601String(),
      'logs': logs.map((x) => x.toMap()).toList(),
      'i2c': i2c.toMap(),
      'spi': spi.toMap(),
      'modbus': modbus.toMap(),
      'oscilloscope': oscilloscope.toMap(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int,
      name: map['name'] as String,
      isRunning: map['isRunning'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastUsedAt: map['lastUsedAt'] != null ? DateTime.parse(map['lastUsedAt'] as String) : null,
      stoppedAt: map['stoppedAt'] != null ? DateTime.parse(map['stoppedAt'] as String) : null,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : null,
      logs: List<Log>.from(
        (map['logs'] as List<int>).map<Log>((x) => Log.fromMap(x as Map<String, dynamic>)),
      ),
      i2c: I2c.fromMap(map['i2c'] as Map<String, dynamic>),
      spi: Spi.fromMap(map['spi'] as Map<String, dynamic>),
      modbus: Modbus.fromMap(map['modbus'] as Map<String, dynamic>),
      oscilloscope: Oscilloscope.fromMap(map['oscilloscope'] as Map<String, dynamic>),
    );
  }

  factory Session.fromEntity(SessionEntity entity) {
    return Session(
      id: entity.id,
      name: entity.name,
      isRunning: entity.isRunning,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastUsedAt: entity.lastUsedAt,
      stoppedAt: entity.stoppedAt,
      startedAt: entity.startedAt,
      logs: entity.logs.map((e) => Log.fromEntity(e)).toList(),
      i2c: I2c.fromEntity(entity.i2c.target!),
      spi: Spi.fromEntity(entity.spi.target!),
      modbus: Modbus.fromEntity(entity.modbus.target!),
      oscilloscope: Oscilloscope.fromEntity(entity.oscilloscope.target!),
    );
  }

  String toJson() => json.encode(toMap());

  factory Session.fromJson(String source) =>
      Session.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Session(id: $id, name: $name, isRunning: $isRunning, createdAt: $createdAt, updatedAt: $updatedAt, lastUsedAt: $lastUsedAt, stoppedAt: $stoppedAt, startedAt: $startedAt, logs: $logs, i2c: $i2c, spi: $spi, modbus: $modbus, oscilloscope: $oscilloscope)';
  }

  @override
  bool operator ==(covariant Session other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.name == name &&
        other.isRunning == isRunning &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastUsedAt == lastUsedAt &&
        other.stoppedAt == stoppedAt &&
        other.startedAt == startedAt &&
        listEquals(other.logs, logs) &&
        other.i2c == i2c &&
        other.spi == spi &&
        other.modbus == modbus &&
        other.oscilloscope == oscilloscope;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        isRunning.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        lastUsedAt.hashCode ^
        stoppedAt.hashCode ^
        startedAt.hashCode ^
        logs.hashCode ^
        i2c.hashCode ^
        spi.hashCode ^
        modbus.hashCode ^
        oscilloscope.hashCode;
  }
}
