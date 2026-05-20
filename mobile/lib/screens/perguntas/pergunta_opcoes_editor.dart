import 'package:flutter/material.dart';



import '../../models/pergunta_opcao.dart';

import '../../theme/app_theme.dart';



class PerguntaOpcoesEditor extends StatefulWidget {

  const PerguntaOpcoesEditor({

    super.key,

    required this.initialOpcoes,

    this.focusAfterLast,

  });



  final List<PerguntaOpcao> initialOpcoes;

  final FocusNode? focusAfterLast;



  @override

  State<PerguntaOpcoesEditor> createState() => PerguntaOpcoesEditorState();

}



class PerguntaOpcoesEditorState extends State<PerguntaOpcoesEditor> {

  late List<PerguntaOpcao> _items;

  final List<TextEditingController> _controllers = [];

  final List<FocusNode> _focusNodes = [];



  @override

  void initState() {

    super.initState();

    _initFrom(widget.initialOpcoes);

  }



  void reloadFrom(List<PerguntaOpcao> opcoes) {

    setState(() => _initFrom(opcoes));

  }



  void requestFocusFirst() {

    if (_focusNodes.isNotEmpty) {

      _focusNodes.first.requestFocus();

    }

  }



  void _initFrom(List<PerguntaOpcao> opcoes) {

    for (final c in _controllers) {

      c.dispose();

    }

    for (final n in _focusNodes) {

      n.dispose();

    }

    _controllers.clear();

    _focusNodes.clear();

    _items = List.of(opcoes);

    for (final o in _items) {

      _controllers.add(TextEditingController(text: o.rotulo));

      _focusNodes.add(FocusNode());

    }

    if (_items.isEmpty) {

      _items.add(PerguntaOpcao(rotulo: '', ordem: 0, ativo: true));

      _controllers.add(TextEditingController());

      _focusNodes.add(FocusNode());

    }

  }



  void _onOpcaoSubmitted(int index) {
    final FocusNode? target = index + 1 < _focusNodes.length
        ? _focusNodes[index + 1]
        : widget.focusAfterLast;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }



  @override

  void dispose() {

    for (final c in _controllers) {

      c.dispose();

    }

    for (final n in _focusNodes) {

      n.dispose();

    }

    super.dispose();

  }



  List<PerguntaOpcao> collectOpcoes() {

    final result = <PerguntaOpcao>[];

    for (var i = 0; i < _items.length; i++) {

      result.add(

        _items[i].copyWith(

          rotulo: _controllers[i].text.trim(),

          ordem: i,

        ),

      );

    }

    return result;

  }



  bool validateOpcoes() {

    final opcoes = collectOpcoes();

    final ativas = opcoes.where((o) => o.ativo && o.rotulo.isNotEmpty);

    return ativas.isNotEmpty;

  }



  void _addOpcao() {

    setState(() {

      _items.add(

        PerguntaOpcao(rotulo: '', ordem: _items.length, ativo: true),

      );

      _controllers.add(TextEditingController());

      _focusNodes.add(FocusNode());

    });

  }



  void _setAtivo(int index, bool ativo) {

    setState(() {

      _items[index] = _items[index].copyWith(ativo: ativo);

    });

  }



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          'Opções da lista',

          style: Theme.of(context).textTheme.titleMedium,

        ),

        const SizedBox(height: 4),

        Text(

          'Itens inativos não aparecem no lançamento, mas permanecem em respostas já enviadas. Não é possível excluir opções.',

          style: Theme.of(context).textTheme.bodySmall,

        ),

        const SizedBox(height: 12),

        ...List.generate(_items.length, (index) {

          final opcao = _items[index];

          final isLast = index == _items.length - 1;

          return Padding(

            padding: const EdgeInsets.only(bottom: 12),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Expanded(

                  child: TextFormField(

                    controller: _controllers[index],

                    focusNode: _focusNodes[index],

                    textInputAction:

                        isLast ? TextInputAction.next : TextInputAction.next,

                    onFieldSubmitted: (_) => _onOpcaoSubmitted(index),
                    onEditingComplete: () => _onOpcaoSubmitted(index),

                    decoration: InputDecoration(

                      labelText: 'Opção ${index + 1}',

                      suffixText: opcao.ativo ? null : 'Inativa',

                    ),

                    validator: (v) {

                      if (!opcao.ativo) return null;

                      if (v == null || v.trim().isEmpty) {

                        return 'Informe o texto da opção';

                      }

                      return null;

                    },

                  ),

                ),

                const SizedBox(width: 8),

                Column(

                  children: [

                    Switch(

                      value: opcao.ativo,

                      onChanged: (v) => _setAtivo(index, v),

                    ),

                    Text(

                      opcao.ativo ? 'Ativa' : 'Inativa',

                      style: TextStyle(

                        fontFamily: AppTheme.fontFamily,

                        fontSize: 11,

                        color: opcao.ativo ? null : Colors.red,

                      ),

                    ),

                  ],

                ),

              ],

            ),

          );

        }),

        Align(

          alignment: Alignment.centerLeft,

          child: TextButton.icon(

            onPressed: _addOpcao,

            icon: const Icon(Icons.add),

            label: const Text('Adicionar opção'),

          ),

        ),

      ],

    );

  }

}


