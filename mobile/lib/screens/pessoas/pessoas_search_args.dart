/// Configuração da tela reutilizável de pesquisa de pessoas.
class PessoasSearchArgs {
  const PessoasSearchArgs({
    this.title = 'Pesquisar assistido',
    this.subtitle,
    this.onlyAtivas = true,
  });

  final String title;
  final String? subtitle;
  final bool onlyAtivas;
}
