import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/services/share_file_service.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/reports/presentation/controllers/report_providers.dart';
import 'package:olcerim/features/reports/presentation/views/generated_pdf_view.dart';

class ReportPreviewView extends ConsumerStatefulWidget {
  const ReportPreviewView({super.key});
  @override ConsumerState<ReportPreviewView> createState() => _ReportPreviewViewState();
}

class _ReportPreviewViewState extends ConsumerState<ReportPreviewView> {
  int? assessmentId;
  bool busy = false;
  final share = ShareFileService();

  @override
  Widget build(BuildContext context) {
    final assessments = ref.watch(assessmentsProvider).valueOrNull ?? const <AssessmentSummaryRow>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: DropdownButtonFormField<int>(
                initialValue: assessmentId,
                decoration: const InputDecoration(labelText: 'Değerlendirme'),
                items: assessments.map((item) => DropdownMenuItem(value: item.assessment.id, child: Text('${item.classroom.name} · ${item.assessment.title}'))).toList(),
                onChanged: busy ? null : (value) => setState(() => assessmentId = value),
              ),
            ),
            const SizedBox(height: 24),
            if (assessmentId == null)
              const Text('Rapor oluşturmak için bir değerlendirme seçin.')
            else ...[
              _ReportCard(icon: Icons.table_chart, title: 'Sınıf değerlendirme çizelgesi', description: 'Tüm öğrencilerin kriter puanlarını tek PDF çizelgesinde gösterir.', onPressed: busy ? null : _classPdf),
              _ReportCard(icon: Icons.description_outlined, title: 'Öğrenci değerlendirme formu', description: 'Bir öğrenci için kriter ve toplam puanları PDF olarak oluşturur.', onPressed: busy ? null : _studentPdf),
              _ReportCard(icon: Icons.grid_on, title: 'Excel sonuç tablosu', description: 'Sınıf sonuçlarını .xlsx dosyası olarak paylaşır.', onPressed: busy ? null : () => _tabular('xlsx')),
              _ReportCard(icon: Icons.data_object, title: 'CSV sonuç tablosu', description: 'Sınıf sonuçlarını standart CSV dosyası olarak paylaşır.', onPressed: busy ? null : () => _tabular('csv')),
              if (busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<AssessmentResults> _load() => ref.read(reportRepositoryProvider).results(assessmentId!);

  Future<void> _classPdf() async {
    await _run(() async {
      final results = await _load();
      final bytes = await ref.read(reportRepositoryProvider).classPdf(results);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratedPdfView(title: 'Sınıf çizelgesi', bytes: bytes, fileName: '${_slug(results.assessment.title)}-sinif.pdf')));
    });
  }

  Future<void> _studentPdf() async {
    await _run(() async {
      final results = await _load();
      if (!mounted || results.students.isEmpty) return;
      final student = await showModalBottomSheet<StudentResult>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(child: ListView(children: results.students.map((item) => ListTile(title: Text(item.student.fullName), subtitle: item.student.schoolNumber == null ? null : Text('No: ${item.student.schoolNumber}'), onTap: () => Navigator.pop(context, item))).toList())),
      );
      if (student == null || !mounted) return;
      final bytes = await ref.read(reportRepositoryProvider).studentPdf(results, student);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratedPdfView(title: 'Öğrenci formu', bytes: bytes, fileName: '${_slug(student.student.fullName)}-degerlendirme.pdf')));
    });
  }

  Future<void> _tabular(String type) async {
    await _run(() async {
      final results = await _load();
      final repository = ref.read(reportRepositoryProvider);
      final bytes = type == 'xlsx' ? repository.xlsx(results) : repository.csv(results);
      await share.share(bytes: bytes, fileName: '${_slug(results.assessment.title)}.$type', mimeType: type == 'xlsx' ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 'text/csv', subject: results.assessment.title);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    try { await action(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor oluşturulamadı. Tekrar deneyin.'))); }
    finally { if (mounted) setState(() => busy = false); }
  }

  String _slug(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.icon, required this.title, required this.description, required this.onPressed});
  final IconData icon; final String title; final String description; final VoidCallback? onPressed;
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Icon(icon, size: 32), title: Text(title, style: Theme.of(context).textTheme.titleMedium), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(description)), trailing: FilledButton.tonal(onPressed: onPressed, child: const Text('Oluştur'))));
}
