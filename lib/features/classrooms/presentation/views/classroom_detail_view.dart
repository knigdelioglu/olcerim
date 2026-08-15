import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';
import 'package:olcerim/features/students/presentation/views/student_import_view.dart';

class ClassroomDetailView extends ConsumerWidget {
  const ClassroomDetailView({required this.classroomId, super.key});
  final int classroomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(classroomDetailProvider(classroomId));
    final students = ref.watch(studentsProvider(classroomId));
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.valueOrNull?.classroom.name ?? 'Sınıf'),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentImportView(classroomId: classroomId))),
            icon: const Icon(Icons.upload_file),
            label: const Text('İçe aktar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _studentDialog(context, ref), icon: const Icon(Icons.person_add_alt_1), label: const Text('Öğrenci')),
      body: detail.when(
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('${value.course.name} · ${value.schoolYear.label}', style: Theme.of(context).textTheme.bodyLarge),
              ),
            const Divider(height: 1),
            Expanded(
              child: students.when(
                data: (items) => items.isEmpty
                    ? const Center(child: Text('Bu sınıfta henüz öğrenci yok. Manuel ekleyin veya Excel/CSV içe aktarın.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) => _StudentTile(student: items[index], classroomId: classroomId),
                      ),
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

  Future<void> _studentDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final number = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenci ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad')), const SizedBox(height: 12), TextField(controller: number, decoration: const InputDecoration(labelText: 'Okul numarası (opsiyonel)'))]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ekle'))],
      ),
    );
    if (confirmed == true && name.text.trim().isNotEmpty) {
      try {
        await ref.read(studentRepositoryProvider).saveStudent(classroomId: classroomId, schoolNumber: number.text, fullName: name.text);
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğrenci eklenemedi. Okul numarası sınıfta kullanılıyor olabilir.')));
      }
    }
  }
}

class _StudentTile extends ConsumerWidget {
  const _StudentTile({required this.student, required this.classroomId});
  final Student student;
  final int classroomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(child: Text(student.fullName.isEmpty ? '?' : student.fullName.characters.first.toUpperCase())),
      title: Text(student.fullName),
      subtitle: student.schoolNumber == null ? null : Text('No: ${student.schoolNumber}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Öğrenci işlemleri',
        onSelected: (value) async {
          if (value == 'archive') {
            await ref.read(studentRepositoryProvider).setArchived(student.id, true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${student.fullName} arşivlendi'), action: SnackBarAction(label: 'Geri al', onPressed: () => ref.read(studentRepositoryProvider).setArchived(student.id, false))),
            );
          }
        },
        itemBuilder: (_) => const [PopupMenuItem(value: 'archive', child: Text('Arşivle'))],
      ),
    );
  }
}
