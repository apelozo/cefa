# App Flutter

## 5. App Flutter

**Terminologia na UI:** o cadastro e a seleção usam o rótulo **Assistido** (menus, títulos, filtros, PDF de submissão). Código e API mantêm `pessoas`, `Pessoa`, `pessoaId` — ver [Terminologia](./modelo-dados.md#terminologia-assistido--pessoa).

### Navegação

O app **não** usa `go_router` nem rotas nomeadas no `MaterialApp`. A navegação é **imperativa**:

- `MaterialApp(home: …)` alterna **Login** / **Home** conforme `authProvider`
- Demais telas: `Navigator.push` + `MaterialPageRoute`
- Registro de atalhos da Home: `mobile/lib/home/home_menu_registry.dart` (mapeia `codigo` do programa → tela). Programa criado em **Programas do sistema** entra na **liberação** e nos checkboxes do módulo; o atalho na Home exige entrada neste arquivo (e rotas em `PROGRAMA_POR_ROTA` no backend, se houver telas/API próprias).

### Telas

| Tela | Função |
|------|--------|
| **Login** | Nome de usuário e senha; persiste token |
| **Home** | Seletor horizontal de **módulos**; atalhos dos programas liberados no módulo selecionado (ordem **alfabética** pelo rótulo) |
| **Módulos do sistema** | CRUD de módulos (código gerado na API; somente leitura na edição); checkboxes para vincular programas; atalho para **Programas do sistema** |
| **Programas do sistema** | Lista, criar e editar programas (`codigo`, nome, listagem automática, módulo); programa `modulos_sistema` |
| **Tipos de usuário** | CRUD de tipos (descrição, perfil, ativo) |
| **Usuários** | CRUD de usuários |
| **Liberação por tipo** | Abas **Programas** (flags por programa) e **Tipos de formulário** (checkbox por tipo); aba **Programas** com filtro **Módulo** (só visualização — salva todas as linhas) |
| **Liberação por usuário** | Idem; aba **Programas** com filtro **Módulo** (só visualização — salva todas as linhas); override de tipos substitui a lista do tipo de usuário após salvar |
| **Submódulos de relatórios** | CRUD de agrupamentos (código, nome, ordem, ativo); exclusão física sem programas vinculados; consulta via `GET /relatorio-submodulos` |
| **Tipos de formulário** | Lista com botões **Alterar** / **Excluir**; FAB para novo |
| **Cadastrar perguntas** | Filtro por **tipo de formulário** no topo; lista com **Alterar** / **Excluir**; FAB para nova |
| **Cadastrar assistidos** | Seções: identificação, filiação, documentos, endereço (bairro/município com pesquisa), contato; **auditoria** na edição; listagem exibe **nome da mãe** quando informado (rotas/código: `pessoas`) |
| **Cadastrar cidades** | Município e UF (código automático; somente leitura na edição; **auditoria** na edição) |
| **Cadastrar bairros** | Nome (código automático; somente leitura na edição; **auditoria** na edição) |
| **Cadastrar escolaridades** | Descrição (código automático; somente leitura na edição; usado na entrevista; **auditoria** na edição) |
| **Cadastrar departamentos** | Descrição (código automático; **auditoria** na edição) |
| **Cadastrar cursos** | Descrição (código automático; **auditoria** na edição) |
| **Cadastro de Alunos** | Lista (nome, CPF, nascimento, idade); formulário com dados pessoais, endereço e contato |
| **Cadastro de Turmas** | Lista com filtro **Curso** no topo; card (código, nome, curso, período, situação); formulário com pesquisa de curso; situação Aberta/Fechada |
| **Inscrição em curso** | Lista com filtros **Aluno**, **Curso** e **Turma** — **ao abrir não carrega**; exige ao menos um filtro para **Buscar**; card em uma linha; formulário com **Pesquisar** aluno/turma e **2 abas**; **AuditoriaSection** na edição |
| **Matricular Alunos no Curso** | Vagas, turma, **Data da matrícula** (hoje); **Carregar candidatos** só após filtros; checkboxes **Matricular** / **Matriculado** (desabilitado) |
| **Atendimento de Alunos** | Turma + aluno (matriculado ou com matrícula cancelada); histórico consultável; **novo** atendimento só com matrícula ativa |
| **Relatório de Alunos da Turma** | Filtros **Curso** (todos ou específico), **Turma** (todas ou específica — só com curso), **Situação** e **Tipo** (Resumido/Detalhado); cursos carregados ao abrir; PDF no AppBar |
| **Cadastrar voluntários** | Nome, nome no crachá, dados pessoais, endereço, contribuição, ficha médica; horários por departamento |
| **Pesquisar assistidos** | Campos separados: nome, CPF (máscara) e RG (máscara) |
| **Responder Questionários** | Tipo de formulário → pesquisa assistido → respostas → confirma → envia (código `lancamento`) |
| **Entrevista com o Assistido** | Lista com busca por nome/CPF; FAB nova; alterar/excluir; consulta; formulário com **6 abas** (scroll horizontal na `TabBar`) |
| **Consulta de respostas** | Filtros → lista → detalhe → **exportar/visualizar PDF**; bloco de **auditoria** no detalhe |

### Bloco de auditoria nas telas

Em **cadastros** (edição) e **lançamentos/consultas** (quando o registro já existe), o app exibe um bloco **Auditoria** padronizado. O usuário vê **data/hora em formato brasileiro** e o **login** (`nomeUsuario`); quando couber na mesma linha, também o **nome completo** — **não** o UUID do usuário.

| Item | Detalhe |
|------|---------|
| **Widget** | `AuditoriaSection` — `mobile/lib/widgets/auditoria_section.dart` |
| **Modelo** | `AuditoriaCampos` — `mobile/lib/models/auditoria_campos.dart` (parse de `usuarioInclusaoNomeUsuario`, `usuarioInclusaoNome`, etc.) |
| **Formatação** | `formatAuditoriaEvento` / `formatUsuarioAuditoria` — `mobile/lib/utils/auditoria_display.dart` |
| **Exemplo de linha** | `Inclusão: 25/05/2026 14:30 · alexandre · Alexandre Silva` |
| **Quando aparece** | Formulário em **edição** (`isEditing`) ou tela de **consulta** com registro carregado; **não** aparece em cadastro **novo** (ainda sem auditoria na API) |
| **Linhas exibidas** | **Inclusão** e **Última alteração** (se houver data); **Desativação (soft delete)** quando `mostrarExclusao: true` e o registro está inativo com `dataHoraExclusao` |
| **Fonte dos dados** | `GET` do recurso após salvar ou ao abrir edição/consulta; a API enriquece os IDs com nomes — ver [api.md § auditoria](./api.md#campos-de-auditoria-nas-respostas-json) |

**Telas com o bloco**

| Área | Tela / arquivo |
|------|----------------|
| Catálogos | Bairro, cidade, escolaridade, departamento, curso, turma — `*_form_screen.dart` em `screens/bairros`, `cidades`, `escolaridades`, `departamentos`, `cursos`, `turmas` |
| Pessoas e alunos | Assistido (`pessoa_form_screen.dart`), aluno (`aluno_form_screen.dart`), inscrição (`inscricao_form_screen.dart`), matrícula (`matricula_alunos_screen.dart`), cancelamento de matrícula (`cancelamento_matricula_alunos_screen.dart`), atendimento (`atendimento_alunos_screen.dart`), relatório de alunos da turma (`relatorio_alunos_turma_screen.dart`) |
| Voluntários | `voluntario_form_screen.dart` |
| Administração | Usuário, tipo de usuário, tipo de formulário, pergunta, programa, módulo, **submódulo de relatório** — `screens/usuarios`, `tipos_usuario`, `tipos_formulario`, `perguntas`, `programas`, `modulos_sistema`, `relatorio_submodulos` |
| Lançamentos | Consulta de respostas — `submissao_detail_screen.dart` |
| Entrevista | Edição/consulta — `entrevista_assistido_screen.dart` (cabeçalho, quando `entrevistaId` informado) |

Registros antigos ou criados por sync podem ter `usuarioInclusaoId`/`usuarioAlteracaoId` nulos: nesse caso a linha mostra só a data/hora.

### Fluxo de login e Home

```
1. Abrir o app → Login (nome de usuário + senha)
2. Home carrega GET /modulos-sistema/menu
3. Módulos aparecem nos chips horizontais ordenados pelo campo **ordem** (crescente) e, em empate, por **nome** — configurável em **Módulos do sistema**
4. Usuário escolhe um módulo
5. São exibidos apenas programas daquele módulo com alguma permissão, ordenados **alfabeticamente** pelo rótulo do atalho
6. No módulo **Relatórios**, chips de **submódulo** filtram os atalhos (dados de `GET /relatorio-submodulos` / vínculo no programa)
7. Programas de administração ficam no módulo "Administração" (não há seção fixa separada)
```

Usuário seed: **admin** (tipo Administrador, permissão total na API e na UI).

### Fluxo do cadastro de formulários

```
1. Cadastrar Tipo de Formulário ("Admissão")
2. Cadastrar Perguntas vinculadas a "Admissão" (use o filtro por tipo na lista)
3. (Opcional) Cadastrar Cidades e Bairros para endereço
4. (Opcional) Cadastrar Escolaridades (listbox na entrevista)
5. Cadastrar Departamentos e Voluntários (na edição do voluntário: vínculo departamento + dia/horário)
6. Cadastrar Assistidos (identificação, documentos, endereço, contato)
```

### Cadastro de escolaridades

Telas: `mobile/lib/screens/escolaridades/` (`escolaridades_list_screen.dart`, `escolaridade_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Código | Gerado na API ao criar; somente leitura na edição |
| Descrição | Campo editável |
| Exclusão | Soft delete (`DELETE` → `ativo = false`) |
| Entrevista | Aba **Condições Educacionais** carrega `GET /escolaridades?ativo=true` (inclusão/edição) |

### Cadastro de departamentos

Telas: `mobile/lib/screens/departamentos/` (`departamentos_list_screen.dart`, `departamento_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Código | Gerado na API ao criar; somente leitura na edição |
| Descrição | Campo editável |
| Auditoria | Bloco padrão na edição — ver [Bloco de auditoria nas telas](#bloco-de-auditoria-nas-telas) |
| Exclusão | Desativa (`DELETE` → `ativo = false`); **409** na API se houver voluntário vinculado |
| Vínculo | Usado em **Cadastrar voluntários** (horários por departamento) |

Programa: `departamentos` — atalho **Cadastrar departamentos** na Home (módulo **Formulários**). O filtro por departamento na lista de voluntários exige permissão de **consultar** departamentos.

### Cadastro de cursos

Telas: `mobile/lib/screens/cursos/` (`cursos_list_screen.dart`, `curso_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Código | Gerado na API ao criar; somente leitura na edição |
| Descrição | Campo editável |
| Auditoria | Bloco padrão na edição — ver [Bloco de auditoria nas telas](#bloco-de-auditoria-nas-telas) |
| Exclusão | Desativa (`DELETE` → `ativo = false`) |

Programa: `cursos` — atalho **Cadastrar cursos** na Home (módulo **Formulários**).

### Cadastro de Alunos

Telas: `mobile/lib/screens/alunos/` (`alunos_list_screen.dart`, `aluno_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Lista | Pesquisa por **nome** e **CPF**; filtro **Inativos**; card: **1ª linha** = nome (+ rótulo Inativo); **2ª linha** = CPF, data de nascimento e idade na mesma linha (`Wrap`); dados de `GET /alunos` (sem joins); desativação com confirmação |
| Formulário | Tela única: nome, nome social, estado civil, RG, órgão expedidor, **data de expedição do RG**, CPF, data de nascimento, **idade** (somente leitura), nacionalidade, naturalidade (`AppSearchableSelectField`), nome da mãe/pai, escolaridade (`AppSearchableSelectField`), última escola; seção **Endereço e contato**: endereço, número, bairro, CEP, cidade (`AppSearchableSelectField`), telefone, celular, telefone recado, e-mail |
| Inclusão (Novo) | Formulário abre **imediatamente** — não carrega cidades/escolaridades no `initState`; ao tocar em naturalidade, escolaridade ou cidade, `onBeforeOpen` dispara `GET /cidades` + `GET /escolaridades` em paralelo (cache na sessão da tela) |
| Edição | Lista chama `GET /alunos/:id` antes do form; seletores exibem rótulo salvo (`selectedLabel`) até as listas carregarem |
| Auditoria | Bloco padrão na edição — ver [Bloco de auditoria nas telas](#bloco-de-auditoria-nas-telas) |

Constantes: `estado_civil_voluntario.dart` (listbox). Utilitário: `idade.dart` (`calcularIdadeFromDataBr`).

Programa: `alunos` — atalho **Cadastro de Alunos** na Home (módulo **Formulários**).

### Cadastro de Turmas

Telas: `mobile/lib/screens/turmas/` (`turmas_list_screen.dart`, `turma_form_screen.dart`)

Pesquisa de curso (reutilizável no formulário): `mobile/lib/screens/cursos/cursos_search_screen.dart`.

| Comportamento | Descrição |
|---------------|-----------|
| Lista | Filtro **Curso** no topo (`DropdownButtonFormField`: **Todos os cursos** ou curso ativo; recarrega com `GET /turmas?cursoCodigo=`); turmas ativas por padrão; filtro **Inativos** na AppBar; card com código, nome, curso, período e situação; **FAB** **Novo**; desativação com confirmação (**409** se houver inscrições ativas) |
| Formulário | Código somente leitura na edição; **nome**; **curso** via **Pesquisar**; **período** (Manhã/Tarde/Noite); **situação** (Aberta/Fechada); auditoria na edição; **409** da API se já existir turma aberta no mesmo curso + período |

Constantes: `periodo_inscricao.dart`, `situacao_turma.dart`. Programa: `turmas` — atalho **Cadastro de Turmas** na Home (módulo **Formulários**).

### Inscrição em curso

Telas: `mobile/lib/screens/inscricoes/` (`inscricoes_list_screen.dart`, `inscricao_form_screen.dart`, abas `inscricao_informacoes_gerais_tab.dart`, `inscricao_renda_familiar_tab.dart`)

Pesquisa de vínculos (reutilizável): `mobile/lib/screens/alunos/alunos_search_screen.dart` (nome e/ou CPF); `mobile/lib/screens/cursos/cursos_search_screen.dart` (descrição do curso); `mobile/lib/screens/turmas/turmas_search_screen.dart` (nome da turma e/ou nome do curso; na **inclusão** do formulário, somente turmas **abertas**).

| Comportamento | Descrição |
|---------------|-----------|
| Lista | Filtros **Aluno**, **Curso** e **Turma** no topo (campo somente leitura + ícone **Pesquisar** ao lado; **Limpar** por filtro; **Buscar** e **Limpar filtros**); **ao abrir não carrega registros** — exige ao menos **um** filtro preenchido para habilitar **Buscar**; filtro **Inativos** na AppBar (só recarrega se já houve busca); card em **uma linha** (rolagem horizontal se necessário): labels em **negrito**, **Nome** do aluno com fonte maior; campos **Nome**, **CPF**, **Curso**, **Turma**, **Data de inscrição**, **Período**; após o período, ** - MATRICULADO** ou ** - Matricula Cancelada** (negrito) quando aplicável; **FAB** **Novo**; ícones **Alterar** / **Desativar** (SVG); toque no card **não** abre edição |
| Formulário — cabeçalho | **Código** somente leitura na edição; campos **Aluno** e **Turma** com botão **Pesquisar** — aluno: `GET /alunos`; turma: `GET /turmas` (inclusão filtra `situacao=ABERTA`) |
| Aba **Informações Gerais** | **Data de inscrição** (`dtCurso` na API) pré-preenchida com a data de hoje na **inclusão** (`dataBrHojeCurta()`), editável; checkboxes condicionais: SENAC/SENAI, encaminhamento (órgão + telefone), necessidade especial; **Faz acompanhamento médico**; **Toma medicação** → **Quais medicações**; vacinação e alergias |
| Aba **Renda Familiar** | Linhas dinâmicas (nome, idade, renda, parentesco, profissão) — sem vínculo com assistidos; campo **Renda** com digitação livre e formatação moeda BR (2 decimais) ao sair do campo (`formatarMoedaBrNoController`); **Renda Per Capita R$** no rodapé (soma ÷ quantidade de linhas); foco independente por campo |
| Gravação | Validação manual em `_validarAntesDeSalvar` (data, período, telefone de encaminhamento, nome em linhas de renda parcialmente preenchidas) — evita falha do `Form` com abas do `TabBarView`; em erro, alterna para a aba correspondente |
| Edição | Lista chama `GET /inscricoes/:id` antes do form; `AuditoriaSection` acima do botão Salvar (padrão das demais telas de cadastro) |
| Exclusão | Desativa (`DELETE` → `ativo = false`) |

Constantes: `periodo_inscricao.dart`. Utilitários: `moeda_br.dart` (`parseMoedaBr`, `formatMoedaBr`, `formatarMoedaBrNoController`); `data_br_formatter.dart` (`validateDataBr`); `data_br_hoje.dart` (`dataBrHojeCurta` na data de inscrição na inclusão).

Programa: `inscricoes` — atalho **Inscrição em curso** na Home (módulo **Formulários**).

### Matricular Alunos no Curso

Tela: `mobile/lib/screens/matricula/matricula_alunos_screen.dart`

| Comportamento | Descrição |
|---------------|-----------|
| Cabeçalho | **Quantidade de vagas**; **Turma** via **Pesquisar** (`turmas_search_screen.dart`); **Data da matrícula** (pré-preenchida com hoje — `dataBrHojeCurta()`); botão **Carregar candidatos** (desabilitado até vagas e turma preenchidos — sem chamada à API ao abrir a tela) |
| Lista | Uma linha por candidato (rolagem horizontal): checkbox **Matricular** (ou **Matriculado**, desabilitado, se já matriculado), **Nome**, **Idade**, **Escolaridade**, **Órgão encaminhamento**; ordenação da API (encaminhamento → renda per capita); **não** lista inscrições com matrícula cancelada na turma |
| Seleção | Pré-marca candidatos **não matriculados** até preencher vagas disponíveis; contador **A matricular** (só novos); limite = vagas − matriculados ativos; candidato já matriculado: checkbox marcado, rótulo **Matriculado**, desabilitado; se `totalMatriculados >= vagas`, bloqueia novas seleções |
| Gravação | `POST /inscricoes/matricula` envia apenas IDs **novos** (já matriculados ignorados); turma, data da matrícula (`dtInicioCurso` na API) e vagas; **400** se algum aluno teve matrícula cancelada nesta turma |
| PDF | Ícone no AppBar quando `totalMatriculados > 0` após **Carregar candidatos**; gera lista via `GET /inscricoes/cancelamento-matricula/matriculados` — ver [relatorios.md §7](./relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado) |

Programa: `matricula_alunos` — atalho **Matricular Alunos no Curso** na Home (módulo **Formulários**). Liberar em **Liberação de acesso**.

### Cancelar Matrícula de Alunos no Curso

Tela: `mobile/lib/screens/cancelamento_matricula/cancelamento_matricula_alunos_screen.dart`

| Comportamento | Descrição |
|---------------|-----------|
| Cabeçalho | **Turma** via **Pesquisar** (`turmas_search_screen.dart`); botão **Carregar alunos matriculados** (sem chamada à API ao abrir a tela) |
| Lista | Uma linha por aluno matriculado (rolagem horizontal): checkbox **Cancelar**, **Nome**, **Data da matrícula**, **Idade**, **Escolaridade**, **Órgão encaminhamento**; ordenação por nome (API) |
| Seleção | Checkboxes livres; contador **A cancelar** |
| Gravação | `POST /inscricoes/cancelamento-matricula` com `turmaCodigo` e `inscricaoIds` selecionados; grava `matriculaCancelada`, auditoria de cancelamento e `matriculado=false` |
| PDF | Ícone no AppBar quando há matriculados após **Carregar alunos matriculados**; usa os dados já carregados na tela — ver [relatorios.md §7](./relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado) |

Programa: `cancelamento_matricula_alunos` — atalho **Cancelar Matrícula de Alunos no Curso** na Home (módulo **Formulários**). Liberar em **Liberação de acesso**.

### Atendimento de Alunos

Tela: `mobile/lib/screens/atendimento_alunos/atendimento_alunos_screen.dart`

Pesquisa de alunos: `mobile/lib/screens/atendimento_alunos/alunos_matriculados_search_screen.dart` (nome e/ou CPF; exige turma selecionada; `GET /inscricao-atendimentos/alunos-matriculados` — retorna matriculados **e** com matrícula cancelada; badge **Matrícula cancelada** na lista).

| Área | Comportamento |
|------|----------------|
| Filtros | **Turma** via **Pesquisar** (`turmas_search_screen.dart`); **Aluno** via **Pesquisar**; **Carregar atendimentos** (localiza inscrição ativa na turma — **não** exige matrícula ativa) |
| Lista | Uma linha por atendimento: **Data** + **Atendimento** (resumo 50 caracteres); ícones **Alterar** / **Excluir** (SVG); histórico visível mesmo com matrícula cancelada |
| Novo atendimento | Somente se `matriculado=true` e `matriculaCancelada=false`; aviso em laranja quando matrícula cancelada; formulário de **Novo atendimento** oculto nesse caso |
| Alterar / excluir | Permitido com matrícula cancelada (desde que inscrição ativa) |
| Novo / alterar (form) | **Data do atendimento** (`dataBrHojeCurta()` na inclusão); **Descrição** até 2000 caracteres; botão **Registrar atendimento** ou **Salvar alteração** |
| Exclusão | Diálogo de confirmação; `DELETE` físico na API |

Programa: `atendimento_alunos` — atalho **Atendimento de Alunos** na Home (módulo **Formulários**).

### Relatório de Alunos da Turma

Tela: `mobile/lib/screens/relatorio_alunos_turma/relatorio_alunos_turma_screen.dart`

| Área | Comportamento |
|------|----------------|
| Carga inicial | Ao abrir, carrega cursos via `GET /inscricoes/relatorio-alunos-turma/cursos` (indicador até concluir); formulário só aparece com a lista pronta |
| **Curso** | **Todos os cursos** ou curso específico (dropdown) |
| **Turma** | Desabilitada com **Todos os cursos**; com curso específico: **Todas as turmas** ou turma (`GET /inscricoes/relatorio-alunos-turma/turmas?cursoCodigo=`); ao sair do foco do **Curso** com curso selecionado, foco vai para **Turma** |
| **Situação** | Matriculados / Matrículas canceladas / A matricular / Todas as opções |
| **Tipo de relatório** | **Resumido** (PDF retrato) ou **Detalhado** (PDF paisagem) |
| Gerar | **Gerar relatório** → `GET /inscricoes/relatorio-alunos-turma`; prévia com contagem de turmas e resumo por turma |
| PDF | Ícone no AppBar após gerar; visualizar ou exportar — ver [relatorios.md §8](./relatorios.md#8-relatório-de-alunos-da-turma-implementado) |

Constantes: `relatorio_alunos_turma.dart` (`SituacaoRelatorioAlunos`, `TipoRelatorioAlunosTurma`). Gerador: `relatorio_alunos_turma_pdf.dart`.

Programa: `relatorio_alunos_turma` — atalho **Relatório de Alunos da Turma** na Home (módulo **Relatórios**, submódulo **IEFA** por padrão). Liberar em **Liberação de acesso** (consultar).

### Submódulos de relatórios

Telas: `mobile/lib/screens/relatorio_submodulos/` (`relatorio_submodulos_list_screen.dart`, `relatorio_submodulo_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Programa | `relatorio_submodulos` — atalho na Home (módulo **Administração**) |
| Campos | **Código** (imutável após criar), **nome**, **descrição** (opcional), **ordem**, **ativo** |
| Listagem | Ordenada por `ordem` e nome; filtro **Inativos** |
| Exclusão | **Física** (`DELETE`); **409** se existir programa vinculado |
| Consulta | `GET /relatorio-submodulos` — catálogo para novos relatórios (não depende de convenção no deploy) |
| Auditoria | Bloco padrão na edição |

**Uso com programas:** em **Programas do sistema**, ao vincular um programa ao módulo **Relatórios** (`codigo` 3), o formulário exige **Submódulo de relatório** (dropdown dos submódulos ativos).

**Home:** no módulo **Relatórios**, chips horizontais de **submódulo** (inclui **Todos**) filtram os atalhos liberados; programas sem submódulo aparecem só em **Todos**.

Constante: `mobile/lib/constants/modulo_relatorios.dart` (`moduloRelatoriosCodigo = 3`).

### Cadastro de voluntários

Telas: `mobile/lib/screens/voluntarios/` (`voluntarios_list_screen.dart`, `voluntario_form_screen.dart`)

| Comportamento | Descrição |
|---------------|-----------|
| Código | Gerado na API ao criar; somente leitura na edição |
| Pesquisa | **Nome** (busca em nome completo e nome no crachá), **CPF** e **Departamento** (`GET ?nome=`, `?cpf=`, `?departamentoCodigo=`) |
| Nome | Nome completo (obrigatório) |
| Nome no Crachá | Nome no crachá (obrigatório); título principal na listagem; subtítulo se diferente do nome |
| Estado civil | Listbox: Casado(a), Divorciado(a), Separado(a), Solteiro(a), Viúvo(a) |
| Município | `AppSearchableSelectField` com `cidades.codigo` (ativos) |
| Bairro | Texto livre (não usa cadastro de bairros) |
| Contribuição | Valor, dia de vencimento (“Qual o melhor dia de Vencimento?”), anos no centro |
| Ficha médica | Até 1000 caracteres |
| Exclusão | Desativa (`DELETE` → `ativo = false`) |
| Departamentos | Na **edição**, widget `VoluntarioDepartamentoHorariosEditor`: departamento, dia da semana (listbox), hora início/término; **permite repetir** o mesmo departamento |
| Horário (UI) | Digite `0800` ou `08:00`; ao sair do campo formata para `HH:mm` (`hora_formatter.dart`) |
| Dialog vínculo (horários) | **Enter** em hora início → hora término → **Salvar** (`AppFormTextField` + `FormEnterFocus` em `voluntario_departamento_horarios_editor.dart`) |
| Inclusão | Vínculos só após salvar o voluntário (FAB **Novo** na seção) |
| Tecla **Enter** | Ver [cadeia Enter — voluntário](#formulários--tecla-enter) abaixo |
| Auditoria | Bloco padrão na edição — ver [Bloco de auditoria nas telas](#bloco-de-auditoria-nas-telas) |

Programa: `voluntarios` — atalho **Cadastrar voluntários** na Home (módulo **Formulários**).

Arquivos: `mobile/lib/screens/voluntarios/`, `mobile/lib/widgets/voluntario_departamento_horarios_editor.dart`, `mobile/lib/constants/estado_civil_voluntario.dart`, `mobile/lib/constants/dia_semana.dart`.

### Cadastro de perguntas (lista)

Tela: `mobile/lib/screens/perguntas/perguntas_list_screen.dart`

| Comportamento | Descrição |
|---------------|-----------|
| Filtro inicial | `DropdownButtonFormField` **Tipo de formulário** no topo da tela (opção **Todos** + tipos de `GET /tipos-formulario`) |
| Recarga | Ao mudar o filtro, lista recarrega com `GET /perguntas?tipoFormularioId=…` (omitido quando **Todos**) |
| Indicador | `LinearProgressIndicator` abaixo do filtro durante a busca |
| Lista vazia | Mensagem específica quando o tipo selecionado não tem perguntas |
| Atualizar | **Puxar para atualizar** na lista mantém o filtro atual |

O padrão de UX é o mesmo da **Consulta de respostas** (`submissoes_list_screen.dart`).

### Pesquisa de assistidos (reutilizável)

Tela: `PessoasSearchScreen` — `mobile/lib/screens/pessoas/pessoas_search_screen.dart` (rótulos na UI: **assistido**)

Três campos independentes:

| Campo | Comportamento |
|-------|----------------|
| Nome | Busca parcial (case insensitive) |
| CPF | Máscara `000.000.000-00`; envia só dígitos à API |
| RG | Máscara `00.000.000-0`; envia sem pontuação à API |

Critérios preenchidos são combinados com **AND**. Botões **Pesquisar** e **Limpar** (ambos em `Expanded` no `Row` — evita erro de layout no Chrome).

```dart
final assistido = await PessoasSearchScreen.select(
  context,
  args: PessoasSearchArgs(
    title: 'Selecionar assistido',
    subtitle: 'Opcional',
    onlyAtivas: true,
  ),
);
```

API: `GET /pessoas?nome=...&cpf=...&rg=...`. Usada no **lançamento**, na **entrevista com o assistido** e na lista de assistidos.

### Entrevista com o Assistido

Telas: `mobile/lib/screens/entrevista_assistido/`  
Programa: `entrevista_assistido` — atalho na Home (módulo **Formulários**).

```
1. Home → Entrevista com o Assistido (lista)
2. Buscar por nome e/ou CPF do assistido (opcional) → lista de entrevistas
3. Toque no card → consulta somente leitura (exige podeConsultar) → ícone **PDF** no AppBar (visualizar / baixar ficha)
4. Ícone alterar → formulário com dados carregados → PUT (exige podeAlterar)
5. Ícone excluir → confirmação → DELETE (exige podeExcluir)
6. FAB Nova → selecionar assistido → preencher abas → POST (exige podeIncluir)
7. Abas: Assistência, Programas Sociais, Composição Familiar, Trabalho e Renda, Condições Educacionais da Família, Condições de Saúde da Família
```

#### Aba Programas Sociais

| Bloco | Campos (checkbox) | Observação |
|-------|-------------------|------------|
| Programas | Bolsa Família, PETI, BPC, Outros Programas | Layout em duas colunas; **Outros Programas** exige texto (até 30 caracteres) |
| Órgãos | CRAS, CENTRO POP, CONSELHO TUTELAR, UBS, CREAS, CAPS, CRAF (Secretaria da Mulher), Outros | Texto descritivo *"A Família é atendida por algum órgão ?"*; **Outros** exige texto (até 30 caracteres) |

Tela: `entrevista_programas_sociais_tab.dart`. Dados em `entrevistas_assistido` (objeto `programasSociais` na API).

#### Data da entrevista (cabeçalho)

| Comportamento | Descrição |
|---------------|-----------|
| **Exibição** | Preferência **dd/mm/aaaa** (hint e valor inicial com ano de 4 dígitos via `dataBrHoje4Anos()`) |
| **Digitação** | Aceita `dd/mm/aa` ou `dd/mm/aaaa` durante a edição |
| **Ao sair do campo** | `formatarDataBrExibicao4Anos` expande ano de 2 para 4 dígitos (ex.: `18/05/26` → `18/05/2026`) |
| **Envio** | `normalizarDataBr` no POST/PUT (API aceita ambos os formatos) |

Utilitários: `mobile/lib/utils/data_br_formatter.dart`, `data_br_hoje.dart`.

#### Aba Trabalho e Renda — totais e campos monetários

| Conceito | Regra no app |
|----------|----------------|
| **Renda total** | Soma de benefício social + renda mensal de cada linha em `condicoesTrabalho` (independente de quem está na composição) |
| **Renda per capita** | `rendaTotal ÷ N`, onde `N` = linhas da **Composição Familiar** com `nome` preenchido (`ComposicaoFamiliarLinha.preenchida`). **Não** inclui o assistido. Se `N = 0`, exibe `R$ 0,00` |
| **Texto de apoio** | *"Base: N integrante(s) na composição familiar"* |
| **Campos monetários** | `Vr. benefício social` e `Renda mensal`: prefixo `R$`; hint `0,00`; digitação **livre** (apenas dígitos, vírgula e ponto) |
| **Formatação** | Ao sair do campo (`onTapOutside` / Enter) e ao **Salvar**: `formatarMoedaBrNoController` → ex.: `2500` vira `2.500,00` |
| **Valor inicial** | Novas linhas: `0,00`; carga da API via `formatMoedaBr(parseMoedaBr(...))` |
| **Persistência** | `parseMoedaBr` no envio; API grava `decimal` |

Utilitários: `formatMoedaBr` / `parseMoedaBr` / `formatarMoedaBrNoController` em `mobile/lib/utils/moeda_br.dart`. A classe `MoedaBrFormatter` (formatação a cada tecla) **não** é usada na entrevista — ver comentário no arquivo.

#### Aba Condições Educacionais da Família

| Campo | UI |
|-------|-----|
| Nome | Dropdown (assistido + composição); ao incluir na composição, linha vinculada com nome sincronizado |
| Idade | Numérico 0–150 |
| Escolaridade | Lista (`GET /escolaridades?ativo=true` — cadastro **Escolaridades**) |
| Sabe Ler e Escrever / Frequenta a Escola | `FilterChip` (tags) |

Tela: `entrevista_condicao_educacional_tab.dart`. Modelo: `entrevista_condicao_educacional.dart` (`escolaridadeCodigo`). Cadastro: `screens/escolaridades/`.

#### Aba Condições de Saúde da Família

**Bloco deficiência** (vários registros):

- Texto: *"Caso haja presença de integrante com deficiência na família, preencha o quadro abaixo"*
- Nome (dropdown), **Tipos_Deficiencia** (lista), checkbox **Necessita de Cuidados Constantes**, campo **Quem é o cuidador ?**

**Questionário** (após os registros de deficiência), com listas Sim/Não (`RespostaSimNao`):

- Remédios controlados para transtornos mentais → se Sim, campo **Quais**
- Uso abusivo de álcool
- Uso abusivo de drogas → se Sim, campo **Quais**
- **Tem gestante na família?** (`temGestante` em `saudeFamilia`) → se **Sim**: bloco de cards **Gestante 1**, **Gestante 2**, … com botão **Adicionar gestante**; se **Não**, a lista é limpa
- Cada gestante: **Nome** (dropdown assistido + composição), **Meses de gestação** (0–10), **Iniciou pré-natal** (Sim/Não)
- Ao salvar com `temGestante = Sim`, é obrigatório ao menos um registro completo em `gestantesFamilia`

Tela: `entrevista_condicao_saude_tab.dart`. Modelos: `entrevista_deficiencia_familiar.dart`, `entrevista_gestante_familiar.dart`, `entrevista_saude_familia.dart` (apenas pergunta `temGestante` e demais itens do questionário). Constantes: `tipo_deficiencia_familiar.dart`, `resposta_sim_nao.dart`.

Arquivos principais:

| Arquivo | Função |
|---------|--------|
| `entrevista_assistido_screen.dart` | Cabeçalho (assistido + data + **auditoria** na edição/consulta), `TabBar` com 6 abas, botão Salvar |
| `entrevista_programas_sociais_tab.dart` | Programas sociais e órgãos de atendimento |
| `entrevista_composicao_familiar_tab.dart` | Lista dinâmica de integrantes |
| `entrevista_condicao_trabalho_tab.dart` | Condições de trabalho, totais de renda |
| `entrevista_condicao_educacional_tab.dart` | Condições educacionais |
| `entrevista_condicao_saude_tab.dart` | Deficiências + questionário de saúde |
| `entrevista_form_linhas.dart` | Linhas dinâmicas: `ComposicaoFamiliarLinha`, `CondicaoTrabalhoLinha`, `CondicaoEducacionalLinha`, `DeficienciaFamiliarLinha`, **`GestanteFamiliarLinha`**, `SaudeFamiliaForm` |
| `models/entrevista_*.dart` | Serialização para API (incl. `entrevista_gestante_familiar.dart`, `entrevista_programas_sociais.dart`) |
| `constants/ocupacao_familiar.dart`, `tipo_deficiencia_familiar.dart`, `resposta_sim_nao.dart` | Enums e rótulos (espelho do backend) |
| `utils/moeda_br.dart` | Parse/format BR nos campos monetários |

#### PDF da entrevista (ficha institucional)

| Item | Detalhe |
|------|---------|
| **Quando** | Tela **Consultar entrevista** (`readOnly: true`) |
| **UI** | Ícone PDF no AppBar → Visualizar ou Baixar/compartilhar |
| **Gerador** | `entrevista_pdf.dart`, `entrevista_layout_config.dart`, `entrevista_pdf_field_resolver.dart`, `pdf_fonts.dart`, `pdf_page_number.dart` (numeração no canto superior direito) |
| **Molde** | `mobile/assets/relatorios/entrevista_assistido_v1.yaml` + PDF/PNG de fundo por página |
| **Dados** | Recarrega `GET /entrevistas-assistido/:id` ao gerar; mescla `programasSociais` da tela; assistido completo no objeto `pessoa` da API |
| **Fontes / numeração** | Open Sans + `Pág. N` no canto superior direito — [relatorios.md](./relatorios.md) §11 e §12 |
| **Marcadores** | `forma.*`, `programas.*`, etc.: imprime **"X"** só se o checkbox estiver marcado na entrevista |
| **Gestantes no PDF** | `gestante.linha1` … `linha5` conforme `gestantesFamilia` (ordem de `ordem`) |
| **Booleanos Sim/Não** | Duas chaves no YAML (`.SIM` / `.NAO`) para tags educacionais, cuidados, questionário e pré-natal |

Coordenadas e chaves do mapa: [relatorios.md](./relatorios.md) §6 e [mobile/assets/relatorios/README.md](../mobile/assets/relatorios/README.md).

Após alterar o YAML, o resolvedor ou os fundos em `assets/relatorios/`, use **restart completo** do app (`R`), não só hot reload.

### Consulta de respostas e PDF

Telas: `mobile/lib/screens/submissoes/`  
Utilitários PDF: `submissao_pdf.dart`, `pdf_fonts.dart`, `submissao_pdf_delivery*.dart`  
Estratégia completa (fluxo vs layout fixo por pergunta): **[relatorios.md](./relatorios.md)** (§11 numeração, §12 fontes Unicode)

```
1. Home → módulo Formulários → Consulta de respostas
2. Filtrar por tipo de formulário (opcional), nome e/ou CPF do assistido
3. Buscar → lista de lançamentos (data, assistido, quantidade de respostas)
4. Toque no item → detalhe com perguntas numeradas, valores e bloco **Auditoria** (inclusão/alteração com `nomeUsuario` e nome completo)
5. Ícone PDF no AppBar:
   - Visualizar PDF (nova aba no Chrome; visualizador no mobile/desktop)
   - Baixar / compartilhar PDF
```

**PDF atual (implementado — relatório em fluxo):** cabeçalho (tipo de formulário), assistido, CPF, data do envio, respostas em **ordem de cadastro** (pergunta + valor compactos: valor em **uma linha**, exceto `TEXTO` com texto integral; uma linha em branco entre perguntas), rodapé com data de geração e **número da página** (`Pág. N`) no canto superior direito (`pdf_page_number.dart`). Novas perguntas entram automaticamente; **não** há posição fixa na folha.

**PDF institucional fixo (submissões — planejado):** molde com fundo + mapa `perguntaId` por tipo de formulário. A **entrevista** já usa layout fixo — ver [relatorios.md](./relatorios.md) §6.

**Plataformas:**

| Plataforma | Entrega do PDF |
|------------|----------------|
| Chrome / Web | Download ou abertura via `package:web` (sem plugin nativo `printing`) |
| Android / iOS / desktop | `printing` (`sharePdf` / `layoutPdf`) |

Requer permissão no programa `submissoes` (qualquer flag para abrir a consulta; exportar segue a mesma tela).

Opções de lista **inativas** aparecem no detalhe com sufixo `(opção inativa)` quando aplicável.

### Cadastro de pergunta — tipo TEXTO

Tela: `mobile/lib/screens/perguntas/pergunta_form_screen.dart`  
Constantes: `mobile/lib/constants/campo_texto.dart` (alinhadas ao backend)

| Campo na UI | Descrição |
|-------------|-----------|
| **Tamanho do texto (caracteres)** | `tamanhoCampo` enviado à API (1–5000); padrão sugerido **100** em pergunta nova |
| **Linhas no lançamento** | `linhasCampo` (1–20); define `minLines`/`maxLines` do campo na tela de lançamento; padrão sugerido **3** |

Na lista de perguntas, perguntas `TEXTO` exibem chip com caracteres e linhas (ex.: `250 chars, 3 linha(s)`).

No **lançamento** (`campo_input.dart`, `respostaOpcional: true`): `maxLength` = `tamanhoCampo`; altura = `linhasCampo`; campos vazios são aceitos. Com **mais de 1 linha**, o campo não entra na cadeia da tecla **Enter** (use Tab ou toque).

### Cadastro de pergunta — tipo LISTA

No formulário de pergunta, ao escolher **Lista (seleção)**:

- Editor de opções com rótulo e switch **Ativa/Inativa**
- Botão **Adicionar opção** (sem excluir opções existentes)
- Campo **Ordem** sugerido automaticamente em pergunta nova

### Pesquisa de assistidos — CPF/RG no cadastro

`PessoaFormScreen` usa `CpfFormatter` e `RgFormatter`; gravação via `normalizeCpf` / `normalizeRg`. Exibição em listas usa `cpfExibicao` e `rgExibicao`.

### Cadastro de assistido — endereço (bairro e município)

Telas: `mobile/lib/screens/pessoas/pessoa_form_screen.dart`  
Widget: `mobile/lib/widgets/app_searchable_select_field.dart` (`AppSearchableSelectField`)

| Comportamento | Descrição |
|---------------|-----------|
| Seleção | Painel inferior com campo **Pesquisar** e lista filtrada |
| Ordenação | Bairros por **nome** (A–Z); municípios por **nome** e UF |
| Cadastrar no seletor | Botão **Cadastrar bairro** / **Cadastrar município** só se `podeIncluir` em `bairros` / `cidades`; abre o formulário respectivo, recarrega a lista e seleciona o novo código |
| Retorno do formulário | `BairroFormScreen` / `CidadeFormScreen` devolvem o objeto criado no `Navigator.pop` (edição continua retornando `true`) |

### Listagem de assistidos

`PessoasListScreen` usa `PessoaTileBody` (`mobile/lib/widgets/pessoa_tile.dart`). Além de nome, CPF, RG, nascimento e nome social, exibe **Mãe:** *nome da mãe* quando `nomeMae` estiver preenchido.

### Ações nas listas

- Ícones **alterar** e **excluir** (imagens SVG em `assets/images/`) — área de toque 48×48px.
- Cada ícone só aparece se o usuário tiver `podeAlterar` ou `podeExcluir` no programa da tela.
- O FAB **Novo** só aparece com `podeIncluir`.
- Alterar abre o formulário de edição; excluir **remove o registro do banco** (com confirmação).
- Toque no card **não** abre edição (somente pelos ícones).
- O campo `ativo` ainda existe para ocultar itens em listagens/lançamento sem apagar do banco.

### Fluxo de lançamento

```
1. Home → Responder Questionários
2. Escolher tipo de formulário (ex.: "Admissão")
3. Pesquisar e selecionar o assistido (campos nome, CPF ou RG)
4. Preencher os campos desejados (nenhuma pergunta é obrigatória)
5. Revisar e enviar — só perguntas com resposta entram no `POST /submissoes`
6. Confirmação lista apenas respostas preenchidas; envio sem nenhuma resposta é permitido
```

| Regra | Comportamento |
|-------|----------------|
| Campo vazio | Não bloqueia envio; validação só se o usuário começou a preencher (formato inválido) |
| API | `respostas` contém somente itens com valor; array pode ser vazio |

### Formulários — tecla Enter

Em telas de cadastro, pesquisa e no lançamento, **Enter** avança para o próximo campo de texto; no último campo, o foco vai para o botão principal (**Salvar**, **Criar**, **Pesquisar**, **Buscar** ou **Enviar**).

| Componente | Arquivo | Papel |
|------------|---------|--------|
| `FormEnterFocus` | `mobile/lib/utils/form_enter_focus.dart` | Lista de `FocusNode` + `submitFocusNode`; `onSubmitted` tenta `requestFocus` **imediatamente** e repete no **próximo frame** (melhor resposta no Chrome/Web) |
| `AppFormTextField` | `mobile/lib/widgets/app_form_text_field.dart` | `TextFormField` com `textInputAction` + `onFieldSubmitted` / teclado físico (Enter) |
| `AppSearchableSelectField` | `mobile/lib/widgets/app_searchable_select_field.dart` | Opcional: `focusNode`, `onEnterAdvance`, `selectedLabel` (valor sem opção carregada), `onBeforeOpen` (ex.: carregar cidades antes de abrir o picker — usado no cadastro de alunos) |
| `FormEnterFocus.chainSubmit` | `form_enter_focus.dart` | Campos dinâmicos (ex.: lançamento de perguntas) |

Catálogos simples (curso, departamento, escolaridade) usam `TextFormField` direto com `FormEnterFocus` (sem `AppFormTextField`). **Turma** usa nome + pesquisa de curso + dropdowns (período, situação).

| Tela / fluxo | Campos na cadeia Enter |
|--------------|------------------------|
| Login | usuário → senha → Entrar |
| Tipo de formulário | nome → descrição → Salvar/Criar |
| Assistido (cadastro) | nome → nome social → nascimento → CPF → RG → órgão emissor → nome da mãe → nome do pai → NIS → endereço → número → complemento → telefone → telefone 2 → Salvar/Criar (bairro, município, urbano/rural e ativo ficam de fora) |
| **Voluntário (cadastro)** | nome → nome no crachá → empresa → função → **estado civil** (dropdown com foco) → data de nascimento → endereço → número → bairro → CEP → **município** (`AppSearchableSelectField`) → complemento → RG → CPF → CNH → celular → tel. residencial → tel. comercial → e-mail → valor contribuição → dia vencimento → anos no centro → Salvar/Criar (**ficha médica** multiline fica de fora; use Tab) |
| **Voluntário — vínculo departamento** (dialog) | hora início → hora término → Salvar |
| **Cadastro de Alunos** | nome (0) → nome social (1) → RG (2) → órgão expedidor (3) → data expedição RG (4) → CPF (5) → nascimento (6) → nacionalidade (7) → nome da mãe (8) → nome do pai (9) → última escola (10) → endereço (11) → número (12) → bairro (13) → CEP (14) → telefone (15) → celular (16) → telefone recado (17) → e-mail (18) → Salvar/Criar (estado civil, naturalidade, escolaridade e cidade: seletores — use Tab ou toque) |
| Pergunta | enunciado → (tamanho e linhas, se TEXTO) → (opções, se LISTA) → ordem → Salvar/Criar |
| Módulo do sistema | nome → descrição → ordem → Salvar/Criar (código gerado na API; somente leitura na edição) |
| Usuário | login → nome → e-mail → senha → Salvar |
| Tipo de usuário | descrição → Salvar |
| Curso / departamento / escolaridade | descrição → Salvar/Criar |
| Turma (cadastro) | nome → (pesquisar curso) → período → situação → Salvar/Criar |
| Pesquisa de assistidos | nome → CPF → RG → Pesquisar |
| Lista de voluntários | nome → CPF → Pesquisar |
| Lista de alunos | nome → CPF → Pesquisar |
| Lista de inscrições | selecionar ao menos um filtro (aluno / curso / turma) → Buscar |
| Inscrição (formulário) | pesquisar aluno → pesquisar turma (somente abertas na inclusão) → data de inscrição → abas Informações Gerais / Renda |
| Matricular alunos | vagas → pesquisar turma → data da matrícula → Carregar candidatos → marcar Matricular → Gravar (exclui matrícula cancelada) |
| Cancelar matrícula | pesquisar turma → Carregar alunos matriculados → marcar Cancelar → Gravar cancelamento |
| Atendimento de alunos | pesquisar turma → pesquisar aluno → Carregar atendimentos (histórico mesmo cancelado) → Registrar só se matrícula ativa; alterar/excluir na lista |
| Relatório de alunos da turma | curso (opcional turma) → situação → tipo → Gerar relatório → PDF no AppBar |
| Consulta de respostas | nome → CPF → Buscar |
| Responder Questionários (formulário) | campos de texto/número/data por ordem das perguntas → Enviar |

Dropdowns e switches **sem** `focusNode`/`onEnterAdvance` não entram na cadeia automática (use Tab ou toque). No cadastro de **voluntário**, **estado civil** e **município** entram na sequência via foco dedicado. Perguntas **TEXTO** com `linhasCampo > 1` e campos multiline (ex.: ficha médica, enunciado de pergunta) ficam de fora — Enter insere quebra de linha ou use Tab.

### Regras de desenvolvimento (`.cursor/rules/`)

| Arquivo | Conteúdo |
|---------|----------|
| `repositorio-cefa.mdc` | Trabalhar somente em `D:\Projetos\Cursor\Cefa` |
| `sem-delete-cascade.mdc` | Nunca `ON DELETE CASCADE`; bloquear com 409 |
| `tipografia-arial.mdc` | Arial em todas as telas (`AppTheme.fontFamily`) |

### URL da API por plataforma

| Onde roda | `API_BASE_URL` |
|-----------|----------------|
| **Produção (Render)** | `https://cefa-api.onrender.com` |
| Chrome / Web (local) | `http://127.0.0.1:3000` (recomendado no Windows) |
| Android emulador (local) | `http://10.0.2.2:3000` (padrão) |
| iOS simulador (local) | `http://localhost:3000` |
| Celular físico (mesma Wi‑Fi, local) | `http://IP_DO_PC:3000` |

**Local (Chrome):**

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

**Produção (Chrome ou Android):**

```bash
flutter run --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

O app detecta a plataforma quando `--dart-define` não é informado (só URLs locais).

### Autenticação e permissões no app

- Login: `mobile/lib/screens/auth/login_screen.dart`
- Estado: `authProvider` (`mobile/lib/providers/auth_provider.dart`) — mapa `codigo → ProgramaPermissao`
- Token em `shared_preferences`; Dio envia `Authorization: Bearer`; **401** limpa sessão
- `podeAcessar(codigo)`: qualquer flag true → atalho no módulo + entrada na tela (`PermissaoGate`); se `isAdmin`, sempre `true`
- `podeIncluir` / `podeAlterar` / `podeExcluir` / `podeConsultar`: controlam FAB e ícones; admin sempre `true` na UI
- **Tipos de formulário (operacional):** a API filtra `GET /tipos-formulario` — lançamento, perguntas e consulta usam lista já filtrada
- **Cadastro administrativo de tipos:** `listTiposFormulario(todos: true)` na tela **Tipos de formulário**
- **401** em qualquer rota protegida limpa a sessão (Dio interceptor)
- Telas de liberação: `liberacao_tipo_usuario_screen.dart`, `liberacao_usuario_screen.dart` — abas **Programas** (`PermissoesEditor`) e **Tipos de formulário** (`TiposFormularioAcessoEditor`); em **ambas**, aba **Programas** com dropdown **Módulo** (`Todos os módulos` ou filtro por `moduloCodigo`/`moduloNome` de `GET /programas`) — filtro só na UI; **Salvar programas** persiste todas as linhas
- Cadastro de programas: `screens/programas/programas_list_screen.dart`, `programa_form_screen.dart` — acesso pelo ícone na barra de **Módulos do sistema** ou **Novo programa** no formulário do módulo
- Mescla na liberação: `utils/permissao_linhas_merge.dart` — garante linha para cada programa de `GET /programas`
- Constantes de programa: `mobile/lib/auth/programas.dart` (espelho dos códigos em `backend/src/lib/programas.ts`; programas criados só na UI usam o `codigo` definido no formulário)

### Validação dupla

Regras espelhadas no Flutter (`validators/`) e na API (Zod + `lib/campo.ts`) para melhor UX offline e consistência no envio.

### Identidade visual

O app segue a identidade definida em [`IdentidadeGrafica.md`](../IdentidadeGrafica.md):

- Paleta: azul `#1F2A8A`, laranja `#FF8A3D`, azul claro `#E8F1FF`
- Fundo com gradiente vertical; AppBar em faixa azul claro
- CTAs laranja; botões secundários com contorno azul
- Cartões brancos 16px; tipografia **Arial** (obrigatória em todas as telas — ver [`.cursor/rules/tipografia-arial.mdc`](../.cursor/rules/tipografia-arial.mdc))

Implementação: `mobile/lib/theme/app_theme.dart` (`AppTheme.fontFamily`) e `mobile/lib/widgets/` (`AppScaffold`, `AppCard`, `AppButton`, `AppSearchableSelectField`, `AuditoriaSection`, `RecordActionButtons`, `PessoaTile`). Novas telas devem usar o `textTheme` do tema ou `fontFamily: AppTheme.fontFamily` — nunca outra fonte. No Windows/Chrome, Arial é fonte do sistema; em outras plataformas pode ser necessário empacotar `.ttf` no futuro.

Novos formulários de cadastro ou consulta de registro persistido devem reutilizar `AuditoriaSection` com `AuditoriaCampos.fromJson` no modelo — ver [Bloco de auditoria nas telas](#bloco-de-auditoria-nas-telas).

### Programas do sistema e liberação de acesso

**Criar programa**

1. **Módulos do sistema** → ícone de grade (**Programas do sistema**) → **Novo**, ou no formulário do módulo → **Novo programa**.
2. Informar **código** (minúsculas, ex.: `relatorio_extra`), **nome** (texto na liberação) e **módulo** (opcional).
3. Se o módulo for **Relatórios**, selecionar **submódulo** (consulte os existentes em **Submódulos de relatórios** ou `GET /relatorio-submodulos`).
4. Salvar → `POST /programas`. O programa passa a aparecer nos checkboxes do módulo.

**Liberar acesso**

1. **Liberação por tipo** ou **Liberação por usuário** → selecionar tipo/usuário (evite **Administrador** — permissão total).
2. Aba **Programas:** todos os programas de `GET /programas` + flags de `GET …/permissoes` → **Salvar programas**. Use o filtro **Módulo** para reduzir a lista (programas sem módulo vinculado aparecem só em **Todos os módulos**); alterações e **Salvar programas** valem para **todos** os programas em memória, não só os visíveis.
3. Aba **Tipos de formulário:** checklist de todos os tipos (`GET …/tipos-formulario-acesso`) → **Salvar tipos de formulário**. Lista vazia = nenhum tipo nas telas operacionais.

**Cadastro de tipos (administrativo):** `tipos_formulario_list_screen.dart` usa `listTiposFormulario(todos: true)` — lista completa, independente da liberação operacional.

Telas: `mobile/lib/screens/programas/`, `mobile/lib/screens/liberacao/`, `mobile/lib/widgets/tipos_formulario_acesso_editor.dart`. API: [api.md](./api.md), modelo: [modelo-dados.md](./modelo-dados.md).

---
