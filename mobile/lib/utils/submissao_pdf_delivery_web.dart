import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> deliverPdfExport(Uint8List bytes, String filename) async {
  _download(bytes, filename);
}

Future<void> deliverPdfPreview(Uint8List bytes, String filename) async {
  _openInNewTab(bytes);
}

void _download(Uint8List bytes, String filename) {
  final url = _createObjectUrl(bytes);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

void _openInNewTab(Uint8List bytes) {
  final url = _createObjectUrl(bytes);
  web.window.open(url, '_blank');
}

String _createObjectUrl(Uint8List bytes) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  return web.URL.createObjectURL(blob);
}
