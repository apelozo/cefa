import 'dart:typed_data';

Future<void> deliverPdfExport(Uint8List bytes, String filename) {
  throw UnsupportedError('Exportação de PDF não suportada nesta plataforma');
}

Future<void> deliverPdfPreview(Uint8List bytes, String filename) {
  throw UnsupportedError('Visualização de PDF não suportada nesta plataforma');
}
