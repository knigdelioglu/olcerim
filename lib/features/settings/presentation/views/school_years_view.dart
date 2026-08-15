import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';

class SchoolYearsView extends ConsumerWidget {
  const SchoolYearsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(schoolYearsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Eğitim yılları')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createYear(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Eğitim yılı'),
      ),
      body: years.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('Henüz eğitim yılı yok.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final year = items[index];
                  return ListTile(
                    leading: Icon(
                      year.isActive ? Icons.check_circle : Icons.calendar_today_outlined,
                    ),
                    title: Text(year.label),
                    subtitle: Text(
                      '${DateFormat('d MMM y', 'tr').format(year.startsAt)} – ${DateFormat('d MMM y', 'tr').format(year.endsAt)}',
                    ),
                    trailing: year.isActive
                        ? const Chip(label: Text('Aktif'))
                        : TextButton(
                            onPressed: () async {
                              await ref.read(classroomRepositoryProvider).setActiveSchoolYear(year.id);
                              ref.invalidate(activeSchoolYearProvider);
                            },
                            child: const Text('Aktif yap'),
                          ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Eğitim yılları yüklenemedi.')),
      ),
    );
  }

  Future<void> _createYear(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year + 1 : now.year;
    final label = TextEditingController(text: '$startYear–${startYear + 1}');
    var startsAt = DateTime(startYear, 9, 1);
    var endsAt = DateTime(startYear + 1, 8, 31);
    var makeActive = false;

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Yeni eğitim yılı'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Etiket', hintText: '2027–2028'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Başlangıç'),
                  subtitle: Text(DateFormat('d MMMM y', 'tr').format(startsAt)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startsAt,
                      firstDate: DateTime(startYear - 2),
                      lastDate: DateTime(startYear + 3),
                    );
                    if (picked != null) setLocalState(() => startsAt = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bitiş'),
                  subtitle: Text(DateFormat('d MMMM y', 'tr').format(endsAt)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endsAt,
                      firstDate: startsAt,
                      lastDate: DateTime(startYear + 4),
                    );
                    if (picked != null) setLocalState(() => endsAt = picked);
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: makeActive,
                  onChanged: (value) => setLocalState(() => makeActive = value ?? false),
                  title: const Text('Oluşturunca aktif eğitim yılı yap'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );

    if (create != true) {
      label.dispose();
      return;
    }
    try {
      await ref.read(classroomRepositoryProvider).createSchoolYear(
            label: label.text,
            startsAt: startsAt,
            endsAt: endsAt,
            makeActive: makeActive,
          );
      if (makeActive) ref.invalidate(activeSchoolYearProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eğitim yılı oluşturulamadı. Etiket daha önce kullanılmış olabilir.')),
        );
      }
    } finally {
      label.dispose();
    }
  }
}
