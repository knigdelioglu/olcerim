import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/classrooms/data/classroom_repository.dart';

final classroomRepositoryProvider = Provider<ClassroomRepository>(
  (ref) => ClassroomRepository(ref.watch(databaseProvider)),
);

final activeSchoolYearProvider = FutureProvider<SchoolYear?>((ref) {
  return ref.watch(classroomRepositoryProvider).activeSchoolYear();
});

final schoolYearsProvider = StreamProvider<List<SchoolYear>>((ref) {
  return ref.watch(classroomRepositoryProvider).watchSchoolYears();
});

final archivedSchoolYearsProvider = StreamProvider<List<SchoolYear>>((ref) {
  return ref.watch(classroomRepositoryProvider).watchArchivedSchoolYears();
});

final classroomsProvider = StreamProvider.family<List<ClassroomSummaryRow>, int?>((ref, schoolYearId) {
  return ref.watch(classroomRepositoryProvider).watchClassrooms(schoolYearId: schoolYearId);
});

final classroomDetailProvider = FutureProvider.family<ClassroomDetailRow?, int>((ref, id) {
  return ref.watch(classroomRepositoryProvider).classroomDetail(id);
});