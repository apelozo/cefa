import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_fonts.dart';

/// Numeração de páginas nos relatórios PDF do Cefa.
abstract final class PdfPageNumber {
  static final _cor = PdfColor.fromInt(0xFF6B7280);

  /// Cabeçalho do [pw.MultiPage]: canto superior direito.
  static pw.Widget headerSuperiorDireito(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.topRight,
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        rotulo(context.pageNumber),
        style: PdfFonts.textStyle(fontSize: 9, color: _cor),
      ),
    );
  }

  /// Sobreposição em [pw.Page] / [pw.Stack] (ex.: entrevista com fundo).
  static pw.Widget overlaySuperiorDireito(
    pw.Context context, {
    double top = 16,
    double right = 20,
  }) {
    return pw.Positioned(
      top: top,
      right: right,
      child: pw.Text(
        rotulo(context.pageNumber),
        style: PdfFonts.textStyle(fontSize: 9, color: _cor),
      ),
    );
  }

  static String rotulo(int pagina) => 'Pág. $pagina';
}
