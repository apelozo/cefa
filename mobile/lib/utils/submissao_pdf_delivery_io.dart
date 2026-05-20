import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<void> deliverPdfExport(Uint8List bytes, String filename) async {
  await Printing.sharePdf(bytes: bytes, filename: filename);
}

Future<void> deliverPdfPreview(Uint8List bytes, String filename) async {
  await Printing.layoutPdf(
    onLayout: (_) async => bytes,
    name: filename,
  );
}
