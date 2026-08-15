import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:olcerim/core/errors/failures.dart';

class StudentFilePreview {
  const StudentFilePreview({required this.headers, required this.rows, this.suggestedNameColumn, this.suggestedNumberColumn});
  final List<String> headers;
  final List<List<String>> rows;
  final int? suggestedNameColumn;
  final int? suggestedNumberColumn;
}

class StudentPreviewValidation {
  const StudentPreviewValidation({required this.validRows, required this.errors});
  final List<StudentPreviewRecord> validRows;
  final List<String> errors;
  bool get isValid => errors.isEmpty && validRows.isNotEmpty;
}

class StudentPreviewRecord {
  const StudentPreviewRecord({required this.fullName, this.schoolNumber, required this.sourceRow});
  final String fullName;
  final String? schoolNumber;
  final int sourceRow;
}

class ExcelService {
  Future<StudentFilePreview> parseStudentList(Uint8List bytes, String extension) {
    return Isolate.run(() => _parseStudentList(bytes, extension.toLowerCase()));
  }

  StudentPreviewValidation validate(StudentFilePreview preview, {required int nameColumn, int? numberColumn}) {
    final valid = <StudentPreviewRecord>[];
    final errors = <String>[];
    final seenNumbers = <String>{};
    for (var i = 0; i < preview.rows.length; i++) {
      final row = preview.rows[i];
      final name = nameColumn < row.length ? row[nameColumn].trim() : '';
      final rawNumber = numberColumn != null && numberColumn < row.length ? row[numberColumn].trim() : '';
      final number = rawNumber.isEmpty ? null : rawNumber;
      if (name.isEmpty) {
        errors.add('${i + 2}. satır: öğrenci adı boş.');
        continue;
      }
      if (number != null && !seenNumbers.add(number)) {
        errors.add('${i + 2}. satır: $number okul numarası dosyada tekrar ediyor.');
        continue;
      }
      valid.add(StudentPreviewRecord(fullName: name, schoolNumber: number, sourceRow: i + 2));
    }
    if (valid.isEmpty && errors.isEmpty) errors.add('Dosyada içe aktarılabilir öğrenci bulunamadı.');
    return StudentPreviewValidation(validRows: valid, errors: errors);
  }
}

StudentFilePreview _parseStudentList(Uint8List bytes, String extension) {
  try {
    late final List<List<String>> matrix;
    if (extension == 'csv') {
      final text = utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
      matrix = csv.decode(text).map((row) => row.map((cell) => '$cell'.trim()).toList()).toList();
    } else if (extension == 'xlsx') {
      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook.tables.values.firstWhere(
        (candidate) => candidate.rows.isNotEmpty,
        orElse: () => throw const ImportFailure('Excel dosyasında dolu çalışma sayfası bulunamadı.'),
      );
      matrix = sheet.rows
          .map((row) => row.map((cell) => cell?.value?.toString().trim() ?? '').toList())
          .toList();
    } else {
      throw const ImportFailure('Yalnız .xlsx ve .csv dosyaları desteklenir.');
    }
    if (matrix.isEmpty) throw const ImportFailure('Dosya boş.');
    final headers = matrix.first;
    final rows = matrix.skip(1).where((row) => row.any((cell) => cell.trim().isNotEmpty)).toList();
    final normalized = headers.map(_normalizeHeader).toList();
    final nameColumn = _findHeader(normalized, ['ad soyad', 'adı soyadı', 'adi soyadi', 'öğrenci', 'ogrenci', 'isim', 'ad']);
    final numberColumn = _findHeader(normalized, ['okul no', 'okul numarası', 'okul numarasi', 'numara', 'no']);
    return StudentFilePreview(headers: headers, rows: rows, suggestedNameColumn: nameColumn, suggestedNumberColumn: numberColumn);
  } on Failure {
    rethrow;
  } catch (error) {
    throw ImportFailure('Dosya okunamadı. Dosyanın Excel (.xlsx) veya CSV biçiminde olduğundan emin olun.', cause: error);
  }
}

String _normalizeHeader(String value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
int? _findHeader(List<String> headers, List<String> aliases) {
  for (var i = 0; i < headers.length; i++) {
    if (aliases.contains(headers[i])) return i;
  }
  return null;
}
