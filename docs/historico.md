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
| Estado civil — Separado(a) | Enum `EstadoCivilVoluntario` + valor `SEPARADO`; voluntários e alunos de capacitação; migration `20260525150000` |
| Alunos de Capacitação Profissional | `alunos_capacitacao_profissional` + `aluno_capacitacao_renda_familiar`; enum `TipoCasaAlunoCapacitacao`; programa `alunos_capacitacao`; CRUD `/alunos-capacitacao`; formulário com 3 abas no app; migration `20260525170000` |

---
