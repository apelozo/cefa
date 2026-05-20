# App Flutter

## 5. App Flutter

### Navegação

O app **não** usa `go_router` nem rotas nomeadas no `MaterialApp`. A navegação é **imperativa**:

- `MaterialApp(home: …)` alterna **Login** / **Home** conforme `authProvider`
- Demais telas: `Navigator.push` + `MaterialPageRoute`
- Registro de atalhos da Home: `mobile/lib/home/home_menu_registry.dart` (mapeia `codigo` do programa → tela). Programa novo no catálogo **só** aparece na Home após entrada neste arquivo (além do sync e das permissões).

### Telas

| Tela | Função |
|------|--------|
| **Login** | Nome de usuário e senha; persiste token |
| **Home** | Seletor horizontal de **módulos**; atalhos dos programas liberados no módulo selecionado |
| **Módulos do sistema** | CRUD de módulos; checkboxes para vincular programas |
| **Tipos de usuário** | CRUD de tipos (descrição, perfil, ativo) |
| **Usuários** | CRUD de usuários |
| **Liberação por tipo** | Permissões padrão do tipo em todos os programas |
| **Liberação por usuário** | Override de permissões por usuário |
| **Tipos de formulário** | Lista com botões **Alterar** / **Excluir**; FAB para novo |
| **Cadastrar perguntas** | Filtro por **tipo de formulário** no topo; lista com **Alterar** / **Excluir**; FAB para nova |
| **Cadastrar pessoas** | Seções: identificação, filiação, documentos, endereço (bairro/município com pesquisa), contato; listagem exibe **nome da mãe** quando informado |
| **Cadastrar cidades** | Município e UF (código automático; somente leitura na edição) |
| **Cadastrar bairros** | Nome (código automático; somente leitura na edição) |
| **Pesquisar pessoas** | Campos separados: nome, CPF (máscara) e RG (máscara) |
| **Lançamento** | Tipo de formulário → pesquisa pessoa → respostas → confirma → envia |
| **Entrevista com o Assistido** | Lista com busca por nome/CPF; FAB nova; alterar/excluir; consulta; formulário com **6 abas** (scroll horizontal na `TabBar`) |
| **Consulta de respostas** | Filtros → lista → detalhe → **exportar/visualizar PDF** |

### Fluxo de login e Home

```
1. Abrir o app → Login (nome de usuário + senha)
2. Home carrega GET /modulos-sistema/menu
3. Usuário escolhe um módulo (chips horizontais)
4. São exibidos apenas programas daquele módulo com alguma permissão
5. Programas de administração ficam no módulo "Administração" (não há seção fixa separada)
```

Usuário seed: **admin** (tipo Administrador, permissão total na API e na UI).

### Fluxo do cadastro de formulários

```
1. Cadastrar Tipo de Formulário ("Admissão")
2. Cadastrar Perguntas vinculadas a "Admissão" (use o filtro por tipo na lista)
3. (Opcional) Cadastrar Cidades e Bairros para endereço
4. Cadastrar Pessoas (identificação, documentos, endereço, contato)
```

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

### Pesquisa de pessoas (reutilizável)

Tela: `PessoasSearchScreen` — `mobile/lib/screens/pessoas/pessoas_search_screen.dart`

Três campos independentes:

| Campo | Comportamento |
|-------|----------------|
| Nome | Busca parcial (case insensitive) |
| CPF | Máscara `000.000.000-00`; envia só dígitos à API |
| RG | Máscara `00.000.000-0`; envia sem pontuação à API |

Critérios preenchidos são combinados com **AND**. Botões **Pesquisar** e **Limpar** (ambos em `Expanded` no `Row` — evita erro de layout no Chrome).

```dart
final pessoa = await PessoasSearchScreen.select(
  context,
  args: PessoasSearchArgs(
    title: 'Selecionar pessoa',
    subtitle: 'Opcional',
    onlyAtivas: true,
  ),
);
```

API: `GET /pessoas?nome=...&cpf=...&rg=...`. Usada no **lançamento**, na **entrevista com o assistido** e na lista de pessoas.

### Entrevista com o Assistido

Telas: `mobile/lib/screens/entrevista_assistido/`  
Programa: `entrevista_assistido` — atalho na Home (módulo **Formulários**).

```
1. Home → Entrevista com o Assistido (lista)
2. Buscar por nome e/ou CPF da pessoa (opcional) → lista de entrevistas
3. Toque no card → consulta somente leitura (exige podeConsultar) → ícone **PDF** no AppBar (visualizar / baixar ficha)
4. Ícone alterar → formulário com dados carregados → PUT (exige podeAlterar)
5. Ícone excluir → confirmação → DELETE (exige podeExcluir)
6. FAB Nova → selecionar pessoa → preencher abas → POST (exige podeIncluir)
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
| **Texto de apoio** | *"Base: N pessoa(s) na composição familiar"* |
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
| Escolaridade | Lista (`EscolaridadeFamiliar`) |
| Sabe Ler e Escrever / Frequenta a Escola | `FilterChip` (tags) |

Tela: `entrevista_condicao_educacional_tab.dart`. Modelo: `entrevista_condicao_educacional.dart`. Constantes: `constants/escolaridade_familiar.dart`.

#### Aba Condições de Saúde da Família

**Bloco deficiência** (vários registros):

- Texto: *"Caso haja presença de pessoa com deficiência na familia, preencha o quadro abaixo"*
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
| `entrevista_assistido_screen.dart` | Cabeçalho (pessoa + data), `TabBar` com 6 abas, botão Salvar |
| `entrevista_programas_sociais_tab.dart` | Programas sociais e órgãos de atendimento |
| `entrevista_composicao_familiar_tab.dart` | Lista dinâmica de integrantes |
| `entrevista_condicao_trabalho_tab.dart` | Condições de trabalho, totais de renda |
| `entrevista_condicao_educacional_tab.dart` | Condições educacionais |
| `entrevista_condicao_saude_tab.dart` | Deficiências + questionário de saúde |
| `entrevista_form_linhas.dart` | Linhas dinâmicas: `ComposicaoFamiliarLinha`, `CondicaoTrabalhoLinha`, `CondicaoEducacionalLinha`, `DeficienciaFamiliarLinha`, **`GestanteFamiliarLinha`**, `SaudeFamiliaForm` |
| `models/entrevista_*.dart` | Serialização para API (incl. `entrevista_gestante_familiar.dart`, `entrevista_programas_sociais.dart`) |
| `constants/ocupacao_familiar.dart`, `escolaridade_familiar.dart`, `tipo_deficiencia_familiar.dart`, `resposta_sim_nao.dart` | Enums e rótulos (espelho do backend) |
| `utils/moeda_br.dart` | Parse/format BR nos campos monetários |

#### PDF da entrevista (ficha institucional)

| Item | Detalhe |
|------|---------|
| **Quando** | Tela **Consultar entrevista** (`readOnly: true`) |
| **UI** | Ícone PDF no AppBar → Visualizar ou Baixar/compartilhar |
| **Gerador** | `entrevista_pdf.dart`, `entrevista_layout_config.dart`, `entrevista_pdf_field_resolver.dart`, `pdf_fonts.dart`, `pdf_page_number.dart` (numeração no canto superior direito) |
| **Molde** | `mobile/assets/relatorios/entrevista_assistido_v1.yaml` + PDF/PNG de fundo por página |
| **Dados** | Recarrega `GET /entrevistas-assistido/:id` ao gerar; mescla `programasSociais` da tela; pessoa completa no objeto `pessoa` |
| **Fontes / numeração** | Open Sans + `Pág. N` no canto superior direito — [relatorios.md](./relatorios.md) §10 e §11 |
| **Marcadores** | `forma.*`, `programas.*`, etc.: imprime **"X"** só se o checkbox estiver marcado na entrevista |
| **Gestantes no PDF** | `gestante.linha1` … `linha5` conforme `gestantesFamilia` (ordem de `ordem`) |
| **Booleanos Sim/Não** | Duas chaves no YAML (`.SIM` / `.NAO`) para tags educacionais, cuidados, questionário e pré-natal |

Coordenadas e chaves do mapa: [relatorios.md](./relatorios.md) §6 e [mobile/assets/relatorios/README.md](../mobile/assets/relatorios/README.md).

Após alterar o YAML, o resolvedor ou os fundos em `assets/relatorios/`, use **restart completo** do app (`R`), não só hot reload.

### Consulta de respostas e PDF

Telas: `mobile/lib/screens/submissoes/`  
Utilitários PDF: `submissao_pdf.dart`, `pdf_fonts.dart`, `submissao_pdf_delivery*.dart`  
Estratégia completa (fluxo vs layout fixo por pergunta): **[relatorios.md](./relatorios.md)** (§10 numeração, §11 fontes Unicode)

```
1. Home → módulo Formulários → Consulta de respostas
2. Filtrar por tipo de formulário (opcional), nome e/ou CPF da pessoa
3. Buscar → lista de lançamentos (data, pessoa, quantidade de respostas)
4. Toque no item → detalhe com perguntas numeradas e valores
5. Ícone PDF no AppBar:
   - Visualizar PDF (nova aba no Chrome; visualizador no mobile/desktop)
   - Baixar / compartilhar PDF
```

**PDF atual (implementado — relatório em fluxo):** cabeçalho (tipo de formulário), pessoa, CPF, data do envio, respostas em **ordem de cadastro** (pergunta + valor compactos: valor em **uma linha**, exceto `TEXTO` com texto integral; uma linha em branco entre perguntas), rodapé com data de geração e **número da página** (`Pág. N`) no canto superior direito (`pdf_page_number.dart`). Novas perguntas entram automaticamente; **não** há posição fixa na folha.

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

### Pesquisa de pessoas — CPF/RG no cadastro

`PessoaFormScreen` usa `CpfFormatter` e `RgFormatter`; gravação via `normalizeCpf` / `normalizeRg`. Exibição em listas usa `cpfExibicao` e `rgExibicao`.

### Cadastro de pessoa — endereço (bairro e município)

Telas: `mobile/lib/screens/pessoas/pessoa_form_screen.dart`  
Widget: `mobile/lib/widgets/app_searchable_select_field.dart` (`AppSearchableSelectField`)

| Comportamento | Descrição |
|---------------|-----------|
| Seleção | Painel inferior com campo **Pesquisar** e lista filtrada |
| Ordenação | Bairros por **nome** (A–Z); municípios por **nome** e UF |
| Cadastrar no seletor | Botão **Cadastrar bairro** / **Cadastrar município** só se `podeIncluir` em `bairros` / `cidades`; abre o formulário respectivo, recarrega a lista e seleciona o novo código |
| Retorno do formulário | `BairroFormScreen` / `CidadeFormScreen` devolvem o objeto criado no `Navigator.pop` (edição continua retornando `true`) |

### Listagem de pessoas

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
1. Home → Lançamento
2. Escolher tipo de formulário (ex.: "Admissão")
3. Pesquisar e selecionar a pessoa (campos nome, CPF ou RG)
4. Preencher os campos desejados (nenhuma pergunta é obrigatória)
5. Revisar e enviar — só perguntas com resposta entram no `POST /submissoes`
6. Confirmação lista apenas respostas preenchidas; envio sem nenhuma resposta é permitido
```

| Regra | Comportamento |
|-------|----------------|
| Campo vazio | Não bloqueia envio; validação só se o usuário começou a preencher (formato inválido) |
| API | `respostas` contém somente itens com valor; array pode ser vazio |

### Formulários — tecla Enter

Em telas de cadastro, pesquisa e no lançamento, **Enter** avança para o próximo campo de texto; no último campo, o foco vai para o botão principal (**Salvar**, **Criar**, **Pesquisar**, **Buscar** ou **Enviar**). Utilitário: `mobile/lib/utils/form_enter_focus.dart` (`FormEnterFocus` e `FormEnterFocus.chainSubmit` para campos dinâmicos).

| Tela / fluxo | Campos na cadeia Enter |
|--------------|------------------------|
| Login | usuário → senha → Entrar |
| Tipo de formulário | nome → descrição → Salvar/Criar |
| Pessoa | nome → nome social → nascimento → CPF → RG → órgão emissor → nome da mãe → nome do pai → NIS → endereço → número → complemento → telefone → telefone 2 → Salvar/Criar (bairro, município, urbano/rural e ativo ficam de fora) |
| Pergunta | enunciado → (tamanho e linhas, se TEXTO) → (opções, se LISTA) → ordem → Salvar/Criar |
| Módulo do sistema | código → nome → descrição → ordem → Salvar/Criar |
| Usuário | login → nome → e-mail → senha → Salvar |
| Tipo de usuário | descrição → Salvar |
| Pesquisa de pessoas | nome → CPF → RG → Pesquisar |
| Consulta de respostas | nome → CPF → Buscar |
| Lançamento (formulário) | campos de texto/número/data por ordem das perguntas → Enviar |

Dropdowns, switches e campos **Sim/Não** / **Lista** não entram na cadeia (use Tab ou toque). Perguntas **TEXTO** com `linhasCampo > 1` também ficam de fora da cadeia Enter. Campos multiline (ex.: enunciado no cadastro de pergunta) podem inserir quebra de linha com Enter em vez de avançar.

### Regras de desenvolvimento (`.cursor/rules/`)

| Arquivo | Conteúdo |
|---------|----------|
| `repositorio-cefa.mdc` | Trabalhar somente em `D:\Projetos\Cursor\Cefa` |
| `sem-delete-cascade.mdc` | Nunca `ON DELETE CASCADE`; bloquear com 409 |
| `tipografia-arial.mdc` | Arial em todas as telas (`AppTheme.fontFamily`) |

### URL da API por plataforma

| Onde roda | `API_BASE_URL` |
|-----------|----------------|
| Chrome / Web | `http://127.0.0.1:3000` (recomendado no Windows) |
| Android emulador | `http://10.0.2.2:3000` (padrão) |
| iOS simulador | `http://localhost:3000` |
| Celular físico (mesma Wi‑Fi) | `http://IP_DO_PC:3000` |

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

O app detecta a plataforma quando `--dart-define` não é informado.

### Autenticação e permissões no app

- Login: `mobile/lib/screens/auth/login_screen.dart`
- Estado: `authProvider` (`mobile/lib/providers/auth_provider.dart`) — mapa `codigo → ProgramaPermissao`
- Token em `shared_preferences`; Dio envia `Authorization: Bearer`; **401** limpa sessão
- `podeAcessar(codigo)`: qualquer flag true → atalho no módulo + entrada na tela (`PermissaoGate`); se `isAdmin`, sempre `true`
- `podeIncluir` / `podeAlterar` / `podeExcluir` / `podeConsultar`: controlam FAB e ícones; admin sempre `true` na UI
- **401** em qualquer rota protegida limpa a sessão (Dio interceptor)
- Telas de liberação: `liberacao_tipo_usuario_screen.dart`, `liberacao_usuario_screen.dart` + `PermissoesEditor`
- Constantes de programa: `mobile/lib/auth/programas.dart` (espelho de `backend/src/lib/programas.ts`)

### Validação dupla

Regras espelhadas no Flutter (`validators/`) e na API (Zod + `lib/campo.ts`) para melhor UX offline e consistência no envio.

### Identidade visual

O app segue a identidade definida em [`IdentidadeGrafica.md`](../IdentidadeGrafica.md):

- Paleta: azul `#1F2A8A`, laranja `#FF8A3D`, azul claro `#E8F1FF`
- Fundo com gradiente vertical; AppBar em faixa azul claro
- CTAs laranja; botões secundários com contorno azul
- Cartões brancos 16px; tipografia **Arial** (obrigatória em todas as telas — ver [`.cursor/rules/tipografia-arial.mdc`](../.cursor/rules/tipografia-arial.mdc))

Implementação: `mobile/lib/theme/app_theme.dart` (`AppTheme.fontFamily`) e `mobile/lib/widgets/` (`AppScaffold`, `AppCard`, `AppButton`, `AppSearchableSelectField`, `RecordActionButtons`, `PessoaTile`). Novas telas devem usar o `textTheme` do tema ou `fontFamily: AppTheme.fontFamily` — nunca outra fonte. No Windows/Chrome, Arial é fonte do sistema; em outras plataformas pode ser necessário empacotar `.ttf` no futuro.

---
