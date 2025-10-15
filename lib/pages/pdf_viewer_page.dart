import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String fileName;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        // Opcionalmente, puedes añadir una barra de progreso mientras carga
        canShowScrollHead: true,
      ),
    );
  }
}