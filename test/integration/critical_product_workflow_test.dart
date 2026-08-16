import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';
import 'package:olcerim/core/services/excel_service.dart';
import 'package:olcerim/core/services/pdf_export_service.dart';
import 'package:olcerim/core/services/tabular_export_service.dart';
import 'package:olcerim/features/backup/data/backup_repository.dart';
import 'package:olcerim/features/classrooms/data/classroom_repository.dart';
import 'package:olcerim/features/evaluations/data/assessment_repository.dart';
import 'package:olcerim/features/evaluations/data/evaluation_repository.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/reports/data/report_repository.dart';
import 'package:olcerim/features/rubrics/data/rubric_repository.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';
import 'package:olcerim/features/students/data/student_repository.dart';

void main() {
  test('kritik ürün zinciri restart ve restore dahil uçtan uca çalışır', () async {
    final directory = await Directory.systemTemp.createTemp('olcerim-critical-flow-');
    final sourceFile = File('${directory.path}/source.sqlite');
    final restoredFile = File('${directory.path}/restored.sqlite');
    AppDatabase? source;
    AppDatabase? restored;

    try {
      source = AppDatabase.forTesting(NativeDatabase(sourceFile));
      final classrooms = ClassroomRepository(source);
      final students = StudentRepository(source);
      final rubrics = RubricRepository(source);
      final assessments = AssessmentRepository(source);
      final evaluations = EvaluationRepository(source);

      final year = await classrooms.activeSchoolYear();
      expect(year, isNotNull);
      final classroomId = await classrooms.createClassroom(
        schoolYearId: year!.id,
        name: '10/Test',
        courseName: 'Course',
        description: 'Critical integration flow',
      );

      final importService = ExcelService();
      final preview = await importService.parseStudentList(
        Uint8List.fromList(
          utf8.encode('Okul No,Ad Soyad\n101,Ada Test\n102,Bora Test'),
        ),
        'csv',
      );
      final validation = importService.validate(
        preview,
        nameColumn: preview.suggestedNameColumn!,
        numberColumn: preview.suggestedNumberColumn,
      );
      expect(validation.isValid, isTrue);
      await students.importStudents(
        classroomId,
        validation.validRows
            .map(
              (row) => StudentImportRecord(
                fullName: row.fullName,
                schoolNumber: row.schoolNumber,
              ),
            )
            .toList(),
      );

      final rubricId = await rubrics.save(
        RubricDraft(
          title: 'Integration Rubric',
          criteria: [
            CriterionDraft(
              title: 'Content',
              maxScore: 20,
              levels: [
                LevelDraft(label: 'Developing', score: 10),
                LevelDraft(label: 'Complete', score: 20),
              ],
            ),
            CriterionDraft(title: 'Delivery', maxScore: 10),
          ],
        ),
      );

      final assessmentId = await assessments.create(
        classroomId: classroomId,
        rubricId: rubricId,
        type: AssessmentType.rubric,
        title: 'Integration Assessment',
        description: 'Critical release gate',
        assessmentDate: DateTime(2026, 8, 16),
      );

      final studentRows = await evaluations.watchStudents(assessmentId).first;
      final criteria = await evaluations.criteria(assessmentId);
      expect(studentRows, hasLength(2));
      expect(criteria, hasLength(2));

      for (var studentIndex = 0; studentIndex < studentRows.length; studentIndex++) {
        final evaluationId = studentRows[studentIndex].evaluation.id;
        await evaluations.score(
          evaluationId: evaluationId,
          criterionId: criteria[0].id,
          score: studentIndex == 0 ? 18 : 16,
          note: studentIndex == 0 ? 'Criterion note' : null,
        );
        await evaluations.score(
          evaluationId: evaluationId,
          criterionId: criteria[1].id,
          score: studentIndex == 0 ? 9 : 8,
        );
        if (studentIndex == 0) {
          await evaluations.saveStudentNote(evaluationId, 'Teacher note');
          await evaluations.addObservation(evaluationId, 'Observation note');
        }
      }
      await assessments.setStatus(assessmentId, AssessmentStatus.completed);

      final reportRepository = ReportRepository(
        evaluations,
        PdfExportService(),
        TabularExportService(),
      );
      final beforeRestart = await reportRepository.results(assessmentId);
      expect(beforeRestart.completedCount, 2);
      expect(beforeRestart.students.map((student) => student.total).toList(), [27, 24]);

      final pdf = await reportRepository.classPdf(beforeRestart);
      final csv = reportRepository.csv(beforeRestart);
      final xlsx = reportRepository.xlsx(beforeRestart);
      expect(pdf.length, greaterThan(500));
      expect(xlsx.length, greaterThan(500));
      expect(utf8.decode(csv), contains('Ada Test'));
      expect(utf8.decode(csv), contains('Bora Test'));

      await source.close();
      source = null;

      source = AppDatabase.forTesting(NativeDatabase(sourceFile));
      final afterRestart = await EvaluationRepository(source).loadResults(assessmentId);
      expect(afterRestart.completedCount, 2);
      expect(afterRestart.students.map((student) => student.total).toList(), [27, 24]);
      expect(afterRestart.students.first.note, 'Teacher note');
      expect(afterRestart.students.first.observations.single.content, 'Observation note');

      const password = 'critical-flow-backup-password';
      final crypto = BackupRestoreService();
      final encrypted = await BackupRepository(source, crypto).create(password);

      restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
      final restoredBackup = BackupRepository(restored, crypto);
      final decoded = await restoredBackup.decode(encrypted, password);
      await restoredBackup.restore(decoded);

      final restoredResults = await EvaluationRepository(restored).loadResults(assessmentId);
      expect(restoredResults.completedCount, 2);
      expect(restoredResults.students.map((student) => student.total).toList(), [27, 24]);
      expect(restoredResults.students.first.entries.first.note, 'Criterion note');
      expect(restoredResults.students.first.note, 'Teacher note');
      expect(restoredResults.students.first.observations.single.content, 'Observation note');
      expect(await restored.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    } finally {
      await source?.close();
      await restored?.close();
      await directory.delete(recursive: true);
    }
  });
}
