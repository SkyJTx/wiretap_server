// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:wiretap_server/repo/database/entity/token_entity.dart';

class Token {
  int id;
  String accessToken;
  String refreshToken;
  DateTime createdAt;
  DateTime updatedAt;

  Token({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
    required this.updatedAt,
  });

  Token copyWith({
    int? id,
    String? accessToken,
    String? refreshToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Token(
      id: id ?? this.id,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Token.fromEntity(TokenEntity entity) {
    return Token(
      id: entity.id,
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Token.fromMap(Map<String, dynamic> map) {
    return Token(
      id: map['id'] as int,
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Token.fromJson(String source) => Token.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Token(id: $id, accessToken: $accessToken, refreshToken: $refreshToken, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant Token other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}
