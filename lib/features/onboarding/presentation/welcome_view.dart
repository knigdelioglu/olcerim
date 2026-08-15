import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/classrooms/presentation/views/classroom_form_view.dart';

class WelcomeView extends ConsumerWidget {
  const WelcomeView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeYear = ref.watch(activeSchoolYearProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const Icon(Icons.fact_check_rounded, size: 64),
                  const SizedBox(height: 28),
                  Text('Öğrenci değerlendirmeyi\nhızlandırın', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Sınıfınızı aktarın, rubriğinizi oluşturun, öğrencilerinizi değerlendirin ve raporlayın. Veriler cihazınızda kalır.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: activeYear.value == null ? null : () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomFormView(initialSchoolYearId: activeYear.value!.id)));
                      },
                      child: const Text('İlk sınıfımı oluştur'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
