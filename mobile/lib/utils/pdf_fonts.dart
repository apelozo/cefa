import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Fontes com suporte a Unicode (pt-BR, travessão, acentos) para relatórios PDF.
///
/// O pacote `pdf` usa Helvetica por padrão, que não desenha "—", "ã", etc.
abstract final class PdfFonts {
  static bool _ready = false;
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    _regular = await PdfGoogleFonts.openSansRegular();
    _bold = await PdfGoogleFonts.openSansBold();
    _ready = true;
  }

  static pw.ThemeData get theme {
    assert(_ready, 'Chame PdfFonts.ensureInitialized() antes de gerar o PDF');
    return pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
      italic: _regular!,
      boldItalic: _bold!,
    );
  }

  static pw.TextStyle textStyle({
    double fontSize = 9,
    PdfColor? color,
    pw.FontWeight? fontWeight,
  }) {
    assert(_ready, 'Chame PdfFonts.ensureInitialized() antes de gerar o PDF');
    final useBold = fontWeight == pw.FontWeight.bold;
    return pw.TextStyle(
      font: useBold ? _bold : _regular,
      fontSize: fontSize,
      color: color ?? PdfColors.black,
      fontWeight: fontWeight,
    );
  }
}
