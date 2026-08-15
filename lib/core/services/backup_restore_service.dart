import 'dart:typed_data';

/// Contract for full local backup/restore.
///
/// Implementations must encrypt the payload before it leaves the app sandbox,
/// carry a format/schema version, and restore inside a database transaction.
abstract interface class BackupRestoreService {
  Future<Uint8List> createEncryptedBackup({required String passphrase});

  Future<void> restoreEncryptedBackup(
    Uint8List bytes, {
    required String passphrase,
  });
}
