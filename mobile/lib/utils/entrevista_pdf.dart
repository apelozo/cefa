import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/entrevista_assistido.dart';
import '../models/pessoa.dart';
import 'entrevista_layout_config.dart';
import 'entrevista_pdf_field_resolver.dart';
import 'pdf_fonts.dart';
import 'pdf_page_number.dart';
import 'submissao_pdf_delivery.dart';

/// Gera PDF da entrevista com o assistido (fundo + mapa YAML).
abstract final class EntrevistaPdf {
  static Future<void> exportar(
    EntrevistaAssistido entrevista,
    Pessoa pessoa,
  ) async {
    final bytes = await buildBytes(entrevista, pessoa);
    await entregarPdfExportacao(bytes, _nomeArquivo(entrevista, pessoa));
  }

  static Future<void> visualizar(
    EntrevistaAssistido entrevista,
    Pessoa pessoa,
  ) async {
    final bytes = await buildBytes(entrevista, pessoa);
    await entregarPdfVisualizacao(bytes, _nomeArquivo(entrevista, pessoa));
  }

  static String _nomeArquivo(EntrevistaAssistido e, Pessoa p) {
    final nome = p.nome
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final idCurto = e.id.length >= 8 ? e.id.substring(0, 8) : e.id;
    return 'cefa_entrevista_${nome.isEmpty ? 'assistido' : nome}_$idCurto.pdf';
  }

  static Future<Uint8List> buildBytes(
    EntrevistaAssistido entrevista,
    Pessoa pessoa,
  ) async {
    await PdfFonts.ensureInitialized();
    final config = await EntrevistaLayoutConfig.load();
    final resolver = EntrevistaPdfFieldResolver(
      entrevista: entrevista,
      pessoa: pessoa,
    );

    final pageFormat = PdfPageFormat(
      config.paginaLargura,
      config.paginaAltura,
      marginAll: 0,
    );

    final fundoCache = <int, pw.MemoryImage>{};
    final pdf = pw.Document(
      title: 'Entrevista - ${pessoa.nome}',
      author: 'Cefa',
      theme: PdfFonts.theme,
    );

    for (final pagina in config.paginasOrdenadas) {
      final fundo = await _carregarFundo(
        config.fundosPorPagina[pagina],
        fundoCache,
        pagina,
      );

      final overlays = <pw.Widget>[];
      for (final campo in config.camposDaPagina(pagina)) {
        final widget = _buildCampo(campo, resolver);
        if (widget != null) overlays.add(widget);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: PdfFonts.theme,
          build: (context) {
            return pw.Stack(
              children: [
                if (fundo != null)
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.Image(
                      fundo,
                      width: config.paginaLargura,
                      height: config.paginaAltura,
                      fit: pw.BoxFit.fill,
                    ),
                  ),
                ...overlays,
                PdfPageNumber.overlaySuperiorDireito(context),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget? _buildCampo(
    EntrevistaCampoLayout campo,
    EntrevistaPdfFieldResolver resolver,
  ) {
    if (campo.isMarcador) {
      if (!resolver.isMarcadorAtivo(campo.chave)) return null;
      return pw.Positioned(
        left: campo.x,
        top: campo.y,
        child: pw.Text(
          campo.textoMarcado,
          style: PdfFonts.textStyle(fontSize: campo.tamanhoFonte),
        ),
      );
    }

    final texto = resolver.resolveTexto(campo.chave);
    if (texto == null || texto.isEmpty) return null;

    final display = _truncar(texto, campo.maxLinhas);

    return pw.Positioned(
      left: campo.x,
      top: campo.y,
      child: pw.SizedBox(
        width: campo.largura,
        child: pw.Text(
          display,
          style: PdfFonts.textStyle(fontSize: campo.tamanhoFonte),
          textAlign: _textAlign(campo.alinhamento),
          maxLines: campo.maxLinhas,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  static String _truncar(String texto, int? maxLinhas) {
    if (maxLinhas == null || maxLinhas < 1) return texto;
    final linhas = texto.split('\n');
    if (linhas.length <= maxLinhas) return texto;
    return linhas.take(maxLinhas).join('\n');
  }

  static pw.TextAlign _textAlign(String alinhamento) {
    switch (alinhamento) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  static Future<pw.MemoryImage?> _carregarFundo(
    String? arquivo,
    Map<int, pw.MemoryImage> cache,
    int pagina,
  ) async {
    if (arquivo == null || arquivo.isEmpty) return null;
    if (cache.containsKey(pagina)) return cache[pagina];

    final path = '${EntrevistaLayoutConfig.assetBase}$arquivo';
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();

    pw.MemoryImage? image;
    if (arquivo.toLowerCase().endsWith('.pdf')) {
      await for (final raster in Printing.raster(
        bytes,
        pages: [0],
        dpi: 150,
      )) {
        final png = await raster.toPng();
        image = pw.MemoryImage(png);
        break;
      }
    } else {
      image = pw.MemoryImage(bytes);
    }

    if (image != null) cache[pagina] = image;
    return image;
  }
}
