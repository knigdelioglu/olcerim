import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/evaluations/presentation/views/create_assessment_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/quick_scale_grading_view.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('new quick assessment replaces creator with grading screen', (tester) async {
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

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CreateAssessmentView(initialClassroomId: classroomId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hızlı derecelendirme').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('0–100').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Sözlü notu');
    await tester.pump();
    await tester.tap(find.text('Oluştur ve puanlamaya başla'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateAssessmentView), findsNothing);
    expect(find.byType(QuickScaleGradingView), findsOneWidget);
    expect(find.text('Ada Öğrenci'), findsOneWidget);
    expect(find.text('0–100 puan'), findsOneWidget);
  });
}
