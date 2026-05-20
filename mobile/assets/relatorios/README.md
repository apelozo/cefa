# Relatórios — molde da entrevista com o assistido

## Arquivos

| Arquivo | Uso |
|---------|-----|
| `Ficha_Entrevista_Assistido_pag01.pdf` (e `pag02`, `pag03`, …) | Fundo A4 — PDF rasterizado na geração |
| `entrevista_assistido_v1.yaml` | Mapa de posições — **preencha `x`, `y`, `largura`** |

O gerador está em `mobile/lib/utils/entrevista_pdf.dart` (fontes Unicode: `pdf_fonts.dart`). Documentação completa: [docs/relatorios.md](../../../docs/relatorios.md) §6 e §10.

## Estrutura do YAML

1. **Pessoa** (`pessoa.*`) — cadastro completo do assistido  
2. **Entrevista** — data, formas de acesso, programas sociais/órgãos, composição, trabalho, educação, deficiência, gestantes, questionário de saúde  

### Programas sociais — chaves (`programas.*`)

| Chave | Tipo no PDF |
|-------|-------------|
| `programas.bolsaFamilia`, `peti`, `bpc`, `outrosProgramas` | `tipo: marcador` (X quando marcado) |
| `programas.outrosProgramasSociais` | Texto (até 30 caracteres) |
| `programas.cras`, `centroPop`, `conselhoTutelar`, `ubs`, `creas`, `caps`, `craf`, `outrosAtendimentoFamilia` | Marcador |
| `programas.outrosOrgaosSociais` | Texto (até 30 caracteres) |

### Seção Pessoa — chaves

| Chave | Origem |
|-------|--------|
| `pessoa.nome`, `nomeSocial`, `nomeMae`, `nomePai` | Tabela `pessoas` |
| `pessoa.dtNascimento` | Tabela `pessoas` |
| `pessoa.cpfFormatado`, `rgFormatado`, `rgOrgaoEmissao`, `nis` | API (preferir formatados no papel) |
| `pessoa.endereco`, `enderecoNumero`, `enderecoComplemento` | Tabela `pessoas` |
| `pessoa.bairroNome`, `municipioExibicao` | Join bairro/cidade |
| `pessoa.telefoneFormatado`, `telefone2Formatado` | API |
| `pessoa.urbanoRuralRotulo` ou `urbanoRural.URBANO` / `.RURAL` (marcadores) | Enum `URBANO` / `RURAL` |

### Gestantes na família — chaves (`gestante.linhaN.*`)

Várias gestantes no app → `gestante.linha1`, `linha2`, … (limite no YAML: `limites.gestantesFamilia`, padrão 5).

| Chave | Tipo no PDF |
|-------|-------------|
| `gestante.linha1.nome` | Texto |
| `gestante.linha1.mesesGestacao` | Texto (número) |
| `gestante.linha1.iniciouPreNatal.SIM` / `.NAO` | Marcador (pré-natal da gestante) |
| `saude.temGestante.SIM` / `.NAO` | Marcador (pergunta “tem gestante na família?”) |

Chaves legadas `saude.gestanteNome`, `saude.gestanteMesesGestacao`, `saude.gestanteIniciouPreNatal.*` usam os dados da **primeira** gestante.

## Como preencher

1. Abra `entrevista_assistido_v1.yaml`.
2. Em `fundos`, liste cada página com o arquivo PDF ou PNG.
3. Preencha `x`, `y`, `largura` (em **pt**, origem **superior esquerda**).
4. Campos não medidos: deixe `x: 0`, `y: 0` (são ignorados na geração).
5. Após salvar, **restart completo** do app Flutter (`R`).

### Propriedades

| Propriedade | Descrição |
|-------------|-----------|
| `pagina` | 1, 2, … |
| `x`, `y` | Posição (pt) |
| `largura` | Caixa de texto |
| `tamanhoFonte` | Padrão 9 |
| `tipo: marcador` | Desenha `X` quando o checkbox correspondente está marcado na entrevista (`forma.*`, `programas.*`, …) |
| Campos **booleanos** (tags) | Duas chaves: `....SIM` (valor true) e `....NAO` (valor false), ex.: `educacional.linha1.sabeLerEscrever.SIM` |
| `alinhamento` | `left`, `center`, `right` |

**Novas chaves no YAML:** além de `x`/`y`, registre o mapeamento em `mobile/lib/utils/entrevista_pdf_field_resolver.dart`.

**Marcadores de programas sociais:** só aparecem no PDF se a opção estiver marcada na aba Programas Sociais da entrevista (não basta posicionar no YAML).

### Conversão Inkscape (mm → pt)

```
x_pt = x_mm × 72 ÷ 25,4
y_pt = y_mm × 72 ÷ 25,4
```
