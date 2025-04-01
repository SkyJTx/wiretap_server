// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/i2c_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/i2c_entity.dart';

class I2c {
  final int id;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<I2cMsg> i2cMsgEntities;

  I2c({
    List<I2cMsg>? i2cMsgEntities,
    required this.id,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  }) : i2cMsgEntities = i2cMsgEntities ?? [];

  I2c copyWith({
    int? id,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<I2cMsg>? i2cMsgEntities,
  }) {
    return I2c(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      i2cMsgEntities: i2cMsgEntities ?? this.i2cMsgEntities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'i2cMsgEntities': i2cMsgEntities.map((x) => x.toMap()).toList(),
    };
  }

  factory I2c.fromMap(Map<String, dynamic> map) {
    return I2c(
      id: map['id'] as int,
      isEnabled: map['isEnabled'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      i2cMsgEntities: List<I2cMsg>.from((map['i2cMsgEntities'] as List<int>).map<I2cMsg>((x) => I2cMsg.fromMap(x as Map<String,dynamic>),),),
    );
  }

  factory I2c.fromEntity(I2cEntity entity) {
    return I2c(
      id: entity.id,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      i2cMsgEntities: entity.i2cMsgEntities.map((e) => I2cMsg.fromEntity(e)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory I2c.fromJson(String source) => I2c.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'I2c(id: $id, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt, i2cMsgEntities: $i2cMsgEntities)';
  }

  @override
  bool operator ==(covariant I2c other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return 
      other.id == id &&
      other.isEnabled == isEnabled &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      listEquals(other.i2cMsgEntities, i2cMsgEntities);
  }

  @override
  int get hashCode {
    return id.hashCode ^
      isEnabled.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      i2cMsgEntities.hashCode;
  }
}

class I2cMsg {
  final int id;
  final int address;
  final bool isTenBitAddressing;
  final bool isWriteMode;
  final String data;
  final DateTime createdAt;

  I2cMsg({
    required this.id,
    required this.address,
    required this.isTenBitAddressing,
    required this.isWriteMode,
    required this.data,
    required this.createdAt,
  });

  I2cMsg copyWith({
    int? id,
    int? address,
    bool? isTenBitAddressing,
    bool? isWriteMode,
    String? data,
    DateTime? createdAt,
  }) {
    return I2cMsg(
      id: id ?? this.id,
      address: address ?? this.address,
      isTenBitAddressing: isTenBitAddressing ?? this.isTenBitAddressing,
      isWriteMode: isWriteMode ?? this.isWriteMode,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'address': address,
      'isTenBitAddressing': isTenBitAddressing,
      'isWriteMode': isWriteMode,
      'data': data,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory I2cMsg.fromMap(Map<String, dynamic> map) {
    return I2cMsg(
      id: map['id'] as int,
      address: map['address'] as int,
      isTenBitAddressing: map['isTenBitAddressing'] as bool,
      isWriteMode: map['isWriteMode'] as bool,
      data: map['data'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory I2cMsg.fromEntity(I2cMsgEntity entity) {
    return I2cMsg(
      id: entity.id,
      address: entity.address,
      isTenBitAddressing: entity.isTenBitAddressing,
      isWriteMode: entity.isWriteMode,
      data: entity.data,
      createdAt: entity.createdAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory I2cMsg.fromJson(String source) => I2cMsg.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'I2cMsg(id: $id, address: $address, isTenBitAddressing: $isTenBitAddressing, isWriteMode: $isWriteMode, data: $data, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant I2cMsg other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.address == address &&
      other.isTenBitAddressing == isTenBitAddressing &&
      other.isWriteMode == isWriteMode &&
      other.data == data &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      address.hashCode ^
      isTenBitAddressing.hashCode ^
      isWriteMode.hashCode ^
      data.hashCode ^
      createdAt.hashCode;
  }
}
