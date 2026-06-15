# Histórico de evolução

## 7. Histórico de evolução

| Fase | O que foi feito |
|------|-----------------|
| v1 inicial | Perguntas com `SIM_NAO` e `TEXTO_100`; submissões em lote |
| Tipos flexíveis | `INTEIRO`, `DECIMAL`, `TEXTO`, `LOGICO`, `DATA`; `tamanhoCampo` configurável (hoje até 5000; antes até 1000 em `VARCHAR`) |
| Tipo de formulário | Cadastro de tipos; perguntas e submissões vinculadas; filtro ao responder |
| Identidade visual | Tema alinhado ao App Viagens (`IdentidadeGrafica.md`) |
| UX listas | Botões Alterar/Excluir; exclusão permanente sem cascade |
| Infra | Neon como banco; suporte a Chrome para desenvolvimento |
| Pessoas e lançamento | Cadastro de pessoas; submissão com `pessoaId`; fluxo tipo → pesquisa → respostas |
| Pesquisa de pessoas | `PessoasSearchScreen` reutilizável; `GET /pessoas?q=` |
| Exclusão definitiva | `DELETE` físico; sem cascade; 409 se houver vínculos |
| UX formulários | Enter avança campos; ícones SVG nas listas |
| Datas UTC | Correção de “um dia a menos” em nascimento e campos DATA |
| Tipo LISTA | Opções configuráveis; desativar sem excluir; `valor_opcao_id` em respostas |
| Ordem única | `(tipoFormularioId, ordem)` único; sugestão automática no cadastro |
| Consulta respostas | `GET /submissoes`; telas lista e detalhe no app |
| Pesquisa pessoas | Campos separados nome / CPF / RG; máscaras na UI |
| CPF/RG normalizados | Gravação sem formatação; exibição formatada na API e telas |
| Usuários e permissões | Login JWT; tipos de usuário; programas; liberação por tipo/usuário; UI condicional |
| Acesso sem só Consultar | Menu e GET liberados com qualquer flag no programa; ações HTTP seguem flag específica |
| Módulos do sistema | Tabela `modulos_sistema`; Home com filtro; CRUD; vínculo programa ↔ módulo |
| Auth global (fastify-plugin) | JWT e permissões em todas as rotas; correção de 401 após login |
| Consulta + PDF | Detalhe de submissão com exportação PDF (web e mobile) |
| Pergunta TEXTO — linhas e teto | `linhasCampo` (1–20) no cadastro e no lançamento; `valor_texto` → `TEXT`; máx. 5000 caracteres por pergunta |
| Lançamento — respostas opcionais | Perguntas em branco não geram erro; API grava só respostas preenchidas (`respostas` pode ser vazio) |
| PDF submissões — layout e erros | Lista plana + `TextOverflow.span` (evita `TooManyPagesException`); layout compacto; numeração `Pág. N` (`pdf_page_number.dart`) |
| UX pesquisa pessoas | Botões Pesquisar/Limpar com layout corrigido no `Row` |
| Auditoria global | `usuario_*` + `data_hora_*` (UTC) em todas as tabelas; migration `20260518120000_auditoria` |
| Enter em formulários | `FormEnterFocus` em todas as telas de cadastro/pesquisa principais |
| Identidade do produto | Documentação: **Sistema de Auxílio Centro Espírita Francisco de Assis** (*Cefa*) |
| Cidades e bairros | Tabelas `cidades` / `bairros`; programas `cidades` e `bairros`; soft delete; UF `UfBrasil` |
| Pessoa ampliada | Endereço, filiação, NIS, telefones, `urbanoRural`; FK por código de bairro/município |
| Código de município | Campo `cidades.codigo` para referência em pessoas |
| Módulo código numérico | `modulos_sistema.codigo` como `Int` (1 = Formulários, 2 = Administração); migration `20260518170000_modulo_codigo_numerico` |
| Sync não destrutivo | `syncModulos` / `syncProgramas` não sobrescrevem nome de módulo nem vínculo programa↔módulo na UI |
| Código bairro inteiro | `bairros.codigo` e `pessoas.bairro_codigo` como `Int` sequencial automático; migration `20260518180000_bairro_codigo_inteiro` |
| Código município inteiro | `cidades.codigo` e `pessoas.cidade_codigo` como `Int` sequencial automático; migration `20260518190000_cidade_codigo_inteiro` |
| Seletor com pesquisa | `AppSearchableSelectField` para bairro/município no cadastro de pessoa; ordenação alfabética; botão Cadastrar com permissão |
| Enter no cadastro de pessoa | Cadeia `FormEnterFocus` com 14 campos de texto (inclui nome social, filiação, endereço e telefones) |
| Listagem de pessoas | `PessoaTile` exibe nome da mãe quando cadastrado |
| Neon pooler | `pgbouncer=true` na `DATABASE_URL` recomendado após alteração de tipo de colunas |
| Entrevista com o Assistido | Programa `entrevista_assistido`; tabelas `entrevistas_assistido` e filhas; migrations `20260518200000`, `20260518220000` |
| Composição/trabalho na pessoa (revertido) | Dados de família/renda ficam na **entrevista**, não em `POST /pessoas` |
| Entrevista — máscara monetária | `MoedaBrFormatter` em reais + vírgula opcional; exibição `1.234,56`; defaults `0,00` |
| Entrevista — renda per capita | Divisor = apenas integrantes da **Composição Familiar** (nome preenchido); assistido fora da base |
| Entrevista — condições educacionais | Tabela `entrevista_condicao_educacional`; aba com escolaridade e tags; migration `20260518230000` |
| Entrevista — condições de saúde | Tabela `entrevista_deficiencia_familiar` + questionário em `entrevistas_assistido`; migration `20260518240000` |
| Entrevista — data 4 dígitos | Campo data da entrevista: exibição `dd/mm/aaaa`; expansão do ano ao sair do campo |
| Entrevista — moeda ao sair do campo | Campos monetários: digitação livre; `formatarMoedaBrNoController` no blur e no salvar (sem `MoedaBrFormatter` na digitação) |
| Entrevista — PUT sem falhar por timeout | Transação Prisma com limite estendido; `findUniqueOrThrow` removido do fim da mesma transação; tratamento **P2028** → **503** com mensagem amigável |
| Cadastro de perguntas — filtro | Lista com seletor **Tipo de formulário** no topo; `GET /perguntas?tipoFormularioId=` (`perguntas_list_screen.dart`) |
| Documentação — relatórios | [relatorios.md](./relatorios.md): PDF em fluxo (implementado) vs molde fundo + mapa por `perguntaId` (layout fixo; planejado) |
| Entrevista — PDF institucional | Molde YAML + fundo PDF/PNG; gerador `entrevista_pdf.dart`; botão PDF na consulta; `GET /entrevistas-assistido/:id` com pessoa completa |
| UX — foco em formulários | Correção: mesmo `FocusNode` não pode estar no `Focus` pai e no `TextFormField` (`AppFormTextField`, `EntrevistaTextField`, `CampoInput`) |
| Entrevista — Programas Sociais | Nova aba (2ª): programas (Bolsa Família, PETI, BPC, Outros) e órgãos (CRAS, CREAS, etc.); colunas em `entrevistas_assistido`; migration `20260519100000` |
| Entrevista — PDF programas sociais | Chaves `programas.*` no YAML; resolvedor em `entrevista_pdf_field_resolver.dart`; geração recarrega entrevista da API antes do PDF |
| PDF — fontes Unicode | `pdf_fonts.dart` (Open Sans via `PdfGoogleFonts`); evita erro Helvetica com travessão e acentos; usado em `entrevista_pdf.dart` e `submissao_pdf.dart` |
| Entrevista — gestantes múltiplas | Tabela `entrevista_gestante_familiar`; API `gestantesFamilia[]`; UI lista com Adicionar/Remover; migration `20260520100000` |
| Entrevista — PDF gestantes | Chaves `gestante.linhaN.*` no YAML; resolvedor `_gestanteLinha`; legado `saude.gestante*` = 1ª gestante |
| Entrevista — PDF booleanos | Campos lógicos com caixas Sim/Não no molde: sufixos `.SIM` / `.NAO` no YAML (`educacional`, `deficiencia`, `saude`, `gestante`) |
| Documentação — deploy Render | [deploy-render.md](./deploy-render.md): Web Service (`backend/`), Neon/`pgbouncer=true`, `JWT_SECRET`, `ADMIN_INITIAL_PASSWORD`, Flutter `API_BASE_URL` |
| API em produção (Render) | `https://cefa-api.onrender.com` — health, login e app com `--dart-define=API_BASE_URL` documentados em [deploy-render.md](./deploy-render.md) |
| Terminologia Assistido | Conceito de negócio **assistido** na UI e docs; banco/API/código permanecem `pessoas` / `pessoaId`; programa `pessoas` → nome **Cadastrar assistidos**; rótulos em telas, PDF de submissão e mensagens da API |
| Programa Responder Questionários | Menu e liberação de acessos: programa `lancamento` exibe **Responder Questionários** (antes “Lançamento”); código e rota `POST /submissoes` inalterados |
| CRUD de programas | `POST`/`PUT` `/programas`; telas **Programas do sistema** no app; `listProgramasParaPermissoes` na liberação |
| Liberação — lista unificada | App mescla `GET …/permissoes` + `GET /programas`; programas criados na UI aparecem na liberação sem depender só do catálogo fixo |
| Liberação por tipo de formulário | Tabelas `tipos_usuario_tipos_formulario` e `usuarios_tipos_formulario`; `usuarios.override_tipos_formulario`; rotas `…/tipos-formulario-acesso`; filtro em listagens operacionais; migration `20260521100000` |
| Módulo — código automático | `POST /modulos-sistema` sem `codigo` no body; API atribui `max(codigo)+1`; app sem campo Código no cadastro |
| Cadastro de escolaridades | Tabela `escolaridades` (código, descrição, ativo); programa `escolaridades`; FK `escolaridadeCodigo` na entrevista; migration `20260525100000` (seed **Nunca Frequentou Escola**); remove enum `EscolaridadeFamiliar` |
| Cadastro de departamentos | Tabela `departamentos`; programa `departamentos`; CRUD `/departamentos`; migration `20260525110000`; desativação **409** com vínculo |
| Cadastro de voluntários | Tabela `voluntarios`; enum `EstadoCivilVoluntario`; FK `cidadeCodigo`; programa `voluntarios`; CRUD `/voluntarios`; migrations `20260525120000`, `20260525140000` (`nome` + `nomeCracha`) |
| Voluntário × departamento | `voluntario_departamento_horarios`; dia da semana + horários; mesmo voluntário/departamento pode repetir; migration `20260525130000`; UI com máscara de hora |
| Lista de voluntários | Pesquisa por nome (nome + crachá), CPF e departamento (`?departamentoCodigo`) |
| Cadastro de cursos | Tabela `cursos`; programa `cursos`; CRUD `/cursos`; migration `20260525160000` |
| Estado civil — Separado(a) | Enum `EstadoCivilVoluntario` + valor `SEPARADO`; voluntários e alunos; migration `20260525150000` |
| Alunos de Capacitação Profissional | `alunos_capacitacao_profissional` + `aluno_capacitacao_renda_familiar`; enum `TipoCasaAlunoCapacitacao`; programa `alunos_capacitacao`; CRUD `/alunos-capacitacao`; formulário com 3 abas no app; migration `20260525170000` |
| Auditoria na UI (nomes) | API enriquece respostas com `usuario*NomeUsuario` e `usuario*Nome`; app usa `AuditoriaSection` em cadastros, consulta de submissão e entrevista (exibe login + nome completo, não UUID) |
| API — `resposta-api` + auditoria enrich | `backend/src/lib/resposta-api.ts` (`replyMapped` / `replyMappedList`); `auditoria.ts` com `enrichUsuarioMap`; rotas de cadastro retornam nomes de usuário na auditoria |
| Build TypeScript (voluntários / alunos) | Correções em services/rotas: `include` em desativação, `cidadeCodigo` nullable, `ativo` só em update; cast Prisma onde necessário |
| Enter — cadastro de voluntário | Cadeia completa em `voluntario_form_screen.dart` (estado civil + município na sequência); dialog de horários com `AppFormTextField` |
| Enter — `FormEnterFocus` | `onSubmitted` chama `requestFocus` imediatamente e no post-frame (menos “delay” no Chrome/Web) |
| `AppFormTextField` | Alinhado ao padrão de teclado físico da entrevista; `AppSearchableSelectField` com `focusNode` + `onEnterAdvance` opcional |
| Neon — `DATABASE_URL` local | Recomendado `pgbouncer=true` e **sem** `channel_binding=require` no `.env` de desenvolvimento |
| Atendimento médico — planejamento | [`docs/atendimento-medico.md`](./atendimento-medico.md): STT só Android/iOS (texto no banco), JSON vs colunas, checklist antes de implementar; índice em `DOCUMENTACAO.md` |
| Alunos de capacitação — simplificação | Remove abas endereço/adicionais/renda; drop `aluno_capacitacao_renda_familiar`, enum `TipoCasaAlunoCapacitacao` e colunas de endereço/contato/adicionais; formulário único no app; migration `20260609100000` |
| Cadastro de Alunos — rename | Tabela `alunos`; programa `alunos`; rotas `/alunos`; tela **Cadastro de Alunos**; migration `20260609110000` |
| Cadastro de Alunos — endereço e contato | Campos `dtExpedicaoRg`, endereço, CEP, `cidadeCodigo`, telefones e e-mail; migration `20260609120000` |
| Alunos — listagem enxuta na API | `GET /alunos` sem joins nem auditoria (`mapAlunoLista`: `id`, `nome`, `cpf`, `dtNascimento`, `idade`, `ativo`); detalhe completo só em `GET /alunos/:id` |
| Alunos — UX inclusão | Formulário **Novo aluno** abre sem carregar cidades/escolaridades; listas carregadas ao abrir seletor (`onBeforeOpen` em `AppSearchableSelectField`) |
| Alunos — layout da lista | Card: nome na 1ª linha; 2ª linha com CPF, data de nascimento e idade |
| Inscrição em curso | Tabelas `inscricoes_aluno_curso` + `inscricao_renda_familiar`; enum `PeriodoInscricao`; programa `inscricoes`; CRUD `/inscricoes`; formulário com 2 abas no app; migration `20260609130000` |
| Inscrições — listagem alinhada à identidade | FAB **Novo** inferior direito; filtro Inativos na AppBar; botão **Buscar**; ícones SVG alterar/desativar; badge de código no card |
| Inscrições — pesquisa de aluno e curso | Botão **Pesquisar** no formulário; telas `alunos_search_screen.dart` (nome/CPF) e `cursos_search_screen.dart` (nome do curso) |
| Inscrições — medicação | `tomaMedicacao` boolean + `quaisMedicacoes` (independente de `fazAcompanhamentoMedico`); migration `20260609140000` |
| Inscrições — UX formulário | Foco independente nas abas; renda com moeda BR ao sair do campo; validação manual ao gravar (abas `TabBarView`); auditoria com 4 campos somente leitura na edição |
| Inscrições — correção `POST`/`PUT` | `mapInscricao` era `async` e `replyMapped` não aguardava — resposta `{}` e `TypeError` no app ao criar; corrigido: mapper síncrono + `replyMapped`/`replyMappedList` com `await` em mappers assíncronos |
| Turmas | Tabela `turmas` (curso + período + situação Aberta/Fechada); programa `turmas`; CRUD `/turmas`; regra de unicidade de turma aberta por curso/período; inscrição com `turmaCodigo` (remove `cursoCodigo` e `periodo` da tabela); migration `20260611100000` |
| Turmas — filtro na lista | App: dropdown **Curso** no topo da listagem (`GET /turmas?cursoCodigo=`) |
| Inscrições — filtros na lista | App: filtros **Aluno**, **Curso** e **Turma** com ícone pesquisa ao lado do campo; API: `alunoId`, `cursoCodigo`, `turmaCodigo` em `GET /inscricoes` |
| Inscrições — card da lista | Uma linha com labels (negrito); nome do aluno em destaque; rolagem horizontal |
| Inscrições — formulário | Rótulo **Data de inscrição** (`dtCurso`); data de hoje na inclusão; `AuditoriaSection` (sem card) |
| Matrícula de inscrições | Campos `matriculado`, `dtInicioCurso`, `usuarioMatriculaId`, `dataHoraMatricula`; programa `matricula_alunos`; `GET/POST /inscricoes/matricula`; tela com vagas, turma, candidatos ordenados e checkboxes; migration `20260611110000` |
| Matrícula — UX tela | Sem carga automática ao abrir; **Data da matrícula** pré-preenchida (`dataBrHojeCurta()`); **Carregar candidatos** só com vagas + turma; alterar filtros limpa lista |
| Matrícula — checkbox matriculado | Candidato já matriculado: rótulo **Matriculado**, checkbox marcado e desabilitado |
| Matrícula — gravar só novos | `POST /inscricoes/matricula` ignora IDs já matriculados; app envia apenas candidatos marcados com **Matricular**; contador **A matricular** |
| Inscrições — lista obriga filtro | App não lista ao abrir; **Buscar** exige ao menos um filtro (Aluno, Curso ou Turma); **Limpar filtros** zera lista sem nova busca |
| Atendimento de alunos | Tabela `inscricao_atendimentos`; programa `atendimento_alunos`; CRUD `/inscricao-atendimentos`; pesquisa inclui matriculados e cancelados; **`POST`** exige matrícula ativa; histórico consultável após cancelamento; migration `20260611120000` |
| Cancelamento de matrícula | Campos `matriculaCancelada`, `usuarioCancelamentoMatriculaId`, `dataHoraCancelamentoMatricula`; programa `cancelamento_matricula_alunos`; `GET/POST /inscricoes/cancelamento-matricula`; tela com turma + checkboxes **Cancelar**; aluno cancelado não volta à matrícula; migration `20260611130000` |
| Matrícula — regras pós-cancelamento | Candidatos com `matriculaCancelada=true` excluídos da lista; **400** ao tentar matricular novamente na mesma turma |
| Atendimento — regras pós-cancelamento | Listagem/alteração/exclusão de atendimentos sem exigir matrícula ativa; **POST** bloqueado se matrícula cancelada |
| Liberação por usuário — filtro módulo | Aba **Programas**: dropdown **Módulo** filtra a visualização por `moduloCodigo` de `GET /programas`; **Salvar programas** grava todas as linhas |
| Liberação por tipo — filtro módulo | Mesma lógica da liberação por usuário na aba **Programas** (`liberacao_tipo_usuario_screen.dart`) |
| `AppButton` em `Row` | `fullWidth: false` usa `IntrinsicWidth` (evita erro de layout no Flutter Web) |
| Relatório — alunos matriculados | PDF em fluxo (`matriculados_pdf.dart`); ícone no AppBar nas telas **Matricular** e **Cancelar matrícula**; dados de `GET /inscricoes/cancelamento-matricula/matriculados` |
| Relatório — layout e rodapé | Tabela: Nº, nome, idade, data da matrícula, CPF, escolaridade; rodapé com *Documento gerado por {usuário logado} em dd/mm/aaaa às HH:mm*; API de matriculados inclui `alunoCpf` / `alunoCpfFormatado` |
| Inscrições — status no card da lista | Após o período: ** - MATRICULADO** ou ** - Matricula Cancelada** (negrito); `GET /inscricoes` (listagem) retorna `matriculado` e `matriculaCancelada` |
| Home — ordem dos programas | Dentro do módulo selecionado, atalhos ordenados **alfabeticamente** pelo rótulo (`home_screen.dart`) |
| Relatório de Alunos da Turma | Programa `relatorio_alunos_turma`; `GET /inscricoes/relatorio-alunos-turma` (+ `/cursos`, `/turmas`); tela com filtros curso/turma/situação/tipo; PDF resumido (retrato) e detalhado (paisagem) em `relatorio_alunos_turma_pdf.dart` |
| Submódulos de relatórios | Tabela `relatorio_submodulos`; CRUD `/relatorio-submodulos`; módulo **Relatórios** na Home com chips de submódulo; seed **IEFA**; migration `20260615100000` |

---
