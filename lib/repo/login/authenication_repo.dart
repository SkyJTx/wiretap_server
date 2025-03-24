import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:wiretap_server/dotenv.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/error/error_base.dart';

class AuthenticationRepo {
  AuthenticationRepo.createInstance();

  static AuthenticationRepo? _instance;

  factory AuthenticationRepo() {
    _instance ??= AuthenticationRepo.createInstance();
    return _instance!;
  }

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

  Future<bool> isAdmin(String username) async {
    final isAdmin = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      username,
    ) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }
      return user.isAdmin;
    }, username);

    return isAdmin;
  }

  Future<List<String>> login(String username, String password) async {
    final [userInDB, paswordInDB] = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      username,
    ) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      return [user?.username, user?.password];
    }, username);

    if (userInDB == null || paswordInDB == null) {
      throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
    }
    if (!bcryptVerify(paswordInDB, utf8.encode(password))) {
      throw ErrorBase(code: 'PASSWORD_INCORRECT', message: 'Password incorrect', statusCode: 400);
    }

    final accessToken = await generateAccessToken(username);
    final refreshToken = await generateRefreshToken(username);

    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final userBox = store.box<UserEntity>();
      final tokenBox = store.box<TokenEntity>();

      final String username = params[0];
      final String accessToken = params[1];
      final String refreshToken = params[2];

      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      if (user!.token.target != null) {
        final token = user.token.target!;
        tokenBox.remove(token.id);
      }

      user.lastLoginAt = DateTime.now().toUtc();
      final token = TokenEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      user.token.target = token;
      userBox.put(user);
    }, [username, accessToken, refreshToken]);

    return [accessToken, refreshToken];
  }

  Future<void> logout(String username) async {
    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, username) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      final token = user!.token.target;
      if (token != null) {
        final tokenBox = store.box<TokenEntity>();
        tokenBox.remove(token.id);
      }
    }, username);
  }

  Future<UserEntity> addUser(
    String username,
    String password, {
    String? alias,
    bool isAdmin = false,
  }) async {
    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final userBox = store.box<UserEntity>();

      final [username as String, password as String, alias as String?, isAdmin as bool] = params;

      final user = UserEntity(
        username: username,
        password: bcrypt(utf8.encode(password)),
        alias: alias,
        isAdmin: isAdmin,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      try {
        userBox.put(user);
      } catch (e) {
        throw ErrorBase(
          code: 'USER_ALREADY_EXISTS',
          message: 'User already exists',
          statusCode: 400,
        );
      }
    }, [username, password, alias, isAdmin]);

    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, username) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }
      return user;
    }, username);
  }

  Future<List<String>> refreshToken(String refreshToken) async {
    final refreshTokenInDB = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      refreshToken,
    ) {
      final tokenBox = store.box<TokenEntity>();
      final token =
          tokenBox.query(TokenEntity_.refreshToken.equals(refreshToken)).build().findFirst();

      return token?.refreshToken;
    }, refreshToken);

    if (refreshTokenInDB == null) {
      throw ErrorBase(code: 'TOKEN_NOT_FOUND', message: 'Token not found', statusCode: 400);
    }

    late String username;

    try {
      username = JWT.verify(refreshToken, SecretKey(refreshTokenSecret)).payload['username'];
    } catch (e) {
      throw ErrorBase(
        code: 'REFRESH_TOKEN_INVALID',
        message: 'Refresh token invalid. Please login again.',
        statusCode: 400,
        data: e,
      );
    }

    final newAccessToken = await generateAccessToken(username);

    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final tokenBox = store.box<TokenEntity>();

      final String newAccessToken = params[0];
      final String refreshToken = params[1];

      final token =
          tokenBox.query(TokenEntity_.refreshToken.equals(refreshToken)).build().findFirst();
      token!.accessToken = newAccessToken;
      token.updatedAt = DateTime.now().toUtc();
      tokenBox.put(token);
    }, [newAccessToken, refreshToken]);

    return [newAccessToken, refreshToken];
  }

  Future<void> revokeToken(String refreshToken) async {
    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, refreshToken) {
      final tokenBox = store.box<TokenEntity>();
      final token =
          tokenBox.query(TokenEntity_.refreshToken.equals(refreshToken)).build().findFirst();
      if (token == null) {
        throw ErrorBase(code: 'TOKEN_NOT_FOUND', message: 'Token not found', statusCode: 400);
      }
      tokenBox.remove(token.id);
    }, refreshToken);
  }
}
