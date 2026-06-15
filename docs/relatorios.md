# Relatórios e PDF

Documentação da estratégia de geração de PDF no Cefa: o que está implementado hoje e o modelo recomendado para **relatórios com layout institucional fixo** (cada pergunta em posição definida no papel).

Na UI, o cadastro vinculado a submissões e entrevistas é **Assistido**; no PDF da entrevista as chaves do mapa continuam `pessoa.*` (tabela `pessoas`). O PDF de submissão em fluxo usa o rótulo **Assistido** no cabeçalho. Ver [Terminologia](./modelo-dados.md#terminologia-assistido--pessoa).

---

## 0. Menu do módulo Relatórios e submódulos

Os atalhos de relatório na **Home** ficam no módulo **Relatórios** (`modulos_sistema.codigo = 3`), agrupados por **submódulo** cadastrado em `relatorio_submodulos`.

| Conceito | Descrição |
|----------|-----------|
| **Módulo Relatórios** | Chip na Home; contém programas de consulta/PDF (ex.: `relatorio_alunos_turma`) |
| **Submódulo** | Agrupamento dentro do módulo (ex.: **IEFA**, `codigo` `iefa`) — entidade distinta de um eventual módulo operacional com o mesmo nome |
| **Catálogo** | `GET /relatorio-submodulos` ou tela **Submódulos de relatórios** (Administração) |
| **Vínculo** | Cada programa no módulo Relatórios tem `relatorioSubmoduloId` obrigatório (`POST`/`PUT` `/programas`) |
| **Home** | Chips **Todos** + submódulos; atalhos filtrados e ordenados alfabeticamente |

**Checklist — novo relatório com PDF:**

1. Consultar submódulos existentes (`GET /relatorio-submodulos`); criar submódulo se necessário.
2. Implementar tela/API/PDF no código; registrar programa em `PROGRAMAS_CATALOGO` (módulo `3`) ou `POST /programas` com módulo Relatórios + submódulo.
3. Entrada em `HomeMenuRegistry`; liberar programa; documentar em [relatorios.md](./relatorios.md) e [api.md](./api.md).

Modelo: [modelo-dados.md § Submódulo](./modelo-dados.md#submódulo-de-relatório-relatorio_submodulos). App: [mobile.md § Submódulos](./mobile.md#submódulos-de-relatórios).

---

## 1. Contexto

| Conceito | Descrição |
|----------|-----------|
| **Perguntas** | Cadastradas por **tipo de formulário**, com `tipoCampo`, `ordem` e opções (se LISTA). Estrutura **dinâmica** no banco. |
| **Lançamento (submissão)** | Um envio com `pessoaId` (assistido), `tipoFormularioId` e **respostas opcionais** (só perguntas preenchidas são gravadas; `respostas` pode ser vazio). |
| **Relatório** | PDF (ou outro formato) gerado a partir de uma submissão (e dados do **assistido**), para consulta, arquivo ou impressão. |

O desafio: o cadastro de perguntas é flexível, mas alguns relatórios precisam seguir um **padrão visual rígido** — como um formulário impresso oficial, com cada resposta em um lugar específico da folha.

---

## 2. Dois tipos de relatório

### 2.1 Relatório em fluxo (implementado)

**Uso:** consulta genérica de lançamentos; perguntas em ordem; layout montado pelo código.

| Item | Detalhe |
|------|---------|
| **Código** | `mobile/lib/utils/submissao_pdf.dart`, `submissao_pdf_delivery*.dart` |
| **Fontes** | `mobile/lib/utils/pdf_fonts.dart` — Open Sans (Unicode; ver §12) |
| **Tela** | Consulta de respostas → detalhe → ícone PDF no AppBar |
| **Layout** | `MultiPage` (`maxPages: 200`) com widgets **planos** (sem `Column` por resposta); `TextOverflow.span` em textos longos; demais tipos em **1 linha**; ~1 linha em branco entre perguntas; cabeçalho sem logo |
| **Numeração** | `Pág. N` no **canto superior direito** — `header` do `MultiPage` (`pdf_page_number.dart`) |
| **Dados** | `Submissao` com `respostas` ordenadas por `perguntaOrdem`; valores via `formatRespostaSubmissao` (`resposta_display.dart`) |
| **Novas perguntas** | Entram automaticamente na lista, na ordem cadastrada |

**Detalhes de layout (submissões):**

| Elemento | Comportamento |
|----------|----------------|
| Enunciado | Uma linha visível (`maxLines: 1`); quebra de página via `span` se longo |
| Resposta `TEXTO` | Texto integral, com quebra entre páginas |
| Outros tipos | Valor em uma linha (truncado visualmente se necessário) |
| Rodapé | Data/hora de geração do documento |

**Limitação:** não garante posição fixa na página nem aparência de ficha pré-impressa.

Ver também [mobile.md](./mobile.md) (§ Consulta de respostas e PDF).

### 2.2 Relatório com layout fixo por pergunta (planejado)

**Uso:** quando o PDF deve seguir um **modelo desenhado** (linhas, rótulos, caixas) e **cada pergunta ativa** daquele tipo de formulário ocupa um retângulo definido no molde.

Nesse modo, **todas as perguntas do tipo são tratadas como “campos fixos” no relatório**: não no banco, mas no **mapa de layout** (coordenadas + página + estilo).

| Item | Detalhe |
|------|---------|
| **Molde (template)** | Por **tipo de formulário**, versionado (ex.: `admissao_v1`) |
| **Fundo** | PNG ou PDF de fundo desenhado (formulário vazio: logo, rótulos, linhas) |
| **Mapa** | JSON/YAML: `perguntaId` (ou `codigoRelatorio`) → `pagina`, `x`, `y`, `largura`, `tamanhoFonte`, … |
| **Gerador** | Carrega fundo + para cada entrada do mapa busca a resposta da submissão e desenha o texto em `Stack` / posição absoluta |
| **Novas perguntas** | Exigem **atualizar o molde** (nova versão ou novas coordenadas); validação recomendada |

---

## 3. Modelo “fundo + mapa” (layout fixo)

### 3.1 O que é o “modelo desenhado por você”

1. Você monta a aparência no **Word**, **LibreOffice**, **Canva** ou similar (A4).
2. Exporta um arquivo **sem dados reais** — só layout: `assets/relatorios/{tipo}_v1_fundo.png` (ou PDF da 1ª página rasterizado).
3. O desenvolvedor (ou ferramenta) mede onde cada **resposta** deve aparecer e grava no **mapa**.
4. O app/servidor **não redesenha** o formulário; apenas **escreve por cima** do fundo.

```
┌─────────────────────────────────────┐
│  [fundo PNG — desenhado por você]    │
│  Nome: ████████████████████          │  ← texto da API em (x,y)
│  CPF:  ████████████████████          │
└─────────────────────────────────────┘
```

Coordenadas em **pontos PDF (pt)**; página A4 ≈ **595 × 842 pt**. Origem do pacote `pdf` no Flutter: canto **superior esquerdo** (`left` / `top`).

### 3.2 Amarrar pergunta dinâmica ↔ posição fixa

| Chave no mapa | Quando usar |
|---------------|-------------|
| **`perguntaId` (UUID)** | Recomendado: estável se mudar só o enunciado ou a ordem na tela de lançamento |
| **`ordem`** | Só se a ordem no cadastro for **igual** à posição no papel (frágil ao inserir pergunta no meio) |
| **`codigoRelatorio`** | Campo estável legível (ex.: `nome_mae`); exige convenção no cadastro de perguntas |

Exemplo de mapa (ilustrativo):

```yaml
# assets/relatorios/admissao_v1.yaml
versao: 1
tipoFormularioCodigo: tipos_formulario   # ou UUID do tipo
fundo: admissao_v1_fundo.png
paginaFormato: A4

campos:
  "550e8400-e29b-41d4-a716-446655440001":
    pagina: 1
    x: 95
    y: 620
    largura: 400
    tamanhoFonte: 10
    alinhamento: left
```

O gerador, para cada chave, localiza `respostas.where((r) => r.perguntaId == chave)` e formata o valor conforme `tipoCampo` (mesmas regras de `formatRespostaSubmissao`).

### 3.3 Regras operacionais

- **Toda pergunta ativa** do tipo deve ter entrada no molde da versão em uso; caso contrário: aviso no admin e/ou campo vazio no PDF.
- **Alterar layout** (nova pergunta, mover caixa): nova versão do molde (`v2`) ou edição do mapa.
- **Texto longo:** definir no molde `maxLinhas`, truncar com reticências ou `tamanhoFonteMinimo`.
- **Submissões antigas:** opcionalmente guardar `layoutVersao` na submissão para regenerar com o molde da época.

---

## 4. Comparação rápida

| Critério | Fluxo (`submissao_pdf`) | Layout fixo por pergunta |
|----------|-------------------------|---------------------------|
| Perguntas novas | Automático | Exige atualizar molde |
| Posição na folha | Flui (quebra de página) | Fixa por mapa |
| Manutenção | Baixa | Média/alta (design + coordenadas) |
| Aparência institucional | Padronizada em código | Igual ao PDF/Word aprovado |
| Implementação atual | **Sim** (submissões, alunos matriculados — §7, relatório de alunos da turma — §8) | **Sim** (entrevista); submissões fixas: planejado |

---

## 5. Arquitetura sugerida (implementação futura)

| Peça | Local sugerido | Função |
|------|----------------|--------|
| Molde | `mobile/assets/relatorios/` + JSON/YAML | Fundo + mapa por tipo/versão |
| Gerador fixo | `mobile/lib/utils/relatorio_submissao_fixo_pdf.dart` | `gerar(Submissao, MoldeConfig)` |
| Gerador fluxo | `submissao_pdf.dart` (atual) | Consulta genérica |
| Metadado no tipo | `tipos_formulario.layoutRelatorio` (JSON na API) ou só assets versionados no app | Qual molde usar |
| Validação | Backend ou tela admin | Perguntas ativas sem slot no molde |
| Entrega | Reutilizar `submissao_pdf_delivery*.dart` | Visualizar / baixar / compartilhar |

**Onde gerar:** começar no **Flutter** (mesmo padrão da consulta atual); migrar para **backend** (Node + `pdf-lib`) se for necessário PDF idêntico em todos os canais ou geração em lote.

---

## 6. Entrevista com o assistido — layout fixo (implementado)

**Uso:** ficha institucional da entrevista social; fundo desenhado (PDF ou PNG) + dados do assistido e da entrevista nas coordenadas do mapa.

| Item | Detalhe |
|------|---------|
| **Molde** | `mobile/assets/relatorios/entrevista_assistido_v1.yaml` |
| **Fundo** | PDF ou PNG por página (ex.: `Ficha_Entrevista_Assistido_pag01.pdf`); PDF é rasterizado via `Printing.raster` (150 dpi) |
| **Mapa** | Chaves: `pessoa.*`, `entrevista.*`, `forma.*`, `programas.*`, `composicao.linhaN.*`, `trabalho.linhaN.*`, `educacional.linhaN.*`, `deficiencia.linhaN.*`, `gestante.linhaN.*`, `saude.*` |
| **Gerador** | `mobile/lib/utils/entrevista_pdf.dart` (+ `entrevista_layout_config.dart`, `entrevista_pdf_field_resolver.dart`, `pdf_fonts.dart`) |
| **Tela** | Consulta da entrevista → ícone PDF no AppBar (visualizar / baixar) |
| **Dados** | Antes de gerar, **recarrega** `GET /entrevistas-assistido/:id` e mescla `programasSociais` da tela; objeto `pessoa` com assistido **completo** (mesmo formato de `GET /pessoas/:id`) + filhos da entrevista |
| **Entrega** | Reutiliza `submissao_pdf_delivery*.dart` |
| **Numeração** | `Pág. N` no canto superior direito (`PdfPageNumber.overlaySuperiorDireito` no `Stack` de cada página) |
| **Fontes** | Open Sans via `PdfFonts.ensureInitialized()` (§12) |

### 6.1 Estrutura do YAML

```yaml
versao: 1
paginaLargura: 595.28
paginaAltura: 842

fundos:
  - pagina: 1
    arquivo: Ficha_Entrevista_Assistido_pag01.pdf
  - pagina: 2
    arquivo: Ficha_Entrevista_Assistido_pag02.pdf

campos:
  pessoa.nome:
    pagina: 1
    x: 83
    y: 109
    largura: 480
    tamanhoFonte: 10
  forma.DEMANDA_ESPONTANEA:
    pagina: 1
    tipo: marcador
    x: 49
    y: 349
    textoMarcado: "X"
  composicao.linha1.nome:
    pagina: 1
    x: 62
    y: 607
    largura: 210
```

| Propriedade | Descrição |
|-------------|-----------|
| `pagina` | Número da página (1, 2, …) |
| `x`, `y` | Posição em **pt**; origem no **canto superior esquerdo** |
| `largura` | Caixa de texto (opcional) |
| `tamanhoFonte` | Padrão 9 |
| `tipo: marcador` | Desenha `textoMarcado` (padrão `X`) quando o valor está ativo |
| `alinhamento` | `left`, `center`, `right` |
| `maxLinhas` | Trunca texto longo |

Campos com `x: 0` e `y: 0` são **ignorados** (ainda não posicionados). Tabelas usam `linha1`, `linha2`, … conforme linhas fixas no formulário impresso.

Instruções de medição (Inkscape/Figma): [mobile/assets/relatorios/README.md](../mobile/assets/relatorios/README.md).

### 6.2 Chaves principais

| Grupo | Exemplos |
|-------|----------|
| Assistido (chaves `pessoa.*`) | `pessoa.nome`, `pessoa.cpfFormatado`, `pessoa.municipioExibicao`, `pessoa.urbanoRuralRotulo` |
| Entrevista | `entrevista.dataEntrevista`, `entrevista.outrosTexto` |
| Assistência | `forma.DEMANDA_ESPONTANEA`, … `forma.OUTROS` |
| Programas sociais | `programas.bolsaFamilia`, `programas.peti`, `programas.bpc`, `programas.outrosProgramas`, `programas.outrosProgramasSociais`, `programas.cras`, `programas.centroPop`, `programas.conselhoTutelar`, `programas.ubs`, `programas.creas`, `programas.caps`, `programas.craf`, `programas.outrosAtendimentoFamilia`, `programas.outrosOrgaosSociais` (marcadores = checkbox; textos = descrição de Outros) |
| Composição | `composicao.linha1.nome`, `.cpf`, `.dtNascimento`, `.parentesco` |
| Trabalho | `trabalho.linha1.ocupacao`, `.rendaMensal`, `trabalho.rendaTotal`, `trabalho.rendaPerCapita` |
| Educação | `educacional.linha1.escolaridade`, `.sabeLerEscrever.SIM` / `.NAO`, `.frequentaEscola.SIM` / `.NAO` |
| Deficiência | `deficiencia.linha1.tipoDeficiencia`, `deficiencia.linha1.necessitaCuidadosConstantes.SIM` / `.NAO` |
| Questionário saúde | `saude.remediosControladosMental.SIM` / `.NAO`, `saude.usoAbusivoAlcool.*`, `saude.usoAbusivoDrogas.*`, `saude.temGestante.SIM` / `.NAO` |
| Gestantes | `gestante.linha1.nome`, `gestante.linha1.mesesGestacao`, `gestante.linha1.iniciouPreNatal.SIM` / `.NAO` (até `linha5` no molde; ver `limites.gestantesFamilia` no YAML) |
| Gestantes (legado) | `saude.gestanteNome`, `saude.gestanteMesesGestacao`, `saude.gestanteIniciouPreNatal.SIM` / `.NAO` — equivalem à **1ª** gestante de `gestantesFamilia` |

Renda per capita no PDF segue a mesma regra da tela: total ÷ integrantes da composição com nome preenchido (assistido **fora** do divisor).

**Campos booleanos com caixas Sim/Não no formulário impresso:** use **duas** entradas no YAML — sufixo `.SIM` (marca X quando o valor é `true`) e `.NAO` (marca X quando é `false`). Ex.: `educacional.linha1.sabeLerEscrever.SIM` / `.NAO`, `gestante.linha1.iniciouPreNatal.SIM` / `.NAO`. Sem sufixo, o resolvedor trata como legado (X só se `true`). Coordenadas `x:0 y:0` continuam ignoradas até medição.

**Marcadores (`tipo: marcador`):** o **"X"** só é desenhado se o valor correspondente estiver ativo na entrevista (ex.: `programas.bolsaFamilia` só imprime quando o checkbox Bolsa Família estiver marcado). Coordenadas no YAML sem dado marcado não aparecem.

**Textos `programas.outrosProgramasSociais` / `programas.outrosOrgaosSociais`:** impressos quando preenchidos e o checkbox **Outros** respectivo estiver ativo.

**Gestantes no PDF:** cada registro salvo em `gestantesFamilia` ocupa `gestante.linha1`, `gestante.linha2`, … na ordem de `ordem`. Campos booleanos de tags/educação/pré-natal usam sufixos **`.SIM`** e **`.NAO`** em caixas distintas do formulário impresso.

### 6.3 Manutenção

- Novo campo no formulário impresso → nova entrada no YAML com `x`/`y` **e** mapeamento em `entrevista_pdf_field_resolver.dart` (prefixo `programas.`, `forma.`, etc.).
- Nova página → adicionar em `fundos` e posicionar campos com `pagina: N`.
- Dependência: pacote `yaml` no Flutter; assets em `pubspec.yaml` (`assets/relatorios/`).
- Após alterar YAML ou código do gerador: **restart completo** do app (`R`), não só hot reload.

---

## 7. Alunos matriculados — lista em fluxo (implementado)

**Uso:** relatório tabular dos alunos **matriculados ativos** (`matriculado=true`, `matriculaCancelada=false`) em uma **turma** (curso + período).

| Item | Detalhe |
|------|---------|
| **Gerador** | `mobile/lib/utils/matriculados_pdf.dart` |
| **Dados** | `GET /inscricoes/cancelamento-matricula/matriculados?turmaCodigo=` (mesma resposta da tela de cancelamento) |
| **Telas** | **Matricular Alunos no Curso** e **Cancelar Matrícula** — ícone PDF no AppBar após carregar a lista e com `totalMatriculados > 0` |
| **Entrega** | `submissao_pdf_delivery*.dart` (visualizar / baixar / compartilhar) |
| **Layout** | Cabeçalho (curso, turma, período, total) + tabela (Nº sequencial, nome, idade, data da matrícula, CPF, escolaridade); ordenação alfabética por nome; rodapé: *Documento gerado por {nome do usuário logado} em dd/mm/aaaa às HH:mm* |
| **Numeração** | `Pág. N` no canto superior direito (`pdf_page_number.dart`) |

Na tela de **matrícula**, o PDF recarrega os matriculados pela API (não usa só os candidatos da lista) para incluir **data da matrícula**.

---

## 8. Relatório de Alunos da Turma (implementado)

**Uso:** relatório parametrizado por **curso**, **turma** e **situação do aluno**, com PDF **resumido** ou **detalhado**. Uma seção por turma; **resumo geral** ao final com totais por turma.

| Item | Detalhe |
|------|---------|
| **Tela** | `mobile/lib/screens/relatorio_alunos_turma/relatorio_alunos_turma_screen.dart` |
| **Gerador** | `mobile/lib/utils/relatorio_alunos_turma_pdf.dart` |
| **Dados** | `GET /inscricoes/relatorio-alunos-turma` (+ `/cursos` e `/turmas` para filtros) |
| **Programa** | `relatorio_alunos_turma` |
| **Entrega** | `submissao_pdf_delivery*.dart` (visualizar / baixar / compartilhar) |
| **Numeração** | `Pág. N` no canto superior direito (`pdf_page_number.dart`) |

### Filtros (tela)

| Filtro | Comportamento |
|--------|----------------|
| **Curso** | **Todos os cursos** ou curso específico |
| **Turma** | Só com curso específico: **Todas as turmas** ou uma turma |
| **Situação** | Matriculados / Matrículas canceladas / A matricular / Todas as opções |
| **Tipo** | **Resumido** ou **Detalhado** |

Com **Todos os cursos**, o PDF quebra páginas por **curso/turma**. O resumo final lista, por turma: matriculados, matrículas canceladas e **a matricular** (somente se a turma estiver **Aberta**).

### PDF — Detalhado (paisagem)

| Item | Detalhe |
|------|---------|
| **Título** | `Relatório Detalhado de Alunos da Turma` (centralizado) |
| **Cabeçalho** | 1ª linha: curso e turma; 2ª linha: período e situação da turma (sem filtro de situação nem tipo no cabeçalho) |
| **Colunas** | Nome do Aluno, CPF, Idade, Escolaridade, Data Insc., Data Matr., Data Canc., Situação, Nro Atend. |

### PDF — Resumido (retrato)

| Item | Detalhe |
|------|---------|
| **Título** | `Relatório de alunos da turma` |
| **Colunas** | Nome do Aluno, CPF, Dt Ult. Situação, situação |

`Dt Ult. Situação`: data da inscrição, matrícula ou cancelamento conforme a situação atual do aluno.

Rodapé do resumo geral: *Documento gerado por {usuário logado} em dd/mm/aaaa às HH:mm*.

### 8.1 Outros relatórios (assistido)

O **cadastro de assistido** (`/pessoas`) ainda não possui PDF institucional; pode reutilizar o mesmo padrão fundo + mapa no futuro.

---

## 9. Referências no repositório

| Arquivo | Papel |
|---------|--------|
| `mobile/lib/utils/pdf_fonts.dart` | Open Sans para PDF (Unicode) |
| `mobile/lib/utils/pdf_page_number.dart` | Numeração `Pág. N` (canto superior direito) |
| `mobile/lib/utils/submissao_pdf.dart` | PDF de submissões em fluxo |
| `mobile/lib/utils/matriculados_pdf.dart` | PDF — alunos matriculados por turma (telas Matricular / Cancelar) |
| `mobile/lib/utils/relatorio_alunos_turma_pdf.dart` | PDF — relatório de alunos da turma (resumido / detalhado) |
| `mobile/lib/widgets/pdf_export_menu_button.dart` | Menu AppBar (visualizar / exportar PDF) |
| `mobile/lib/utils/entrevista_pdf.dart` | PDF da entrevista (layout fixo) |
| `mobile/lib/constants/campo_texto.dart` | Limites de `TEXTO` no app (espelho da API) |
| `mobile/lib/utils/entrevista_layout_config.dart` | Leitura do YAML |
| `mobile/lib/utils/entrevista_pdf_field_resolver.dart` | Chave → valor (`programas.*`, `forma.*`, …) |
| `mobile/lib/models/entrevista_programas_sociais.dart` | Modelo `programasSociais` da API |
| `mobile/assets/relatorios/` | Fundos PDF/PNG + `entrevista_assistido_v1.yaml` |
| `mobile/lib/utils/resposta_display.dart` | Formatação de respostas dinâmicas |
| `docs/modelo-dados.md` | Entrevista, assistido (`pessoas`), submissões |
| `docs/api.md` | `GET /entrevistas-assistido/:id`, `GET /submissoes/:id` |
| `IdentidadeGrafica.md` | Cores e tipografia |

---

## 10. Fora do escopo v1 (relatórios)

- Editor visual de molde dentro do app
- Geração em massa (ZIP de PDFs) — ver [setup.md](./setup.md)
- Relatório fixo por **pergunta** em formulários dinâmicos (submissões) — ainda planejado (`relatorio_submissao_fixo_pdf.dart`)

---

## 11. Numeração de páginas

Todos os relatórios PDF gerados no app exibem o número da página no **canto superior direito**, no formato **`Pág. 1`**, **`Pág. 2`**, …

| Relatório | Implementação | Arquivo |
|-----------|---------------|---------|
| Submissões (fluxo) | `header` do `pw.MultiPage` | `mobile/lib/utils/pdf_page_number.dart` → `headerSuperiorDireito` |
| Alunos matriculados (fluxo) | `header` do `pw.MultiPage` | `matriculados_pdf.dart` |
| Relatório de alunos da turma | `header` do `pw.MultiPage` | `relatorio_alunos_turma_pdf.dart` |
| Entrevista (layout fixo) | `Positioned` no `Stack` de cada folha | `overlaySuperiorDireito` (padrão: `top: 16`, `right: 20` pt) |

Constantes compartilhadas: fonte 9pt, cor cinza (`#6B7280`), mesma família Open Sans do §12.

---

## 12. Fontes nos PDFs (Unicode)

O pacote `pdf` usa **Helvetica** por padrão, que **não** desenha travessão (`—`), acentos (ã, ç, …) e outros caracteres usados no cadastro (ex.: `município — UF`).

| Item | Detalhe |
|------|---------|
| **Utilitário** | `mobile/lib/utils/pdf_fonts.dart` |
| **Fonte** | Open Sans Regular/Bold via `PdfGoogleFonts` (pacote `printing`) |
| **Uso** | `await PdfFonts.ensureInitialized()` no início de `buildBytes`; `PdfFonts.textStyle(...)` nos `pw.Text` |
| **Onde** | `entrevista_pdf.dart`, `submissao_pdf.dart`, `matriculados_pdf.dart`, `relatorio_alunos_turma_pdf.dart`, `pdf_page_number.dart` |
| **Chrome / 1ª vez** | Pode exigir **rede** para baixar a fonte; depois fica em cache |
| **Erro típico** | `Helvetica has no Unicode support` / `Unable to find a font to draw "—"` — ver [troubleshooting.md](./troubleshooting.md) |

**UI do app** continua com **Arial** (`AppTheme.fontFamily`); o PDF usa Open Sans por limitação técnica do gerador, não do `Theme` Flutter.
