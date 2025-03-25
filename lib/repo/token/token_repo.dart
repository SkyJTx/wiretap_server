import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:wiretap_server/dotenv.dart';
import 'package:wiretap_server/data_model/error_base.dart';

class TokenRepo with TokenMixin {
  TokenRepo.createInstance();

  static TokenRepo? _instance;

  factory TokenRepo() {
    _instance ??= TokenRepo.createInstance();
    return _instance!;
  }
}

mixin TokenMixin {
  String get accessTokenSecret {
    final result = env['ACCESS_TOKEN_SECRET'];
    if (result == null) {
      throw ErrorBase(
        code: 'ACCESS_TOKEN_SECRET_NOT_SET',
        message: 'ACCESS_TOKEN_SECRET must be set in .env',
        statusCode: 500,
      );
    }
    return result;
  }

  String get refreshTokenSecret {
    final result = env['REFRESH_TOKEN_SECRET'];
    if (result == null) {
      throw ErrorBase(
        code: 'REFRESH_TOKEN_SECRET_NOT_SET',
        message: 'REFRESH_TOKEN_SECRET must be set in .env',
        statusCode: 500,
      );
    }
    return result;
  }

  Future<String> generateAccessToken(String username) async {
    return JWT({
      'username': username,
    }).sign(SecretKey(accessTokenSecret), expiresIn: Duration(days: 1));
  }

  Future<String> generateRefreshToken(String username) async {
    return JWT({
      'username': username,
    }).sign(SecretKey(refreshTokenSecret), expiresIn: Duration(days: 7));
  }

  Map<String, String> decodeAccessToken(String accessToken) {
    final payload = JWT.verify(accessToken, SecretKey(accessTokenSecret)).payload;
    return {'username': payload['username'] as String};
  }

  Map<String, String> decodeRefreshToken(String refreshToken) {
    final payload = JWT.verify(refreshToken, SecretKey(refreshTokenSecret)).payload;
    return {'username': payload['username'] as String};
  }
}