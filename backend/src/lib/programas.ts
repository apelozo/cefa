export type ProgramaDef = {
  codigo: string;
  nome: string;
  autoListagem: boolean;
  moduloCodigo: number;
};

export const PROGRAMAS_CATALOGO: ProgramaDef[] = [
  {
    codigo: "tipos_formulario",
    nome: "Tipos de formulário",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "perguntas",
    nome: "Cadastrar perguntas",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "pessoas",
    nome: "Cadastrar assistidos",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "cidades",
    nome: "Cadastrar cidades",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "bairros",
    nome: "Cadastrar bairros",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "escolaridades",
    nome: "Cadastrar escolaridades",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "departamentos",
    nome: "Cadastrar departamentos",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "cursos",
    nome: "Cadastrar cursos",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "turmas",
    nome: "Cadastro de Turmas",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "alunos",
    nome: "Cadastro de Alunos",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "inscricoes",
    nome: "Inscrição em curso",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "matricula_alunos",
    nome: "Matricular Alunos no Curso",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "cancelamento_matricula_alunos",
    nome: "Cancelar Matrícula de Alunos no Curso",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "atendimento_alunos",
    nome: "Atendimento de Alunos",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "relatorio_alunos_turma",
    nome: "Relatório de Alunos da Turma",
    autoListagem: true,
    moduloCodigo: 3,
  },
  {
    codigo: "voluntarios",
    nome: "Cadastrar voluntários",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "submissoes",
    nome: "Consultar respostas",
    autoListagem: true,
    moduloCodigo: 1,
  },
  { codigo: "lancamento", nome: "Responder Questionários", autoListagem: false, moduloCodigo: 1 },
  {
    codigo: "entrevista_assistido",
    nome: "Entrevista com o Assistido",
    autoListagem: true,
    moduloCodigo: 1,
  },
  {
    codigo: "usuarios",
    nome: "Cadastro de usuários",
    autoListagem: false,
    moduloCodigo: 2,
  },
  {
    codigo: "tipos_usuario",
    nome: "Tipos de usuário",
    autoListagem: false,
    moduloCodigo: 2,
  },
  {
    codigo: "liberacao_usuario",
    nome: "Liberação de acesso (usuário)",
    autoListagem: false,
    moduloCodigo: 2,
  },
  {
    codigo: "liberacao_tipo_usuario",
    nome: "Liberação de acesso (tipo)",
    autoListagem: false,
    moduloCodigo: 2,
  },
  {
    codigo: "modulos_sistema",
    nome: "Módulos do sistema",
    autoListagem: false,
    moduloCodigo: 2,
  },
  {
    codigo: "relatorio_submodulos",
    nome: "Submódulos de relatórios",
    autoListagem: true,
    moduloCodigo: 2,
  },
];

export type AcaoPermissao = "incluir" | "alterar" | "consultar" | "excluir";

export const PROGRAMA_POR_ROTA: Record<
  string,
  { programa: string; acao: AcaoPermissao }
> = {
  "GET /tipos-formulario": { programa: "tipos_formulario", acao: "consultar" },
  "GET /tipos-formulario/:id": { programa: "tipos_formulario", acao: "consultar" },
  "POST /tipos-formulario": { programa: "tipos_formulario", acao: "incluir" },
  "PUT /tipos-formulario/:id": { programa: "tipos_formulario", acao: "alterar" },
  "DELETE /tipos-formulario/:id": { programa: "tipos_formulario", acao: "excluir" },
  "GET /perguntas": { programa: "perguntas", acao: "consultar" },
  "GET /perguntas/:id": { programa: "perguntas", acao: "consultar" },
  "POST /perguntas": { programa: "perguntas", acao: "incluir" },
  "PUT /perguntas/:id": { programa: "perguntas", acao: "alterar" },
  "DELETE /perguntas/:id": { programa: "perguntas", acao: "excluir" },
  "GET /pessoas": { programa: "pessoas", acao: "consultar" },
  "GET /pessoas/:id": { programa: "pessoas", acao: "consultar" },
  "POST /pessoas": { programa: "pessoas", acao: "incluir" },
  "PUT /pessoas/:id": { programa: "pessoas", acao: "alterar" },
  "DELETE /pessoas/:id": { programa: "pessoas", acao: "excluir" },
  "GET /cidades": { programa: "cidades", acao: "consultar" },
  "GET /cidades/:id": { programa: "cidades", acao: "consultar" },
  "POST /cidades": { programa: "cidades", acao: "incluir" },
  "PUT /cidades/:id": { programa: "cidades", acao: "alterar" },
  "DELETE /cidades/:id": { programa: "cidades", acao: "excluir" },
  "GET /bairros": { programa: "bairros", acao: "consultar" },
  "GET /bairros/:id": { programa: "bairros", acao: "consultar" },
  "POST /bairros": { programa: "bairros", acao: "incluir" },
  "PUT /bairros/:id": { programa: "bairros", acao: "alterar" },
  "DELETE /bairros/:id": { programa: "bairros", acao: "excluir" },
  "GET /escolaridades": { programa: "escolaridades", acao: "consultar" },
  "GET /escolaridades/:id": { programa: "escolaridades", acao: "consultar" },
  "POST /escolaridades": { programa: "escolaridades", acao: "incluir" },
  "PUT /escolaridades/:id": { programa: "escolaridades", acao: "alterar" },
  "DELETE /escolaridades/:id": { programa: "escolaridades", acao: "excluir" },
  "GET /departamentos": { programa: "departamentos", acao: "consultar" },
  "GET /departamentos/:id": { programa: "departamentos", acao: "consultar" },
  "POST /departamentos": { programa: "departamentos", acao: "incluir" },
  "PUT /departamentos/:id": { programa: "departamentos", acao: "alterar" },
  "DELETE /departamentos/:id": { programa: "departamentos", acao: "excluir" },
  "GET /cursos": { programa: "cursos", acao: "consultar" },
  "GET /cursos/:id": { programa: "cursos", acao: "consultar" },
  "POST /cursos": { programa: "cursos", acao: "incluir" },
  "PUT /cursos/:id": { programa: "cursos", acao: "alterar" },
  "DELETE /cursos/:id": { programa: "cursos", acao: "excluir" },
  "GET /turmas": { programa: "turmas", acao: "consultar" },
  "GET /turmas/:id": { programa: "turmas", acao: "consultar" },
  "POST /turmas": { programa: "turmas", acao: "incluir" },
  "PUT /turmas/:id": { programa: "turmas", acao: "alterar" },
  "DELETE /turmas/:id": { programa: "turmas", acao: "excluir" },
  "GET /alunos": { programa: "alunos", acao: "consultar" },
  "GET /alunos/:id": { programa: "alunos", acao: "consultar" },
  "POST /alunos": { programa: "alunos", acao: "incluir" },
  "PUT /alunos/:id": { programa: "alunos", acao: "alterar" },
  "DELETE /alunos/:id": { programa: "alunos", acao: "excluir" },
  "GET /inscricoes": { programa: "inscricoes", acao: "consultar" },
  "GET /inscricoes/:id": { programa: "inscricoes", acao: "consultar" },
  "POST /inscricoes": { programa: "inscricoes", acao: "incluir" },
  "PUT /inscricoes/:id": { programa: "inscricoes", acao: "alterar" },
  "DELETE /inscricoes/:id": { programa: "inscricoes", acao: "excluir" },
  "GET /inscricoes/matricula/candidatos": {
    programa: "matricula_alunos",
    acao: "consultar",
  },
  "POST /inscricoes/matricula": {
    programa: "matricula_alunos",
    acao: "alterar",
  },
  "GET /inscricoes/cancelamento-matricula/matriculados": {
    programa: "cancelamento_matricula_alunos",
    acao: "consultar",
  },
  "POST /inscricoes/cancelamento-matricula": {
    programa: "cancelamento_matricula_alunos",
    acao: "alterar",
  },
  "GET /inscricoes/relatorio-alunos-turma": {
    programa: "relatorio_alunos_turma",
    acao: "consultar",
  },
  "GET /inscricoes/relatorio-alunos-turma/cursos": {
    programa: "relatorio_alunos_turma",
    acao: "consultar",
  },
  "GET /inscricoes/relatorio-alunos-turma/turmas": {
    programa: "relatorio_alunos_turma",
    acao: "consultar",
  },
  "GET /inscricao-atendimentos/alunos-matriculados": {
    programa: "atendimento_alunos",
    acao: "consultar",
  },
  "GET /inscricao-atendimentos": {
    programa: "atendimento_alunos",
    acao: "consultar",
  },
  "GET /inscricao-atendimentos/:id": {
    programa: "atendimento_alunos",
    acao: "consultar",
  },
  "POST /inscricao-atendimentos": {
    programa: "atendimento_alunos",
    acao: "incluir",
  },
  "PUT /inscricao-atendimentos/:id": {
    programa: "atendimento_alunos",
    acao: "alterar",
  },
  "DELETE /inscricao-atendimentos/:id": {
    programa: "atendimento_alunos",
    acao: "excluir",
  },
  "GET /voluntarios": { programa: "voluntarios", acao: "consultar" },
  "GET /voluntarios/:id": { programa: "voluntarios", acao: "consultar" },
  "POST /voluntarios": { programa: "voluntarios", acao: "incluir" },
  "PUT /voluntarios/:id": { programa: "voluntarios", acao: "alterar" },
  "DELETE /voluntarios/:id": { programa: "voluntarios", acao: "excluir" },
  "GET /voluntarios/:id/departamento-horarios": {
    programa: "voluntarios",
    acao: "consultar",
  },
  "POST /voluntarios/:id/departamento-horarios": {
    programa: "voluntarios",
    acao: "incluir",
  },
  "GET /voluntario-departamento-horarios/:id": {
    programa: "voluntarios",
    acao: "consultar",
  },
  "PUT /voluntario-departamento-horarios/:id": {
    programa: "voluntarios",
    acao: "alterar",
  },
  "DELETE /voluntario-departamento-horarios/:id": {
    programa: "voluntarios",
    acao: "excluir",
  },
  "GET /submissoes": { programa: "submissoes", acao: "consultar" },
  "GET /submissoes/:id": { programa: "submissoes", acao: "consultar" },
  "POST /submissoes": { programa: "lancamento", acao: "incluir" },
  "GET /entrevistas-assistido": {
    programa: "entrevista_assistido",
    acao: "consultar",
  },
  "POST /entrevistas-assistido": {
    programa: "entrevista_assistido",
    acao: "incluir",
  },
  "GET /entrevistas-assistido/:id": {
    programa: "entrevista_assistido",
    acao: "consultar",
  },
  "PUT /entrevistas-assistido/:id": {
    programa: "entrevista_assistido",
    acao: "alterar",
  },
  "DELETE /entrevistas-assistido/:id": {
    programa: "entrevista_assistido",
    acao: "excluir",
  },
  "GET /tipos-usuario": { programa: "tipos_usuario", acao: "consultar" },
  "GET /tipos-usuario/:id": { programa: "tipos_usuario", acao: "consultar" },
  "POST /tipos-usuario": { programa: "tipos_usuario", acao: "incluir" },
  "PUT /tipos-usuario/:id": { programa: "tipos_usuario", acao: "alterar" },
  "DELETE /tipos-usuario/:id": { programa: "tipos_usuario", acao: "excluir" },
  "GET /tipos-usuario/:id/permissoes": {
    programa: "liberacao_tipo_usuario",
    acao: "consultar",
  },
  "PUT /tipos-usuario/:id/permissoes": {
    programa: "liberacao_tipo_usuario",
    acao: "alterar",
  },
  "GET /tipos-usuario/:id/tipos-formulario-acesso": {
    programa: "liberacao_tipo_usuario",
    acao: "consultar",
  },
  "PUT /tipos-usuario/:id/tipos-formulario-acesso": {
    programa: "liberacao_tipo_usuario",
    acao: "alterar",
  },
  "GET /usuarios": { programa: "usuarios", acao: "consultar" },
  "GET /usuarios/:id": { programa: "usuarios", acao: "consultar" },
  "POST /usuarios": { programa: "usuarios", acao: "incluir" },
  "PUT /usuarios/:id": { programa: "usuarios", acao: "alterar" },
  "DELETE /usuarios/:id": { programa: "usuarios", acao: "excluir" },
  "GET /usuarios/:id/permissoes": {
    programa: "liberacao_usuario",
    acao: "consultar",
  },
  "PUT /usuarios/:id/permissoes": {
    programa: "liberacao_usuario",
    acao: "alterar",
  },
  "GET /usuarios/:id/tipos-formulario-acesso": {
    programa: "liberacao_usuario",
    acao: "consultar",
  },
  "PUT /usuarios/:id/tipos-formulario-acesso": {
    programa: "liberacao_usuario",
    acao: "alterar",
  },
  "GET /programas": { programa: "liberacao_usuario", acao: "consultar" },
  "GET /programas/:id": { programa: "liberacao_usuario", acao: "consultar" },
  "POST /programas": { programa: "modulos_sistema", acao: "incluir" },
  "PUT /programas/:id": { programa: "modulos_sistema", acao: "alterar" },
  "GET /modulos-sistema": { programa: "modulos_sistema", acao: "consultar" },
  "GET /modulos-sistema/:id": { programa: "modulos_sistema", acao: "consultar" },
  "POST /modulos-sistema": { programa: "modulos_sistema", acao: "incluir" },
  "PUT /modulos-sistema/:id": { programa: "modulos_sistema", acao: "alterar" },
  "DELETE /modulos-sistema/:id": { programa: "modulos_sistema", acao: "excluir" },
  "PUT /modulos-sistema/:id/programas": {
    programa: "modulos_sistema",
    acao: "alterar",
  },
  "GET /relatorio-submodulos": {
    programa: "relatorio_submodulos",
    acao: "consultar",
  },
  "GET /relatorio-submodulos/:id": {
    programa: "relatorio_submodulos",
    acao: "consultar",
  },
  "POST /relatorio-submodulos": {
    programa: "relatorio_submodulos",
    acao: "incluir",
  },
  "PUT /relatorio-submodulos/:id": {
    programa: "relatorio_submodulos",
    acao: "alterar",
  },
  "DELETE /relatorio-submodulos/:id": {
    programa: "relatorio_submodulos",
    acao: "excluir",
  },
};

const ROTAS_SEM_PERMISSAO_PROGRAMA = new Set([
  "GET /modulos-sistema/menu",
  "GET /auth/me",
]);

export function rotaPermissaoKey(method: string, path: string): string | null {
  const normalized = path.replace(
    /\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi,
    "/:id",
  );
  const key = `${method.toUpperCase()} ${normalized}`;
  if (ROTAS_SEM_PERMISSAO_PROGRAMA.has(key)) return null;
  if (PROGRAMA_POR_ROTA[key]) return key;
  return null;
}
