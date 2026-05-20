class EntrevistaProgramasSociais {
  const EntrevistaProgramasSociais({
    this.bolsaFamilia = false,
    this.peti = false,
    this.bpc = false,
    this.outrosProgramas = false,
    this.outrosProgramasSociais,
    this.cras = false,
    this.centroPop = false,
    this.conselhoTutelar = false,
    this.ubs = false,
    this.creas = false,
    this.caps = false,
    this.craf = false,
    this.outrosAtendimentoFamilia = false,
    this.outrosOrgaosSociais,
  });

  final bool bolsaFamilia;
  final bool peti;
  final bool bpc;
  final bool outrosProgramas;
  final String? outrosProgramasSociais;
  final bool cras;
  final bool centroPop;
  final bool conselhoTutelar;
  final bool ubs;
  final bool creas;
  final bool caps;
  final bool craf;
  final bool outrosAtendimentoFamilia;
  final String? outrosOrgaosSociais;

  factory EntrevistaProgramasSociais.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EntrevistaProgramasSociais();
    return EntrevistaProgramasSociais(
      bolsaFamilia: _asBool(json['bolsaFamilia']),
      peti: _asBool(json['peti']),
      bpc: _asBool(json['bpc']),
      outrosProgramas: _asBool(json['outrosProgramas']),
      outrosProgramasSociais: json['outrosProgramasSociais'] as String?,
      cras: _asBool(json['cras']),
      centroPop: _asBool(json['centroPop']),
      conselhoTutelar: _asBool(json['conselhoTutelar']),
      ubs: _asBool(json['ubs']),
      creas: _asBool(json['creas']),
      caps: _asBool(json['caps']),
      craf: _asBool(json['craf']),
      outrosAtendimentoFamilia: _asBool(json['outrosAtendimentoFamilia']),
      outrosOrgaosSociais: json['outrosOrgaosSociais'] as String?,
    );
  }

  /// Aceita bool nativo ou 0/1 vindos de serialização legada.
  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  Map<String, dynamic> toJson() => {
        'bolsaFamilia': bolsaFamilia,
        'peti': peti,
        'bpc': bpc,
        'outrosProgramas': outrosProgramas,
        if (outrosProgramas &&
            outrosProgramasSociais != null &&
            outrosProgramasSociais!.trim().isNotEmpty)
          'outrosProgramasSociais': outrosProgramasSociais!.trim(),
        'cras': cras,
        'centroPop': centroPop,
        'conselhoTutelar': conselhoTutelar,
        'ubs': ubs,
        'creas': creas,
        'caps': caps,
        'craf': craf,
        'outrosAtendimentoFamilia': outrosAtendimentoFamilia,
        if (outrosAtendimentoFamilia &&
            outrosOrgaosSociais != null &&
            outrosOrgaosSociais!.trim().isNotEmpty)
          'outrosOrgaosSociais': outrosOrgaosSociais!.trim(),
      };
}
