import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/students/data/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => StudentRepository(ref.watch(databaseProvider)),
);

final studentsProvider = StreamProvider.family<List<Student>, int>((ref, classroomId) {
  return ref.watch(studentRepositoryProvider).watchStudents(classroomId);
});

final archivedStudentsProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(studentRepositoryProvider).watchArchivedStudents();
});
