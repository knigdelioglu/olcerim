import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';

final archivedClassroomsProvider = StreamProvider((ref) => ref.watch(classroomRepositoryProvider).watchClassrooms(archived: true));
final archivedRubricsProvider = StreamProvider((ref) => ref.watch(rubricRepositoryProvider).watchTemplates(archived: true));
final archivedStudentsProvider = StreamProvider<List<Student>>((ref) => ref.watch(databaseProvider).studentDao.watchArchivedStudents());

class ArchivesView extends ConsumerStatefulWidget {
  const ArchivesView({super.key});
  @override ConsumerState<ArchivesView> createState() => _ArchivesViewState();
}
class _ArchivesViewState extends ConsumerState<ArchivesView> {
  var section = 0;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Arşivlenen veriler')), body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('Sınıflar')), ButtonSegment(value: 1, label: Text('Öğrenciler')), ButtonSegment(value: 2, label: Text('Rubrikler'))], selected: {section}, onSelectionChanged: (values) => setState(() => section = values.first))), Expanded(child: switch (section) { 0 => _classrooms(), 1 => _students(), _ => _rubrics() })]));

  Widget _classrooms() => ref.watch(archivedClassroomsProvider).when(data: (items) => items.isEmpty ? const _Empty(text: 'Arşivlenmiş sınıf yok.') : ListView(children: items.map((item) => ListTile(title: Text(item.classroom.name), subtitle: Text(item.course.name), trailing: TextButton(onPressed: () => ref.read(classroomRepositoryProvider).setArchived(item.classroom.id, false), child: const Text('Geri yükle')))).toList()), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')));
  Widget _students() => ref.watch(archivedStudentsProvider).when(data: (items) => items.isEmpty ? const _Empty(text: 'Arşivlenmiş öğrenci yok.') : ListView(children: items.map((item) => ListTile(title: Text(item.fullName), subtitle: item.schoolNumber == null ? null : Text('No: ${item.schoolNumber}'), trailing: TextButton(onPressed: () => ref.read(studentRepositoryProvider).setArchived(item.id, false), child: const Text('Geri yükle')))).toList()), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')));
  Widget _rubrics() => ref.watch(archivedRubricsProvider).when(data: (items) => items.isEmpty ? const _Empty(text: 'Arşivlenmiş rubrik yok.') : ListView(children: items.map((item) => ListTile(title: Text(item.rubric.title), subtitle: Text('${item.criteriaCount} kriter'), trailing: TextButton(onPressed: () => ref.read(rubricRepositoryProvider).setArchived(item.rubric.id, false), child: const Text('Geri yükle')))).toList()), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')));
}
class _Empty extends StatelessWidget { const _Empty({required this.text}); final String text; @override Widget build(BuildContext context) => Center(child: Text(text)); }
