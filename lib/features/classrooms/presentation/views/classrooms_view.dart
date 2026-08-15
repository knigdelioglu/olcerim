import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/classrooms/presentation/views/classroom_detail_view.dart';
import 'package:olcerim/features/classrooms/presentation/views/classroom_form_view.dart';
import 'package:olcerim/features/students/presentation/views/student_import_view.dart';

class ClassroomsView extends ConsumerStatefulWidget {
  const ClassroomsView({super.key});

  @override
  ConsumerState<ClassroomsView> createState() => _ClassroomsViewState();
}

class _ClassroomsViewState extends ConsumerState<ClassroomsView> {
  int? selectedYearId;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final years = ref.watch(schoolYearsProvider).valueOrNull ?? const [];
    final active = ref.watch(activeSchoolYearProvider).valueOrNull;
    selectedYearId ??= active?.id ?? (years.isEmpty ? null : years.first.id);
    final classrooms = ref.watch(classroomsProvider(selectedYearId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflar'),
        actions: [
          IconButton(
            tooltip: 'Sınıf ara',
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedYearId == null ? null : () => _openForm(context, selectedYearId!),
        icon: const Icon(Icons.add),
        label: const Text('Sınıf'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (years.isNotEmpty)
              DropdownButton<int>(
                value: selectedYearId,
                items: years
                    .map((year) => DropdownMenuItem(value: year.id, child: Text(year.label)))
                    .toList(),
                onChanged: (value) => setState(() => selectedYearId = value),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: classrooms.when(
                data: (items) {
                  final needle = query.trim().toLowerCase();
                  final filtered = items.where((item) {
                    return needle.isEmpty ||
                        item.classroom.name.toLowerCase().contains(needle) ||
                        item.course.name.toLowerCase().contains(needle);
                  }).toList();
                  if (filtered.isEmpty) {
                    return _EmptyClassrooms(
                      onCreate: selectedYearId == null ? null : () => _openForm(context, selectedYearId!),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1100
                          ? 3
                          : constraints.maxWidth >= 640
                              ? 2
                              : 1;
                      if (columns == 1) {
                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, index) => _ClassroomCard(
                            item: filtered[index],
                            onOpen: () => _openDetail(filtered[index]),
                          ),
                        );
                      }
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.25,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) => _ClassroomCard(
                          item: filtered[index],
                          onOpen: () => _openDetail(filtered[index]),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Sınıflar yüklenemedi.')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(ClassroomSummaryRow item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClassroomDetailView(classroomId: item.classroom.id)),
    );
  }

  Future<void> _openForm(BuildContext context, int yearId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClassroomFormView(initialSchoolYearId: yearId)),
    );
  }

  Future<void> _showSearch(BuildContext context) async {
    final controller = TextEditingController(text: query);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıf ara'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sınıf veya ders'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) setState(() => query = value);
  }
}

class _ClassroomCard extends ConsumerWidget {
  const _ClassroomCard({required this.item, required this.onOpen});
  final ClassroomSummaryRow item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.classroom.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(item.course.name),
                    const SizedBox(height: 14),
                    Text(
                      '${item.studentCount} öğrenci · ${item.schoolYear.label}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Sınıf işlemleri',
                onSelected: (value) async {
                  switch (value) {
                    case 'open':
                      onOpen();
                      return;
                    case 'edit':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassroomFormView(
                            initialSchoolYearId: item.schoolYear.id,
                            classroomId: item.classroom.id,
                            initialName: item.classroom.name,
                            initialCourseName: item.course.name,
                            initialDescription: item.classroom.description,
                          ),
                        ),
                      );
                      return;
                    case 'import':
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentImportView(classroomId: item.classroom.id),
                        ),
                      );
                      return;
                    case 'archive':
                      await ref.read(classroomRepositoryProvider).setArchived(item.classroom.id, true);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.classroom.name} arşivlendi'),
                          action: SnackBarAction(
                            label: 'Geri al',
                            onPressed: () => ref
                                .read(classroomRepositoryProvider)
                                .setArchived(item.classroom.id, false),
                          ),
                        ),
                      );
                      return;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('Sınıfı aç')),
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'import', child: Text('Öğrenci içe aktar')),
                  PopupMenuItem(value: 'archive', child: Text('Arşivle')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyClassrooms extends StatelessWidget {
  const _EmptyClassrooms({this.onCreate});
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 56),
              const SizedBox(height: 16),
              Text('Henüz sınıfınız yok', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Öğrencilerinizi değerlendirmeye başlamak için ilk sınıfınızı oluşturun.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onCreate, child: const Text('Sınıf oluştur')),
            ],
          ),
        ),
      );
}
