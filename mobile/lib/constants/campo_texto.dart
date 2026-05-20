/// Limites de perguntas e respostas do tipo TEXTO (alinhado ao backend).
abstract final class CampoTextoLimites {
  static const maxTamanho = 5000;
  static const minTamanho = 1;
  static const maxLinhas = 20;
  static const minLinhas = 1;
  static const defaultLinhas = 3;
  static const defaultTamanho = 100;
}
