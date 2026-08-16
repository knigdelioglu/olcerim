import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';

final archivedClassroomsProvider = StreamProvider(
  (ref) => ref.watch(classroomRepositoryProvider).watchClassrooms(archived: true),
);
final archivedRubricsProvider = StreamProvider(
  (ref) => ref.watch(rubricRepositoryProvider).watchTemplates(archived: true),
);

class ArchivesView extends ConsumerStatefulWidget {
  const ArchivesView({super.key});

  @override
  ConsumerState<ArchivesView> createState() => _ArchivesViewState();
}

class _ArchivesViewState extends ConsumerState<ArchivesView> {
  var section = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Arşivlenen veriler')),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Eğitim yılları')),
                  ButtonSegment(value: 1, label: Text('Sınıflar')),
                  ButtonSegment(value: 2, label: Text('Öğrenciler')),
                  ButtonSegment(value: 3, label: Text('Rubrikler')),
                  ButtonSegment(value: 4, label: Text('Değerlendirmeler')),
                ],
                selected: {section},
                onSelectionChanged: (values) => setState(() => section = values.first),
              ),
            ),
            Expanded(
              child: switch (section) {
                0 => _schoolYears(),
                1 => _classrooms(),
                2 => _students(),
                3 => _rubrics(),
                _ => _assessments(),
              },
            ),
          ],
        ),
      );

  Widget _schoolYears() => ref.watch(archivedSchoolYearsProvider).when(
        data: (items) => items.isEmpty
            ? const _Empty(text: 'Arşivlenmiş eğitim yılı yok.')
            : ListView(
                children: items
                    .map(
                      (year) => ListTile(
                        title: Text(year.label),
                        subtitle: Text(
                          '${year.startsAt.day}.${year.startsAt.month}.${year.startsAt.year} – '
                          '${year.endsAt.day}.${year.endsAt.month}.${year.endsAt.year}',
                        ),
                        trailing: TextButton(
                          onPressed: () => ref
                              .read(classroomRepositoryProvider)
                              .setSchoolYearArchived(year.id, false),
                          child: const Text('Geri yükle'),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')),
      );

  Widget _classrooms() => ref.watch(archivedClassroomsProvider).when(
        data: (items) => items.isEmpty
            ? const _Empty(text: 'Arşivlenmiş sınıf yok.')
            : ListView(
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text(item.classroom.name),
                        subtitle: Text(item.course.name),
                        trailing: TextButton(
                          onPressed: () => ref
                              .read(classroomRepositoryProvider)
                              .setArchived(item.classroom.id, false),
                          child: const Text('Geri yükle'),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')),
      );

  Widget _students() => ref.watch(archivedStudentsProvider).when(
        data: (items) => items.isEmpty
            ? const _Empty(text: 'Arşivlenmiş öğrenci yok.')
            : ListView(
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text(item.fullName),
                        subtitle: item.schoolNumber == null ? null : Text('No: ${item.schoolNumber}'),
                        trailing: TextButton(
                          onPressed: () => ref.read(studentRepositoryProvider).setArchived(item.id, false),
                          child: const Text('Geri yükle'),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')),
      );

  Widget _rubrics() => ref.watch(archivedRubricsProvider).when(
        data: (items) => items.isEmpty
            ? const _Empty(text: 'Arşivlenmiş rubrik yok.')
            : ListView(
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text(item.rubric.title),
                        subtitle: Text('${item.criteriaCount} kriter'),
                        trailing: TextButton(
                          onPressed: () => ref
                              .read(rubricRepositoryProvider)
                              .setArchived(item.rubric.id, false),
                          child: const Text('Geri yükle'),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')),
      );

  Widget _assessments() => ref.watch(archivedAssessmentsProvider).when(
        data: (items) => items.isEmpty
            ? const _Empty(text: 'Arşivlenmiş değerlendirme yok.')
            : ListView(
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text(item.assessment.title),
                        subtitle: Text('${item.classroom.name} · ${item.course.name}'),
                        trailing: TextButton(
                          onPressed: () => ref
                              .read(assessmentRepositoryProvider)
                              .setArchived(item.assessment.id, false),
                          child: const Text('Geri yükle'),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Arşiv yüklenemedi.')),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
