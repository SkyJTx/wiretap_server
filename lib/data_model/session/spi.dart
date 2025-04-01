// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:wiretap_server/repo/database/entity/message_entity/spi_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/spi_entity.dart';

class Spi {
  final int id;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SpiMsg> spiMsgEntities;

  Spi({
    required this.id,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
    List<SpiMsg>? spiMsgEntities,
  }) : spiMsgEntities = spiMsgEntities ?? [];

  Spi copyWith({
    int? id,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SpiMsg>? spiMsgEntities,
  }) {
    return Spi(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spiMsgEntities: spiMsgEntities ?? this.spiMsgEntities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'spiMsgEntities': spiMsgEntities.map((x) => x.toMap()).toList(),
    };
  }

  factory Spi.fromMap(Map<String, dynamic> map) {
    return Spi(
      id: map['id'] as int,
      isEnabled: map['isEnabled'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      spiMsgEntities: List<SpiMsg>.from(
        (map['spiMsgEntities'] as List<dynamic>).map<SpiMsg>(
          (x) => SpiMsg.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory Spi.fromEntity(SpiEntity entity) {
    return Spi(
      id: entity.id,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
      spiMsgEntities: List<SpiMsg>.from(
        (entity.spiMsgEntities as List<SpiMsgEntity>).map<SpiMsg>(
          (x) => SpiMsg.fromEntity(x),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Spi.fromJson(String source) => Spi.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Spi(id: $id, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant Spi other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.isEnabled == isEnabled &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.spiMsgEntities == spiMsgEntities;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      isEnabled.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      spiMsgEntities.hashCode;
  }
}

class SpiMsg {
  final int id;
  final String mosi;
  final String miso;
  final DateTime createdAt;

  SpiMsg({
    required this.id,
    required this.mosi,
    required this.miso,
    required this.createdAt,
  });
  

  SpiMsg copyWith({
    int? id,
    String? mosi,
    String? miso,
    DateTime? createdAt,
  }) {
    return SpiMsg(
      id: id ?? this.id,
      mosi: mosi ?? this.mosi,
      miso: miso ?? this.miso,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'mosi': mosi,
      'miso': miso,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory SpiMsg.fromMap(Map<String, dynamic> map) {
    return SpiMsg(
      id: map['id'] as int,
      mosi: map['mosi'] as String,
      miso: map['miso'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory SpiMsg.fromEntity(SpiMsgEntity entity) {
    return SpiMsg(
      id: entity.id,
      mosi: entity.mosi,
      miso: entity.miso,
      createdAt: entity.createdAt.toUtc(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SpiMsg.fromJson(String source) => SpiMsg.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SpiMsg(id: $id, mosi: $mosi, miso: $miso, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant SpiMsg other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.mosi == mosi &&
      other.miso == miso &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      mosi.hashCode ^
      miso.hashCode ^
      createdAt.hashCode;
  }
}
