import 'package:flutter/material.dart';

import '../auth/programas.dart';
import '../screens/entrevista_assistido/entrevistas_assistido_list_screen.dart';
import '../screens/lancamento/lancamento_tipo_screen.dart';
import '../screens/liberacao/liberacao_tipo_usuario_screen.dart';
import '../screens/liberacao/liberacao_usuario_screen.dart';
import '../screens/modulos_sistema/modulos_sistema_list_screen.dart';
import '../screens/perguntas/perguntas_list_screen.dart';
import '../screens/bairros/bairros_list_screen.dart';
import '../screens/departamentos/departamentos_list_screen.dart';
import '../screens/cursos/cursos_list_screen.dart';
import '../screens/alunos_capacitacao/alunos_capacitacao_list_screen.dart';
import '../screens/voluntarios/voluntarios_list_screen.dart';
import '../screens/escolaridades/escolaridades_list_screen.dart';
import '../screens/cidades/cidades_list_screen.dart';
import '../screens/pessoas/pessoas_list_screen.dart';
import '../screens/submissoes/submissoes_list_screen.dart';
import '../screens/tipos_formulario/tipos_formulario_list_screen.dart';
import '../screens/tipos_usuario/tipos_usuario_list_screen.dart';
import '../screens/usuarios/usuarios_list_screen.dart';

class HomeMenuEntry {
  const HomeMenuEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget screen;
}

abstract final class HomeMenuRegistry {
  static HomeMenuEntry? entryForCodigo(String codigo) => _entries[codigo];

  static const _entries = <String, HomeMenuEntry>{
    Programas.tiposFormulario: HomeMenuEntry(
      icon: Icons.category_outlined,
      label: 'Tipos de formulário',
      subtitle: 'Cadastrar categorias de formulário',
      screen: TiposFormularioListScreen(),
    ),
    Programas.perguntas: HomeMenuEntry(
      icon: Icons.quiz_outlined,
      label: 'Cadastrar perguntas',
      subtitle: 'Criar, editar e desativar perguntas',
      screen: PerguntasListScreen(),
    ),
    Programas.pessoas: HomeMenuEntry(
      icon: Icons.person_outline,
      label: 'Cadastrar assistidos',
      subtitle: 'Nome, data de nascimento, CPF e RG',
      screen: PessoasListScreen(),
    ),
    Programas.cidades: HomeMenuEntry(
      icon: Icons.location_city_outlined,
      label: 'Cadastrar cidades',
      subtitle: 'Município e estado (UF)',
      screen: CidadesListScreen(),
    ),
    Programas.bairros: HomeMenuEntry(
      icon: Icons.map_outlined,
      label: 'Cadastrar bairros',
      subtitle: 'Código e nome do bairro',
      screen: BairrosListScreen(),
    ),
    Programas.escolaridades: HomeMenuEntry(
      icon: Icons.school_outlined,
      label: 'Cadastrar escolaridades',
      subtitle: 'Código e descrição para a entrevista',
      screen: EscolaridadesListScreen(),
    ),
    Programas.departamentos: HomeMenuEntry(
      icon: Icons.apartment_outlined,
      label: 'Cadastrar departamentos',
      subtitle: 'Código e descrição do departamento',
      screen: DepartamentosListScreen(),
    ),
    Programas.cursos: HomeMenuEntry(
      icon: Icons.menu_book_outlined,
      label: 'Cadastrar cursos',
      subtitle: 'Código e descrição do curso',
      screen: CursosListScreen(),
    ),
    Programas.alunosCapacitacao: HomeMenuEntry(
      icon: Icons.school_outlined,
      label: 'Alunos de Capacitação Profissional',
      subtitle: 'Cadastro completo com renda familiar',
      screen: AlunosCapacitacaoListScreen(),
    ),
    Programas.voluntarios: HomeMenuEntry(
      icon: Icons.volunteer_activism_outlined,
      label: 'Cadastrar voluntários',
      subtitle: 'Dados pessoais, endereço e contribuição',
      screen: VoluntariosListScreen(),
    ),
    Programas.lancamento: HomeMenuEntry(
      icon: Icons.assignment_outlined,
      label: 'Responder Questionários',
      subtitle: 'Tipo de formulário, assistido e respostas',
      screen: LancamentoTipoScreen(),
    ),
    Programas.entrevistaAssistido: HomeMenuEntry(
      icon: Icons.record_voice_over_outlined,
      label: 'Entrevista com o Assistido',
      subtitle: 'Consultar, registrar e alterar entrevistas',
      screen: EntrevistasAssistidoListScreen(),
    ),
    Programas.submissoes: HomeMenuEntry(
      icon: Icons.fact_check_outlined,
      label: 'Consulta de respostas',
      subtitle: 'Pesquisar lançamentos e exportar PDF',
      screen: SubmissoesListScreen(),
    ),
    Programas.tiposUsuario: HomeMenuEntry(
      icon: Icons.badge_outlined,
      label: 'Tipos de usuário',
      subtitle: 'Perfis e categorias de acesso',
      screen: TiposUsuarioListScreen(),
    ),
    Programas.usuarios: HomeMenuEntry(
      icon: Icons.manage_accounts_outlined,
      label: 'Usuários',
      subtitle: 'Cadastro de usuários do sistema',
      screen: UsuariosListScreen(),
    ),
    Programas.liberacaoTipoUsuario: HomeMenuEntry(
      icon: Icons.admin_panel_settings_outlined,
      label: 'Liberação por tipo',
      subtitle: 'Permissões padrão do tipo de usuário',
      screen: LiberacaoTipoUsuarioScreen(),
    ),
    Programas.liberacaoUsuario: HomeMenuEntry(
      icon: Icons.key_outlined,
      label: 'Liberação por usuário',
      subtitle: 'Permissões individuais',
      screen: LiberacaoUsuarioScreen(),
    ),
    Programas.modulosSistema: HomeMenuEntry(
      icon: Icons.view_module_outlined,
      label: 'Módulos do sistema',
      subtitle: 'Agrupar programas em módulos do menu',
      screen: ModulosSistemaListScreen(),
    ),
  };
}
