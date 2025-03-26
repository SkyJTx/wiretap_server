import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/dotenv.dart';

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
      throw ErrorType.internalServerError.addMessage('Secret access token not found');
    }
    return result;
  }

  String get refreshTokenSecret {
    final result = env['REFRESH_TOKEN_SECRET'];
    if (result == null) {
      throw ErrorType.internalServerError.addMessage('Secret refresh token not found');
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