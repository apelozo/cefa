import '../constants/tipo_deficiencia_familiar.dart';

class EntrevistaDeficienciaFamiliar {
  const EntrevistaDeficienciaFamiliar({
    this.id,
    required this.nome,
    required this.tipoDeficiencia,
    this.necessitaCuidadosConstantes = false,
    this.quemECuidador,
    this.ordem = 0,
  });

  final String? id;
  final String nome;
  final String tipoDeficiencia;
  final bool necessitaCuidadosConstantes;
  final String? quemECuidador;
  final int ordem;

  factory EntrevistaDeficienciaFamiliar.fromJson(Map<String, dynamic> json) {
    return EntrevistaDeficienciaFamiliar(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      tipoDeficiencia: json['tipoDeficiencia'] as String,
      necessitaCuidadosConstantes:
          json['necessitaCuidadosConstantes'] as bool? ?? false,
      quemECuidador: json['quemECuidador'] as String?,
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'tipoDeficiencia': tipoDeficiencia,
        'necessitaCuidadosConstantes': necessitaCuidadosConstantes,
        if (quemECuidador != null && quemECuidador!.trim().isNotEmpty)
          'quemECuidador': quemECuidador!.trim(),
      };

  TipoDeficienciaFamiliar? get tipoEnum =>
      TipoDeficienciaFamiliar.fromApi(tipoDeficiencia);
}
