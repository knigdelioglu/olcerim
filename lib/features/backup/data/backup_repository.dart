import 'dart:typed_data';

import 'package:olcerim/core/services/backup_restore_service.dart';

class BackupRepository {
  const BackupRepository(this._service);

  final BackupRestoreService _service;

  Future<Uint8List> create(String passphrase) {
    return _service.createEncryptedBackup(passphrase: passphrase);
  }

  Future<void> restore(Uint8List bytes, String passphrase) {
    return _service.restoreEncryptedBackup(bytes, passphrase: passphrase);
  }
}
