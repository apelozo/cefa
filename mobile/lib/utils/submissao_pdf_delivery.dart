import 'dart:typed_data';

import 'submissao_pdf_delivery_stub.dart'
    if (dart.library.html) 'submissao_pdf_delivery_web.dart'
    if (dart.library.io) 'submissao_pdf_delivery_io.dart';

export 'submissao_pdf_delivery_stub.dart'
    if (dart.library.html) 'submissao_pdf_delivery_web.dart'
    if (dart.library.io) 'submissao_pdf_delivery_io.dart';

Future<void> entregarPdfExportacao(Uint8List bytes, String filename) =>
    deliverPdfExport(bytes, filename);

Future<void> entregarPdfVisualizacao(Uint8List bytes, String filename) =>
    deliverPdfPreview(bytes, filename);
