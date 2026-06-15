import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cancelamento_matricula.dart';
import 'pdf_fonts.dart';
import 'pdf_page_number.dart';
import 'resposta_display.dart';
import 'submissao_pdf_delivery.dart';

/// Nome exibido no rodapé do relatório (nome completo; senão login).
String nomeGeradorRelatorio({String? nome, String? nomeUsuario}) {
  final completo = nome?.trim();
  if (completo != null && completo.isNotEmpty) return completo;
  final login = nomeUsuario?.trim();
  if (login != null && login.isNotEmpty) return login;
  return 'Usuário';
}

/// PDF em fluxo: lista de alunos matriculados em uma turma/curso.
abstract final class MatriculadosPdf {
  static final _primaryBlue = PdfColor.fromInt(0xFF1F2A8A);
  static final _neutralGray = PdfColor.fromInt(0xFF6B7280);
  static final _headerBg = PdfColor.fromInt(0xFFE8EAF6);
  static final _border = PdfColor.fromInt(0xFFD1D5DB);

  static const _fontTitulo = 16.0;
  static const _fontSubtitulo = 11.0;
  static const _fontCorpo = 9.0;
  static const _fontCabecalhoTabela = 8.5;

  static Future<void> exportar(
    CancelamentoMatriculaResult dados, {
    required String geradoPor,
  }) async {
    final bytes = await _buildBytes(dados, geradoPor: geradoPor);
    await entregarPdfExportacao(bytes, _nomeArquivo(dados));
  }

  static Future<void> visualizar(
    CancelamentoMatriculaResult dados, {
    required String geradoPor,
  }) async {
    final bytes = await _buildBytes(dados, geradoPor: geradoPor);
    await entregarPdfVisualizacao(bytes, _nomeArquivo(dados));
  }

  static String _nomeArquivo(CancelamentoMatriculaResult dados) {
    final curso = dados.cursoDescricao
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final turma = dados.turmaCodigo.toString();
    return 'cefa_matriculados_${curso.isEmpty ? 'curso' : curso}_turma_$turma.pdf';
  }

  static Future<Uint8List> _buildBytes(
    CancelamentoMatriculaResult dados, {
    required String geradoPor,
  }) async {
    await PdfFonts.ensureInitialized();

    final pdf = pw.Document(
      title: 'Alunos matriculados — ${dados.cursoDescricao}',
      author: 'Cefa',
      theme: PdfFonts.theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: PdfFonts.theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        maxPages: 200,
        header: PdfPageNumber.headerSuperiorDireito,
        build: (context) => _buildWidgets(dados, geradoPor: geradoPor),
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildWidgets(
    CancelamentoMatriculaResult dados, {
    required String geradoPor,
  }) {
    final periodo = dados.periodoRotulo ?? dados.periodo;
    final matriculados = [...dados.matriculados]
      ..sort((a, b) => a.alunoNome.compareTo(b.alunoNome));

    return [
      pw.Text(
        'Alunos matriculados',
        style: PdfFonts.textStyle(
          fontSize: _fontTitulo,
          fontWeight: pw.FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
      pw.SizedBox(height: 10),
      _linhaInfo('Curso', dados.cursoDescricao),
      pw.SizedBox(height: 4),
      _linhaInfo('Turma', '${dados.turmaCodigo} — ${dados.turmaNome}'),
      pw.SizedBox(height: 4),
      _linhaInfo('Período', periodo),
      pw.SizedBox(height: 4),
      _linhaInfo('Total matriculados', dados.totalMatriculados.toString()),
      pw.SizedBox(height: 14),
      if (matriculados.isEmpty)
        pw.Text(
          'Nenhum aluno matriculado ativo nesta turma.',
          style: PdfFonts.textStyle(fontSize: _fontSubtitulo, color: _neutralGray),
        )
      else
        _tabelaMatriculados(matriculados),
      pw.SizedBox(height: 12),
      pw.Divider(color: _neutralGray),
      pw.SizedBox(height: 6),
      pw.Text(
        'Documento gerado por $geradoPor em ${formatSubmissaoData(DateTime.now())}',
        style: PdfFonts.textStyle(fontSize: 8, color: _neutralGray),
      ),
    ];
  }

  static pw.Widget _linhaInfo(String rotulo, String valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            rotulo,
            style: PdfFonts.textStyle(
              fontSize: _fontCorpo,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            valor,
            style: PdfFonts.textStyle(fontSize: _fontCorpo),
          ),
        ),
      ],
    );
  }

  static pw.Widget _tabelaMatriculados(List<CancelamentoMatriculaAluno> linhas) {
    const colunas = [
      'Nº',
      'Nome',
      'Idade',
      'Data matrícula',
      'CPF',
      'Escolaridade',
    ];

    final flex = <int>[1, 5, 1, 3, 3, 4];

    pw.Widget cell(
      String texto, {
      bool header = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          texto,
          textAlign: align,
          style: PdfFonts.textStyle(
            fontSize: header ? _fontCabecalhoTabela : _fontCorpo,
            fontWeight: header ? pw.FontWeight.bold : null,
            color: header ? _primaryBlue : null,
          ),
        ),
      );
    }

    final headerRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: _headerBg),
      children: [
        for (var i = 0; i < colunas.length; i++)
          cell(colunas[i], header: true, align: i == 0 ? pw.TextAlign.center : pw.TextAlign.left),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (var i = 0; i < linhas.length; i++) {
      final a = linhas[i];
      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _border, width: 0.5),
            ),
          ),
          children: [
            cell('${i + 1}', align: pw.TextAlign.center),
            cell(a.alunoNome),
            cell(a.alunoIdade != null ? '${a.alunoIdade}' : '—', align: pw.TextAlign.center),
            cell(a.dataMatricula ?? '—'),
            cell(a.alunoCpfFormatado ?? a.alunoCpf ?? '—'),
            cell(a.escolaridadeDescricao ?? '—'),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        for (var i = 0; i < flex.length; i++) i: pw.FlexColumnWidth(flex[i].toDouble()),
      },
      children: [headerRow, ...dataRows],
    );
  }
}
