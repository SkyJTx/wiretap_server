// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:wiretap_server/data_model/token.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';

class User {
  int id;
  String username;
  String? alias;
  bool isAdmin;
  int? tokenId;
  Token? token;
  DateTime createdAt;
  DateTime? lastLoginAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    this.alias,
    required this.isAdmin,
    this.tokenId,
    this.token,
    required this.createdAt,
    this.lastLoginAt,
    required this.updatedAt,
  });

  User copyWith({
    int? id,
    String? username,
    String? alias,
    bool? isAdmin,
    int? tokenId,
    Token? token,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      alias: alias ?? this.alias,
      isAdmin: isAdmin ?? this.isAdmin,
      tokenId: tokenId ?? this.tokenId,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory User.fromEntity(UserEntity entity) {
    return User(
      id: entity.id,
      username: entity.username,
      alias: entity.alias,
      isAdmin: entity.isAdmin,
      tokenId: entity.token.target?.id,
      token: entity.token.target == null ? null : Token.fromEntity(entity.token.target!),
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'alias': alias,
      'isAdmin': isAdmin,
      'tokenId': tokenId,
      'token': token?.toMap(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastLoginAt': lastLoginAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      alias: map['alias'] != null ? map['alias'] as String : null,
      isAdmin: map['isAdmin'] as bool,
      tokenId: map['tokenId'] != null ? map['tokenId'] as int : null,
      token: map['token'] != null ? Token.fromMap(map['token'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt'] as String) : null,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, username: $username, alias: $alias, isAdmin: $isAdmin, tokenId: $tokenId, token: $token, createdAt: $createdAt, lastLoginAt: $lastLoginAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.username == username &&
        other.alias == alias &&
        other.isAdmin == isAdmin &&
        other.tokenId == tokenId &&
        other.token == token &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        alias.hashCode ^
        isAdmin.hashCode ^
        tokenId.hashCode ^
        token.hashCode ^
        createdAt.hashCode ^
        lastLoginAt.hashCode ^
        updatedAt.hashCode;
  }
}

class UserSafe {
  int id;
  String username;
  String? alias;
  bool isAdmin;
  DateTime createdAt;
  DateTime? lastLoginAt;
  DateTime updatedAt;

  UserSafe({
    required this.id,
    required this.username,
    this.alias,
    required this.isAdmin,
    required this.createdAt,
    this.lastLoginAt,
    required this.updatedAt,
  });

  UserSafe copyWith({
    int? id,
    String? username,
    String? alias,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
  }) {
    return UserSafe(
      id: id ?? this.id,
      username: username ?? this.username,
      alias: alias ?? this.alias,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserSafe.fromEntity(UserEntity entity) {
    return UserSafe(
      id: entity.id,
      username: entity.username,
      alias: entity.alias,
      isAdmin: entity.isAdmin,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'alias': alias,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastLoginAt': lastLoginAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory UserSafe.fromMap(Map<String, dynamic> map) {
    return UserSafe(
      id: map['id'] as int,
      username: map['username'] as String,
      alias: map['alias'] != null ? map['alias'] as String : null,
      isAdmin: map['isAdmin'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt'] as String) : null,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSafe.fromJson(String source) => UserSafe.fromMap(json
      .decode(source) as Map<String, dynamic>);
  
  @override
  String toString() {
    return 'UserSafe(id: $id, username: $username, alias: $alias, isAdmin: $isAdmin, createdAt: $createdAt, lastLoginAt: $lastLoginAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant UserSafe other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.username == username &&
        other.alias == alias &&
        other.isAdmin == isAdmin &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        alias.hashCode ^
        isAdmin.hashCode ^
        createdAt.hashCode ^
        lastLoginAt.hashCode ^
        updatedAt.hashCode;
  }
}
