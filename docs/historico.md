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

---
