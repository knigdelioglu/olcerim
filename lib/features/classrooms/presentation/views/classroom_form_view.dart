import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';

class ClassroomFormView extends ConsumerStatefulWidget {
  const ClassroomFormView({required this.initialSchoolYearId, super.key});
  final int initialSchoolYearId;

  @override
  ConsumerState<ClassroomFormView> createState() => _ClassroomFormViewState();
}

class _ClassroomFormViewState extends ConsumerState<ClassroomFormView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final courseController = TextEditingController();
  final descriptionController = TextEditingController();
  late int schoolYearId = widget.initialSchoolYearId;
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = ref.watch(schoolYearsProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni sınıf')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.formMaxWidth),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: schoolYearId,
                    decoration: const InputDecoration(labelText: 'Eğitim yılı'),
                    items: years.map((year) => DropdownMenuItem(value: year.id, child: Text(year.label))).toList(),
                    onChanged: (value) => schoolYearId = value ?? schoolYearId,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Sınıf adı', hintText: '10/A'), validator: _required),
                  const SizedBox(height: 16),
                  TextFormField(controller: courseController, decoration: const InputDecoration(labelText: 'Ders', hintText: 'Türk Dili ve Edebiyatı'), validator: _required),
                  const SizedBox(height: 16),
                  TextFormField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'), minLines: 2, maxLines: 4),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'Kaydediliyor…' : 'Sınıfı oluştur')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await ref.read(classroomRepositoryProvider).createClassroom(
            schoolYearId: schoolYearId,
            name: nameController.text,
            courseName: courseController.text,
            description: descriptionController.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sınıf kaydedilemedi. Aynı sınıf zaten var olabilir.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
