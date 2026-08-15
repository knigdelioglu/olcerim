import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/errors/failures.dart';

class BackupPreview {
  const BackupPreview({required this.createdAt, required this.databaseSchemaVersion, required this.counts});
  final DateTime createdAt;
  final int databaseSchemaVersion;
  final Map<String, int> counts;
}

class DecodedBackup {
  const DecodedBackup({required this.preview, required this.data});
  final BackupPreview preview;
  final Map<String, dynamic> data;
}

class BackupRestoreService {
  BackupRestoreService({Cipher? cipher, KdfAlgorithm? kdf})
      : _cipher = cipher ?? AesGcm.with256bits(),
        _kdf = kdf ?? Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 600000, bits: 256);

  final Cipher _cipher;
  final KdfAlgorithm _kdf;

  Future<Uint8List> encrypt({required Map<String, dynamic> payload, required String password}) async {
    if (password.length < 8) throw const BackupFailure('Yedek parolası en az 8 karakter olmalıdır.');
    final salt = _cipher.newNonce();
    final nonce = _cipher.newNonce();
    final key = await _kdf.deriveKeyFromPassword(password: password, nonce: salt);
    final clearBytes = utf8.encode(jsonEncode(payload));
    final box = await _cipher.encrypt(clearBytes, secretKey: key, nonce: nonce);
    final envelope = <String, dynamic>{
      'format': AppConstants.backupFormat,
      'formatVersion': AppConstants.backupFormatVersion,
      'cipher': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': 600000,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<DecodedBackup> decrypt(Uint8List bytes, String password) async {
    try {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is! Map<String, dynamic> || raw['format'] != AppConstants.backupFormat || raw['formatVersion'] != AppConstants.backupFormatVersion) {
        throw const BackupFailure('Bu dosya desteklenen bir Ölçerim yedeği değil.');
      }
      final salt = base64Decode(raw['salt'] as String);
      final nonce = base64Decode(raw['nonce'] as String);
      final cipherText = base64Decode(raw['cipherText'] as String);
      final mac = base64Decode(raw['mac'] as String);
      final iterations = raw['iterations'] as int? ?? 600000;
      final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
      final key = await kdf.deriveKeyFromPassword(password: password, nonce: salt);
      final clear = await _cipher.decrypt(SecretBox(cipherText, nonce: nonce, mac: Mac(mac)), secretKey: key);
      final payload = jsonDecode(utf8.decode(clear));
      if (payload is! Map<String, dynamic>) throw const BackupFailure('Yedek içeriği geçersiz.');
      final metadata = payload['metadata'];
      final data = payload['data'];
      if (metadata is! Map<String, dynamic> || data is! Map<String, dynamic>) throw const BackupFailure('Yedek içeriği eksik.');
      final rawCounts = metadata['counts'];
      final counts = <String, int>{};
      if (rawCounts is Map<String, dynamic>) {
        for (final entry in rawCounts.entries) counts[entry.key] = (entry.value as num?)?.toInt() ?? 0;
      }
      final preview = BackupPreview(
        createdAt: DateTime.parse(metadata['createdAt'] as String),
        databaseSchemaVersion: (metadata['databaseSchemaVersion'] as num).toInt(),
        counts: counts,
      );
      return DecodedBackup(preview: preview, data: data);
    } on BackupFailure {
      rethrow;
    } on SecretBoxAuthenticationError catch (error) {
      throw BackupFailure('Parola yanlış veya yedek dosyası değiştirilmiş.', error);
    } catch (error) {
      throw BackupFailure('Yedek açılamadı. Dosya bozuk veya parola yanlış olabilir.', error);
    }
  }
}
