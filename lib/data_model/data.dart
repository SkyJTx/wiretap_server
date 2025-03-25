// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Data {
  final String message;
  final dynamic data;

  Data({
    required this.message,
    required this.data,
  });

  Data copyWith({
    String? message,
    dynamic data,
  }) {
    return Data(
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      'data': data,
    };
  }

  factory Data.fromMap(Map<String, dynamic> map) {
    return Data(
      message: map['message'] as String,
      data: map['data'] as dynamic,
    );
  }

  String toJson() => json.encode(toMap());

  factory Data.fromJson(String source) => Data.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Data(message: $message, data: $data)';

  @override
  bool operator ==(covariant Data other) {
    if (identical(this, other)) return true;
  
    return 
      other.message == message &&
      other.data == data;
  }

  @override
  int get hashCode => message.hashCode ^ data.hashCode;
}
