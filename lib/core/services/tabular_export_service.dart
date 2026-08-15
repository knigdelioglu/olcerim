import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class TabularExportService {
  Uint8List csvBytes(AssessmentResults results) {
    final rows = _rows(results);
    return Uint8List.fromList(csv.encode(rows).codeUnits);
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
    final header = ['No', 'Öğrenci', ...results.criteria.map((c) => c.title), 'Toplam', 'Durum'];
    final data = results.students.map((student) {
      final entryMap = {for (final entry in student.entries) entry.criterionId: entry};
      return [
        student.student.schoolNumber ?? '',
        student.student.fullName,
        ...results.criteria.map((criterion) => entryMap[criterion.criterionId]?.score.toString() ?? ''),
        student.total.toString(),
        switch (student.status) { 'completed' => 'Tamamlandı', 'incomplete' => 'Eksik', _ => 'Değerlendirilmedi' },
      ];
    });
    return [header, ...data];
  }
}
