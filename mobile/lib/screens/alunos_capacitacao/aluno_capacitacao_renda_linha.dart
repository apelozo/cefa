import 'package:flutter/material.dart';

class AlunoCapacitacaoRendaLinha {
  AlunoCapacitacaoRendaLinha({
    String nome = '',
    String idade = '',
    String renda = '',
    String parentesco = '',
    String profissao = '',
  })  : nome = TextEditingController(text: nome),
        idade = TextEditingController(text: idade),
        renda = TextEditingController(text: renda),
        parentesco = TextEditingController(text: parentesco),
        profissao = TextEditingController(text: profissao);

  final TextEditingController nome;
  final TextEditingController idade;
  final TextEditingController renda;
  final TextEditingController parentesco;
  final TextEditingController profissao;

  bool get preenchida => nome.text.trim().isNotEmpty;

  void dispose() {
    nome.dispose();
    idade.dispose();
    renda.dispose();
    parentesco.dispose();
    profissao.dispose();
  }
}
