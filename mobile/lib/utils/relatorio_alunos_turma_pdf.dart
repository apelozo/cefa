import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/relatorio_alunos_turma.dart';
import '../models/relatorio_alunos_turma.dart';
import 'pdf_fonts.dart';
import 'pdf_page_number.dart';
import 'resposta_display.dart';
import 'submissao_pdf_delivery.dart';

abstract final class RelatorioAlunosTurmaPdf {
  static final _primaryBlue = PdfColor.fromInt(0xFF1F2A8A);
  static final _neutralGray = PdfColor.fromInt(0xFF6B7280);
  static final _headerBg = PdfColor.fromInt(0xFFE8EAF6);
  static final _border = PdfColor.fromInt(0xFFD1D5DB);

  static const _fontTitulo = 15.0;
  static const _fontSubtitulo = 10.0;
  static const _fontCorpo = 7.5;
  static const _fontCabecalhoTabela = 7.0;

  static Future<void> exportar(
    RelatorioAlunosTurmaResult dados, {
    required String tipoRelatorio,
    required String geradoPor,
  }) async {
    final bytes = await _buildBytes(
      dados,
      tipoRelatorio: tipoRelatorio,
      geradoPor: geradoPor,
    );
    await entregarPdfExportacao(bytes, _nomeArquivo(tipoRelatorio));
  }

  static Future<void> visualizar(
    RelatorioAlunosTurmaResult dados, {
    required String tipoRelatorio,
    required String geradoPor,
  }) async {
    final bytes = await _buildBytes(
      dados,
      tipoRelatorio: tipoRelatorio,
      geradoPor: geradoPor,
    );
    await entregarPdfVisualizacao(bytes, _nomeArquivo(tipoRelatorio));
  }

  static String _nomeArquivo(String tipoRelatorio) {
    final sufixo =
        tipoRelatorio == TipoRelatorioAlunosTurma.detalhado
            ? 'detalhado'
            : 'resumido';
    return 'cefa_relatorio_alunos_turma_$sufixo.pdf';
  }

  static Future<Uint8List> _buildBytes(
    RelatorioAlunosTurmaResult dados, {
    required String tipoRelatorio,
    required String geradoPor,
  }) async {
    await PdfFonts.ensureInitialized();

    final detalhado = tipoRelatorio == TipoRelatorioAlunosTurma.detalhado;
    final pageFormat =
        detalhado
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4;

    final pdf = pw.Document(
      title: 'Relatório de alunos da turma',
      author: 'Cefa',
      theme: PdfFonts.theme,
    );

    for (final secao in dados.secoes) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          theme: PdfFonts.theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          maxPages: 500,
          header: PdfPageNumber.headerSuperiorDireito,
          build:
              (context) => _buildSecaoWidgets(
                secao,
                detalhado: detalhado,
              ),
        ),
      );
    }

    if (dados.resumoGeral.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: PdfFonts.theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          maxPages: 100,
          header: PdfPageNumber.headerSuperiorDireito,
          build:
              (context) => _buildResumoGeralWidgets(
                dados,
                geradoPor: geradoPor,
              ),
        ),
      );
    } else if (dados.secoes.isEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: PdfFonts.theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          maxPages: 10,
          header: PdfPageNumber.headerSuperiorDireito,
          build:
              (context) => [
                pw.Text(
                  'Relatório de alunos da turma',
                  style: PdfFonts.textStyle(
                    fontSize: _fontTitulo,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Nenhuma turma ou aluno encontrado para os filtros selecionados.',
                  style: PdfFonts.textStyle(
                    fontSize: _fontSubtitulo,
                    color: _neutralGray,
                  ),
                ),
                pw.SizedBox(height: 12),
                _rodape(geradoPor),
              ],
        ),
      );
    }

    return pdf.save();
  }

  static List<pw.Widget> _buildSecaoWidgets(
    RelatorioAlunosTurmaSecao secao, {
    required bool detalhado,
  }) {
    final periodo = secao.periodoRotulo ?? secao.periodo;
    final situacaoTurma =
        secao.situacaoTurmaRotulo ?? secao.situacaoTurma;
    final turmaRotulo = '${secao.turmaCodigo} — ${secao.turmaNome}';

    final cabecalho =
        detalhado
            ? [
              pw.Center(
                child: pw.Text(
                  'Relatório Detalhado de Alunos da Turma',
                  textAlign: pw.TextAlign.center,
                  style: PdfFonts.textStyle(
                    fontSize: _fontTitulo,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              _linhaDuplaEsquerda(
                esquerda: 'Curso: ${secao.cursoDescricao}',
                direita: 'Turma: $turmaRotulo',
              ),
              pw.SizedBox(height: 3),
              _linhaDuplaEsquerda(
                esquerda: 'Período: $periodo',
                direita: 'Situação da turma: $situacaoTurma',
              ),
            ]
            : [
              pw.Text(
                'Relatório de alunos da turma',
                style: PdfFonts.textStyle(
                  fontSize: _fontTitulo,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryBlue,
                ),
              ),
              pw.SizedBox(height: 8),
              _linhaInfo('Curso', secao.cursoDescricao),
              pw.SizedBox(height: 3),
              _linhaInfo('Turma', turmaRotulo),
              pw.SizedBox(height: 3),
              _linhaInfo('Período', periodo),
              pw.SizedBox(height: 3),
              _linhaInfo('Situação da turma', situacaoTurma),
            ];

    return [
      ...cabecalho,
      pw.SizedBox(height: 10),
      if (secao.alunos.isEmpty)
        pw.Text(
          'Nenhum aluno encontrado para os filtros selecionados.',
          style: PdfFonts.textStyle(fontSize: _fontSubtitulo, color: _neutralGray),
        )
      else if (detalhado)
        _tabelaDetalhada(secao.alunos)
      else
        _tabelaResumida(secao.alunos),
    ];
  }

  static List<pw.Widget> _buildResumoGeralWidgets(
    RelatorioAlunosTurmaResult dados, {
    required String geradoPor,
  }) {
    final tituloResumo =
        dados.todosCursos || dados.todasTurmas || dados.secoes.length > 1
            ? 'Resumo geral por turma'
            : 'Resumo da turma';

    return [
      pw.Text(
        tituloResumo,
        style: PdfFonts.textStyle(
          fontSize: _fontTitulo,
          fontWeight: pw.FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
      pw.SizedBox(height: 10),
      _tabelaResumoGeral(dados.resumoGeral),
      pw.SizedBox(height: 12),
      _rodape(geradoPor),
    ];
  }

  static pw.Widget _rodape(String geradoPor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _neutralGray),
        pw.SizedBox(height: 6),
        pw.Text(
          'Documento gerado por $geradoPor em ${formatSubmissaoData(DateTime.now())}',
          style: PdfFonts.textStyle(fontSize: 8, color: _neutralGray),
        ),
      ],
    );
  }

  static pw.Widget _linhaDuplaEsquerda({
    required String esquerda,
    required String direita,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            esquerda,
            style: PdfFonts.textStyle(
              fontSize: _fontSubtitulo,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            direita,
            style: PdfFonts.textStyle(
              fontSize: _fontSubtitulo,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _linhaInfo(String rotulo, String valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            rotulo,
            style: PdfFonts.textStyle(
              fontSize: _fontSubtitulo,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            valor,
            style: PdfFonts.textStyle(fontSize: _fontSubtitulo),
          ),
        ),
      ],
    );
  }

  static pw.Widget _tabelaDetalhada(List<RelatorioAlunosTurmaAluno> linhas) {
    const colunas = [
      'Nome do Aluno',
      'CPF',
      'Idade',
      'Escolaridade',
      'Data Insc.',
      'Data Matr.',
      'Data Canc.',
      'Situação',
      'Nro Atend.',
    ];
    const flex = [4, 2, 1, 2, 2, 2, 2, 2, 1];

    return _tabela(
      colunas: colunas,
      flex: flex,
      linhas:
          linhas
              .map(
                (a) => [
                  a.alunoNome,
                  a.alunoCpfFormatado ?? a.alunoCpf ?? '—',
                  a.alunoIdade != null ? '${a.alunoIdade}' : '—',
                  a.escolaridadeDescricao ?? '—',
                  a.dataInscricao,
                  a.dataMatricula ?? '—',
                  a.dataCancelamento ?? '—',
                  a.situacao,
                  '${a.quantidadeAtendimentos}',
                ],
              )
              .toList(),
    );
  }

  static pw.Widget _tabelaResumida(List<RelatorioAlunosTurmaAluno> linhas) {
    const colunas = [
      'Nome do Aluno',
      'CPF',
      'Dt Ult. Situação',
      'situação',
    ];
    const flex = [5, 3, 2, 3];

    return _tabela(
      colunas: colunas,
      flex: flex,
      linhas:
          linhas
              .map(
                (a) => [
                  a.alunoNome,
                  a.alunoCpfFormatado ?? a.alunoCpf ?? '—',
                  a.dataUltSituacao,
                  a.situacao,
                ],
              )
              .toList(),
    );
  }

  static pw.Widget _tabelaResumoGeral(
    List<RelatorioAlunosTurmaResumoGeral> linhas,
  ) {
    final temAberta = linhas.any((l) => l.situacaoTurma == 'ABERTA');
    final colunas = <String>[
      'Curso',
      'Turma',
      'Período',
      'Matriculados',
      'Matr. canceladas',
      if (temAberta) 'A matricular',
    ];
    final flex = <int>[
      4,
      3,
      2,
      2,
      2,
      if (temAberta) 2,
    ];

    return _tabela(
      colunas: colunas,
      flex: flex,
      linhas:
          linhas
              .map((r) {
                final row = <String>[
                  r.cursoDescricao,
                  '${r.turmaCodigo} — ${r.turmaNome}',
                  r.periodoRotulo ?? '—',
                  '${r.matriculados}',
                  '${r.matriculasCanceladas}',
                ];
                if (temAberta) {
                  row.add(
                    r.situacaoTurma == 'ABERTA'
                        ? '${r.aMatricular ?? 0}'
                        : '—',
                  );
                }
                return row;
              })
              .toList(),
    );
  }

  static pw.Widget _tabela({
    required List<String> colunas,
    required List<int> flex,
    required List<List<String>> linhas,
  }) {
    pw.Widget cell(
      String texto, {
      bool header = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(
          horizontal: header ? 2 : 3,
          vertical: 4,
        ),
        child: pw.Text(
          texto,
          textAlign: align,
          maxLines: header ? 2 : 1,
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
          cell(colunas[i], header: true),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (final linha in linhas) {
      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _border, width: 0.5),
            ),
          ),
          children: [for (final valor in linha) cell(valor)],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        for (var i = 0; i < flex.length; i++)
          i: pw.FlexColumnWidth(flex[i].toDouble()),
      },
      children: [headerRow, ...dataRows],
    );
  }
}
