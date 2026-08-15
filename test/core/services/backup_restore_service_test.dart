import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';

void main() {
  final service = BackupRestoreService();
  const password = 'guvenli-test-parolasi';
  final payload = <String, dynamic>{
    'metadata': {'createdAt': '2026-08-15T20:00:00.000Z', 'databaseSchemaVersion': 5, 'counts': {'students': 2}},
    'data': {'students': [{'id': 1, 'fullName': 'Sentetik Öğrenci'}]},
  };

  test('encrypted backup round-trip payloadı korur', () async {
    final encrypted = await service.encrypt(payload: payload, password: password);
    expect(String.fromCharCodes(encrypted), isNot(contains('Sentetik Öğrenci')));
    final decoded = await service.decrypt(encrypted, password);
    expect(decoded.preview.databaseSchemaVersion, 5);
    expect(decoded.preview.counts['students'], 2);
    expect((decoded.data['students'] as List).first['fullName'], 'Sentetik Öğrenci');
  });

  test('yanlış parola authenticated decrypt ile reddedilir', () async {
    final encrypted = await service.encrypt(payload: payload, password: password);
    expect(() => service.decrypt(encrypted, 'yanlis-parola'), throwsA(anything));
  });
}
