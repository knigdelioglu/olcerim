import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';
import 'package:olcerim/core/services/share_file_service.dart';
import 'package:olcerim/features/backup/presentation/controllers/backup_controller.dart';

class BackupView extends ConsumerStatefulWidget {
  const BackupView({super.key});

  @override
  ConsumerState<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends ConsumerState<BackupView> {
  bool busy = false;
  String stage = '';
  final share = ShareFileService();

  @override
  Widget build(BuildContext context) {
    final lastBackup = ref.watch(lastBackupAtProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Yedekleme ve geri yükleme')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verileriniz bu cihazda saklanıyor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cihazınızı kaybetmeniz veya uygulamayı silmeniz durumunda '
                      'verileri geri getirmek için düzenli olarak yedek alın.',
                    ),
                    if (lastBackup != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Son yedek: ${DateFormat('d MMMM y, HH:mm', 'tr').format(lastBackup)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : _createBackup,
              icon: const Icon(Icons.backup),
              label: const Text('Yedek oluştur'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Yedekten geri yükle'),
            ),
            if (busy) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(stage),
            ],
            const SizedBox(height: 20),
            const Text(
              'Yedek parolanızı unutursanız yedek içeriği geri getirilemez. '
              'Parolanızı güvenli bir yerde saklayın.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    final password = await _passwordDialog(confirm: true);
    if (password == null) return;

    setState(() {
      busy = true;
      stage = 'Yedek hazırlanıyor…';
    });

    try {
      final bytes = await ref.read(backupRepositoryProvider).create(password);
      final date = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
      if (mounted) {
        setState(() => stage = 'Sistem paylaşım ekranı açılıyor…');
      }
      await share.share(
        bytes: bytes,
        fileName: 'olcerim-backup-$date.${AppConstants.backupExtension}',
        mimeType: 'application/octet-stream',
        subject: 'Ölçerim yedeği',
      );
      ref.invalidate(lastBackupAtProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          stage = '';
        });
      }
    }
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [AppConstants.backupExtension],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final password = await _passwordDialog(confirm: false);
    if (password == null) return;

    setState(() {
      busy = true;
      stage = 'Yedek doğrulanıyor…';
    });

    try {
      final decoded = await ref.read(backupRepositoryProvider).decode(bytes, password);
      if (!mounted) return;

      setState(() {
        busy = false;
        stage = '';
      });
      final confirmed = await _previewDialog(decoded);
      if (!confirmed || !mounted) return;

      setState(() {
        busy = true;
        stage = 'Veriler geri yükleniyor…';
      });
      await ref.read(backupRepositoryProvider).restore(decoded);
      ref.invalidate(lastBackupAtProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler geri yüklendi.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yedek geri yüklenemedi. Mevcut verileriniz değiştirilmedi.\n$error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          stage = '';
        });
      }
    }
  }

  Future<String?> _passwordDialog({required bool confirm}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    var obscure = true;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(confirm ? 'Yedek parolası' : 'Yedek parolasını girin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                obscureText: obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Parola',
                  suffixIcon: IconButton(
                    onPressed: () => setLocal(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: second,
                  obscureText: obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Parolayı tekrar girin'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                confirm
                    ? 'En az 8 karakter kullanın. Bu parola unutulursa yedek açılamaz.'
                    : 'Yedek oluşturulurken kullandığınız parolayı girin.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (first.text.length < 8 || (confirm && first.text != second.text)) {
                  return;
                }
                Navigator.pop(dialogContext, first.text);
              },
              child: Text(confirm ? 'Devam' : 'Yedeği aç'),
            ),
          ],
        ),
      ),
    );

    first.dispose();
    second.dispose();
    return result;
  }

  Future<bool> _previewDialog(DecodedBackup backup) async {
    final counts = backup.preview.counts;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ölçerim yedeği'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM y, HH:mm', 'tr')
                      .format(backup.preview.createdAt.toLocal()),
                ),
                const SizedBox(height: 16),
                Text('${counts['classrooms'] ?? 0} sınıf'),
                Text('${counts['students'] ?? 0} öğrenci'),
                Text('${counts['rubrics'] ?? 0} rubrik kaydı'),
                Text('${counts['assessments'] ?? 0} değerlendirme'),
                const SizedBox(height: 12),
                Text('Veritabanı sürümü: ${backup.preview.databaseSchemaVersion}'),
                const SizedBox(height: 16),
                const Text(
                  'Geri yükleme, cihazdaki mevcut Ölçerim verilerini bu '
                  'yedekteki verilerle değiştirecektir.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Yedeği geri yükle'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
