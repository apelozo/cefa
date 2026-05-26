# Solução de problemas

## 10. Solução de problemas

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| Timeout ao salvar | API não está rodando ou URL errada | `npm run dev`; Chrome: `http://127.0.0.1:3000` |
| **Bad Request** ao excluir | Cliente enviava `Content-Type: application/json` em `DELETE` sem corpo; Fastify rejeita | Corrigido no `ApiClient` (DELETE sem Content-Type) |
| Erro ao **editar** | Dropdown sem tipo inativo vinculado | Formulário carrega todos os tipos; PUT com corpo JSON explícito |
| Erro `SegmentedButton` no formulário | Nenhuma opção selecionada em Sim/Não | `emptySelectionAllowed: true` |
| Migration falha | `DATABASE_URL` incorreta | Conferir `.env` e conexão Neon |
| App não conecta no celular | IP incorreto | `flutter run --dart-define=API_BASE_URL=http://SEU_IP:3000` |
| Data salva com **1 dia a menos** | Fuso ao gravar `@db.Date` | Corrigido com UTC em `campo.ts`; reeditar registros antigos |
| **409** ao excluir | Existem perguntas, lançamentos ou respostas vinculados | Esperado; remover vínculos antes ou usar `ativo = false` |
| **409** ao salvar pergunta | Ordem duplicada no mesmo tipo de formulário | Escolher outro número de ordem |
| Erro `contentType` no DELETE | Conflito Dio + header JSON | Corrigido no `ApiClient` (`_deleteOptions`) |
| Texto invertido ao digitar opção LISTA | `setState` recriava controllers a cada tecla | Corrigido: estado local no editor de opções |
| **403** em listagem com permissão só Alterar | Versão antiga exigia `podeConsultar` no GET | Atualizado: GET aceita qualquer permissão no programa |
| Card do menu não aparece com só Alterar/Incluir | Home filtrava só `podeConsultar` | Atualizado: Home usa `podeAcessar` |
| Login falha / token inválido | `JWT_SECRET` diferente entre deploys ou usuário inativo | Conferir `.env`; usar usuário ativo; relogar |
| Não autenticado em todas as rotas | Token ausente ou expirado | Fazer login; reiniciar app após `npm run dev` |
| **401** logo após login (menu/Home) | Plugin de auth encapsulado sem `fastify-plugin` | Corrigido: `auth.ts` usa `fastify-plugin`; reinicie a API |
| **MissingPluginException** ao gerar PDF no Chrome | Pacote `printing` sem implementação nativa na Web | Corrigido: download/abertura via `web` no Chrome; reinicie o app (`R`) |
| **Cannot hit test a render box…** na pesquisa de assistido | `AppButton` com largura infinita fora de `Expanded` em `Row` | Corrigido em `pessoas_search_screen.dart` |
| Menu da Home vazio (não admin) | Nenhuma permissão ou módulo sem programas | Liberar programas; vincular programas ao módulo em Módulos do sistema |
| PDF não baixa no Chrome | Hot reload após adicionar dependências | `flutter run` completo ou hot **restart** (`R`) |
| Erro Prisma após pull (`created_at` / colunas de auditoria) | Migration `20260518120000_auditoria` não aplicada | `cd backend && npx prisma migrate deploy` |
| Nome do módulo ou vínculo de programa **volta** após reiniciar API | Versão antiga do sync sobrescrevia UI | Atualizado: sync só cria módulos novos e não altera `moduloSistemaId` em programas existentes |
| Novo programa não aparece na Home | Falta registro no `HomeMenuRegistry` ou permissão | Adicionar em `home_menu_registry.dart`; liberar programa; reiniciar API |
| Programa criado não aparece na liberação de acesso | Lista desatualizada ou programa só no módulo sem registro em `programas` | Criar em **Programas do sistema** (`POST /programas`); reabrir liberação (app mescla `GET /programas` + permissões); hot restart |
| `operator does not exist: integer = text` no sync | Banco já com `codigo` inteiro; Prisma 6 + `findUnique` | Corrigido: `syncModulos` usa `findFirst`; rode `npx prisma generate` após migrations |
| Migrations pendentes (cidades, bairros, assistidos/`pessoas`, módulo) | Deploy incompleto | `cd backend && npx prisma migrate deploy && npx prisma generate` |
| Migration `20260521100000` pendente | Liberação por tipo de formulário | `cd backend && npx prisma migrate deploy && npx prisma generate` |
| Migration `20260525100000`–`20260525140000` pendente | Escolaridades, departamentos, voluntários, vínculos, campo `nome` | `cd backend && npx prisma migrate deploy && npx prisma generate`; liberar programas `escolaridades`, `departamentos`, `voluntarios` |
| Migration `20260525150000`–`20260525170000` pendente | Estado civil Separado(a), cursos, alunos de capacitação | `cd backend && npx prisma migrate deploy && npx prisma generate`; liberar `cursos`, `alunos_capacitacao` |
| Atalho **Alunos de Capacitação** não aparece | Programa não liberado ou Prisma Client antigo | Liberação de acesso → `alunos_capacitacao`; parar API; `npx prisma generate`; reiniciar app (`R`) |
| Erro ao salvar aluno (validação) | Campos condicionais vazios | Com Aluguel: informar valor; com checkbox Senac/Senai, necessidade ou médico: preencher campos habilitados |
| `horarioBaseSchema.partial is not a function` ao subir API | Validador Zod de horários (`.superRefine` antes de `.partial`) | Corrigido em `validators/voluntario-departamento-horarios.ts` — reinicie a API |
| Filtro **Departamento** vazio na lista de voluntários | Sem permissão `consultar` em **Cadastrar departamentos** | Liberar programa `departamentos` ou usar usuário admin |
| Não consigo desativar departamento | Existem vínculos em `voluntario_departamento_horarios` | Remova os vínculos na edição dos voluntários ou altere o departamento nos horários |
| Entrevista — escolaridade vazia no listbox | Nenhuma escolaridade ativa cadastrada | **Cadastrar escolaridades** (seed: só código 1 na migration) |
| **Responder Questionários** sem tipos na lista (não admin) | Nenhum tipo liberado para o usuário/tipo | **Liberação por tipo** ou **por usuário** → aba **Tipos de formulário** → marcar tipos e salvar |
| Erro ao criar módulo pedindo código | App/API antigos | Atualizar app e API: `POST /modulos-sistema` não envia `codigo`; reiniciar API |
| **400** ao criar pergunta `TEXTO` | Falta `linhasCampo` ou `tamanhoCampo` | Enviar ambos (ex.: `tamanhoCampo: 250`, `linhasCampo: 3`); atualizar app de cadastro |
| Erro ao gravar texto longo / coluna `valor_texto` | Migration `20260520110000` não aplicada | `cd backend && npx prisma migrate deploy` |
| **500** / Internal Server Error em bairros/cidades após migration | Pooler Neon com plano SQL em cache (`cached plan must not change result type`) | Adicionar `pgbouncer=true` na `DATABASE_URL`; reiniciar a API (`npm run dev`) |
| Prisma `EPERM` ao gerar client | API em execução bloqueia `query_engine` | Parar `npm run dev`; `npx prisma generate`; subir a API de novo |
| **500** ao salvar entrevista | Migrations de entrevista não aplicadas ou Prisma Client desatualizado | `npx prisma migrate deploy`; parar API; `npx prisma generate`; reiniciar `npm run dev` |
| **500** ao **alterar** entrevista (Prisma **P2028**) | Transação expirando antes do fim do PUT (várias exclusões/inclusões no Neon) | Corrigido com timeout maior + releitura fora da transação; atualizar código e reiniciar a API; em caso raro de **503**, tentar salvar de novo |
| **409** ao excluir assistido com entrevistas | Entrevistas vinculadas ao assistido | Esperado; remover ou reatribuir entrevistas antes (sem cascade) |
| Prisma **`EPERM`** ao `generate` | Várias instâncias de `npm run dev` / `tsx watch` bloqueiam `query_engine-windows.dll.node` | Parar todos os terminais com a API (Ctrl+C); encerrar processos Node do Cefa se necessário; rodar `npx prisma generate` de novo |
| Campos monetários “pulam” ao digitar | `MoedaBrFormatter` reformatava a cada tecla | Corrigido: digitação livre + formatação no blur (`formatarMoedaBrNoController`) |
| Tela vermelha ao abrir cadastro de assistido / entrevista | Mesmo `FocusNode` no `Focus` e no `TextFormField` | Corrigido em `AppFormTextField`, `EntrevistaTextField`, `CampoInput`; hot restart |
| PDF da entrevista vazio ou sem fundo | YAML com `x:0 y:0` ou asset ausente | Preencher coordenadas; colocar PDF/PNG em `mobile/assets/relatorios/`; restart completo (`R`) |
| PDF sem programas sociais (X/texto) | App com hot reload após alterar YAML/código; API sem migration | **Restart completo** (`R`); `npx prisma migrate deploy` + reiniciar API; marcar checkboxes na entrevista antes do PDF (marcador só imprime se estiver ativo) |
| **`TooManyPagesException`** ao PDF de submissão (poucas páginas visíveis) | `Column` com texto longo não quebra no `MultiPage`; loop interno do pacote `pdf` (não é limite real de páginas do documento) | Corrigido: widgets planos + `TextOverflow.span` em `submissao_pdf.dart`; **restart completo** (`R`) |
| PDF sem **Pág. N** no canto | App antigo ou hot reload | Código em `pdf_page_number.dart`; reiniciar app (`R`) |
| Erro Helvetica / Unicode no PDF (`—`, acentos) | Fonte padrão do pacote `pdf` sem suporte a Unicode | Corrigido com `PdfFonts` (Open Sans); na 1ª geração no Chrome pode precisar de rede para baixar a fonte |
| Falha ao gerar PDF da entrevista (raster) | `Printing.raster` no Chrome pode falhar | Testar Windows/Android; ou exportar fundo como PNG |
| PDF da entrevista sem endereço/telefone | API antiga só devolvia nome/CPF do assistido | Reiniciar API; `GET /entrevistas-assistido/:id` deve retornar objeto `pessoa` completo |
| **Render** — build falha no Prisma | `prisma generate` ausente do build | Build Command: `npm install && npx prisma generate && npm run build` — ver [deploy-render.md](./deploy-render.md) |
| **Render** — API sobe mas 500 no banco | `DATABASE_URL` sem `pgbouncer=true` no pooler Neon | URL com `?sslmode=require&pgbouncer=true`; redeploy |
| **Render** — timeout no primeiro request | Plano free (cold start) | Aguardar e repetir; ou plano pago |
| **Render** — login `admin` rejeitado | Usuário já existia com outra senha | `ADMIN_INITIAL_PASSWORD` só na 1ª criação; alterar senha em usuários ou no Neon |
| App aponta para Render mas não conecta | `API_BASE_URL` errada (http, barra final, URL antiga) | `--dart-define=API_BASE_URL=https://cefa-api.onrender.com` (HTTPS, sem `/` no fim) — ver [deploy-render.md](./deploy-render.md) |

---
