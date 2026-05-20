import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/campo_texto.dart';
import '../../models/pergunta.dart';
import '../../models/tipo_campo.dart';
import '../../theme/app_theme.dart';
import '../../utils/data_br_formatter.dart';
import '../../validators/resposta_validator.dart';

class CampoInput extends StatelessWidget {
  const CampoInput({
    super.key,
    required this.pergunta,
    this.textController,
    this.logicoValue,
    this.onLogicoChanged,
    this.listaValue,
    this.onListaChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.respostaOpcional = false,
  });

  final Pergunta pergunta;
  final bool respostaOpcional;
  final TextEditingController? textController;
  final bool? logicoValue;
  final ValueChanged<bool?>? onLogicoChanged;
  final String? listaValue;
  final ValueChanged<String?>? onListaChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  bool get _chainEnter => onFieldSubmitted != null && focusNode != null;

  VoidCallback? get _advance => _chainEnter ? () => onFieldSubmitted!('') : null;

  Widget _wrapEnterFocus(Widget field, {required bool multiline}) {
    if (!_chainEnter || multiline) return field;
    final node = focusNode!;
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter) {
          return KeyEventResult.ignored;
        }
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored;
        }
        if (!node.hasFocus) return KeyEventResult.ignored;
        onFieldSubmitted!('');
        return KeyEventResult.handled;
      },
      child: field,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (pergunta.tipoCampo) {
      case TipoCampo.inteiro:
        return _wrapEnterFocus(
          TextFormField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onEditingComplete: _advance,
          decoration: const InputDecoration(
            labelText: 'Número inteiro',
            hintText: 'Até 9 dígitos',
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
            LengthLimitingTextInputFormatter(10),
          ],
          validator:
              respostaOpcional ? validateInteiroOpcional : validateInteiro,
        ),
          multiline: false,
        );
      case TipoCampo.decimal:
        return _wrapEnterFocus(
          TextFormField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onEditingComplete: _advance,
          decoration: const InputDecoration(
            labelText: 'Número decimal',
            hintText: 'Ex.: 12,50',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?[\d.,]*')),
          ],
          validator:
              respostaOpcional ? validateDecimalOpcional : validateDecimal,
        ),
          multiline: false,
        );
      case TipoCampo.texto:
        final maxChars =
            pergunta.tamanhoCampo ?? CampoTextoLimites.defaultTamanho;
        final linhas =
            pergunta.linhasCampo ?? CampoTextoLimites.defaultLinhas;
        final multiline = linhas > 1;
        return _wrapEnterFocus(
          TextFormField(
            controller: textController,
            focusNode: focusNode,
            textInputAction:
                multiline ? TextInputAction.newline : textInputAction,
            onFieldSubmitted: multiline ? null : onFieldSubmitted,
            onEditingComplete: multiline ? null : _advance,
            decoration: InputDecoration(
              labelText: 'Texto',
              counterText: '',
              helperText: 'Máx. $maxChars caracteres',
            ),
            maxLength: maxChars,
            minLines: linhas,
            maxLines: linhas,
            validator: (v) => respostaOpcional
                ? validateTextoOpcional(v, maxChars)
                : validateTexto(v, maxChars),
          ),
          multiline: multiline,
        );
      case TipoCampo.logico:
        return FormField<bool>(
          initialValue: logicoValue,
          validator: (_) => respostaOpcional
              ? validateLogicoOpcional(logicoValue)
              : validateLogico(logicoValue),
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Sim')),
                  ButtonSegment(value: false, label: Text('Não')),
                ],
                emptySelectionAllowed: true,
                selected: logicoValue != null ? {logicoValue!} : {},
                onSelectionChanged: (selected) {
                  if (selected.isEmpty) return;
                  onLogicoChanged?.call(selected.first);
                  state.didChange(selected.first);
                },
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      case TipoCampo.lista:
        final opcoes = pergunta.opcoesAtivas;
        return DropdownButtonFormField<String>(
          key: ValueKey('lista_${pergunta.id}_$listaValue'),
          initialValue: listaValue != null &&
                  opcoes.any((o) => o.id == listaValue)
              ? listaValue
              : null,
          decoration: const InputDecoration(labelText: 'Selecione uma opção'),
          items: opcoes
              .map(
                (o) => DropdownMenuItem(
                  value: o.id,
                  child: Text(o.rotulo),
                ),
              )
              .toList(),
          onChanged: onListaChanged,
          validator: (_) => respostaOpcional
              ? validateListaOpcional(listaValue)
              : validateLista(listaValue),
        );
      case TipoCampo.data:
        return _wrapEnterFocus(
          TextFormField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onEditingComplete: _advance,
          decoration: const InputDecoration(
            labelText: 'Data',
            hintText: 'dd/mm/aa',
            helperText: 'Digite só os 2 últimos dígitos do ano (ex.: 20/10/26)',
          ),
          keyboardType: TextInputType.datetime,
          inputFormatters: [DataBrFormatter()],
          validator:
              respostaOpcional ? validateDataBrOpcional : validateDataBr,
        ),
          multiline: false,
        );
    }
  }
}
