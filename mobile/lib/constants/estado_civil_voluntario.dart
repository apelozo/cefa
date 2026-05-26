/// Estado civil do voluntário (valores da API / enum Prisma).
abstract final class EstadoCivilVoluntario {
  static const casado = 'CASADO';
  static const divorciado = 'DIVORCIADO';
  static const separado = 'SEPARADO';
  static const solteiro = 'SOLTEIRO';
  static const viuvo = 'VIUVO';

  static const opcoes = <String, String>{
    casado: 'Casado(a)',
    divorciado: 'Divorciado(a)',
    separado: 'Separado(a)',
    solteiro: 'Solteiro(a)',
    viuvo: 'Viúvo(a)',
  };

  static String? rotulo(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    return opcoes[valor];
  }
}
