import 'package:olcerim/core/database/app_database.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._database);
  final AppDatabase _database;

  Future<String?> get(String key) => _database.getSetting(key);
  Future<void> set(String key, String value) => _database.setSetting(key, value);
}
