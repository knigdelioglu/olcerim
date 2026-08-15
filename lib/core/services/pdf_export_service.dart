import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class PdfExportService {
  Future<Uint8List> classAssessment(AssessmentResults results) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(results.assessment.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('${results.classroom.name} · Sınıf değerlendirme çizelgesi'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Öğrenci', ...results.criteria.map((c) => c.title), 'Toplam', 'Durum'],
            data: results.students.map((student) {
              final entryMap = {for (final entry in student.entries) entry.criterionId: entry};
              return [
                student.student.schoolNumber ?? '',
                student.student.fullName,
                ...results.criteria.map((criterion) => entryMap[criterion.criterionId] == null ? '' : _score(entryMap[criterion.criterionId]!.score)),
                _score(student.total),
                _status(student.status),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Sınıf ortalaması: ${_score(results.classAverage)} / ${_score(results.maxTotal)}'),
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List> studentAssessment(AssessmentResults results, StudentResult student) async {
    final document = pw.Document();
    final entryMap = {for (final entry in student.entries) entry.criterionId: entry};
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text('Ölçerim · Öğrenci değerlendirme formu', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Text(student.student.fullName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('${results.classroom.name} · ${results.assessment.title}'),
          if (student.student.schoolNumber != null) pw.Text('Okul no: ${student.student.schoolNumber}'),
          pw.SizedBox(height: 20),
          pw.Text('${_score(student.total)} / ${_score(results.maxTotal)}', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          ...results.criteria.map((criterion) {
            final entry = entryMap[criterion.criterionId];
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Expanded(child: pw.Text(criterion.title)), pw.Text('${entry == null ? '—' : _score(entry.score)} / ${_score(criterion.maxScore)}')],
              ),
            );
          }),
          if (student.note?.isNotEmpty == true) ...[
            pw.Divider(),
            pw.Text('Öğretmen notu', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(student.note!),
          ],
        ],
      ),
    );
    return document.save();
  }

  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  String _status(String value) => switch (value) { 'completed' => 'Tamamlandı', 'incomplete' => 'Eksik', _ => 'Değerlendirilmedi' };
}
