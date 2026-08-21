import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/evaluations/domain/quick_scale.dart';
import 'package:olcerim/features/evaluations/presentation/views/quick_scale_grading_view.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<({int assessmentId, int firstEvaluationId, int secondEvaluationId})> fixture() async {
    final year = await db.schoolDao.activeSchoolYear();
    final classroomId = await db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '10/A',
      courseName: 'Türk Dili ve Edebiyatı',
    );
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '101',
      fullName: 'Ada Öğrenci',
    );
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '102',
      fullName: 'Bora Öğrenci',
    );

    final assessmentId = await db.assessmentDao.createQuickScaleAssessment(
      classroomId: classroomId,
      preset: QuickScalePreset.numericHundred,
      title: 'Hızlı not girişi',
      assessmentDate: DateTime(2026, 8, 21),
    );
    final rows = await db.evaluationDao.watchStudentsForAssessment(assessmentId).first;
    return (
      assessmentId: assessmentId,
      firstEvaluationId: rows[0].evaluation.id,
      secondEvaluationId: rows[1].evaluation.id,
    );
  }

  testWidgets('0-100 quick grading renders inline fields and saves through canonical path',
      (tester) async {
    final data = await fixture();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: QuickScaleGradingView(assessmentId: data.assessmentId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0–100 puan'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '87');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final firstEntries = await db.evaluationDao.watchEntries(data.firstEvaluationId).first;
    expect(firstEntries.single.score, 87);
    final firstRow = (await db.evaluationDao.watchStudentsForAssessment(data.assessmentId).first)
        .firstWhere((row) => row.evaluation.id == data.firstEvaluationId);
    expect(firstRow.evaluation.status, 'completed');

    await tester.enterText(find.byType(TextField).at(1), '101');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(find.text('0 ile 100 arasında bir puan girin.'), findsOneWidget);
    expect(await db.evaluationDao.watchEntries(data.secondEvaluationId).first, isEmpty);
  });
}
