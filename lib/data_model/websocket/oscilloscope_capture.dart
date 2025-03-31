// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class OscilloscopeCapture {
  bool isEnabled;
  bool? isDecodeEnabled;
  String? decodeMode;
  String? decodeFormat;
  String? imageFilePath;
  DateTime? createdAt;

  OscilloscopeCapture({
    required this.isEnabled,
    this.isDecodeEnabled,
    this.decodeMode,
    this.decodeFormat,
    this.imageFilePath,
    this.createdAt,
  });

  OscilloscopeCapture copyWith({
    bool? isEnabled,
    bool? isDecodeEnabled,
    String? decodeMode,
    String? decodeFormat,
    String? imageFilePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OscilloscopeCapture(
      isEnabled: isEnabled ?? this.isEnabled,
      isDecodeEnabled: isDecodeEnabled ?? this.isDecodeEnabled,
      decodeMode: decodeMode ?? this.decodeMode,
      decodeFormat: decodeFormat ?? this.decodeFormat,
      imageFilePath: imageFilePath ?? this.imageFilePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'isDecodeEnabled': isDecodeEnabled,
      'decodeMode': decodeMode,
      'decodeFormat': decodeFormat,
      'imageFilePath': imageFilePath,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  factory OscilloscopeCapture.fromMap(Map<String, dynamic> map) {
    return OscilloscopeCapture(
      isEnabled: map['isEnabled'] as bool,
      isDecodeEnabled: map['isDecodeEnabled'] as bool,
      decodeMode: map['decodeMode'] != null ? map['decodeMode'] as String : null,
      decodeFormat: map['decodeFormat'] != null ? map['decodeFormat'] as String : null,
      imageFilePath: map['imageFilePath'] as String,
      createdAt: map['createdAt'] is String ? DateTime.parse(map['createdAt'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OscilloscopeCapture.fromJson(String source) => OscilloscopeCapture.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OscilloscopeCapture(isEnabled: $isEnabled, isDecodeEnabled: $isDecodeEnabled, decodeMode: $decodeMode, decodeFormat: $decodeFormat, imageFilePath: $imageFilePath, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant OscilloscopeCapture other) {
    if (identical(this, other)) return true;
  
    return 
      other.isEnabled == isEnabled &&
      other.isDecodeEnabled == isDecodeEnabled &&
      other.decodeMode == decodeMode &&
      other.decodeFormat == decodeFormat &&
      other.imageFilePath == imageFilePath &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return isEnabled.hashCode ^
      isDecodeEnabled.hashCode ^
      decodeMode.hashCode ^
      decodeFormat.hashCode ^
      imageFilePath.hashCode ^
      createdAt.hashCode;
  }
}
