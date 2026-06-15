# Cefa — Documentação do Projeto

Ponto de entrada da documentação. O conteúdo está **dividido por tema** na pasta [`docs/`](./docs/) para facilitar leitura humana e uso por assistentes de IA.

## Índice

Para localizar **modelo + API + app** de um recurso (cursos, alunos, voluntários, etc.), use o [Índice por recurso](#índice-por-recurso) abaixo.

| Documento | Conteúdo |
|-----------|----------|
| [docs/visao-arquitetura.md](./docs/visao-arquitetura.md) | Visão geral do produto, objetivos da v1, stack, escopo do repositório, diagrama e estrutura de pastas |
| [docs/modelo-dados.md](./docs/modelo-dados.md) | Auditoria, entidades, relacionamentos, regras de negócio do banco |
| [docs/api.md](./docs/api.md) | Referência da API REST (rotas, exemplos JSON, regras) |
| [docs/mobile.md](./docs/mobile.md) | App Flutter: navegação, telas, fluxos, **bloco de auditoria** (`AuditoriaSection`), permissões, identidade |
| [docs/relatorios.md](./docs/relatorios.md) | PDF: submissões em fluxo; **entrevista** com layout fixo (YAML + fundo); **alunos matriculados** por turma; submissões fixas planejadas |
| [docs/setup.md](./docs/setup.md) | Pré-requisitos, Neon/Docker, execução da API e do app; **fora do escopo v1**; scripts úteis |
| [docs/deploy-render.md](./docs/deploy-render.md) | Deploy da API no **Render** + Neon (`DATABASE_URL`, `JWT_SECRET`, `ADMIN_INITIAL_PASSWORD`, Flutter `API_BASE_URL`) |
| [docs/historico.md](./docs/historico.md) | Histórico de evolução do projeto |
| [docs/troubleshooting.md](./docs/troubleshooting.md) | Solução de problemas (FAQ técnico) |
| [docs/atendimento-medico.md](./docs/atendimento-medico.md) | **Planejamento** do prontuário / atendimento médico (STT, JSON, checklist — **sem código ainda**) |

Documentação visual: [`IdentidadeGrafica.md`](./IdentidadeGrafica.md). Regras fixas do projeto: [`.cursor/rules/`](./.cursor/rules/).

> **Prontuário médico:** o desenvolvimento **não** deve começar até o solicitante enviar as respostas do [checklist em docs/atendimento-medico.md §10](./docs/atendimento-medico.md#10-checklist-para-iniciar-implementação).

---

## Índice por recurso

Atalho para achar **modelo**, **API** e **app** do mesmo domínio. Detalhes completos nos arquivos temáticos acima.

### Formulários e lançamentos

| Recurso | Programa (`codigo`) | Modelo | API | App |
|---------|---------------------|--------|-----|-----|
| Tipos de formulário | `tipos_formulario` | [modelo-dados § tipos_formulario](./docs/modelo-dados.md#tipo-de-formulário-tipos_formulario) | [api § tipos](./docs/api.md#tipos-de-formulário) | [mobile § telas](./docs/mobile.md#telas) |
| Perguntas | `perguntas` | [modelo-dados § perguntas](./docs/modelo-dados.md#pergunta-perguntas) | [api § perguntas](./docs/api.md#perguntas) | [mobile § cadastro perguntas](./docs/mobile.md#cadastro-de-perguntas-lista) |
| Responder questionários | `lancamento` | [modelo-dados § submissoes](./docs/modelo-dados.md#submissão-submissoes) | [api § submissões](./docs/api.md#submissões) | [mobile § lançamento](./docs/mobile.md#fluxo-de-lançamento) |
| Consulta de respostas | `submissoes` | [modelo-dados § submissoes](./docs/modelo-dados.md#submissão-submissoes) | [api § submissões](./docs/api.md#submissões) | [mobile § consulta PDF](./docs/mobile.md#consulta-de-respostas-e-pdf) |
| Liberação por tipo de formulário | `liberacao_*` | [modelo-dados § permissões](./docs/modelo-dados.md#permissões) | [api § liberação tipos](./docs/api.md#liberação-de-tipos-de-formulário) | [mobile § liberação](./docs/mobile.md#programas-do-sistema-e-liberação-de-acesso) |

### Assistidos e entrevista

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| Assistidos | `pessoas` | [modelo-dados § pessoas](./docs/modelo-dados.md#pessoa-pessoas--assistido-na-interface) | [api § pessoas](./docs/api.md#assistidos-pessoas) | [mobile § assistidos](./docs/mobile.md#cadastro-de-assistido--endereço-bairro-e-município) |
| Entrevista com o assistido | `entrevista_assistido` | [modelo-dados § entrevista](./docs/modelo-dados.md#entrevista-com-o-assistido-entrevistas_assistido) | [api § entrevistas](./docs/api.md#entrevistas-com-o-assistido) | [mobile § entrevista](./docs/mobile.md#entrevista-com-o-assistido) |
| PDF da entrevista | — | — | — | [relatorios.md](./docs/relatorios.md) |

### Catálogos (código automático)

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| Cidades | `cidades` | [modelo-dados § cidades](./docs/modelo-dados.md#cidade-cidades) | [api § cidades](./docs/api.md#cidades) | [mobile § telas](./docs/mobile.md#telas) |
| Bairros | `bairros` | [modelo-dados § bairros](./docs/modelo-dados.md#bairro-bairros) | [api § bairros](./docs/api.md#bairros) | [mobile § telas](./docs/mobile.md#telas) |
| Escolaridades | `escolaridades` | [modelo-dados § escolaridades](./docs/modelo-dados.md#escolaridade-escolaridades) | [api § escolaridades](./docs/api.md#escolaridades) | [mobile § escolaridades](./docs/mobile.md#cadastro-de-escolaridades) |
| Departamentos | `departamentos` | [modelo-dados § departamentos](./docs/modelo-dados.md#departamento-departamentos) | [api § departamentos](./docs/api.md#departamentos) | [mobile § departamentos](./docs/mobile.md#cadastro-de-departamentos) |
| **Cursos** | `cursos` | [modelo-dados § cursos](./docs/modelo-dados.md#curso-cursos) | [api § cursos](./docs/api.md#cursos) | [mobile § cursos](./docs/mobile.md#cadastro-de-cursos) |
| **Turmas** | `turmas` | [modelo-dados § turmas](./docs/modelo-dados.md#turma-turmas) | [api § turmas](./docs/api.md#turmas-turmas) | [mobile § turmas](./docs/mobile.md#cadastro-de-turmas) |

### Pessoas e vínculos

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| Voluntários | `voluntarios` | [modelo-dados § voluntarios](./docs/modelo-dados.md#voluntário-voluntarios) | [api § voluntários](./docs/api.md#voluntários) | [mobile § voluntários](./docs/mobile.md#cadastro-de-voluntários) |
| Voluntário × departamento (horários) | `voluntarios` | [modelo-dados § horarios](./docs/modelo-dados.md#voluntário--departamento-voluntario_departamento_horarios) | [api § horários](./docs/api.md#voluntário--departamento-horários) | [widget horários](./docs/mobile.md#cadastro-de-voluntários) |
| **Cadastro de Alunos** | `alunos` | [modelo-dados § alunos](./docs/modelo-dados.md#aluno-alunos) | [api § alunos](./docs/api.md#alunos-alunos) | [mobile § alunos](./docs/mobile.md#cadastro-de-alunos) |
| **Inscrição em curso** | `inscricoes` | [modelo-dados § inscrições](./docs/modelo-dados.md#inscrição-em-curso-inscricoes_aluno_curso) | [api § inscrições](./docs/api.md#inscrições-inscricoes) | [mobile § inscrições](./docs/mobile.md#inscrição-em-curso) |
| **Matricular Alunos no Curso** | `matricula_alunos` | [modelo-dados § inscrições](./docs/modelo-dados.md#inscrição-em-curso-inscricoes_aluno_curso) | [api § matrícula](./docs/api.md#matrícula-de-inscrições-inscricoesmatricula) | [mobile § matrícula](./docs/mobile.md#matricular-alunos-no-curso) · [PDF §7](./docs/relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado) |
| **Cancelar Matrícula de Alunos no Curso** | `cancelamento_matricula_alunos` | [modelo-dados § inscrições](./docs/modelo-dados.md#inscrição-em-curso-inscricoes_aluno_curso) | [api § cancelamento](./docs/api.md#cancelamento-de-matrícula-inscricoescancelamento-matricula) | [mobile § cancelamento](./docs/mobile.md#cancelar-matrícula-de-alunos-no-curso) · [PDF §7](./docs/relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado) |
| **Atendimento de Alunos** | `atendimento_alunos` | [modelo-dados § atendimentos](./docs/modelo-dados.md#atendimento-de-aluno-inscricao_atendimentos) | [api § atendimentos](./docs/api.md#atendimentos-de-alunos-inscricao-atendimentos) | [mobile § atendimento](./docs/mobile.md#atendimento-de-alunos) |
| **Relatório de Alunos da Turma** | `relatorio_alunos_turma` | [modelo-dados § inscrições](./docs/modelo-dados.md#inscrição-em-curso-inscricoes_aluno_curso) | [api § relatório](./docs/api.md#relatório-de-alunos-da-turma-inscricoesrelatorio-alunos-turma) | [mobile § relatório](./docs/mobile.md#relatório-de-alunos-da-turma) · [PDF §8](./docs/relatorios.md#8-relatório-de-alunos-da-turma-implementado) |

### Relatórios (módulo e submódulos)

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| **Submódulos de relatórios** | `relatorio_submodulos` | [modelo-dados § submódulos](./docs/modelo-dados.md#submódulo-de-relatório-relatorio_submodulos) | [api § submódulos](./docs/api.md#submódulos-de-relatórios) | [mobile § submódulos](./docs/mobile.md#submódulos-de-relatórios) |
| Módulo **Relatórios** (menu Home) | — | [modelo-dados § módulos](./docs/modelo-dados.md#módulo-do-sistema-modulos_sistema) | [api § menu](./docs/api.md#módulos-do-sistema) | [mobile § Home](./docs/mobile.md#fluxo-de-login-e-home) |
| Organização menu / novos PDFs | — | [relatorios.md §0](./docs/relatorios.md#0-menu-do-módulo-relatórios-e-submódulos) | — | — |

### Saúde (planejamento)

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| Atendimento médico / prontuário | *a definir* | [atendimento-medico.md](./docs/atendimento-medico.md) | *pendente* | *pendente* |

### Administração

| Recurso | Programa | Modelo | API | App |
|---------|----------|--------|-----|-----|
| Módulos do sistema | `modulos_sistema` | [modelo-dados § módulos](./docs/modelo-dados.md#módulo-do-sistema-modulos_sistema) | [api § módulos](./docs/api.md#módulos-do-sistema) | [mobile § módulos](./docs/mobile.md#telas) |
| Submódulos de relatórios | `relatorio_submodulos` | [modelo-dados § submódulos](./docs/modelo-dados.md#submódulo-de-relatório-relatorio_submodulos) | [api § submódulos](./docs/api.md#submódulos-de-relatórios) | [mobile § submódulos](./docs/mobile.md#submódulos-de-relatórios) |
| Programas do sistema | `modulos_sistema` | [modelo-dados § programas](./docs/modelo-dados.md#programa-programas) | [api § programas](./docs/api.md#programas) | [mobile § programas](./docs/mobile.md#programas-do-sistema-e-liberação-de-acesso) |
| Usuários / tipos / liberação | `usuarios`, `tipos_usuario`, `liberacao_*` | [modelo-dados § usuários](./docs/modelo-dados.md#usuário-usuarios) | [api § auth e usuários](./docs/api.md#autenticação) | [mobile § auth](./docs/mobile.md#autenticação-e-permissões-no-app) |

**Diagrama ER (visão geral):** [modelo-dados.md § diagrama](./docs/modelo-dados.md#diagrama-entidade-relacionamento).

---

## Como evoluir esta documentação

- Preferir **editar o arquivo temático** em `docs/` ao acrescentar detalhes longos; mantenha este índice atualizado se criar arquivo novo.
- O **README.md** na raiz continua com início rápido e visão compacta.
- Convenções estáveis (Arial, escopo do repo, sem cascade) ficam em **`.cursor/rules/`**.
- Registros históricos: §7 em [docs/historico.md](./docs/historico.md) — apenas marcos; evite duplicar texto das seções estáveis.

---

*Documentação alinhada ao estado do repositório em junho/2026. Destaques: catálogos **escolaridades**, **departamentos**, **cursos** (código automático); **Cadastro de Turmas** (filtro por **curso** na lista; curso + período + situação Aberta/Fechada — [mobile.md § Turmas](./docs/mobile.md#cadastro-de-turmas)); **voluntários** (estado civil inclui **Separado(a)**; horários por departamento; cadeia **Enter** — [mobile.md § Enter](./docs/mobile.md#formulários--tecla-enter)); **Cadastro de Alunos** ([mobile.md § Cadastro de Alunos](./docs/mobile.md#cadastro-de-alunos)); **Inscrição em curso** (lista exige ao menos um filtro antes de buscar; card em uma linha com ** - MATRICULADO** ou ** - Matricula Cancelada** após o período — [mobile.md § Inscrição](./docs/mobile.md#inscrição-em-curso)); **Matricular Alunos no Curso** (vagas, turma, **Data da matrícula**; PDF de matriculados — [relatorios.md §7](./docs/relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado)); **Cancelar Matrícula** e **Atendimento de Alunos**; **módulo Relatórios** (`codigo` 3) com **submódulos** consultáveis (`relatorio_submodulos`, seed **IEFA**); **Relatório de Alunos da Turma** no módulo Relatórios (filtros curso/turma/situação; PDF resumido ou detalhado — [relatorios.md §8](./docs/relatorios.md#8-relatório-de-alunos-da-turma-implementado)); **assistidos** (`pessoas`); **Responder Questionários** (`lancamento`); liberação por **programa** e **tipo de formulário**; **Home** com módulos por **`ordem`**, chips de **submódulo** em Relatórios e programas em **ordem alfabética**; entrevista **6 abas** + PDF ([relatorios.md](./docs/relatorios.md)); API **`https://cefa-api.onrender.com`** ([deploy-render.md](./docs/deploy-render.md)); auditoria com nomes na API. Migrations: `20260525100000`–`20260615100000` (ver [setup.md](./docs/setup.md)). Ao alterar modelo: migration Prisma + [modelo-dados.md](./docs/modelo-dados.md) + [api.md](./docs/api.md) + [mobile.md](./docs/mobile.md).*
