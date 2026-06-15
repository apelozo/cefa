# Atendimento médico e prontuário — planejamento

Documento de **especificação e decisões de arquitetura** para o módulo de prontuário / atendimento médico no Cefa. O código (Prisma, API, telas Flutter) **ainda não foi implementado**.

**Status:** planejamento — aguardando respostas do solicitante antes do desenvolvimento.

---

## Antes de iniciar o desenvolvimento

> **Lembrete:** envie ao assistente as respostas do [checklist §10](#10-checklist-para-iniciar-implementação) (mesmo que parciais) **antes** de pedir implementação. Sem isso, o escopo do MVP, permissões e modelo de dados ficam indefinidos.

Preferências de trabalho a confirmar:

- **Proposta primeiro** (modelo + telas + programas) **ou** implementação direta quando o escopo estiver fechado?
- Criar/atualizar este arquivo junto com cada entrega de código?

---

## 1. Contexto no produto

O **Cefa** (Sistema de Auxílio Centro Espírita Francisco de Assis) já possui:

- Cadastro de **assistidos** (`pessoas`)
- **Entrevista com o assistido** (6 abas, incluindo condições de saúde da família) — escopo **assistência social**, não prontuário clínico
- **Liberação de acesso** em duas camadas: **programa** (incluir/alterar/consultar/excluir) e **tipo de formulário** (operacional)
- **Identidade gráfica** em [`IdentidadeGrafica.md`](../IdentidadeGrafica.md) e widgets `App*` no Flutter
- **Formulários dinâmicos** (`perguntas`, `tipos_formulario`, `submissoes`) — alternativa a JSON livre para campos configuráveis

Rascunho de visão de produto (áreas com visibilidade cruzada): medicamentos, psicológico, **médico**, dentário, farmacêutico — ver [`Modelos Relatorios/Descritivo do Sistema.txt`](../Modelos%20Relatorios/Descritivo%20do%20Sistema.txt).

Este módulo deve ser documentado **separadamente** da entrevista social até o escopo estabilizar. Após implementação, atualizar também [`modelo-dados.md`](./modelo-dados.md), [`api.md`](./api.md) e [`mobile.md`](./mobile.md).

---

## 2. Capacidades e limitações do desenvolvimento (IA + Cefa)

### O que o assistente implementa bem

- CRUD no padrão Cefa: migration Prisma → service → rotas Zod → telas Flutter → programa na liberação
- Permissões por programa, auditoria (`AuditoriaSection`), validação espelhada app/API
- Ditado por voz **somente Android/iOS**, texto final no banco (ver §4)
- Documentação técnica alinhada ao repositório

### O que depende do solicitante ou da instituição

- Regras clínicas e de negócio ambíguas
- Nomes de programas (`codigo`), perfis e visibilidade entre áreas (médico × farmácia × psicologia)
- Decisões LGPD / política de dados de saúde
- Validação em dispositivo real (STT, UX, fluxo com profissionais)
- Integrações externas (e-SUS, etc.) — escopo explícito

### Git e deploy

- Commits e PR apenas quando solicitados
- Ambiente local via `.env.example`; produção Neon/Render conforme [`setup.md`](./setup.md) e [`deploy-render.md`](./deploy-render.md)

---

## 3. Liberação de acesso (reutilizar padrão Cefa)

O prontuário seguirá o mesmo modelo documentado em [`modelo-dados.md` § Permissões](./modelo-dados.md#permissões) e [`mobile.md` § Programas e liberação](./mobile.md#programas-do-sistema-e-liberação-de-acesso):

| Camada | Controla |
|--------|----------|
| **Programa** | Abrir tela + incluir / alterar / consultar / excluir |
| **Tipo de formulário** | Só se o módulo usar tipos operacionais de questionário (opcional) |

**Checklist para novo programa** (códigos a definir no checklist §10):

1. `POST /programas` ou entrada em `PROGRAMAS_CATALOGO` (`backend/src/lib/programas.ts`)
2. Rotas + serviço + validador; `PROGRAMA_POR_ROTA`
3. `Programas.*` em `mobile/lib/auth/programas.dart`
4. Atalho em `mobile/lib/home/home_menu_registry.dart`
5. Módulo na Home (ex.: novo módulo **Saúde**)
6. Liberação por tipo / por usuário

**Identidade visual:** [`IdentidadeGrafica.md`](../IdentidadeGrafica.md), Arial obrigatória (`.cursor/rules/tipografia-arial.mdc`), widgets `AppScaffold`, `AppCard`, `AppButton`, `AppFormTextField`.

---

## 4. Speech-to-text (ditado)

### Decisões acordadas na conversa

| Tópico | Decisão |
|--------|---------|
| Onde funciona | **Apenas Android e iOS** — botão de microfone oculto em Web, Windows, macOS e Linux |
| O que persiste | **Somente o texto** revisado pelo profissional — **não** gravar áudio no banco |
| Backend | Recebe o mesmo JSON/texto que digitação manual; transcrição ocorre **no dispositivo** |
| Custo de infra | **Desprezível** no Neon/Render — sem job de transcrição server-side nem armazenamento de áudio |

### Implementação prevista (quando autorizado)

- Pacote Flutter (ex.: `speech_to_text`), locale `pt_BR`
- Widget reutilizável (ex.: `AppSpeechTextField`) encapsulando detecção de plataforma:

```dart
bool get speechToTextDisponivel {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}
```

- Permissões de microfone só em `AndroidManifest.xml` e `Info.plist`
- Verificar `initialize()` / `isAvailable` antes de exibir o botão
- Campo opcional de auditoria `origemTexto: manual | voz` — a definir no checklist

### Limitações

- Precisão em termos médicos (medicamentos, CID) — **revisão humana obrigatória**
- STT do sistema pode usar serviços do SO/nuvem do fabricante — documentar para LGPD; não substitui política institucional
- Consultório ruidoso: UX com iniciar/parar por campo

---

## 5. Modelo de dados: colunas, JSON e formulários dinâmicos

### Estado atual do repositório

O PostgreSQL do Cefa **não usa colunas `Json`/`jsonb` no Prisma** hoje; domínios existentes preferem **tabelas relacionais** e enums (ex.: entrevista com tabelas filhas).

### Quando JSON (`jsonb`) faz sentido

- Seções que **evoluem** sem migration frequente
- Texto estruturado por versão de formulário
- **Não** como substituto de tudo que vira indicador estatístico

### Quando usar colunas ou tabelas filhas

- Campos estáveis de relatório (data, tipo de atendimento, CID principal, flags de comorbidade)
- Listas clínicas (medicamentos, procedimentos, diagnósticos) — padrão `entrevista_*`

### Estatísticas com JSON

**É possível** no PostgreSQL (`->`, `->>`, `@>`, índices **GIN**, views), desde que:

- Chaves **estáveis** e `schemaVersion` em cada documento
- Tipos consistentes (boolean vs string)
- Campos de KPI conhecidos **espelhados** em colunas indexadas ou tabelas filhas

Exemplo de contrato lógico:

```json
{
  "schemaVersion": 1,
  "anamnese": {
    "queixaPrincipal": "texto",
    "comorbidades": { "diabetes": true, "hipertensao": false }
  },
  "sinaisVitais": {
    "pressaoSistolica": 120,
    "pressaoDiastolica": 80
  },
  "conduta": { "observacoes": "texto livre" }
}
```

### JSON vs “novo campo na tela”

| Abordagem | Novo campo simples | Evita migration? | Evita alterar código? |
|-----------|-------------------|------------------|------------------------|
| Colunas relacionais | Migration + código | Não | Não |
| JSON + tela fixa | Código + validação | Sim | **Não** |
| JSON + schema dinâmico (admin) | Config no banco | Sim | Sim*, se o tipo de campo já existir |
| Módulo **perguntas** Cefa (já existe) | Cadastro admin | Sim (respostas) | Sim*, para questionários |

\* Novos **tipos** de widget (ex.: assinatura) ainda exigem código.

### Recomendação híbrida (pendente validação no checklist)

1. **Cabeçalho relacional:** assistido, data, profissional, tipo, status, auditoria
2. **`jsonb` versionado** para blocos flexíveis e texto clínico
3. **Tabelas filhas** para itens que entram em estatística (medicamentos, CIDs)
4. **Validação Zod** no backend por `schemaVersion`

---

## 6. Comparativo de abordagens para o prontuário

| Abordagem | Prós | Contras |
|-----------|------|---------|
| Só colunas | Relatórios simples, tipagem forte | Migrations a cada campo novo |
| Só JSON + tela fixa | Poupa migration | Quase mesmo trabalho de código; estatística frágil |
| Híbrido (recomendado) | Equilíbrio flexibilidade + KPIs | Desenho inicial mais cuidadoso |
| Reusar **perguntas** | Campos novos sem deploy | Modelo de questionário, não timeline clínica completa |

---

## 7. Referências cruzadas (já implementado)

| Tema | Documento |
|------|-----------|
| Permissões e programas | [`modelo-dados.md` § Permissões](./modelo-dados.md#permissões) |
| API liberação | [`api.md` § tipos/usuários/programas](./api.md#tipos-de-usuário) |
| App liberação e identidade | [`mobile.md`](./mobile.md) |
| Entrevista (saúde social) | [`modelo-dados.md` § entrevista](./modelo-dados.md#entrevista-com-o-assistido-entrevistas_assistido) |
| Aluno — cadastro atual (dados pessoais, endereço e contato) | [`mobile.md` § Cadastro de Alunos](./mobile.md#cadastro-de-alunos) · [`modelo-dados.md` § Aluno](./modelo-dados.md#aluno-alunos) |

---

## 8. Entregáveis previstos (após checklist)

Ordem sugerida:

1. Migration Prisma + [`modelo-dados.md`](./modelo-dados.md)
2. Serviços e rotas + [`api.md`](./api.md)
3. Programas, módulo Home, liberação
4. Telas Flutter + [`mobile.md`](./mobile.md)
5. (Opcional) PDF consulta — padrão [`relatorios.md`](./relatorios.md)
6. (Opcional) widget `AppSpeechTextField` nos campos indicados

---

## 9. Pendências de produto (Descritivo)

Itens do rascunho ainda **não especificados** para implementação:

- Visibilidade entre áreas: psicológico, médico, dentário, farmacêutico, medicamentos
- Coordenadores / grupos de usuário além de tipos de usuário atuais
- Integração ou separação total da **entrevista assistido**

---

## 10. Checklist para iniciar implementação

Preencher e enviar ao assistente **antes** de pedir código.

### Escopo MVP

- [ ] O que entra na v1 e o que fica fora
- [ ] Objetivo em uma frase
- [ ] Ordem de prioridade das telas

### Atores e permissões

- [ ] Quem usa (médico, enfermagem, recepção, farmácia, …)
- [ ] Códigos de programa propostos (ex.: `atendimento_medico`)
- [ ] Quem inclui / altera / consulta / exclui
- [ ] Visibilidade entre áreas (quem vê o quê)

### Vínculo com o existente

- [ ] Sempre vinculado a `pessoas` (assistido)?
- [ ] Histórico (lista + detalhe + edição)?
- [ ] Exclusão física ou soft delete?
- [ ] Módulo na Home (nome e `codigo` do módulo)

### Campos e seções

- [ ] Lista de campos: nome, tipo, obrigatório, tamanho
- [ ] Campos condicionais
- [ ] Listas repetíveis (medicamentos, CID, …)
- [ ] Enums (tipo de atendimento, status, …)
- [ ] Campos que entram em **estatística** (coluna/filha vs JSON)
- [ ] Formulário papel / Word de referência (se houver)

### UI e formulário

- [ ] Tela única ou abas
- [ ] Campos fixos no código **ou** modelo configurável (admin)
- [ ] Frequência de novos campos sem programador
- [ ] Ditado: sim/não; em quais campos
- [ ] Rascunho vs gravar só ao final

### Regras de negócio

- [ ] Alterar após “fechado”?
- [ ] Quem exclui; bloqueio por vínculo
- [ ] Status (rascunho, concluído, cancelado)
- [ ] Validações (CID, CRM, ranges)

### API, relatórios, ambiente

- [ ] Só REST Cefa ou integração externa
- [ ] PDF na consulta (sim/não; molde)
- [ ] Plataforma principal (celular, tablet, web, Windows)

### Preferências de trabalho

- [ ] Proposta técnica primeiro **ou** implementar direto
- [ ] Confirmar: auditoria padrão Cefa; **só texto** no banco para ditado

---

*Documento criado em maio/2026 a partir da conversa de planejamento (capacidades/limitações, STT mobile-only, JSON vs colunas, checklist de implementação).*
