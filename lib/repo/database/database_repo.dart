import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hashlib/hashlib.dart';

import 'package:wiretap_server/component/task.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/dotenv.dart';
import 'package:wiretap_server/objectbox.g.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';

class DatabaseRepo {
  final _directory = Directory('objectbox');

  DatabaseRepo.createInstance();

  final Completer<void> _storeCompleter = Completer<void>();
  Store? _store;

  static DatabaseRepo? _instance;

  factory DatabaseRepo() {
    _instance ??= DatabaseRepo.createInstance();
    return _instance!;
  }

  Store get store {
    if (!_storeCompleter.isCompleted) {
      throw ErrorType.internalServerError.addMessage('Database is not ready');
    }
    return _store!;
  }

  void init() async {
    final path = _directory.path;
    await Task.run((path) {
      openStore(directory: path);
    }, path);
    _store = Store.attach(getObjectBoxModel(), path);
    
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

    _storeCompleter.complete();
  }
}
