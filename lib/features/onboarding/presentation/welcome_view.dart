import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/classrooms/presentation/views/classroom_form_view.dart';
import 'package:olcerim/features/demo/presentation/controllers/demo_provider.dart';

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});
  @override ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  bool loadingDemo = false;
  @override Widget build(BuildContext context) {
    final activeYear = ref.watch(activeSchoolYearProvider);
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(children: [
      const Icon(Icons.fact_check_rounded, size: 64), const SizedBox(height: 28), Text('Öğrenci değerlendirmeyi\nhızlandırın', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center), const SizedBox(height: 16), Text('Sınıfınızı aktarın, rubriğinizi oluşturun, öğrencilerinizi değerlendirin ve raporlayın. Veriler cihazınızda kalır.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center), const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: activeYear.value == null || loadingDemo ? null : () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomFormView(initialSchoolYearId: activeYear.value!.id))); }, child: const Text('İlk sınıfımı oluştur'))), const SizedBox(height: 8),
      TextButton.icon(onPressed: loadingDemo ? null : _createDemo, icon: loadingDemo ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.science_outlined), label: Text(loadingDemo ? 'Örnek veriler hazırlanıyor…' : 'Örnek verilerle incele')),
      const SizedBox(height: 8), Text('Örnek veriler tamamen sentetiktir ve istediğiniz zaman arşivlenebilir.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
    ]))))));
  }
  Future<void> _createDemo() async { setState(() => loadingDemo = true); try { await ref.read(demoRepositoryProvider).createDemoWorkspace(); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Örnek veriler oluşturulamadı.'))); } finally { if (mounted) setState(() => loadingDemo = false); } }
}
