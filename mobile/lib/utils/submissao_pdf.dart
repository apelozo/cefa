import 'dart:typed_data';



import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import '../models/submissao.dart';

import '../models/tipo_campo.dart';

import 'pdf_fonts.dart';

import 'pdf_page_number.dart';

import 'resposta_display.dart';

import 'submissao_pdf_delivery.dart';



/// Gera PDF das respostas de uma submissão (visualizar, imprimir ou salvar).

abstract final class SubmissaoPdf {

  static final _primaryBlue = PdfColor.fromInt(0xFF1F2A8A);

  static final _neutralGray = PdfColor.fromInt(0xFF6B7280);



  static const _fontPergunta = 10.0;

  static const _fontResposta = 10.0;

  static const _espacoEntrePerguntas = 10.0;



  static Future<void> exportar(Submissao submissao) async {

    final bytes = await _buildBytes(submissao);

    final nomeArquivo = _nomeArquivo(submissao);

    await entregarPdfExportacao(bytes, nomeArquivo);

  }



  static Future<void> visualizar(Submissao submissao) async {

    final bytes = await _buildBytes(submissao);

    await entregarPdfVisualizacao(bytes, _nomeArquivo(submissao));

  }



  static String _nomeArquivo(Submissao s) {

    final tipo = s.tipoFormularioNome

        .toLowerCase()

        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')

        .replaceAll(RegExp(r'^_|_$'), '');

    final idCurto = s.id.length >= 8 ? s.id.substring(0, 8) : s.id;

    return 'cefa_${tipo.isEmpty ? 'formulario' : tipo}_$idCurto.pdf';

  }



  static Future<Uint8List> _buildBytes(Submissao submissao) async {

    await PdfFonts.ensureInitialized();

    final respostas = [...submissao.respostas]

      ..sort((a, b) => a.perguntaOrdem.compareTo(b.perguntaOrdem));



    final pdf = pw.Document(

      title: 'Respostas - ${submissao.tipoFormularioNome}',

      author: 'Cefa',

      theme: PdfFonts.theme,

    );



    pdf.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        theme: PdfFonts.theme,

        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),

        maxPages: 200,

        header: PdfPageNumber.headerSuperiorDireito,

        build: (context) => _buildWidgets(submissao, respostas),

      ),

    );



    return pdf.save();

  }



  /// Lista plana de widgets (sem [Column] por resposta) para o [MultiPage]

  /// paginar corretamente. [pw.Text] com [TextOverflow.span] quebra entre páginas.

  static List<pw.Widget> _buildWidgets(

    Submissao submissao,

    List<RespostaSubmissao> respostas,

  ) {

    final widgets = <pw.Widget>[

      _buildCabecalho(submissao),

      pw.SizedBox(height: 10),

      _linhaInfo('Pessoa', submissao.pessoaNome),

      pw.SizedBox(height: 4),

      _linhaInfo('CPF', submissao.pessoaCpfFormatado),

      pw.SizedBox(height: 4),

      _linhaInfo('Enviado em', formatSubmissaoData(submissao.createdAt)),

      pw.SizedBox(height: 14),

      pw.Text(

        'Respostas',

        style: PdfFonts.textStyle(

          fontSize: 12,

          fontWeight: pw.FontWeight.bold,

          color: _primaryBlue,

        ),

      ),

      pw.SizedBox(height: 8),

    ];



    for (final r in respostas) {

      widgets.addAll(_widgetsResposta(r));

    }



    widgets.addAll([

      pw.SizedBox(height: 10),

      pw.Divider(color: _neutralGray),

      pw.SizedBox(height: 8),

      pw.Text(

        'Documento gerado pelo Cefa em ${formatSubmissaoData(DateTime.now())}',

        style: PdfFonts.textStyle(fontSize: 9, color: _neutralGray),

      ),

    ]);



    return widgets;

  }



  static pw.Widget _buildCabecalho(Submissao s) {

    return pw.Text(

      s.tipoFormularioNome,

      style: PdfFonts.textStyle(

        fontSize: 16,

        fontWeight: pw.FontWeight.bold,

        color: _primaryBlue,

      ),

    );

  }



  static pw.Widget _linhaInfo(String rotulo, String valor) {

    return pw.Row(

      crossAxisAlignment: pw.CrossAxisAlignment.start,

      children: [

        pw.SizedBox(

          width: 90,

          child: pw.Text(

            rotulo,

            style: PdfFonts.textStyle(

              fontSize: 10,

              fontWeight: pw.FontWeight.bold,

              color: _primaryBlue,

            ),

          ),

        ),

        pw.Expanded(

          child: pw.Text(

            valor,

            style: PdfFonts.textStyle(fontSize: 10),

            overflow: pw.TextOverflow.span,

          ),

        ),

      ],

    );

  }



  static String _valorUmaLinha(String valor) {

    final limpo = valor.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

    if (limpo.isEmpty) return '-';

    return limpo;

  }



  static List<pw.Widget> _widgetsResposta(RespostaSubmissao r) {

    final valorBruto = formatRespostaSubmissao(r);

    final exibir = valorBruto.isEmpty ? '-' : valorBruto;

    final textoLongo = r.tipoCampo == TipoCampo.texto;

    final valor = textoLongo ? exibir : _valorUmaLinha(exibir);



    return [

      pw.Text(

        r.perguntaEnunciado,

        style: PdfFonts.textStyle(

          fontSize: _fontPergunta,

          fontWeight: pw.FontWeight.bold,

          color: _primaryBlue,

        ),

        overflow: pw.TextOverflow.span,

      ),

      pw.Text(

        valor,

        style: PdfFonts.textStyle(fontSize: _fontResposta),

        maxLines: textoLongo ? null : 1,

        overflow:

            textoLongo ? pw.TextOverflow.span : pw.TextOverflow.clip,

      ),

      pw.SizedBox(height: _espacoEntrePerguntas),

    ];

  }

}


