/// Dia da semana (valores da API / enum Prisma).
abstract final class DiaSemana {
  static const domingo = 'DOMINGO';
  static const segundaFeira = 'SEGUNDA_FEIRA';
  static const tercaFeira = 'TERCA_FEIRA';
  static const quartaFeira = 'QUARTA_FEIRA';
  static const quintaFeira = 'QUINTA_FEIRA';
  static const sextaFeira = 'SEXTA_FEIRA';
  static const sabado = 'SABADO';

  static const opcoes = <String, String>{
    domingo: 'Domingo',
    segundaFeira: 'Segunda-feira',
    tercaFeira: 'Terça-feira',
    quartaFeira: 'Quarta-feira',
    quintaFeira: 'Quinta-feira',
    sextaFeira: 'Sexta-feira',
    sabado: 'Sábado',
  };

  static String? rotulo(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    return opcoes[valor];
  }
}
