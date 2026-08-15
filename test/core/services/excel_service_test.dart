import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/services/excel_service.dart';

void main() {
  final service = ExcelService();

  test('CSV Türkçe karakterleri ve kolonları okur', () async {
    final bytes = Uint8List.fromList(utf8.encode('Okul No,Ad Soyad\n101,Çağrı Şahin\n102,İpek Öztürk'));
    final preview = await service.parseStudentList(bytes, 'csv');
    expect(preview.rows, hasLength(2));
    expect(preview.suggestedNumberColumn, 0);
    expect(preview.suggestedNameColumn, 1);
    expect(preview.rows.first[1], 'Çağrı Şahin');
  });

  test('boş CSV reddedilir', () async {
    expect(() => service.parseStudentList(Uint8List.fromList(utf8.encode('')), 'csv'), throwsA(anything));
  });

  test('duplicate okul numarası validation hatasıdır', () {
    const preview = StudentFilePreview(headers: ['No', 'Ad'], rows: [['1', 'Ada Test'], ['1', 'Bora Test']]);
    final result = service.validate(preview, nameColumn: 1, numberColumn: 0);
    expect(result.errors, hasLength(1));
    expect(result.validRows, hasLength(1));
  });

  test('1000 satırlık sınıf listesi doğrulanır', () {
    final rows = List.generate(1000, (index) => ['${index + 1}', 'Öğrenci ${index + 1}']);
    final result = service.validate(StudentFilePreview(headers: const ['No', 'Ad'], rows: rows), nameColumn: 1, numberColumn: 0);
    expect(result.errors, isEmpty);
    expect(result.validRows, hasLength(1000));
  });
}
