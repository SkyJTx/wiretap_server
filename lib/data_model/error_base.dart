import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:wiretap_server/constant/response.dart';

class ErrorBase {
  final int statusCode;
  final String message;
  final String code;
  final Object? data;

  ErrorBase({required this.statusCode, required this.message, required this.code, this.data});

  Response toResponse() {
    return Response(
      statusCode,
      body: jsonEncode({'code': code, 'message': message}),
      headers: jsonHeader,
    );
  }

  @override
  String toString() {
    return '$code: $message';
  }
}
