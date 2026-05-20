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
| **Cannot hit test a render box…** na pesquisa de pessoa | `AppButton` com largura infinita fora de `Expanded` em `Row` | Corrigido em `pessoas_search_screen.dart` |
| Menu da Home vazio (não admin) | Nenhuma permissão ou módulo sem programas | Liberar programas; vincular programas ao módulo em Módulos do sistema |
| PDF não baixa no Chrome | Hot reload após adicionar dependências | `flutter run` completo ou hot **restart** (`R`) |
| Erro Prisma após pull (`created_at` / colunas de auditoria) | Migration `20260518120000_auditoria` não aplicada | `cd backend && npx prisma migrate deploy` |
| Nome do módulo ou vínculo de programa **volta** após reiniciar API | Versão antiga do sync sobrescrevia UI | Atualizado: sync só cria módulos novos e não altera `moduloSistemaId` em programas existentes |
| Novo programa não aparece na Home | Falta registro no `HomeMenuRegistry` ou permissão | Adicionar em `home_menu_registry.dart`; liberar programa; reiniciar API |
| `operator does not exist: integer = text` no sync | Banco já com `codigo` inteiro; Prisma 6 + `findUnique` | Corrigido: `syncModulos` usa `findFirst`; rode `npx prisma generate` após migrations |
| Migrations pendentes (cidades, bairros, pessoa, módulo) | Deploy incompleto | `cd backend && npx prisma migrate deploy && npx prisma generate` |
| **400** ao criar pergunta `TEXTO` | Falta `linhasCampo` ou `tamanhoCampo` | Enviar ambos (ex.: `tamanhoCampo: 250`, `linhasCampo: 3`); atualizar app de cadastro |
| Erro ao gravar texto longo / coluna `valor_texto` | Migration `20260520110000` não aplicada | `cd backend && npx prisma migrate deploy` |
| **500** / Internal Server Error em bairros/cidades após migration | Pooler Neon com plano SQL em cache (`cached plan must not change result type`) | Adicionar `pgbouncer=true` na `DATABASE_URL`; reiniciar a API (`npm run dev`) |
| Prisma `EPERM` ao gerar client | API em execução bloqueia `query_engine` | Parar `npm run dev`; `npx prisma generate`; subir a API de novo |
| **500** ao salvar entrevista | Migrations de entrevista não aplicadas ou Prisma Client desatualizado | `npx prisma migrate deploy`; parar API; `npx prisma generate`; reiniciar `npm run dev` |
| **500** ao **alterar** entrevista (Prisma **P2028**) | Transação expirando antes do fim do PUT (várias exclusões/inclusões no Neon) | Corrigido com timeout maior + releitura fora da transação; atualizar código e reiniciar a API; em caso raro de **503**, tentar salvar de novo |
| **409** ao excluir pessoa com entrevistas | Entrevistas vinculadas à pessoa | Esperado; remover ou reatribuir entrevistas antes (sem cascade) |
| Prisma **`EPERM`** ao `generate` | Várias instâncias de `npm run dev` / `tsx watch` bloqueiam `query_engine-windows.dll.node` | Parar todos os terminais com a API (Ctrl+C); encerrar processos Node do Cefa se necessário; rodar `npx prisma generate` de novo |
| Campos monetários “pulam” ao digitar | `MoedaBrFormatter` reformatava a cada tecla | Corrigido: digitação livre + formatação no blur (`formatarMoedaBrNoController`) |
| Tela vermelha ao abrir cadastro de pessoa / entrevista | Mesmo `FocusNode` no `Focus` e no `TextFormField` | Corrigido em `AppFormTextField`, `EntrevistaTextField`, `CampoInput`; hot restart |
| PDF da entrevista vazio ou sem fundo | YAML com `x:0 y:0` ou asset ausente | Preencher coordenadas; colocar PDF/PNG em `mobile/assets/relatorios/`; restart completo (`R`) |
| PDF sem programas sociais (X/texto) | App com hot reload após alterar YAML/código; API sem migration | **Restart completo** (`R`); `npx prisma migrate deploy` + reiniciar API; marcar checkboxes na entrevista antes do PDF (marcador só imprime se estiver ativo) |
| **`TooManyPagesException`** ao PDF de submissão (poucas páginas visíveis) | `Column` com texto longo não quebra no `MultiPage`; loop interno do pacote `pdf` (não é limite real de páginas do documento) | Corrigido: widgets planos + `TextOverflow.span` em `submissao_pdf.dart`; **restart completo** (`R`) |
| PDF sem **Pág. N** no canto | App antigo ou hot reload | Código em `pdf_page_number.dart`; reiniciar app (`R`) |
| Erro Helvetica / Unicode no PDF (`—`, acentos) | Fonte padrão do pacote `pdf` sem suporte a Unicode | Corrigido com `PdfFonts` (Open Sans); na 1ª geração no Chrome pode precisar de rede para baixar a fonte |
| Falha ao gerar PDF da entrevista (raster) | `Printing.raster` no Chrome pode falhar | Testar Windows/Android; ou exportar fundo como PNG |
| PDF da entrevista sem endereço/telefone | API antiga só devolvia nome/CPF da pessoa | Reiniciar API; `GET /entrevistas-assistido/:id` deve retornar `pessoa` completa |

---
