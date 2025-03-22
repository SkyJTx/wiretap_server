class DatabaseRepo {
  DatabaseRepo.createInstance();

  static DatabaseRepo? _instance;

  factory DatabaseRepo() {
    _instance ??= DatabaseRepo.createInstance();
    return _instance!;
  }
}