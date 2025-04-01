// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:wiretap_server/repo/database/entity/message_entity/modbus_msg_entity.dart';
import 'package:wiretap_server/repo/database/entity/peripheral_entity/modbus_entity.dart';

class Modbus {
  final int id;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ModbusMsg> modbusMsgEntities;

  Modbus({
    required this.id,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
    List<ModbusMsg>? modbusMsgEntities,
  }) : modbusMsgEntities = modbusMsgEntities ?? [];

  Modbus copyWith({
    int? id,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ModbusMsg>? modbusMsgEntities,
  }) {
    return Modbus(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modbusMsgEntities: modbusMsgEntities ?? this.modbusMsgEntities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'modbusMsgEntities': modbusMsgEntities.map((x) => x.toMap()).toList(),
    };
  }

  factory Modbus.fromMap(Map<String, dynamic> map) {
    return Modbus(
      id: map['id'] as int,
      isEnabled: map['isEnabled'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      modbusMsgEntities: List<ModbusMsg>.from(
        (map['modbusMsgEntities'] as List<int>).map<ModbusMsg>(
          (x) => ModbusMsg.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory Modbus.fromEntity(ModbusEntity entity) {
    return Modbus(
      id: entity.id,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
      modbusMsgEntities: entity.modbusMsgEntities
          .map((e) => ModbusMsg.fromEntity(e))
          .toList()
    );
  }

  String toJson() => json.encode(toMap());

  factory Modbus.fromJson(String source) =>
      Modbus.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Modbus(id: $id, isEnabled: $isEnabled, createdAt: $createdAt, updatedAt: $updatedAt, modbusMsgEntities: $modbusMsgEntities)';
  }

  @override
  bool operator ==(covariant Modbus other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.id == id &&
        other.isEnabled == isEnabled &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.modbusMsgEntities, modbusMsgEntities);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        isEnabled.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        modbusMsgEntities.hashCode;
  }
}

class ModbusMsg {
  final int id;
  final int address;
  final int functionCode;
  final int startingAddress;
  final int quantity;
  final int dataLength;
  final String data;
  final int queryCRC;
  final int responseCRC;
  final DateTime createdAt;

  ModbusMsg({
    required this.id,
    required this.address,
    required this.functionCode,
    required this.startingAddress,
    required this.quantity,
    required this.dataLength,
    required this.data,
    required this.queryCRC,
    required this.responseCRC,
    required this.createdAt,
  });

  ModbusMsg copyWith({
    int? id,
    int? address,
    int? functionCode,
    int? startingAddress,
    int? quantity,
    int? dataLength,
    String? data,
    int? queryCRC,
    int? responseCRC,
    DateTime? createdAt,
  }) {
    return ModbusMsg(
      id: id ?? this.id,
      address: address ?? this.address,
      functionCode: functionCode ?? this.functionCode,
      startingAddress: startingAddress ?? this.startingAddress,
      quantity: quantity ?? this.quantity,
      dataLength: dataLength ?? this.dataLength,
      data: data ?? this.data,
      queryCRC: queryCRC ?? this.queryCRC,
      responseCRC: responseCRC ?? this.responseCRC,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'address': address,
      'functionCode': functionCode,
      'startingAddress': startingAddress,
      'quantity': quantity,
      'dataLength': dataLength,
      'data': data,
      'queryCRC': queryCRC,
      'responseCRC': responseCRC,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory ModbusMsg.fromMap(Map<String, dynamic> map) {
    return ModbusMsg(
      id: map['id'] as int,
      address: map['address'] as int,
      functionCode: map['functionCode'] as int,
      startingAddress: map['startingAddress'] as int,
      quantity: map['quantity'] as int,
      dataLength: map['dataLength'] as int,
      data: map['data'] as String,
      queryCRC: map['queryCRC'] as int,
      responseCRC: map['responseCRC'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory ModbusMsg.fromEntity(ModbusMsgEntity entity) {
    return ModbusMsg(
      id: entity.id,
      address: entity.address,
      functionCode: entity.functionCode,
      startingAddress: entity.startingAddress,
      quantity: entity.quantity,
      dataLength: entity.dataLength,
      data: entity.data,
      queryCRC: entity.queryCRC,
      responseCRC: entity.responseCRC,
      createdAt: entity.createdAt.toUtc(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ModbusMsg.fromJson(String source) =>
      ModbusMsg.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ModbusMsg(id: $id, address: $address, functionCode: $functionCode, startingAddress: $startingAddress, quantity: $quantity, dataLength: $dataLength, data: $data, queryCRC: $queryCRC, responseCRC: $responseCRC, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant ModbusMsg other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.address == address &&
        other.functionCode == functionCode &&
        other.startingAddress == startingAddress &&
        other.quantity == quantity &&
        other.dataLength == dataLength &&
        other.data == data &&
        other.queryCRC == queryCRC &&
        other.responseCRC == responseCRC &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        address.hashCode ^
        functionCode.hashCode ^
        startingAddress.hashCode ^
        quantity.hashCode ^
        dataLength.hashCode ^
        data.hashCode ^
        queryCRC.hashCode ^
        responseCRC.hashCode ^
        createdAt.hashCode;
  }
}
