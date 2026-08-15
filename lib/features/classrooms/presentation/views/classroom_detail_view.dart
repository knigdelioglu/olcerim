import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/classrooms/presentation/views/classroom_form_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/create_assessment_view.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';
import 'package:olcerim/features/students/presentation/views/student_form_view.dart';
import 'package:olcerim/features/students/presentation/views/student_import_view.dart';

class ClassroomDetailView extends ConsumerStatefulWidget {
  const ClassroomDetailView({required this.classroomId, super.key});
  final int classroomId;

  @override
  ConsumerState<ClassroomDetailView> createState() => _ClassroomDetailViewState();
}

class _ClassroomDetailViewState extends ConsumerState<ClassroomDetailView> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(classroomDetailProvider(widget.classroomId));
    final students = ref.watch(studentsProvider(widget.classroomId));
    final detailValue = detail.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(detailValue?.classroom.name ?? 'Sınıf'),
        actions: [
          IconButton(
            tooltip: 'Sınıfı düzenle',
            onPressed: detailValue == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassroomFormView(
                          initialSchoolYearId: detailValue.schoolYear.id,
                          classroomId: detailValue.classroom.id,
                          initialName: detailValue.classroom.name,
                          initialCourseName: detailValue.course.name,
                          initialDescription: detailValue.classroom.description,
                        ),
                      ),
                    ),
            icon: const Icon(Icons.edit_outlined),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentImportView(classroomId: widget.classroomId),
              ),
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('İçe aktar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentFormView(classroomId: widget.classroomId),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Öğrenci'),
      ),
      body: detail.when(
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${value.course.name} · ${value.schoolYear.label}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAssessmentView(initialClassroomId: widget.classroomId),
                        ),
                      ),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Değerlendirme başlat'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchBar(
                hintText: 'Öğrenci adı veya okul numarası ara',
                leading: const Icon(Icons.search),
                onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: students.when(
                data: (items) {
                  final filtered = items.where((student) {
                    if (query.isEmpty) return true;
                    return student.fullName.toLowerCase().contains(query) ||
                        (student.schoolNumber?.toLowerCase().contains(query) ?? false);
                  }).toList();
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Bu sınıfta henüz öğrenci yok. Manuel ekleyin veya Excel/CSV içe aktarın.'),
                    );
                  }
                  if (filtered.isEmpty) {
                    return const Center(child: Text('Aramanızla eşleşen öğrenci bulunamadı.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => _StudentTile(
                      student: filtered[index],
                      classroomId: widget.classroomId,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Öğrenciler yüklenemedi.')),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Sınıf yüklenemedi.')),
      ),
    );
  }
}

class _StudentTile extends ConsumerWidget {
  const _StudentTile({required this.student, required this.classroomId});
  final Student student;
  final int classroomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(student.fullName.isEmpty ? '?' : student.fullName.characters.first.toUpperCase()),
      ),
      title: Text(student.fullName),
      subtitle: student.schoolNumber == null ? null : Text('No: ${student.schoolNumber}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Öğrenci işlemleri',
        onSelected: (value) async {
          if (value == 'edit') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentFormView(classroomId: classroomId, student: student),
              ),
            );
            return;
          }
          if (value == 'archive') {
            await ref.read(studentRepositoryProvider).setArchived(student.id, true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${student.fullName} arşivlendi'),
                action: SnackBarAction(
                  label: 'Geri al',
                  onPressed: () => ref.read(studentRepositoryProvider).setArchived(student.id, false),
                ),
              ),
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Düzenle')),
          PopupMenuItem(value: 'archive', child: Text('Arşivle')),
        ],
      ),
    );
  }
}
