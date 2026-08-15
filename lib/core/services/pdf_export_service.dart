import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class PdfExportService {
  Future<Uint8List> classAssessment(AssessmentResults results) async {
    final document = pw.Document();
    final description = results.assessment.description?.trim();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(results.assessment.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('${results.classroom.name} · Sınıf değerlendirme çizelgesi'),
          if (description?.isNotEmpty == true) ...[
            pw.SizedBox(height: 6),
            pw.Text(description!),
          ],
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Öğrenci',
              ...results.criteria.map((c) => c.title),
              'Toplam',
              'Durum',
              'Notlar / gözlemler',
            ],
            data: results.students.map((student) {
              final entryMap = {for (final entry in student.entries) entry.criterionId: entry};
              return [
                student.student.schoolNumber ?? '',
                student.student.fullName,
                ...results.criteria.map(
                  (criterion) => entryMap[criterion.criterionId] == null
                      ? ''
                      : _score(entryMap[criterion.criterionId]!.score),
                ),
                _score(student.total),
                _status(student.status),
                _studentNotes(student),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
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
    final description = results.assessment.description?.trim();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text(
            'Ölçerim · Öğrenci değerlendirme formu',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Text(student.student.fullName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('${results.classroom.name} · ${results.assessment.title}'),
          if (student.student.schoolNumber != null) pw.Text('Okul no: ${student.student.schoolNumber}'),
          if (description?.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text(description!),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            '${_score(student.total)} / ${_score(results.maxTotal)}',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          ...results.criteria.map((criterion) {
            final entry = entryMap[criterion.criterionId];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(criterion.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Text('${entry == null ? '—' : _score(entry.score)} / ${_score(criterion.maxScore)}'),
                    ],
                  ),
                  if (entry?.note?.isNotEmpty == true) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('Kriter notu: ${entry!.note}'),
                  ],
                ],
              ),
            );
          }),
          if (student.note?.isNotEmpty == true) ...[
            pw.Divider(),
            pw.Text('Öğretmen notu', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(student.note!),
          ],
          if (student.observations.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Text('Gözlem notları', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...student.observations.map(
              (observation) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text('${_date(observation.createdAt)} · ${observation.content}'),
              ),
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  String _studentNotes(StudentResult student) {
    final lines = <String>[];
    if (student.note?.isNotEmpty == true) lines.add('Öğretmen: ${student.note}');
    for (final entry in student.entries) {
      if (entry.note?.isNotEmpty == true) lines.add('${entry.title}: ${entry.note}');
    }
    for (final observation in student.observations) {
      lines.add('Gözlem ${_date(observation.createdAt)}: ${observation.content}');
    }
    return lines.join('\n');
  }

  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  String _status(String value) => switch (value) {
        'completed' => 'Tamamlandı',
        'incomplete' => 'Eksik',
        _ => 'Değerlendirilmedi',
      };

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
