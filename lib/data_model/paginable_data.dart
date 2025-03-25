// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class PaginableData {
  final String message;
  final int totalSize;
  final int totalPage;
  final int size;
  final int page;
  final List<dynamic> data;

  PaginableData({
    required this.message,
    required this.totalSize,
    required this.totalPage,
    required this.size,
    required this.page,
    required this.data,
  });

  PaginableData copyWith({
    String? message,
    int? totalSize,
    int? totalPage,
    int? size,
    int? page,
    List<dynamic>? data,
  }) {
    return PaginableData(
      message: message ?? this.message,
      totalSize: totalSize ?? this.totalSize,
      totalPage: totalPage ?? this.totalPage,
      size: size ?? this.size,
      page: page ?? this.page,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      'totalSize': totalSize,
      'totalPage': totalPage,
      'size': size,
      'page': page,
      'data': data,
    };
  }

  factory PaginableData.fromMap(Map<String, dynamic> map) {
    return PaginableData(
      message: map['message'] as String,
      totalSize: map['totalSize'] as int,
      totalPage: map['totalPage'] as int,
      size: map['size'] as int,
      page: map['page'] as int,
      data: List<dynamic>.from((map['data'] as List<dynamic>)),
    );
  }

  String toJson() => json.encode(toMap());

  factory PaginableData.fromJson(String source) =>
      PaginableData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaginableData(message: $message, totalSize: $totalSize, totalPage: $totalPage, size: $size, page: $page, data: $data)';
  }

  @override
  bool operator ==(covariant PaginableData other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.message == message &&
        other.totalSize == totalSize &&
        other.totalPage == totalPage &&
        other.size == size &&
        other.page == page &&
        listEquals(other.data, data);
  }

  @override
  int get hashCode {
    return message.hashCode ^
        totalSize.hashCode ^
        totalPage.hashCode ^
        size.hashCode ^
        page.hashCode ^
        data.hashCode;
  }
}
