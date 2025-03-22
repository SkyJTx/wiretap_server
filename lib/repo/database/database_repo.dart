import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:objectbox/internal.dart';
import 'package:wiretap_server/component/task.dart';
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
      throw Exception('DatabaseRepo is not initialized');
    }
    return _store!;
  }

  void init() async {
    final path = _directory.path;
    _store = openStore(directory: path);

    final length = _store!.box<UserEntity>().count();
    if (length == 0) {
      final userBox = _store!.box<UserEntity>();
      final user = UserEntity(
        username: env['MASTER_USERNAME'] ?? 'admin',
        password: env['MASTER_PASSWORD'] ?? 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      userBox.put(user);
    }

    _storeCompleter.complete();
  }
}
