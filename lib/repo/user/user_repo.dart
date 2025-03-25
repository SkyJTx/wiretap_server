import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/database_repo.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/data_model/error_base.dart';

class UserRepo {
  UserRepo.createInstance();

  static UserRepo? _instance;

  factory UserRepo() {
    _instance ??= UserRepo.createInstance();
    return _instance!;
  }

  Future<UserEntity> getUserByUsername(String username) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, username) {
      final userBox = store.box<UserEntity>();
      final user = userBox.query(UserEntity_.username.equals(username)).build().findFirst();
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }
      return user;
    }, username);
  }

  Future<UserEntity> getUserById(int id) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, id) {
      final userBox = store.box<UserEntity>();
      final user = userBox.get(id);
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }
      return user;
    }, id);
  }

  Future<List<UserEntity>> getUsers(int userPerPage, int page, {String? searchParam}) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, params) {
      final userBox = store.box<UserEntity>();
      final [userPerPage as int, page as int, searchParam as String?] = params;
      final query =
          userBox
              .query(
                searchParam?.replaceAll(' ', '').isEmpty ?? true
                    ? null
                    : UserEntity_.username.contains(searchParam!) |
                        UserEntity_.alias.contains(searchParam),
              )
              .build();
      if (userPerPage < 1) {
        throw ErrorBase(
          code: 'INVALID_REQUEST_QUERY',
          message: 'User per page must not be less than 1',
          statusCode: 400,
        );
      }
      if (page < 1) {
        throw ErrorBase(
          code: 'INVALID_REQUEST_QUERY',
          message: 'Page must not be less than 1',
          statusCode: 400,
        );
      }
      query.offset = (userPerPage * (page - 1));
      query.limit = userPerPage;
      final users = query.find();
      return users;
    }, [userPerPage, page, searchParam]);
  }

  Future<List<UserEntity>> getAllUsers() async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, _) {
      final userBox = store.box<UserEntity>();
      final users = userBox.getAll();
      return users;
    }, null);
  }

  Future<int> getUserCount([Condition<UserEntity>? qc]) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, _) {
      final userBox = store.box<UserEntity>();
      return userBox.query(qc).build().count();
    }, null);
  }

  Future<int> getPageCount(int userPerPage, [Condition<UserEntity>? qc]) async {
    return await DatabaseRepo().store.runInTransactionAsync(TxMode.read, (store, userPerPage) {
      final userBox = store.box<UserEntity>();
      final count = userBox.query(qc).build().count();
      final page = count / userPerPage;
      return page.clamp(1, double.infinity).ceil();
    }, userPerPage);
  }

  Future<UserEntity> addUser(
    String username,
    String password, {
    String? alias,
    bool isAdmin = false,
  }) async {
    final user = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
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

      late final int id;
      try {
        id = userBox.put(user);
      } catch (e) {
        throw ErrorBase(
          code: 'USER_ALREADY_EXISTS',
          message: 'User already exists',
          statusCode: 400,
        );
      }

      return userBox.get(id);
    }, [username, password, alias, isAdmin]);

    if (user == null) {
      throw ErrorBase(code: 'FAILED_TO_ADD_USER', message: 'Failed to add user', statusCode: 500);
    }

    return user;
  }

  Future<UserEntity> editUser(int id, {String? username, String? alias, bool? isAdmin}) async {
    final user = await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, params) {
      final userBox = store.box<UserEntity>();

      final [id as int, username as String?, alias as String?, isAdmin as bool?] = params;

      final user = userBox.get(id);
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }

      if (username != null) user.username = username;
      if (alias != null) user.alias = alias;
      if (isAdmin != null) user.isAdmin = isAdmin;
      if (username != null || alias != null || isAdmin != null) {
        user.updatedAt = DateTime.now().toUtc();
      }

      final realId = userBox.put(user);

      return userBox.get(realId);
    }, [id, username, alias, isAdmin]);

    if (user == null) {
      throw ErrorBase(code: 'FAILED_TO_EDIT_USER', message: 'Failed to edit user', statusCode: 500);
    }

    return user;
  }

  Future<void> deleteUserById(int id) async {
    await DatabaseRepo().store.runInTransactionAsync(TxMode.write, (store, id) {
      final userBox = store.box<UserEntity>();
      final user = userBox.get(id);
      if (user == null) {
        throw ErrorBase(code: 'USER_NOT_FOUND', message: 'User not found', statusCode: 400);
      }
      userBox.remove(id);
    }, id);
  }
}
