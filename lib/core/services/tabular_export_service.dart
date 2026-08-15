import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class TabularExportService {
  Uint8List csvBytes(AssessmentResults results) {
    final rows = _rows(results);
    return Uint8List.fromList(utf8.encode(csv.encode(rows)));
  }

  Uint8List xlsxBytes(AssessmentResults results) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Sonuçlar') {
      workbook.rename(defaultSheet, 'Sonuçlar');
    }
    final sheet = workbook['Sonuçlar'];
    for (final row in _rows(results)) {
      sheet.appendRow(row.map((value) => TextCellValue(value)).toList());
    }
    final encoded = workbook.encode();
    if (encoded == null) throw StateError('Excel dosyası oluşturulamadı.');
    return Uint8List.fromList(encoded);
  }

  List<List<String>> _rows(AssessmentResults results) {
    final criterionColumns = <String>[];
    for (final criterion in results.criteria) {
      criterionColumns
        ..add(criterion.title)
        ..add('${criterion.title} · Kriter notu');
    }
    final header = [
      'No',
      'Öğrenci',
      ...criterionColumns,
      'Öğretmen notu',
      'Gözlemler',
      'Toplam',
      'Durum',
    ];
    final data = results.students.map((student) {
      final entryMap = {for (final entry in student.entries) entry.criterionId: entry};
      final criterionValues = <String>[];
      for (final criterion in results.criteria) {
        final entry = entryMap[criterion.criterionId];
        criterionValues
          ..add(entry?.score.toString() ?? '')
          ..add(entry?.note ?? '');
      }
      return [
        student.student.schoolNumber ?? '',
        student.student.fullName,
        ...criterionValues,
        student.note ?? '',
        student.observations
            .map((observation) => '${_date(observation.createdAt)} | ${observation.content}')
            .join('\n'),
        student.total.toString(),
        switch (student.status) {
          'completed' => 'Tamamlandı',
          'incomplete' => 'Eksik',
          _ => 'Değerlendirilmedi',
        },
      ];
    });
    return [header, ...data];
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
