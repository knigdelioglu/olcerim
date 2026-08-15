import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class GeneratedPdfView extends StatelessWidget {
  const GeneratedPdfView({required this.title, required this.bytes, required this.fileName, super.key});
  final String title;
  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(tooltip: 'Paylaş', onPressed: () => Printing.sharePdf(bytes: bytes, filename: fileName), icon: const Icon(Icons.share)),
            IconButton(tooltip: 'Yazdır', onPressed: () => Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes), icon: const Icon(Icons.print)),
          ],
        ),
        body: PdfPreview(
          build: (_) async => bytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: fileName,
        ),
      );
}
