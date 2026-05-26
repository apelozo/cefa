# Visão geral e arquitetura

## 1. Visão geral

O **Cefa** (*Centro Espírita Francisco de Assis*) é o **Sistema de Auxílio Centro Espírita Francisco de Assis**.

Na versão atual, o sistema inclui módulos para **cadastrar perguntas** com tipos de campo configuráveis e permitir que usuários **respondam formulários dinâmicos** gerados a partir dessas perguntas, além de cadastro de **assistidos** (tabela `pessoas`: dados pessoais e endereço), **cidades**, **bairros**, **escolaridades** (usadas na entrevista), **departamentos**, **cursos** (catálogo), **voluntários** (com vínculo de horários por departamento e dia da semana), **alunos de capacitação profissional** (cadastro com abas e renda familiar), **responder questionários** (submissões / `lancamento`), **entrevista com o assistido** (seis abas), consulta com exportação PDF, usuários, **permissões por programa** e **liberação por tipo de formulário**, e organização do menu por **módulos** (código numérico sequencial automático).

Cada conjunto de perguntas pertence a um **Tipo de Formulário** (ex.: “Admissão”, “Pesquisa de satisfação”). Cada **lançamento** vincula um tipo de formulário, um **assistido** (`pessoaId`) e as respostas preenchidas.

### Objetivos da v1

- Cadastro de **tipos de formulário**
- Cadastro de **perguntas** vinculadas a um tipo de formulário (tipo `TEXTO`: `tamanhoCampo` até 5000 caracteres e `linhasCampo` 1–20 para altura do campo no lançamento)
- Cadastro de **assistidos** (identificação, filiação, documentos, endereço e contato; API `pessoas`)
- Cadastro de **cidades** (município, UF, código do município)
- Cadastro de **bairros** (código e nome; soft delete)
- Cadastro de **escolaridades** (código e descrição; soft delete; usado na entrevista)
- Cadastro de **departamentos** (código e descrição; desativação via `DELETE`; **409** se existir vínculo com voluntário)
- Cadastro de **cursos** (código automático e descrição; desativação via `DELETE`)
- Cadastro de **voluntários** (`nome`, nome no crachá, dados pessoais, endereço, contribuição, ficha médica; FK município; estado civil com **Separado(a)**)
- Cadastro de **alunos de capacitação profissional** (dados pessoais, endereço/contato, informações adicionais, renda familiar com per capita calculada)
- **Voluntário × departamento** (`voluntario_departamento_horarios`: dia da semana, hora início/término; mesmo par voluntário/departamento pode repetir)
- **Responder Questionários** (`lancamento`): tipo → pesquisa de assistido → formulário dinâmico → submissão (**nenhuma pergunta obrigatória**)
- **Entrevista com o Assistido**: seleção do assistido e data; abas **Assistência**, **Programas Sociais**, **Composição Familiar**, **Trabalho e Renda**, **Condições Educacionais da Família** e **Condições de Saúde da Família** (registro único por envio)
- **Consulta de respostas**: pesquisar lançamentos, ver detalhe e **exportar PDF**
- **Módulos do sistema**: agrupar programas no menu da Home (CRUD módulos + vínculo programa ↔ módulo); `codigo` gerado na API (`max(codigo)+1`)
- **Programas do sistema**: CRUD de programas (`POST`/`PUT` `/programas`) — listagem unificada com liberação de acesso
- **Liberação por tipo de formulário**: quais tipos cada tipo de usuário ou usuário pode usar em lançamento, perguntas e consulta (independente do programa `tipos_formulario` no cadastro administrativo)
- **Submissão** agrupada (um envio com `pessoaId` + **apenas respostas preenchidas**; pode ter zero linhas em `respostas`)
- **Autenticação** com login (nome de usuário + senha) e **controle de acesso** por programa (incluir, alterar, consultar, excluir)

### Stack técnica

| Camada | Tecnologia |
|--------|------------|
| API | Node.js, Fastify, TypeScript |
| Validação | Zod |
| ORM / migrations | Prisma |
| Banco | PostgreSQL (Neon em produção / Docker opcional local) |
| App | Flutter (mobile-first; roda em Chrome, Android, iOS) |
| HTTP client | Dio |
| Estado (app) | Riverpod |
| PDF (app) | `pdf` + `pdf_fonts`, `pdf_page_number`, `submissao_pdf`, `entrevista_pdf`; numeração **Pág. N** no canto superior direito — ver [relatorios.md](./relatorios.md) |

### Escopo do repositório (obrigatório)

Todo o trabalho neste projeto — código, documentação, assets, configuração e automações — deve permanecer **exclusivamente** na raiz:

**`D:\Projetos\Cursor\Cefa`**

| Permitido | Proibido |
|-----------|----------|
| Alterar `backend/`, `mobile/` e arquivos na raiz do Cefa | Criar, editar ou excluir arquivos em outros repositórios ou pastas fora desta raiz |
| Consultar outros projetos só como **referência** (sem modificar) | Copiar alterações para fora do Cefa ou puxar mudanças de fora sem manter o escopo aqui |

Esta regra também está em [`.cursor/rules/repositorio-cefa.mdc`](../.cursor/rules/repositorio-cefa.mdc) para orientar o assistente de IA em todas as sessões.

---

## 2. Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     App Flutter (mobile/)                    │
│  Login → Home (filtro por módulo) → programas liberados      │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP (JSON) + JWT Bearer
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                   API REST (backend/)                        │
│  /auth · /modulos-sistema · /tipos-formulario · /perguntas  │
│  /pessoas · /cidades · /bairros · /escolaridades · /departamentos · /cursos · /voluntarios · /alunos-capacitacao · /submissoes · /entrevistas-assistido · … │
└────────────────────────────┬────────────────────────────────┘
                             │ Prisma
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL (Neon ou Docker local)               │
│  modulos_sistema · programas · tipos_formulario · tipos_*_acesso  │
│  pessoas · cidades · bairros · escolaridades · departamentos · cursos · voluntarios · alunos_capacitacao_profissional · submissoes · entrevistas_assistido · … │
└─────────────────────────────────────────────────────────────┘
```

### Estrutura de pastas

```
Cefa/
├── .cursor/rules/                 # Regras para o assistente (escopo, Arial, sem cascade)
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/
│   ├── src/
│   │   ├── index.ts
│   │   ├── lib/                   # prisma, auditoria, programas, escolaridade/tipo-deficiencia/resposta-sim-nao, ocupacao-familiar, …
│   │   ├── plugins/               # auth JWT (fastify-plugin) + permissões
│   │   ├── routes/                # auth, pessoas, escolaridades, departamentos, cursos, alunos-capacitacao, voluntarios, …
│   │   ├── services/              # permissoes, escolaridades, departamentos, cursos, alunos-capacitacao, voluntarios, …
│   │   └── validators/
│   └── docker-compose.yml
├── mobile/
│   ├── assets/images/             # Ícones alterar/excluir (SVG)
│   └── lib/
│       ├── auth/                  # constantes de programa (codigos)
│       ├── home/                  # registro de atalhos do menu (HomeMenuRegistry)
│       ├── config/
│       ├── models/                # usuario, modulo_sistema, submissao, permissao, …
│       ├── providers/             # auth_provider, api_client
│       ├── screens/
│       │   ├── auth/              # login
│       │   ├── modulos_sistema/   # CRUD módulos + vínculo com programas
│       │   ├── programas/         # CRUD programas (código, nome, módulo)
│       │   ├── tipos_usuario/     # CRUD tipos
│       │   ├── usuarios/          # CRUD usuários
│       │   ├── liberacao/         # programas + tipos de formulário (abas)
│       │   ├── pessoas/           # cadastro de assistidos (lista, formulário, pesquisa reutilizável)
│       │   ├── entrevista_assistido/  # entrevista (6 abas; inclusão/edição/consulta)
│       │   ├── cidades/           # CRUD municípios (código numérico + UF)
│       │   ├── bairros/           # CRUD bairros (soft delete)
│       │   ├── escolaridades/     # CRUD escolaridades (listbox na entrevista)
│       │   ├── departamentos/     # CRUD departamentos
│       │   ├── cursos/            # CRUD cursos
│       │   ├── alunos_capacitacao/  # alunos de capacitação (formulário com abas)
│       │   ├── voluntarios/       # CRUD voluntários + pesquisa (nome, CPF, departamento)
│       │   ├── lancamento/        # tipo → formulário de respostas
│       │   ├── submissoes/        # consulta + detalhe + PDF
│       │   ├── formulario/        # campos dinâmicos, confirmação
│       │   └── ...
│       ├── services/              # ApiClient (Dio), auth_storage
│       ├── theme/                 # AppTheme, cores, layout (Arial)
│       ├── utils/                 # CPF/RG, hora_formatter, pdf_*, resposta_display, …
│       ├── constants/             # estado_civil_voluntario, tipo_casa_aluno_capacitacao, dia_semana, …
│       ├── assets/relatorios/     # Fundos PDF/PNG + YAML da ficha da entrevista — ver relatorios.md
│       ├── validators/
│       └── widgets/               # PermissaoGate, VoluntarioDepartamentoHorariosEditor, …
├── docs/                  # Documentação por tema (índice: DOCUMENTACAO.md na raiz)
├── IdentidadeGrafica.md
├── DOCUMENTACAO.md        # Índice da documentação
└── README.md
```

### Próximos passos (planejado)

| Etapa | Descrição |
|-------|-----------|
| Demais catálogos | Escolaridades: popular demais descrições via **Cadastrar escolaridades** (só a seed **Nunca Frequentou Escola** veio na migration). |
| Outros vínculos | Expandir uso de departamentos em outras entidades (ex.: assistido, usuário), se necessário — hoje o vínculo ativo é **voluntário × departamento × horário**. |

---
