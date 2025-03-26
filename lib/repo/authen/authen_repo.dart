import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/repo/database/entity/token_entity.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/repo/token/token_repo.dart';

class AuthenRepo with TokenMixin {
  AuthenRepo.createInstance();

  static AuthenRepo? _instance;

  factory AuthenRepo() {
    _instance ??= AuthenRepo.createInstance();
    return _instance!;
  }

  Future<bool> isAdmin(String username) async {
    final isAdmin = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      username,
    ) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      if (user == null) {
        throw ErrorType.badRequest.addMessage('User not found');
      }
      return user.isAdmin;
    }, username);

    return isAdmin;
  }

  Future<TokenEntity> login(String username, String password) async {
    final [userInDB, paswordInDB] = await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (
      store,
      username,
    ) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      return [user?.username, user?.password];
    }, username);

    if (userInDB == null || paswordInDB == null) {
      throw ErrorType.badRequest.addMessage('User not found');
    }
    if (!bcryptVerify(paswordInDB, utf8.encode(password))) {
      throw ErrorType.badRequest.addMessage('Password is incorrect');
    }

    final accessToken = await generateAccessToken(username);
    final refreshToken = await generateRefreshToken(username);

    final token = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
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
      final id = userBox.put(user);

      return userBox.get(id)?.token.target;
    }, [username, accessToken, refreshToken]);

    if (token == null) {
      throw ErrorType.internalServerError.addMessage('Failed to generate token');
    }

    return token;
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

  Future<TokenEntity> refreshToken(UserEntity user) async {
    final newAccessToken = await generateAccessToken(user.username);

    final token = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final tokenBox = store.box<TokenEntity>();

      final String newAccessToken = params[0];
      final String refreshToken = params[1];

      final token =
          tokenBox.query(TokenEntity_.refreshToken.equals(refreshToken)).build().findFirst();
      token!.accessToken = newAccessToken;
      token.updatedAt = DateTime.now().toUtc();
      final id = tokenBox.put(token);

      return tokenBox.get(id);
    }, [newAccessToken, user.token.target!.refreshToken]);

    if (token == null) {
      throw ErrorType.internalServerError.addMessage('Failed to refresh token');
    }

    return token;
  }
}
