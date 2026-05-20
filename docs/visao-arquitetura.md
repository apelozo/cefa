# Visão geral e arquitetura

## 1. Visão geral

O **Cefa** (*Centro Espírita Francisco de Assis*) é o **Sistema de Auxílio Centro Espírita Francisco de Assis**.

Na versão atual, o sistema inclui módulos para **cadastrar perguntas** com tipos de campo configuráveis e permitir que usuários **respondam formulários dinâmicos** gerados a partir dessas perguntas, além de cadastro de **pessoas** (dados pessoais e endereço), **cidades**, **bairros**, lançamentos, **entrevista com o assistido** (seis abas: assistência, programas sociais, composição familiar, trabalho/renda, condições educacionais e condições de saúde), consulta com exportação PDF, usuários, permissões e organização do menu por módulos.

Cada conjunto de perguntas pertence a um **Tipo de Formulário** (ex.: “Admissão”, “Pesquisa de satisfação”). Cada **lançamento** vincula um tipo de formulário, uma **pessoa** e as respostas preenchidas.

### Objetivos da v1

- Cadastro de **tipos de formulário**
- Cadastro de **perguntas** vinculadas a um tipo de formulário (tipo `TEXTO`: `tamanhoCampo` até 5000 caracteres e `linhasCampo` 1–20 para altura do campo no lançamento)
- Cadastro de **pessoas** (identificação, filiação, documentos, endereço e contato)
- Cadastro de **cidades** (município, UF, código do município)
- Cadastro de **bairros** (código e nome; soft delete)
- **Lançamento**: tipo → pesquisa de pessoa → formulário dinâmico → submissão (**nenhuma pergunta obrigatória**)
- **Entrevista com o Assistido**: seleção de pessoa e data; abas **Assistência**, **Programas Sociais**, **Composição Familiar**, **Trabalho e Renda**, **Condições Educacionais da Família** e **Condições de Saúde da Família** (registro único por envio)
- **Consulta de respostas**: pesquisar lançamentos, ver detalhe e **exportar PDF**
- **Módulos do sistema**: agrupar programas no menu da Home (CRUD + vínculo programa ↔ módulo)
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
│  /pessoas · /cidades · /bairros · /submissoes · /entrevistas-assistido · … │
└────────────────────────────┬────────────────────────────────┘
                             │ Prisma
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL (Neon ou Docker local)               │
│  modulos_sistema · programas · tipos_formulario · perguntas  │
│  pessoas · cidades · bairros · submissoes · entrevistas_assistido · … │
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
│   │   ├── routes/                # auth, modulos-sistema, entrevistas-assistido, pessoas, …
│   │   ├── services/              # permissoes, usuarios, tipos-usuario, ...
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
│       │   ├── tipos_usuario/     # CRUD tipos
│       │   ├── usuarios/          # CRUD usuários
│       │   ├── liberacao/         # permissões por tipo e por usuário
│       │   ├── pessoas/           # lista, formulário, pesquisa (reutilizável)
│       │   ├── entrevista_assistido/  # entrevista (6 abas; inclusão/edição/consulta)
│       │   ├── cidades/           # CRUD municípios (código numérico + UF)
│       │   ├── bairros/           # CRUD bairros (soft delete)
│       │   ├── lancamento/        # tipo → formulário de respostas
│       │   ├── submissoes/        # consulta + detalhe + PDF
│       │   ├── formulario/        # campos dinâmicos, confirmação
│       │   └── ...
│       ├── services/              # ApiClient (Dio), auth_storage
│       ├── theme/                 # AppTheme, cores, layout (Arial)
│       ├── utils/                 # CPF/RG, pdf_fonts, pdf_page_number, submissao_pdf, entrevista_pdf, resposta_display, …
│       ├── constants/             # campo_texto (limites TEXTO), …
│       ├── assets/relatorios/     # Fundos PDF/PNG + YAML da ficha da entrevista — ver relatorios.md
│       ├── validators/
│       └── widgets/               # AppSearchableSelectField, PessoaTile, PermissaoGate, …
├── docs/                  # Documentação por tema (índice: DOCUMENTACAO.md na raiz)
├── IdentidadeGrafica.md
├── DOCUMENTACAO.md        # Índice da documentação
└── README.md
```

---
