import '../constants/resposta_sim_nao.dart';

class EntrevistaSaudeFamilia {
  const EntrevistaSaudeFamilia({
    this.remediosControladosMental,
    this.remediosControladosQuais,
    this.usoAbusivoAlcool,
    this.usoAbusivoDrogas,
    this.usoAbusivoDrogasQuais,
    this.temGestante,
  });

  final String? remediosControladosMental;
  final String? remediosControladosQuais;
  final String? usoAbusivoAlcool;
  final String? usoAbusivoDrogas;
  final String? usoAbusivoDrogasQuais;
  final String? temGestante;

  factory EntrevistaSaudeFamilia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EntrevistaSaudeFamilia();
    return EntrevistaSaudeFamilia(
      remediosControladosMental: json['remediosControladosMental'] as String?,
      remediosControladosQuais: json['remediosControladosQuais'] as String?,
      usoAbusivoAlcool: json['usoAbusivoAlcool'] as String?,
      usoAbusivoDrogas: json['usoAbusivoDrogas'] as String?,
      usoAbusivoDrogasQuais: json['usoAbusivoDrogasQuais'] as String?,
      temGestante: json['temGestante'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (remediosControladosMental != null)
          'remediosControladosMental': remediosControladosMental,
        if (remediosControladosQuais != null &&
            remediosControladosQuais!.trim().isNotEmpty)
          'remediosControladosQuais': remediosControladosQuais!.trim(),
        if (usoAbusivoAlcool != null) 'usoAbusivoAlcool': usoAbusivoAlcool,
        if (usoAbusivoDrogas != null) 'usoAbusivoDrogas': usoAbusivoDrogas,
        if (usoAbusivoDrogasQuais != null &&
            usoAbusivoDrogasQuais!.trim().isNotEmpty)
          'usoAbusivoDrogasQuais': usoAbusivoDrogasQuais!.trim(),
        if (temGestante != null) 'temGestante': temGestante,
      };

  RespostaSimNao? get remediosMentalEnum =>
      RespostaSimNao.fromApi(remediosControladosMental);
  RespostaSimNao? get alcoolEnum => RespostaSimNao.fromApi(usoAbusivoAlcool);
  RespostaSimNao? get drogasEnum => RespostaSimNao.fromApi(usoAbusivoDrogas);
  RespostaSimNao? get gestanteEnum => RespostaSimNao.fromApi(temGestante);
}
