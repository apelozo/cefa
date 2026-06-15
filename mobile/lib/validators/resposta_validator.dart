import '../constants/campo_texto.dart';
import '../models/pergunta.dart';
import '../models/tipo_campo.dart';
import '../utils/data_br_formatter.dart';

const maxInteiro = 999999999;
const minInteiro = -999999999;

String? validateInteiroOpcional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return validateInteiro(value);
}

String? validateInteiro(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe um número inteiro';
  final n = int.tryParse(value.trim());
  if (n == null) return 'Número inteiro inválido';
  if (n < minInteiro || n > maxInteiro) {
    return 'Máximo de 9 dígitos';
  }
  return null;
}

String? validateDecimalOpcional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return validateDecimal(value);
}

String? validateDecimal(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe um decimal';
  final normalized = value.trim().replaceAll(',', '.');
  if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(normalized)) {
    return 'Decimal inválido';
  }
  return null;
}

String? validateTextoOpcional(String? value, int maxLength) {
  if (value == null || value.trim().isEmpty) return null;
  return validateTexto(value, maxLength);
}

String? validateTexto(String? value, int maxLength) {
  if (value == null || value.trim().isEmpty) return 'Informe um texto';
  if (value.length > maxLength) {
    return 'Máximo de $maxLength caracteres';
  }
  return null;
}

String? validateLogicoOpcional(bool? value) => null;

String? validateLogico(bool? value) {
  if (value == null) return 'Selecione Sim ou Não';
  return null;
}

String? validateRespostaForPergunta(Pergunta pergunta, dynamic value) {
  switch (pergunta.tipoCampo) {
    case TipoCampo.inteiro:
      return validateInteiro(value as String?);
    case TipoCampo.decimal:
      return validateDecimal(value as String?);
    case TipoCampo.texto:
      return validateTexto(
        value as String?,
        pergunta.tamanhoCampo ?? CampoTextoLimites.defaultTamanho,
      );
    case TipoCampo.logico:
      return validateLogico(value as bool?);
    case TipoCampo.data:
      return validateDataBr(value as String?);
    case TipoCampo.lista:
      return validateLista(value as String?);
  }
}

String? validateListaOpcional(String? opcaoId) {
  if (opcaoId == null || opcaoId.isEmpty) return null;
  return validateLista(opcaoId);
}

String? validateLista(String? opcaoId) {
  if (opcaoId == null || opcaoId.isEmpty) {
    return 'Selecione uma opção';
  }
  return null;
}
