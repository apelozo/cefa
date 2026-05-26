# Cefa

**Sistema de Auxílio Centro Espírita Francisco de Assis** (*Cefa*).

Inclui, entre outras funções: tipos de formulário e perguntas (formulários dinâmicos; **TEXTO** com até 5000 caracteres e linhas configuráveis no lançamento), **assistidos** (cadastro em `pessoas`, com endereço), **cidades**, **bairros**, **escolaridades** (listbox na entrevista), **departamentos**, **cursos** (catálogo com código automático), **voluntários** (dados completos + horários por departamento/dia da semana), **Alunos de Capacitação Profissional** (cadastro completo com renda familiar), **lançamento** de respostas (campos opcionais), **entrevista com o assistido** (6 abas), **consulta com exportação PDF** (layout compacto + **Pág. N** no canto superior direito), usuários, **permissões por programa** e **liberação por tipo de formulário**, e **módulos do sistema** (código numérico sequencial automático) para organizar o menu.

**Stack:** Node.js · Fastify · Prisma · PostgreSQL · Flutter

## Documentação completa

Consulte **[DOCUMENTACAO.md](./DOCUMENTACAO.md)** (índice) e a pasta **[`docs/`](./docs/)** para o detalhe por tema:

- **Escopo do repositório** — trabalhar somente em `D:\Projetos\Cursor\Cefa`
- Visão geral, arquitetura e modelo de dados (incl. **auditoria**, catálogos com código **inteiro sequencial automático**, **cursos**, **voluntários**, **alunos de capacitação**, cadastro de **assistidos** (`pessoas`), **liberação de tipos de formulário**)
- **Sync na API** — não sobrescreve nome de módulo nem vínculo programa↔módulo definidos na UI
- Referência da API REST (exemplos JSON)
- **Home com filtro por módulo**, telas, fluxos e navegação (`Navigator.push`)
- **Entrevista com o Assistido** (6 abas, incluindo Programas Sociais; **várias gestantes** na aba saúde; PDF da ficha na consulta — molde em `mobile/assets/relatorios/`)
- **Consulta de respostas** e geração de **PDF** em fluxo ([relatórios](./docs/relatorios.md))
- Login, usuários, tipos, permissões por programa e por **tipo de formulário**
- **Auditoria** (usuário e data/hora UTC de inclusão/alteração), tecla **Enter** nos formulários e **seletor com pesquisa** (bairro/município no cadastro de assistido)
- Regras de projeto (Arial, sem delete em cascata) em `.cursor/rules/`
- Configuração, **deploy no Render** ([docs/deploy-render.md](./docs/deploy-render.md)), histórico e troubleshooting
- **Como atualizar a documentação** — ver rodapé de [DOCUMENTACAO.md](./DOCUMENTACAO.md)

## Início rápido

### 1. API

```bash
cd backend
cp .env.example .env   # DATABASE_URL (Neon pooler: use pgbouncer=true — ver .env.example)
npm install
npx prisma migrate deploy
npx prisma generate   # pare a API antes, se der EPERM no Windows
npm run dev
```

API em **http://localhost:3000** — teste: `GET /health`

> **Windows:** se `npx prisma generate` falhar com `EPERM`, encerre `npm run dev` (e instâncias duplicadas do backend) antes de gerar o client.

### 2. App (Chrome)

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Após alterar dependências (ex.: PDF), use **restart completo** (`R`), não só hot reload.

### 3. Login

Usuário inicial: **admin** (senha padrão `admin123` ou valor de `ADMIN_INITIAL_PASSWORD` no `backend/.env`).

Configure também `JWT_SECRET` no `backend/.env` (ver `.env.example`).

O perfil **Administrador** tem acesso total na API e na interface.

### Deploy da API (Render)

API em produção: **`https://cefa-api.onrender.com`** — detalhes em [docs/deploy-render.md](./docs/deploy-render.md).

Testar o app contra a API no Render:

```bash
cd mobile
flutter run -d chrome --dart-define=API_BASE_URL=https://cefa-api.onrender.com
# Android (emulador ou físico):
flutter run --dart-define=API_BASE_URL=https://cefa-api.onrender.com
```

### 4. Ordem de uso no app

1. **Home** — escolha o módulo (**Formulários**, código `1`, ou **Administração**, código `2`)
2. **Tipos de formulário** → **Cadastrar perguntas** → **Cidades** / **Bairros** (opcional) → **Escolaridades** → **Departamentos** / **Cursos** → **Cadastrar voluntários** (vínculo departamento/horário na edição) → **Alunos de Capacitação Profissional** → **Cadastrar assistidos**
3. **Responder Questionários** — tipo → pesquisar assistido → preencher o que quiser (nada é obrigatório) → enviar
4. **Entrevista com o Assistido** — listar, consultar (com **PDF** da ficha), alterar, excluir ou registrar nova entrevista
5. **Consulta de respostas** — buscar lançamentos → abrir detalhe → **PDF**
6. **Administração** — usuários, tipos, liberação (programas + tipos de formulário), **módulos do sistema** (código gerado na API ao criar)

## Estrutura

```
Cefa/
├── .cursor/rules/    # Regras de desenvolvimento (IA e convenções)
├── docs/             # Documentação por tema (índice na raiz)
├── backend/          # API REST
├── mobile/           # App Flutter
├── DOCUMENTACAO.md   # Índice da documentação
├── IdentidadeGrafica.md
└── README.md         # Este arquivo
```

## Endpoints principais

| Recurso | Rotas |
|---------|--------|
| Módulos do sistema | `GET /modulos-sistema/menu`, CRUD `/modulos-sistema` (`POST` sem `codigo` — gerado no servidor), `PUT …/programas` |
| Programas do sistema | `GET` / `POST` `/programas`, `GET` / `PUT` `/programas/:id` — cadastro e liberação usam a mesma lista |
| Liberação tipos formulário | `GET/PUT …/tipos-formulario-acesso` em `/tipos-usuario/:id` e `/usuarios/:id` |
| Tipos de formulário | `/tipos-formulario` (`?todos=true` no cadastro administrativo) |
| Perguntas | `/perguntas` (`?opcoesAtivas=true` no lançamento) |
| Assistidos (`/pessoas`) | `/pessoas` (`?nome=`, `?cpf=`, `?rg=`) |
| Cidades | `/cidades` — `POST` só `nomeMunicipio` + `estado`; código inteiro automático |
| Bairros | `/bairros` — `POST` só `nome`; código inteiro automático; soft delete no `DELETE` |
| Escolaridades | `/escolaridades` — `POST` só `descricao`; código inteiro automático; soft delete no `DELETE` |
| Departamentos | `/departamentos` — `POST` só `descricao`; código inteiro automático; `DELETE` desativa |
| Cursos | `/cursos` — `POST` só `descricao`; código inteiro automático; `DELETE` desativa |
| Alunos de capacitação | `/alunos-capacitacao` — cadastro completo + `rendasFamiliares[]`; `DELETE` desativa |
| Voluntários | `/voluntarios` — código automático; horários em `/voluntarios/:id/departamento-horarios` |
| Submissões | `GET/POST /submissoes`, `GET /submissoes/:id` |
| Entrevistas | CRUD `/entrevistas-assistido` (`GET` lista com `?nome=` / `?cpf=`) |
| Auth | `POST /auth/login`, `GET /auth/me` |
| Usuários / tipos | `/usuarios`, `/tipos-usuario`, permissões e `/programas` |

Detalhes, payloads e validações em [docs/api.md](./docs/api.md) e demais arquivos em [DOCUMENTACAO.md](./DOCUMENTACAO.md).
