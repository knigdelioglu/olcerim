import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareFileService {
  Future<XFile> temporaryFile({required Uint8List bytes, required String fileName, String? mimeType}) async {
    final directory = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File(p.join(directory.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: mimeType, name: safeName);
  }

  Future<void> share({required Uint8List bytes, required String fileName, String? mimeType, String? subject}) async {
    final file = await temporaryFile(bytes: bytes, fileName: fileName, mimeType: mimeType);
    await SharePlus.instance.share(ShareParams(files: [file], subject: subject));
  }
}
