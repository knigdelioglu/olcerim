import 'dart:typed_data';

import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/errors/failures.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';

class BackupRepository {
  BackupRepository(this._database, this._crypto);
  final AppDatabase _database;
  final BackupRestoreService _crypto;

  Future<Uint8List> create(String password) async {
    final payload = await _database.exportBackupPayload();
    final bytes = await _crypto.encrypt(payload: payload, password: password);
    await _database.setSetting('lastBackupAt', DateTime.now().toUtc().toIso8601String());
    return bytes;
  }

  Future<DecodedBackup> decode(Uint8List bytes, String password) => _crypto.decrypt(bytes, password);

  Future<void> restore(DecodedBackup backup) async {
    if (backup.preview.databaseSchemaVersion > _database.schemaVersion) {
      throw const BackupFailure('Bu yedek daha yeni bir Ölçerim sürümüyle oluşturulmuş. Önce uygulamayı güncelleyin.');
    }
    await _database.restoreBackupData(backup.data);
  }

  Future<DateTime?> lastBackupAt() async {
    final value = await _database.getSetting('lastBackupAt');
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }
}
