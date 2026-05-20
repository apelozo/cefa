# Identidade gráfica — App Viagens

Documento extraído da documentação e do código do projeto **App Viagens** (`D:\Projetos\Cursor\Viagens\app_viagens`), com referência principal em `GUIA_IDENTIDADE_VISUAL.md`, `DOCUMENTACAO_ATUAL.md` (§9), `ENTREGAS_E_PENDENCIAS.md` (§2.4) e implementação em `lib/theme/app_theme.dart` e `lib/widgets/`.

**Produto:** App Viagens (planeamento de viagens). O roadmap interno usa o nome **TripWeave**.

**Conceito visual:** interface clara e moderna, com **azul** como cor de marca e **laranja** para ações primárias (CTA), sobre fundos em **gradiente suave** (azul claro → branco), cartões brancos elevados e tipografia **Arial**.

---

## 1. Princípios de design

1. **Fundo de ecrã:** gradiente vertical de `lightBlue` para branco — evitar cinza plano como fundo principal.
2. **Hierarquia de texto:** títulos de ecrã → `headlineLarge` ou `headlineMedium`; secções → `titleLarge`; corpo → `bodyLarge` / `bodyMedium`.
3. **Ações primárias:** botão laranja (`AppButton` padrão); secundárias com contorno azul (`AppButtonType.secondary`).
4. **Superfícies:** cartões brancos com cantos ~16px (`AppCard`); painéis sobre o gradiente com `AppDecor.whiteTopSheet()` quando a lista ou conteúdo “sobe” sobre o fundo branco arredondado no topo.
5. **Referência de padrão:** a **dashboard** (`HomeScreen`) define o visual; todas as telas principais seguem o mesmo sistema de tokens.

---

## 2. Paleta de cores

| Token | Hex | Uso |
|-------|-----|-----|
| `primaryBlue` | `#1F2A8A` | Marca, títulos, ícones principais, texto de tabs selecionadas, contorno de botão secundário |
| `lightBlue` | `#E8F1FF` | Faixa do AppBar, topo do gradiente de fundo |
| `accentOrange` | `#FF8A3D` | CTA, destaques, FAB, indicador de `TabBar`, botões elevados |
| `white` | `#FFFFFF` | Superfícies, fundo final do gradiente, texto em botões primários |
| `neutralGray` | `#6B7280` | Texto secundário, tabs não selecionadas |
| `mediumGray` | `#D1D5DB` | Bordas de campos de formulário (estado normal) |
| `darkGray` | `#1F2937` | Corpo de texto principal |
| `lightGray` | `#F5F8FF` | Fundo suave (alias legado) |
| `green` | `#10B981` | Estados positivos / sucesso (uso pontual) |
| `errorRed` | `Colors.red` (Material) | Erros, eliminação, `AppButtonType.danger` |

**Cores auxiliares (componentes):**

| Uso | Valor |
|-----|-------|
| Borda de cartões / cards do tema | `#E5E7EB` |
| Sombra `AppCard` | `rgba(15, 23, 42, 0.06)`, blur 10, offset `(0, 4)` |
| Sombra `whiteTopSheet` | `rgba(0, 0, 0, 0.06)`, blur 12, offset `(0, -2)` |
| Overlay de modal | `rgba(0, 0, 0, 0.5)` |
| Texto auxiliar em algumas telas | `#64748B` (slate, uso local) |

**ColorScheme Material (tema global):**

- `primary` → `primaryBlue`
- `secondary` → `accentOrange`
- `error` → `errorRed`
- `surface` → `white`

---

## 3. Tipografia

**Família:** `Arial` (global no `ThemeData` e AppBar).

| Estilo | Tamanho | Peso | Cor | Line-height |
|--------|---------|------|-----|-------------|
| `headlineLarge` | 32px | bold | `primaryBlue` | 1.2 |
| `headlineMedium` | 24px | w700 | `primaryBlue` | 1.2 |
| `titleLarge` | 20px | bold | `primaryBlue` | 1.2 |
| `bodyLarge` | 16px | w400 | `darkGray` | 1.5 |
| `bodyMedium` | 14px | w400 | `darkGray` | 1.5 |
| Título AppBar (tema) | 20px | bold | `primaryBlue` | — |
| Botões (`AppButton` / elevated) | 16px | bold | conforme tipo | — |
| SnackBar | 14px | normal | branco sobre `darkGray` | — |

**Pesos usados em destaques pontuais nas telas:** `w600`, `w700`, `w800` para subtítulos e labels de reserva.

---

## 4. Fundos e gradientes

### Gradiente oficial (`AppGradients.screenBackground`)

- **Tipo:** `LinearGradient`
- **Direção:** `topCenter` → `bottomCenter`
- **Cores:** `lightBlue` (#E8F1FF) → `white` (#FFFFFF)
- **Stops:** `0.0` → `0.4` (transição concentrada no terço superior)

**Implementação recomendada:** widget `AppGradientBackground` ou `BoxDecoration(gradient: AppGradients.screenBackground)`.

### Painel superior branco (`AppDecor.whiteTopSheet`)

- Fundo branco
- Cantos superiores arredondados (raio padrão **26px**, configurável)
- Sombra superior suave
- Uso: listas e conteúdo que “assentam” sobre o gradiente (ex.: detalhe de viagem, resultados Places)

---

## 5. Espaçamento e layout

| Token | Valor |
|-------|-------|
| `AppLayout.screenPaddingH` | 24px |
| `AppLayout.screenPaddingTop` | 16px |
| `AppLayout.screenPaddingBottom` | 24px |
| `AppLayout.screenPadding` | `EdgeInsets.fromLTRB(24, 16, 24, 24)` |
| `AppLayout.screenPaddingSymmetricH` | horizontal 24px |
| Padding interno `AppCard` | 16px |
| Padding modal (`showAppModal`) | 24px |
| `insetPadding` modal | horizontal 24, vertical 16 |
| Margem inferior entre cartões | 12px |

---

## 6. Raios de canto e elevação

| Elemento | Raio / elevação |
|----------|-----------------|
| Cartões (`AppCard`, `cardTheme`) | 16px |
| Botões (`AppButton`, `elevatedButtonTheme`) | 12px |
| Campos de texto (`inputDecorationTheme`) | 12px |
| Diálogos / modais | 16px |
| SnackBar | 12px |
| `whiteTopSheet` (topo) | 26px (padrão) |
| AppBar | elevation 0, `surfaceTintColor` transparente |
| Cards do tema Material | elevation 0, borda `#E5E7EB` |

---

## 7. Componentes de interface

### 7.1 AppBar (`AppScreenChrome.appBar`)

- Fundo: `lightBlue`
- Texto e ícones: `primaryBlue`
- Sem elevação; título com `titleLarge` do tema
- `centerTitle`: false (padrão)
- Ícones de ação: cor `primaryBlue`

### 7.2 Botões (`AppButton`)

| Tipo | Fundo | Texto / borda | Altura |
|------|-------|---------------|--------|
| `primary` | `accentOrange` | branco | 56px, largura total |
| `secondary` | transparente | `primaryBlue` + borda 1.6px `primaryBlue` | 56px |
| `danger` | `errorRed` | branco | 56px |

Estado desativado: opacidade ~45% no fundo.

### 7.3 Cartões (`AppCard`)

- Fundo branco, raio 16px
- Borda `#E5E7EB`
- Sombra leve
- Padding 16px; opcional `onTap` com `InkWell`

### 7.4 Campos (`AppInput` + `inputDecorationTheme`)

- Fundo branco preenchido
- Padding interno: 14px horizontal e vertical
- Borda normal: `mediumGray`
- Borda em foco: `primaryBlue`, 1.6px
- Raio 12px

### 7.5 FAB

- Fundo: `accentOrange`
- Ícone/texto: branco

### 7.6 SnackBar

- Comportamento: flutuante (`floating`)
- Fundo: `darkGray`
- Texto: branco, 14px
- Forma: cantos 12px

### 7.7 TabBar

- Indicador: `accentOrange`
- Label selecionada: `primaryBlue`
- Label não selecionada: `neutralGray`

### 7.8 Modais (`showAppModal`)

- Largura máxima: 600px
- Forma: 16px
- Barrier: preto 50% opaco
- *Nota de backlog:* alinhar modais e diálogos genéricos ao mesmo sistema (pendência documentada).

---

## 8. Padrões de composição de ecrã

### Com AppBar

```dart
Scaffold(
  appBar: AppScreenChrome.appBar(context, title: 'Título do ecrã', actions: [...]),
  body: AppGradientBackground(child: /* conteúdo */),
);
```

### Sem AppBar (cabeçalho manual, estilo home)

- `Container` com `BoxDecoration(gradient: AppGradients.screenBackground)`
- `SafeArea` + `padding: AppLayout.screenPadding`

### Imports recomendados

```dart
import '../theme/app_theme.dart';
import '../widgets/app_screen_chrome.dart';
```

---

## 9. Material Design

- **Material 3** ativado (`useMaterial3: true`)
- `scaffoldBackgroundColor` base: branco (o gradiente é aplicado no corpo via chrome/widgets)

---

## 10. Telas alinhadas ao sistema visual

Conforme entregas documentadas, o padrão da dashboard foi aplicado a:

- Home (dashboard)
- Login e registo
- Detalhe de viagem e de cidade
- Wishlist, timeline, sugestões
- Resultados Places
- Formulário de entidades (`EntityFormScreen`)

---

## 11. Ficheiros de referência no repositório origem

| Ficheiro | Conteúdo |
|----------|----------|
| `GUIA_IDENTIDADE_VISUAL.md` | Guia rápido para novas telas Flutter |
| `lib/theme/app_theme.dart` | Cores, gradientes, tema Material, tokens |
| `lib/widgets/app_screen_chrome.dart` | `AppGradientBackground`, `AppScreenChrome` |
| `lib/widgets/app_button.dart` | Botões primário / secundário / perigo |
| `lib/widgets/app_card.dart` | Cartão padrão |
| `lib/widgets/app_input.dart` | Campo de texto |
| `lib/widgets/app_modal.dart` | Diálogo modal |
| `DOCUMENTACAO_ATUAL.md` §9 | Estado do design e UX |
| `ENTREGAS_E_PENDENCIAS.md` §2.4 | Entrega da identidade unificada |

---

## 12. Resumo para replicação (projeto Cefa)

O **Cefa** é o Sistema de Auxílio Centro Espírita Francisco de Assis. Para manter consistência visual com o App Viagens neste frontend:

1. Usar a paleta **azul escuro `#1F2A8A`** + **laranja `#FF8A3D`** + **azul claro `#E8F1FF`**.
2. Aplicar **gradiente vertical** no fundo dos ecrãs principais.
3. Tipografia **Arial** com hierarquia definida (títulos azuis, corpo cinza escuro).
4. CTAs em **laranja**, secundários com **contorno azul**.
5. Superfícies em **cartões brancos 16px** com borda `#E5E7EB`.
6. Espaçamento horizontal padrão **24px**.
7. AppBar / topo em **faixa azul claro** sem sombra.

No projeto Cefa, a tipografia Arial é **obrigatória em todas as telas** — ver `mobile/lib/theme/app_theme.dart` e `.cursor/rules/tipografia-arial.mdc`.

---

*Gerado em 16/05/2026 a partir da documentação do App Viagens. Atualizado para o Cefa em maio/2026.*
