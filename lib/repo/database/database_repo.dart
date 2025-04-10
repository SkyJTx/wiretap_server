import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hashlib/hashlib.dart';

import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/dotenv.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';

class DatabaseRepo {
  static final directory = Directory('objectbox');

  DatabaseRepo.createInstance();

  final Completer<void> _storeCompleter = Completer<void>();
  bool isStoreReady = false;
  Future<void> get storeReady => _storeCompleter.future;
  Store? _store;

  static DatabaseRepo? _instance;

  factory DatabaseRepo() {
    _instance ??= DatabaseRepo.createInstance();
    return _instance!;
  }

  Store get store {
    if (_store == null) {
      throw ErrorType.internalServerError.addMessage('Database is not ready');
    }
    return _store!;
  }

  void init() {
    final path = directory.path;
    _store = openStore(directory: path);
    
    final length = _store!.box<UserEntity>().count();
    if (length == 0) {
      final userBox = _store!.box<UserEntity>();
      final masterUser = env['MASTER_USERNAME'];
      final masterPassword = env['MASTER_PASSWORD'];

      if (masterUser == null || masterPassword == null) {
        throw ErrorType.internalServerError.addMessage('Master user and password not found');
      }

      final user = UserEntity(
        username: masterUser,
        password: bcrypt(utf8.encode(masterPassword)),
        alias: 'Master',
        isAdmin: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      userBox.put(user);
    }
    isStoreReady = true;
    _storeCompleter.complete();
  }
}
