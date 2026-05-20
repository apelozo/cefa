import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Campo posicionado no molde PDF (YAML em assets/relatorios/).
class EntrevistaCampoLayout {
  const EntrevistaCampoLayout({
    required this.chave,
    required this.pagina,
    required this.x,
    required this.y,
    this.largura,
    this.tamanhoFonte = 9,
    this.tipo = 'texto',
    this.textoMarcado = 'X',
    this.alinhamento = 'left',
    this.maxLinhas,
  });

  final String chave;
  final int pagina;
  final double x;
  final double y;
  final double? largura;
  final double tamanhoFonte;
  final String tipo;
  final String textoMarcado;
  final String alinhamento;
  final int? maxLinhas;

  bool get isMarcador => tipo == 'marcador';
  bool get posicionado => x != 0 || y != 0;
}

class EntrevistaLayoutConfig {
  const EntrevistaLayoutConfig({
    required this.paginaLargura,
    required this.paginaAltura,
    required this.fundosPorPagina,
    required this.campos,
  });

  final double paginaLargura;
  final double paginaAltura;
  final Map<int, String> fundosPorPagina;
  final Map<String, EntrevistaCampoLayout> campos;

  static const assetYaml = 'assets/relatorios/entrevista_assistido_v1.yaml';
  static const assetBase = 'assets/relatorios/';

  static Future<EntrevistaLayoutConfig> load({
    String assetPath = assetYaml,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final doc = loadYaml(raw);
    if (doc is! YamlMap) {
      throw const FormatException('Layout da entrevista: YAML inválido.');
    }

    final paginaLargura = _num(doc['paginaLargura']) ?? 595.28;
    final paginaAltura = _num(doc['paginaAltura']) ?? 842;

    final fundosPorPagina = <int, String>{};
    final fundos = doc['fundos'];
    if (fundos is YamlList) {
      for (final item in fundos) {
        if (item is! YamlMap) continue;
        final pagina = _int(item['pagina']);
        final arquivo = item['arquivo']?.toString();
        if (pagina != null && arquivo != null && arquivo.isNotEmpty) {
          fundosPorPagina[pagina] = arquivo;
        }
      }
    }

    final campos = <String, EntrevistaCampoLayout>{};
    final camposMap = doc['campos'];
    if (camposMap is YamlMap) {
      for (final entry in camposMap.entries) {
        final chave = entry.key.toString();
        final cfg = entry.value;
        if (cfg is! YamlMap) continue;
        final x = _num(cfg['x']) ?? 0;
        final y = _num(cfg['y']) ?? 0;
        campos[chave] = EntrevistaCampoLayout(
          chave: chave,
          pagina: _int(cfg['pagina']) ?? 1,
          x: x,
          y: y,
          largura: _num(cfg['largura']),
          tamanhoFonte: _num(cfg['tamanhoFonte']) ?? 9,
          tipo: cfg['tipo']?.toString() ?? 'texto',
          textoMarcado: cfg['textoMarcado']?.toString() ?? 'X',
          alinhamento: cfg['alinhamento']?.toString() ?? 'left',
          maxLinhas: _int(cfg['maxLinhas']),
        );
      }
    }

    return EntrevistaLayoutConfig(
      paginaLargura: paginaLargura,
      paginaAltura: paginaAltura,
      fundosPorPagina: fundosPorPagina,
      campos: campos,
    );
  }

  List<EntrevistaCampoLayout> camposDaPagina(int pagina) {
    return campos.values
        .where((c) => c.pagina == pagina && c.posicionado)
        .toList();
  }

  Iterable<int> get paginasOrdenadas {
    final pages = fundosPorPagina.keys.toSet();
    // Só inclui páginas com campos já posicionados (x/y ≠ 0), para não gerar folha vazia.
    pages.addAll(
      campos.values.where((c) => c.posicionado).map((c) => c.pagina),
    );
    if (pages.isEmpty) pages.add(1);
    return pages.toList()..sort();
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
