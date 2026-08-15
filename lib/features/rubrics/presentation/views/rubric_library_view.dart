import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';
import 'package:olcerim/features/rubrics/presentation/views/rubric_editor_view.dart';

class RubricLibraryView extends ConsumerWidget {
  const RubricLibraryView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rubrics = ref.watch(rubricTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rubrikler')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openEditor(context), icon: const Icon(Icons.add), label: const Text('Rubrik')),
      body: rubrics.when(
        data: (rows) => rows.isEmpty
            ? _Empty(onCreate: () => _openEditor(context))
            : LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000 ? 3 : constraints.maxWidth >= 620 ? 2 : 1;
                if (columns == 1) return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => _RubricCard(row: rows[i]));
                return GridView.builder(padding: const EdgeInsets.fromLTRB(24, 16, 24, 96), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.1), itemCount: rows.length, itemBuilder: (_, i) => _RubricCard(row: rows[i]));
              }),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Rubrikler yüklenemedi.')),
      ),
    );
  }
  void _openEditor(BuildContext context, [int? id]) => Navigator.push(context, MaterialPageRoute(builder: (_) => RubricEditorView(rubricId: id)));
}

class _RubricCard extends ConsumerWidget {
  const _RubricCard({required this.row}); final RubricSummaryRow row;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RubricEditorView(rubricId: row.rubric.id))),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(row.rubric.title, style: Theme.of(context).textTheme.titleLarge), if (row.rubric.description != null) ...[const SizedBox(height: 4), Text(row.rubric.description!, maxLines: 2, overflow: TextOverflow.ellipsis)], const Spacer(), Text('${row.criteriaCount} kriter · ${_score(row.totalScore)} puan')])),
            PopupMenuButton<String>(onSelected: (value) async { if (value == 'copy') await ref.read(rubricRepositoryProvider).duplicate(row.rubric.id); if (value == 'archive') { await ref.read(rubricRepositoryProvider).setArchived(row.rubric.id, true); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${row.rubric.title} arşivlendi'), action: SnackBarAction(label: 'Geri al', onPressed: () => ref.read(rubricRepositoryProvider).setArchived(row.rubric.id, false)))); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Text('Rubriği çoğalt')), PopupMenuItem(value: 'archive', child: Text('Arşivle'))]),
          ])),
        ),
      );
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class _Empty extends StatelessWidget { const _Empty({required this.onCreate}); final VoidCallback onCreate; @override Widget build(BuildContext context) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.rule_outlined, size: 56), const SizedBox(height: 16), Text('Henüz rubriğiniz yok', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), const Text('Kriterlerinizi bir kez oluşturun, farklı sınıflarda tekrar kullanın.', textAlign: TextAlign.center), const SizedBox(height: 24), FilledButton(onPressed: onCreate, child: const Text('Rubrik oluştur'))]))); }
