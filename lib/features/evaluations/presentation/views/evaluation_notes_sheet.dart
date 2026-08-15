import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';

Future<void> showCriterionNoteDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int evaluationId,
  required int criterionId,
  String? currentNote,
}) async {
  final controller = TextEditingController(text: currentNote ?? '');
  final value = await showDialog<String?>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Kriter notu'),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Bu kritere özgü kısa bir değerlendirme notu yazın.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, ''), child: const Text('Notu temizle')),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value == null) return;
  try {
    await ref.read(evaluationRepositoryProvider).saveCriterionNote(
          evaluationId: evaluationId,
          criterionId: criterionId,
          note: value,
        );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kriter notu kaydedilemedi. Önce bu kriter için puan verin.')),
      );
    }
  }
}

Future<void> showObservationNotesSheet(
  BuildContext context,
  int evaluationId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ObservationNotesSheet(evaluationId: evaluationId),
  );
}

class _ObservationNotesSheet extends ConsumerStatefulWidget {
  const _ObservationNotesSheet({required this.evaluationId});
  final int evaluationId;

  @override
  ConsumerState<_ObservationNotesSheet> createState() => _ObservationNotesSheetState();
}

class _ObservationNotesSheetState extends ConsumerState<_ObservationNotesSheet> {
  final controller = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(evaluationObservationsProvider(widget.evaluationId));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Gözlem notları', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Yeni gözlem',
                        hintText: 'Ders sırasında fark ettiğiniz kısa bir gözlemi yazın.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: saving ? null : _add,
                    child: Text(saving ? 'Ekleniyor…' : 'Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: notes.when(
                  data: (items) => items.isEmpty
                      ? const Center(child: Text('Henüz zaman damgalı gözlem notu yok.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final note = items[index];
                            return ListTile(
                              leading: const Icon(Icons.notes),
                              title: Text(note.text),
                              subtitle: Text(
                                DateFormat('d MMM y, HH:mm', 'tr').format(note.createdAt.toLocal()),
                              ),
                            );
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Gözlem notları yüklenemedi.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add() async {
    if (controller.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await ref.read(evaluationRepositoryProvider).addObservation(widget.evaluationId, controller.text);
      controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gözlem notu eklenemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
