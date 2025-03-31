// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SerialData {
  String type;
  String data;

  SerialData({
    required this.type,
    required this.data,
  });

  SerialData copyWith({
    String? type,
    String? data,
  }) {
    return SerialData(
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'data': data,
    };
  }

  factory SerialData.fromMap(Map<String, dynamic> map) {
    return SerialData(
      type: map['type'] as String,
      data: map['data'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SerialData.fromJson(String source) => SerialData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SerialData(type: $type, data: $data)';

  @override
  bool operator ==(covariant SerialData other) {
    if (identical(this, other)) return true;
  
    return 
      other.type == type &&
      other.data == data;
  }

  @override
  int get hashCode => type.hashCode ^ data.hashCode;
}
