import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/core/database/app_database.dart';
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (year.isActive) const Chip(label: Text('Aktif')),
                        PopupMenuButton<String>(
                          tooltip: 'Eğitim yılı işlemleri',
                          onSelected: (value) => _handleAction(
                            context: context,
                            ref: ref,
                            year: year,
                            action: value,
                          ),
                          itemBuilder: (_) => [
                            if (!year.isActive)
                              const PopupMenuItem(
                                value: 'activate',
                                child: Text('Aktif yap'),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Düzenle'),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Arşivle'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Eğitim yılları yüklenemedi.')),
      ),
    );
  }

  Future<void> _handleAction({
    required BuildContext context,
    required WidgetRef ref,
    required SchoolYear year,
    required String action,
  }) async {
    switch (action) {
      case 'activate':
        try {
          await ref.read(classroomRepositoryProvider).setActiveSchoolYear(year.id);
          ref.invalidate(activeSchoolYearProvider);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Eğitim yılı aktif yapılamadı.')),
            );
          }
        }
        return;
      case 'edit':
        await _editYear(context, ref, year);
        return;
      case 'archive':
        await _archiveYear(context, ref, year);
        return;
    }
  }

  Future<void> _createYear(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    final draft = await _showYearDialog(
      context: context,
      title: 'Yeni eğitim yılı',
      actionLabel: 'Oluştur',
      initialLabel: '$startYear–${startYear + 1}',
      initialStartsAt: DateTime(startYear, 9, 1),
      initialEndsAt: DateTime(startYear + 1, 8, 31),
      allowMakeActive: true,
    );
    if (draft == null) return;

    try {
      await ref.read(classroomRepositoryProvider).createSchoolYear(
            label: draft.label,
            startsAt: draft.startsAt,
            endsAt: draft.endsAt,
            makeActive: draft.makeActive,
          );
      if (draft.makeActive) ref.invalidate(activeSchoolYearProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Eğitim yılı oluşturulamadı. Etiketi ve tarih aralığını kontrol edin.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _editYear(
    BuildContext context,
    WidgetRef ref,
    SchoolYear year,
  ) async {
    final draft = await _showYearDialog(
      context: context,
      title: 'Eğitim yılını düzenle',
      actionLabel: 'Kaydet',
      initialLabel: year.label,
      initialStartsAt: year.startsAt,
      initialEndsAt: year.endsAt,
    );
    if (draft == null) return;

    try {
      await ref.read(classroomRepositoryProvider).updateSchoolYear(
            id: year.id,
            label: draft.label,
            startsAt: draft.startsAt,
            endsAt: draft.endsAt,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Eğitim yılı güncellenemedi. Etiketi ve tarih aralığını kontrol edin.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _archiveYear(
    BuildContext context,
    WidgetRef ref,
    SchoolYear year,
  ) async {
    if (year.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aktif eğitim yılı arşivlenemez. Önce başka bir eğitim yılını aktif yapın.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eğitim yılını arşivle'),
        content: Text(
          '${year.label} eğitim yılı aktif listeden kaldırılacak. İlişkili veriler silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(classroomRepositoryProvider).setSchoolYearArchived(year.id, true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${year.label} arşivlendi.'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => ref
                .read(classroomRepositoryProvider)
                .setSchoolYearArchived(year.id, false),
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eğitim yılı arşivlenemedi.')),
        );
      }
    }
  }

  Future<_SchoolYearDraft?> _showYearDialog({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required String initialLabel,
    required DateTime initialStartsAt,
    required DateTime initialEndsAt,
    bool allowMakeActive = false,
  }) async {
    final label = TextEditingController(text: initialLabel);
    var startsAt = initialStartsAt;
    var endsAt = initialEndsAt;
    var makeActive = false;

    final result = await showDialog<_SchoolYearDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: const InputDecoration(
                    labelText: 'Etiket',
                    hintText: '2026–2027',
                  ),
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
                      firstDate: DateTime(startsAt.year - 5),
                      lastDate: DateTime(endsAt.year + 5, 12, 31),
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
                      firstDate: DateTime(startsAt.year),
                      lastDate: DateTime(endsAt.year + 5, 12, 31),
                    );
                    if (picked != null) setLocalState(() => endsAt = picked);
                  },
                ),
                if (allowMakeActive)
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _SchoolYearDraft(
                  label: label.text,
                  startsAt: startsAt,
                  endsAt: endsAt,
                  makeActive: makeActive,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    return result;
  }
}

class _SchoolYearDraft {
  const _SchoolYearDraft({
    required this.label,
    required this.startsAt,
    required this.endsAt,
    required this.makeActive,
  });

  final String label;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool makeActive;
}
