# API REST

## 4. API REST

**Assistidos:** recurso exposto em `/pessoas` (corpo JSON com `pessoaId` onde aplicável). Mensagens de erro e documentação de negócio usam o termo **assistido**; nomes de rotas e campos permanecem `pessoas` / `pessoa`. Ver [Terminologia](./modelo-dados.md#terminologia-assistido--pessoa).

Base URL local: `http://localhost:3000` — produção (Render): `https://cefa-api.onrender.com` ([deploy-render.md](./deploy-render.md))

Rotas protegidas exigem header `Authorization: Bearer <token>` (exceto `/health` e `POST /auth/login`).

### Campos de auditoria nas respostas JSON

Em recursos criados ou atualizados via API autenticada, o JSON inclui (além dos dados do recurso) os IDs e instantes gravados no banco, mais campos **somente leitura** com o login e o nome completo do usuário (resolvidos em `backend/src/lib/auditoria.ts` via `enrichUsuarioMap` + `mapAuditoria` / `mapSoftDeleteAuditoria`; rotas usam `replyMapped` / `replyMappedList` em `backend/src/lib/resposta-api.ts`, que **aguardam** mappers assíncronos antes de enviar o corpo):

```json
{
  "usuarioInclusaoId": "uuid-do-usuario",
  "dataHoraInclusao": "2026-05-18T14:30:00.000Z",
  "usuarioInclusaoNomeUsuario": "alexandre",
  "usuarioInclusaoNome": "Alexandre Silva",
  "usuarioAlteracaoId": "uuid-do-usuario",
  "dataHoraAlteracao": "2026-05-18T15:00:00.000Z",
  "usuarioAlteracaoNomeUsuario": "maria",
  "usuarioAlteracaoNome": "Maria Santos",
  "createdAt": "2026-05-18T14:30:00.000Z"
}
```

Em entidades com **soft delete** que gravam exclusão lógica (`usuarioExclusaoId`, `dataHoraExclusao`), a resposta pode incluir também `usuarioExclusaoNomeUsuario` e `usuarioExclusaoNome` (ex.: bairros, cidades, escolaridades, assistidos, voluntários, alunos).

| Campo (leitura) | Origem |
|-----------------|--------|
| `usuario*NomeUsuario` | `usuarios.nome_usuario` (login) |
| `usuario*Nome` | `usuarios.nome` (nome completo) |

Se o ID de auditoria for `null` (sync/seed/migração antiga), os campos `usuario*NomeUsuario` e `usuario*Nome` vêm `null`. O app Flutter **não** exibe UUID na UI — usa `AuditoriaSection` com `nomeUsuario` e nome completo quando disponíveis ([mobile.md § auditoria](./mobile.md#bloco-de-auditoria-nas-telas)).

`createdAt` repete `dataHoraInclusao` para compatibilidade. O cliente **não** envia campos de auditoria no body de POST/PUT.

### Health

```
GET /health
→ { "status": "ok" }
```

### Autenticação

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/auth/login` | Body: `{ nomeUsuario, senha }` → `token`, `usuario`, `permissoes` |
| `GET` | `/auth/me` | Usuário logado + mapa de permissões por `codigo` de programa |

### Tipos de usuário

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/tipos-usuario` | Lista (`?ativo=`) |
| `GET` | `/tipos-usuario/:id` | Detalhe |
| `POST` | `/tipos-usuario` | Cria |
| `PUT` | `/tipos-usuario/:id` | Atualiza |
| `DELETE` | `/tipos-usuario/:id` | Exclusão; **409** se houver usuários |
| `GET` | `/tipos-usuario/:id/permissoes` | Uma linha por programa em `programas` (`listProgramasParaPermissoes`); tipo **ADMINISTRADOR** → `perfilAdmin: true` (sem grid) |
| `PUT` | `/tipos-usuario/:id/permissoes` | Salva permissões do tipo (body: array com `programaId` e flags; só persiste linhas com ao menos uma flag `true`) |
| `GET` | `/tipos-usuario/:id/tipos-formulario-acesso` | Checklist de tipos (`acessoTotal`, `tipos[]` com `liberado`) — programa `liberacao_tipo_usuario` |
| `PUT` | `/tipos-usuario/:id/tipos-formulario-acesso` | Body: `{ "tipoFormularioIds": ["uuid", ...] }` — substitui a lista do tipo |

### Usuários

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/usuarios` | Lista (`?ativo=`) |
| `GET` | `/usuarios/:id` | Detalhe |
| `POST` | `/usuarios` | Cria (campo `senha` obrigatório) |
| `PUT` | `/usuarios/:id` | Atualiza (`senha` opcional) |
| `DELETE` | `/usuarios/:id` | Exclusão; **409** se for o último admin ativo |
| `GET` | `/usuarios/:id/permissoes` | Override por usuário — mesma regra de listagem que tipo (todos os programas; flags salvas ou `false`) |
| `PUT` | `/usuarios/:id/permissoes` | Salva override (substitui a do tipo por programa quando há linha salva) |
| `GET` | `/usuarios/:id/tipos-formulario-acesso` | Checklist de tipos (`acessoTotal`, `usaOverride`, `tipos[]`) — programa `liberacao_usuario` |
| `PUT` | `/usuarios/:id/tipos-formulario-acesso` | Body: `{ "tipoFormularioIds": [...] }` — ativa override do usuário e substitui a lista |

### Programas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/programas` | Lista para liberação e cadastro de módulos (inclui `moduloSistemaId`, `moduloCodigo`, `moduloNome`, `relatorioSubmoduloId`, `relatorioSubmoduloCodigo`, `relatorioSubmoduloNome`) |
| `GET` | `/programas/:id` | Detalhe |
| `POST` | `/programas` | Cria programa (`codigo`, `nome`, `autoListagem`, `moduloSistemaId` opcional, `relatorioSubmoduloId` quando módulo = Relatórios) — permissão `modulos_sistema` incluir |
| `PUT` | `/programas/:id` | Atualiza nome, `autoListagem`, vínculo ao módulo e submódulo — permissão `modulos_sistema` alterar |

**Exemplo — criar programa (módulo Relatórios):**

```json
POST /programas
{
  "codigo": "meu_relatorio",
  "nome": "Meu relatório",
  "autoListagem": true,
  "moduloSistemaId": "uuid-do-modulo-relatorios",
  "relatorioSubmoduloId": "uuid-do-submodulo-iefa"
}
```

**Exemplo — criar programa (outro módulo):**

```json
POST /programas
{
  "codigo": "meu_programa",
  "nome": "Meu programa",
  "autoListagem": true,
  "moduloSistemaId": "uuid-do-modulo-opcional"
}
```

O código é único e imutável após a criação. Programas do módulo **Relatórios** (`modulos_sistema.codigo = 3`) **exigem** `relatorioSubmoduloId`. Programas criados pela API aparecem na **liberação de acesso** e na lista de **Módulos do sistema** (mesma consulta `GET /programas`).

### Módulos do sistema

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/modulos-sistema/menu` | Menu da Home: módulos ativos (ordenados por **`ordem`**, depois **`nome`**) + programas acessíveis ao usuário, com campos de submódulo quando vinculados (**só autenticação**, sem flag de programa) |
| `GET` | `/modulos-sistema` | Lista (`?ativo=`) com programas vinculados |
| `GET` | `/modulos-sistema/:id` | Detalhe com programas |
| `POST` | `/modulos-sistema` | Cria (`nome`, `descricao`, `ordem`, `ativo`); `codigo` inteiro sequencial gerado no servidor (`max(codigo)+1`) |
| `PUT` | `/modulos-sistema/:id` | Atualiza |
| `DELETE` | `/modulos-sistema/:id` | Exclusão; **409** se houver programas vinculados |
| `PUT` | `/modulos-sistema/:id/programas` | Body: `{ "programaIds": ["uuid", ...] }` — associa programas ao módulo |

**Exemplo — criar módulo:**

```json
POST /modulos-sistema
{
  "nome": "Relatórios",
  "descricao": "Consultas e exportações",
  "ordem": 3,
  "ativo": true
}
```

Resposta inclui `codigo` gerado (ex.: `3`). O campo `codigo` é **imutável** e não entra no `PUT`.

### Submódulos de relatórios

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/relatorio-submodulos` | Lista (`?ativo=`, `?codigo=`, `?nome=`) — programa `relatorio_submodulos` |
| `GET` | `/relatorio-submodulos/:id` | Detalhe |
| `POST` | `/relatorio-submodulos` | Cria (`codigo`, `nome`, `descricao`, `ordem`, `ativo`) |
| `PUT` | `/relatorio-submodulos/:id` | Atualiza (código imutável) |
| `DELETE` | `/relatorio-submodulos/:id` | Exclusão **física**; **409** se houver programas vinculados |

**Exemplo — criar submódulo:**

```json
POST /relatorio-submodulos
{
  "codigo": "iefa",
  "nome": "IEFA",
  "descricao": "Relatórios do IEFA",
  "ordem": 1,
  "ativo": true
}
```

**Exemplo — resposta do menu (trecho de programa com submódulo):**

```json
{
  "codigo": "relatorio_alunos_turma",
  "nome": "Relatório de Alunos da Turma",
  "relatorioSubmoduloId": "uuid",
  "relatorioSubmoduloCodigo": "iefa",
  "relatorioSubmoduloNome": "IEFA",
  "relatorioSubmoduloOrdem": 1
}
```

`GET /modulos-sistema/menu` inclui nos programas os campos de submódulo quando vinculados. Programas do módulo **Relatórios** exigem `relatorioSubmoduloId` em `POST`/`PUT` `/programas`.

### Tipos de formulário

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/tipos-formulario` | Lista operacional (só tipos liberados ao usuário); `?ativo=true`; `?todos=true` lista **todos** (exige programa `tipos_formulario` ou admin) |
| `GET` | `/tipos-formulario/:id` | Detalhe; **403** se tipo fora da liberação (exceto admin / programa `tipos_formulario`) |
| `POST` | `/tipos-formulario` | Cria; concede o novo tipo ao **tipo de usuário** do criador |
| `PUT` | `/tipos-formulario/:id` | Atualiza |
| `DELETE` | `/tipos-formulario/:id` | Exclusão permanente; **409** se houver perguntas ou lançamentos |

**Exemplo — criar tipo:**

```json
POST /tipos-formulario
{
  "nome": "Admissão",
  "descricao": "Formulário de entrada de colaboradores",
  "ativo": true
}
```

Quem cria recebe o tipo liberado no **tipo de usuário** do criador (tabela `tipos_usuario_tipos_formulario`).

### Liberação de tipos de formulário

Complementa as permissões de **programa**. Administrador: `acessoTotal: true` (sem checklist).

**Exemplo — salvar tipos para um tipo de usuário:**

```json
PUT /tipos-usuario/{id}/tipos-formulario-acesso
{
  "tipoFormularioIds": [
    "uuid-tipo-admissao",
    "uuid-tipo-pesquisa"
  ]
}
```

**Resposta (trecho):**

```json
{
  "acessoTotal": false,
  "tipos": [
    {
      "id": "uuid-tipo-admissao",
      "nome": "Admissão",
      "descricao": "...",
      "ativo": true,
      "liberado": true
    }
  ]
}
```

**Exemplo — override por usuário:**

```json
PUT /usuarios/{id}/tipos-formulario-acesso
{
  "tipoFormularioIds": ["uuid-tipo-admissao"]
}
```

Define `override_tipos_formulario = true` no usuário; a lista **substitui** a do tipo de usuário (não faz união). Array vazio = nenhum tipo liberado para esse usuário.

**Listagens operacionais** (`GET /tipos-formulario` sem `todos`, `GET /perguntas`, `GET /submissoes`, `POST /submissoes`) respeitam apenas os tipos liberados ao usuário logado.

### Perguntas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/perguntas` | Lista (`?ativo=`, `?tipoFormularioId=` — usado no filtro da tela **Cadastrar perguntas** e no lançamento, `?opcoesAtivas=true` filtra opções ativas) |
| `GET` | `/perguntas/:id` | Detalhe (inclui `opcoes`) |
| `POST` | `/perguntas` | Cria (tipo `LISTA` exige `opcoes`; tipo `TEXTO` exige `tamanhoCampo` e `linhasCampo`) |
| `PUT` | `/perguntas/:id` | Atualiza (sincroniza `opcoes` sem excluir) |
| `DELETE` | `/perguntas/:id` | Exclusão permanente; **409** se houver respostas |

**Exemplo — criar pergunta:**

```json
POST /perguntas
{
  "enunciado": "Data de admissão",
  "tipoCampo": "DATA",
  "tipoFormularioId": "uuid-do-tipo",
  "ordem": 1,
  "ativo": true
}
```

```json
POST /perguntas
{
  "enunciado": "Observações",
  "tipoCampo": "TEXTO",
  "tamanhoCampo": 250,
  "linhasCampo": 3,
  "tipoFormularioId": "uuid-do-tipo",
  "ordem": 2,
  "ativo": true
}
```

```json
POST /perguntas
{
  "enunciado": "Código interno",
  "tipoCampo": "TEXTO",
  "tamanhoCampo": 30,
  "linhasCampo": 1,
  "tipoFormularioId": "uuid-do-tipo",
  "ordem": 3,
  "ativo": true
}
```

```json
POST /perguntas
{
  "enunciado": "Relato detalhado",
  "tipoCampo": "TEXTO",
  "tamanhoCampo": 5000,
  "linhasCampo": 10,
  "tipoFormularioId": "uuid-do-tipo",
  "ordem": 4,
  "ativo": true
}
```

**Campos `TEXTO` (POST/PUT):**

| Campo | Obrigatório | Intervalo |
|-------|-------------|-----------|
| `tamanhoCampo` | Sim (se `tipoCampo = TEXTO`) | 1–5000 |
| `linhasCampo` | Sim (se `tipoCampo = TEXTO`) | 1–20 |

Fora do tipo `TEXTO`, enviar `tamanhoCampo` ou `linhasCampo` retorna erro de validação.

**Resposta (trecho):**

```json
{
  "id": "...",
  "enunciado": "Observações",
  "tipoCampo": "TEXTO",
  "tamanhoCampo": 250,
  "linhasCampo": 3,
  "tipoFormularioId": "...",
  "tipoFormulario": { "id": "...", "nome": "Admissão" },
  "ordem": 2,
  "ativo": true,
  "usuarioInclusaoId": "uuid-usuario",
  "dataHoraInclusao": "2026-05-18T12:00:00.000Z",
  "usuarioAlteracaoId": "uuid-usuario",
  "dataHoraAlteracao": "2026-05-18T12:00:00.000Z",
  "createdAt": "2026-05-18T12:00:00.000Z"
}
```

**Exemplo — pergunta tipo LISTA:**

```json
POST /perguntas
{
  "enunciado": "Estado civil",
  "tipoCampo": "LISTA",
  "tipoFormularioId": "uuid-do-tipo",
  "ordem": 3,
  "ativo": true,
  "opcoes": [
    { "rotulo": "Solteiro(a)", "ordem": 0, "ativo": true },
    { "rotulo": "Casado(a)", "ordem": 1, "ativo": true }
  ]
}
```

**Atualizar opção existente (desativar, sem excluir):**

```json
PUT /perguntas/:id
{
  "opcoes": [
    { "id": "uuid-opcao-1", "rotulo": "Solteiro(a)", "ordem": 0, "ativo": true },
    { "id": "uuid-opcao-2", "rotulo": "Casado(a)", "ordem": 1, "ativo": false }
  ]
}
```

### Assistidos (`/pessoas`)

Cadastro dos **assistidos** do centro. Rotas e payload usam o nome técnico `pessoas` / `pessoaId` (sem migration). Na interface: **Assistido**. Ver [Terminologia](./modelo-dados.md#terminologia-assistido--pessoa).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/pessoas` | Lista assistidos (`?ativo=`, `?nome=`, `?cpf=`, `?rg=`; `?q=` legado) |
| `GET` | `/pessoas/:id` | Detalhe do assistido |
| `POST` | `/pessoas` | Cria assistido |
| `PUT` | `/pessoas/:id` | Atualiza assistido |
| `DELETE` | `/pessoas/:id` | Exclusão permanente; **409** se houver lançamentos ou entrevistas |

**Exemplo — criar assistido:**

```json
POST /pessoas
{
  "nome": "Maria Silva",
  "nomeSocial": "Maria",
  "nomeMae": "Ana Silva",
  "dtNascimento": "15/03/1990",
  "cpf": "52998224725",
  "rg": "123456789",
  "rgOrgaoEmissao": "SSP/SP",
  "nis": "12345678901",
  "endereco": "Rua das Flores",
  "enderecoNumero": "100",
  "enderecoComplemento": "Apto 12",
  "bairroCodigo": 1,
  "cidadeCodigo": 2,
  "telefone": "11999998888",
  "urbanoRural": "URBANO",
  "ativo": true
}
```

Campos opcionais podem ser omitidos ou enviados como `null`. `bairroCodigo` e `cidadeCodigo` devem referenciar registros **ativos** existentes.

**Resposta (trecho):** CPF/RG formatados para exibição (`cpfFormatado`, `rgFormatado`); pode incluir `bairro` e `cidade` aninhados quando houver FK.

### Cidades

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/cidades` | Lista (`?ativo=true` padrão; `?ativo=false` inclui excluídos logicamente) |
| `GET` | `/cidades/:id` | Detalhe |
| `POST` | `/cidades` | Cria (`nomeMunicipio`, `estado`) — `codigo` gerado automaticamente |
| `PUT` | `/cidades/:id` | Atualiza (`nomeMunicipio`, `estado`); **não** altera `codigo` |
| `DELETE` | `/cidades/:id` | **Soft delete** (`ativo = false`) |

**Exemplo — criar cidade:**

```json
POST /cidades
{
  "nomeMunicipio": "São Paulo",
  "estado": "SP"
}
```

**Resposta (trecho):** inclui `codigo` inteiro atribuído (ex.: `1`, `2`, `3`…).

### Bairros

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/bairros` | Lista (`?ativo=true` padrão; `?codigo=` inteiro; `?nome=`) |
| `GET` | `/bairros/:id` | Detalhe |
| `POST` | `/bairros` | Cria (`nome`) — `codigo` gerado automaticamente |
| `PUT` | `/bairros/:id` | Atualiza (`nome`); **não** altera `codigo` |
| `DELETE` | `/bairros/:id` | **Soft delete** |

**Exemplo — criar bairro:**

```json
POST /bairros
{
  "nome": "Centro"
}
```

**Resposta (trecho):** inclui `codigo` inteiro atribuído.

### Escolaridades

Cadastro usado na aba **Condições Educacionais** da entrevista (`escolaridadeCodigo` em `condicoesEducacionais`).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/escolaridades` | Lista (`?ativo=true` padrão; `?codigo=` inteiro; `?descricao=`) |
| `GET` | `/escolaridades/:id` | Detalhe |
| `POST` | `/escolaridades` | Cria (`descricao`) — `codigo` gerado automaticamente |
| `PUT` | `/escolaridades/:id` | Atualiza (`descricao`); **não** altera `codigo` |
| `DELETE` | `/escolaridades/:id` | **Soft delete** |

**Exemplo — criar escolaridade:**

```json
POST /escolaridades
{
  "descricao": "1º Ano Ens. Fund."
}
```

**Resposta (trecho):** inclui `codigo` inteiro atribuído.

`GET /escolaridades` também é permitido para quem tem **consultar** em `entrevista_assistido` (lista no formulário da entrevista).

### Departamentos

Catálogo de departamentos. Vínculo operacional com **voluntários** via `voluntario_departamento_horarios` (ver abaixo).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/departamentos` | Lista (`?ativo=true` padrão; `?codigo=` inteiro; `?descricao=`) |
| `GET` | `/departamentos/:id` | Detalhe |
| `POST` | `/departamentos` | Cria (`descricao`) — `codigo` gerado automaticamente |
| `PUT` | `/departamentos/:id` | Atualiza (`descricao`); **não** altera `codigo` |
| `DELETE` | `/departamentos/:id` | Desativa (`ativo = false`); **409** se existir vínculo em `voluntario_departamento_horarios` |

**Exemplo — criar departamento:**

```json
POST /departamentos
{
  "descricao": "Assistência Social"
}
```

**Resposta (trecho):** inclui `codigo`, `usuarioInclusaoId`, `dataHoraInclusao`, `usuarioAlteracaoId`, `dataHoraAlteracao` e alias `createdAt`.

### Cursos

Catálogo de cursos (código sequencial automático, descrição, ativo, auditoria).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/cursos` | Lista (`?ativo=`; `?codigo=` inteiro; `?descricao=`) |
| `GET` | `/cursos/:id` | Detalhe |
| `POST` | `/cursos` | Cria (`descricao`) — `codigo` gerado automaticamente |
| `PUT` | `/cursos/:id` | Atualiza (`descricao`); **não** altera `codigo` |
| `DELETE` | `/cursos/:id` | Desativa (`ativo = false`); **409** se existir turma ativa vinculada |

**Exemplo — criar curso:**

```json
POST /cursos
{
  "descricao": "Informática básica"
}
```

### Alunos (`/alunos`)

Cadastro com **dados pessoais**, **endereço** e **contato** (tela **Cadastro de Alunos**). Implementação: `backend/src/services/alunos.ts` (`mapAlunoLista` na listagem; `mapAluno` no detalhe e após `POST`/`PUT`).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/alunos` | Lista enxuta (`?ativo=`; `?nome=`; `?cpf=`) — **sem joins** nem auditoria; ver exemplo abaixo |
| `GET` | `/alunos/:id` | Detalhe completo (FKs resolvidas, auditoria, campos formatados) |
| `POST` | `/alunos` | Cria |
| `PUT` | `/alunos/:id` | Atualiza |
| `DELETE` | `/alunos/:id` | Desativa (`ativo = false`) |

`estadoCivil`: `CASADO`, `DIVORCIADO`, `SEPARADO`, `SOLTEIRO`, `VIUVO`.

**Exemplo — listagem (`GET /alunos`):**

```json
[
  {
    "id": "uuid",
    "nome": "João da Silva",
    "cpf": "12345678901",
    "cpfFormatado": "123.456.789-01",
    "dtNascimento": "10/05/1990",
    "idade": 35,
    "ativo": true
  }
]
```

**Exemplo — criar aluno (trecho):**

```json
POST /alunos
{
  "nome": "João da Silva",
  "nomeSocial": "João",
  "estadoCivil": "SOLTEIRO",
  "dtExpedicaoRg": "15/03/2010",
  "dtNascimento": "10/05/1990",
  "naturalidadeCodigo": 1,
  "escolaridadeCodigo": 2,
  "nomeUltimaEscola": "Escola Municipal Central",
  "endereco": "Rua das Flores",
  "enderecoNumero": "100",
  "bairro": "Centro",
  "cep": "12345678",
  "cidadeCodigo": 1,
  "telefone": "1133334444",
  "celular": "11999998888",
  "telefoneRecado": "1188887777",
  "email": "joao@email.com"
}
```

**Resposta de `POST`/`PUT`/`GET /:id` (trecho):** inclui `idade` (calculada), rótulos (`estadoCivilRotulo`, `naturalidadeNome`, `cidadeNome`, `escolaridadeDescricao`), campos formatados (`cpfFormatado`, `cepFormatado`, `telefoneFormatado`, etc.) e auditoria.

### Turmas (`/turmas`)

Cadastro de **turmas** vinculadas a um **curso** (tela **Cadastro de Turmas**). Implementação: `backend/src/services/turmas.ts`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/turmas` | Lista (`?ativo=`; `?codigo=`; `?nome=`; `?cursoCodigo=`; `?cursoDescricao=`; `?periodo=`; `?situacao=`) |
| `GET` | `/turmas/:id` | Detalhe com auditoria |
| `POST` | `/turmas` | Cria — `codigo` gerado |
| `PUT` | `/turmas/:id` | Atualiza |
| `DELETE` | `/turmas/:id` | Desativa (`ativo = false`) — **409** se houver inscrições ativas |

`periodo`: `MANHA`, `TARDE`, `NOITE`. `situacao`: `ABERTA`, `FECHADA` (padrão `ABERTA` no `POST`). `cursoCodigo` deve referenciar curso **ativo**. **409** ao criar/alterar para `ABERTA` se já existir outra turma aberta no mesmo curso + período (mensagem orienta finalizar a turma existente).

**Exemplo — criar turma:**

```json
POST /turmas
{
  "nome": "Informática — Turma A",
  "cursoCodigo": 2,
  "periodo": "MANHA",
  "situacao": "ABERTA"
}
```

### Inscrições (`/inscricoes`)

Inscrição de **aluno** em **turma** (tela **Inscrição em curso**). Implementação: `backend/src/services/inscricoes.ts` (`mapInscricaoLista` na listagem; `mapInscricao` síncrono no detalhe e após `POST`/`PUT`/`DELETE` via `replyMapped`).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/inscricoes` | Lista (`?ativo=`; `?codigo=`; `?alunoId=`; `?alunoNome=`; `?alunoCpf=`; `?turmaCodigo=`; `?turmaNome=`; `?cursoCodigo=`; `?cursoDescricao=`) — joins em aluno/turma/curso para rótulos; inclui `matriculado` e `matriculaCancelada`; filtros por ID/código têm precedência sobre busca textual no mesmo eixo |
| `GET` | `/inscricoes/:id` | Detalhe completo (informações gerais, `rendaFamiliar`, `rendaPerCapita`, auditoria) |
| `POST` | `/inscricoes` | Cria — `codigo` gerado; corpo completo incluindo `rendaFamiliar` |
| `PUT` | `/inscricoes/:id` | Atualiza corpo completo; `rendaFamiliar` substitui todas as linhas |
| `DELETE` | `/inscricoes/:id` | Desativa (`ativo = false`) |

`alunoId` e `turmaCodigo` obrigatórios; turma **ativa**; novas inscrições e troca de turma exigem turma **aberta** (`situacao = ABERTA`). Resposta inclui `turmaCodigo`, `turmaNome`, `cursoCodigo`, `cursoDescricao`, `periodo`/`periodoRotulo` (da turma). Campos condicionais (SENAC/SENAI, encaminhamento, necessidade especial, medicação) são limpos na gravação quando o checkbox correspondente é `false` — `fazAcompanhamentoMedico` é independente de `tomaMedicacao`/`quaisMedicacoes`.

**Exemplo — listagem (`GET /inscricoes`):**

```json
[
  {
    "id": "uuid",
    "codigo": 1,
    "alunoId": "uuid-aluno",
    "alunoNome": "João da Silva",
    "alunoCpf": "12345678901",
    "alunoCpfFormatado": "123.456.789-01",
    "turmaCodigo": 1,
    "turmaNome": "Informática — Turma A",
    "cursoCodigo": 2,
    "cursoDescricao": "Informática básica",
    "dtCurso": "10/06/2026",
    "periodo": "MANHA",
    "periodoRotulo": "Manhã",
    "matriculado": true,
    "matriculaCancelada": false,
    "ativo": true
  }
]
```

**Exemplo — criar inscrição (trecho):**

```json
POST /inscricoes
{
  "alunoId": "uuid-aluno",
  "turmaCodigo": 1,
  "dtCurso": "10/06/2026",
  "jaFezCursoSenacSenai": true,
  "cursoSenacSenaiDescricao": "Excel básico",
  "possuiEncaminhamento": false,
  "possuiNecessidadeEspecial": false,
  "fazAcompanhamentoMedico": false,
  "tomaMedicacao": true,
  "quaisMedicacoes": "Losartana 50mg",
  "vacinacao": "Em dia",
  "alergias": "Nenhuma",
  "rendaFamiliar": [
    {
      "nome": "Maria Silva",
      "idade": 45,
      "renda": "1500,00",
      "parentesco": "Mãe",
      "profissao": "Doméstica"
    }
  ]
}
```

**Resposta de `POST`/`PUT`/`GET /:id` (trecho):** inclui `rendaFamiliar` (array com `rendaFormatada`), `rendaPerCapita`, `rendaPerCapitaFormatada`, `matriculado`, `matriculaCancelada`, `dtInicioCurso`, `usuarioMatriculaId`, `dataHoraMatricula`, `usuarioCancelamentoMatriculaId`, `dataHoraCancelamentoMatricula`, rótulos de aluno/curso/período, campos formatados e auditoria.

### Matrícula de inscrições (`/inscricoes/matricula`)

Processo **Matricular Alunos no Curso** (programa `matricula_alunos`). Implementação: `backend/src/services/inscricao-matricula.ts`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/inscricoes/matricula/candidatos` | Candidatos da turma (`?turmaCodigo=`) — **exclui** inscrições com `matriculaCancelada=true`; ordenação: encaminhamento primeiro, depois menor renda per capita; inclui `totalMatriculados` |
| `POST` | `/inscricoes/matricula` | Grava matrícula dos IDs selecionados |

Corpo do `POST`:

```json
{
  "turmaCodigo": 1,
  "dtInicioCurso": "10/06/2026",
  "vagas": 20,
  "inscricaoIds": ["uuid-inscricao-1", "uuid-inscricao-2"]
}
```

`dtInicioCurso`: na UI do app, rótulo **Data da matrícula** (pré-preenchida com hoje na inclusão).

Regras: `inscricaoIds` contém apenas inscrições **ainda não matriculadas** (IDs já matriculados são ignorados); novas matrículas gravam `matriculado = true`, `dtInicioCurso`, `usuarioMatriculaId` e `dataHoraMatricula`; quantidade de IDs novos ≤ vagas disponíveis (`vagas` − matriculados atuais, contando só `matriculado=true` e `matriculaCancelada=false`); **409** se não houver vagas disponíveis; **400** se nenhum ID novo for informado; **400** se algum ID tiver `matriculaCancelada=true` (*Não é possível matricular aluno com matrícula cancelada nesta turma*).

**Resposta (lista de candidatos após gravar ou no GET):** `turmaCodigo`, `turmaNome`, `cursoCodigo`, `cursoDescricao`, `periodo`, `periodoRotulo`, `totalMatriculados`, `candidatos[]` com `alunoNome`, `alunoIdade`, `escolaridadeDescricao`, `orgaoEncaminhamento`, `rendaPerCapita`, `matriculado`.

### Cancelamento de matrícula (`/inscricoes/cancelamento-matricula`)

Processo **Cancelar Matrícula de Alunos no Curso** (programa `cancelamento_matricula_alunos`). Implementação: `backend/src/services/inscricao-cancelamento-matricula.ts`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/inscricoes/cancelamento-matricula/matriculados` | Alunos matriculados ativos da turma (`?turmaCodigo=`) — `matriculado=true` e `matriculaCancelada=false`; ordenação por nome do aluno |
| `POST` | `/inscricoes/cancelamento-matricula` | Cancela matrícula dos IDs selecionados |

Corpo do `POST`:

```json
{
  "turmaCodigo": 1,
  "inscricaoIds": ["uuid-inscricao-1", "uuid-inscricao-2"]
}
```

Regras: cada ID deve pertencer à turma e estar **matriculado** (`matriculaCancelada=false`); grava `matriculado=false`, `matriculaCancelada=true`, `usuarioCancelamentoMatriculaId` e `dataHoraCancelamentoMatricula`; **400** se nenhum ID válido ou inscrição não matriculada na turma.

**Resposta (GET e após POST):** `turmaCodigo`, `turmaNome`, `cursoCodigo`, `cursoDescricao`, `periodo`, `periodoRotulo`, `totalMatriculados`, `matriculados[]` com `alunoNome`, `alunoCpf`, `alunoCpfFormatado`, `dataMatricula` (`dtInicioCurso` ou data de `dataHoraMatricula`), `alunoIdade`, `escolaridadeDescricao`, `orgaoEncaminhamento`.

### Relatório de Alunos da Turma (`/inscricoes/relatorio-alunos-turma`)

Processo **Relatório de Alunos da Turma** (programa `relatorio_alunos_turma`). Implementação: `backend/src/services/relatorio-alunos-turma.ts`. Geração do PDF no app — ver [relatorios.md §8](./relatorios.md#8-relatório-de-alunos-da-turma-implementado).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/inscricoes/relatorio-alunos-turma/cursos` | Cursos **ativos** para o filtro da tela (programa `relatorio_alunos_turma`; não exige `cursos` na liberação) |
| `GET` | `/inscricoes/relatorio-alunos-turma/turmas` | Turmas **ativas** do curso (`?cursoCodigo=` obrigatório) |
| `GET` | `/inscricoes/relatorio-alunos-turma` | Dados do relatório conforme filtros |

**Query em `GET /inscricoes/relatorio-alunos-turma`:**

| Parâmetro | Descrição |
|-----------|-----------|
| `cursoCodigo` | Opcional — omitir = **todos os cursos** |
| `turmaCodigo` | Opcional — só com `cursoCodigo`; omitir = **todas as turmas** do curso; **400** se informado sem curso |
| `situacao` | `MATRICULADO`, `MATRICULA_CANCELADA`, `A_MATRICULAR` ou `TODAS` (padrão `TODAS`) — filtra **linhas** da tabela; o **resumo** por turma sempre traz totais completos |

**Situação do aluno (regra):**

| Código | Condição |
|--------|----------|
| `MATRICULADO` | `matriculado=true` e `matriculaCancelada=false` |
| `MATRICULA_CANCELADA` | `matriculaCancelada=true` |
| `A_MATRICULAR` | `matriculado=false` e `matriculaCancelada=false` |

**Resposta (trecho):** `filtros` (`todosCursos`, `todasTurmas`, `cursoCodigo`, `turmaCodigo`, `situacao`); `secoes[]` por turma (`cursoDescricao`, `turmaNome`, `periodoRotulo`, `situacaoTurmaRotulo`, `alunos[]`, `resumo` com `matriculados`, `matriculasCanceladas` e `aMatricular` se turma **Aberta**); `resumoGeral[]` com totais por turma para a página final do PDF.

Cada aluno em `alunos[]`: `alunoNome`, `alunoCpf`/`alunoCpfFormatado`, `alunoIdade`, `escolaridadeDescricao`, `dataInscricao`, `dataMatricula`, `dataCancelamento`, `situacao`, `dataUltSituacao`, `quantidadeAtendimentos` (contagem em `inscricao_atendimentos`).

### Atendimentos de alunos (`/inscricao-atendimentos`)

Processo **Atendimento de Alunos** (programa `atendimento_alunos`). Implementação: `backend/src/services/inscricao-atendimentos.ts`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/inscricao-atendimentos/alunos-matriculados` | Pesquisa alunos na turma (`?turmaCodigo=` obrigatório; `?nome=` e/ou `?cpf=` — exige ao menos um) — inclui **matriculados** e com **matrícula cancelada** (para consultar histórico) |
| `GET` | `/inscricao-atendimentos` | Lista atendimentos (`?inscricaoId=` **ou** `?turmaCodigo=` + `?alunoId=`) — exige inscrição **ativa** (não exige matrícula ativa) |
| `GET` | `/inscricao-atendimentos/:id` | Detalhe com auditoria |
| `POST` | `/inscricao-atendimentos` | Cria atendimento |
| `PUT` | `/inscricao-atendimentos/:id` | Altera data e descrição |
| `DELETE` | `/inscricao-atendimentos/:id` | Exclusão **física** |

**Exemplo — criar atendimento:**

```json
POST /inscricao-atendimentos
{
  "turmaCodigo": 1,
  "alunoId": "uuid-aluno",
  "dataAtendimento": "11/06/2026",
  "descricao": "Orientação sobre frequência e material didático."
}
```

Regras: **`POST`** exige inscrição **ativa** e **matriculada** (`matriculado=true`, `matriculaCancelada=false`); **`GET`** (lista), **`PUT`** e **`DELETE`** exigem apenas inscrição **ativa** — histórico permanece acessível após cancelamento da matrícula; `descricao` até 2000 caracteres; listagem retorna `descricaoResumo` (50 caracteres) e flags `matriculado` / `matriculaCancelada`; desativar inscrição com atendimentos → **409**.

**Resposta `GET /inscricao-atendimentos` (trecho):** `inscricaoId`, `alunoNome`, `turmaNome`, `cursoDescricao`, `matriculado`, `matriculaCancelada`, `atendimentos[]` com `dataAtendimento` e `descricaoResumo`.

### Voluntários

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/voluntarios` | Lista (`?ativo=true` padrão; `?codigo=`; `?nome=` busca em **nome** e **nomeCracha**; `?empresa=`; `?cpf=`; `?departamentoCodigo=` — com ao menos um vínculo naquele departamento) |
| `GET` | `/voluntarios/:id` | Detalhe (inclui `cidadeNome`, `cidadeEstado`, rótulos formatados) |
| `POST` | `/voluntarios` | Cria — `codigo` gerado; `nome` e `nomeCracha` obrigatórios |
| `PUT` | `/voluntarios/:id` | Atualiza campos; **não** altera `codigo` |
| `DELETE` | `/voluntarios/:id` | Desativa (`ativo = false`) |

`estadoCivil`: `CASADO`, `DIVORCIADO`, `SEPARADO`, `SOLTEIRO`, `VIUVO`. `cidadeCodigo` deve referenciar município **ativo**. `fichaMedica` até 1000 caracteres.

**Exemplo — criar voluntário:**

```json
POST /voluntarios
{
  "nome": "Maria Silva Santos",
  "nomeCracha": "Maria Silva",
  "empresa": "Empresa XYZ",
  "funcao": "Atendimento",
  "estadoCivil": "SOLTEIRO",
  "dtNascimento": "15/03/85",
  "cidadeCodigo": 1,
  "cpf": "12345678901",
  "diaVencimento": 10,
  "tempoTrabalhoCentro": 3
}
```

### Voluntário × departamento (horários)

Vínculo na tabela `voluntario_departamento_horarios`. Permissão: programa `voluntarios`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/voluntarios/:voluntarioId/departamento-horarios` | Lista vínculos do voluntário |
| `POST` | `/voluntarios/:voluntarioId/departamento-horarios` | Cria vínculo |
| `PUT` | `/voluntario-departamento-horarios/:id` | Atualiza |
| `DELETE` | `/voluntario-departamento-horarios/:id` | Remove (físico) |

Body do `POST` (exemplo):

```json
{
  "departamentoCodigo": 1,
  "diaSemana": "SEGUNDA_FEIRA",
  "horaInicio": "08:00",
  "horaTermino": "12:00"
}
```

`diaSemana`: `DOMINGO`, `SEGUNDA_FEIRA`, `TERCA_FEIRA`, `QUARTA_FEIRA`, `QUINTA_FEIRA`, `SEXTA_FEIRA`, `SABADO`.

`horaInicio` / `horaTermino`: string `HH:mm` (ex.: `"08:00"`). No app, `0800` é aceito na digitação e normalizado ao sair do campo.

**Resposta (trecho do vínculo):** `voluntarioNome`, `departamentoDescricao`, `diaSemanaRotulo`, `horaInicio`, `horaTermino`, auditoria.

### Entrevistas com o assistido

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/entrevistas-assistido` | Lista resumos (`?nome=`, `?cpf=` do assistido, `?pessoaId=`) |
| `POST` | `/entrevistas-assistido` | Cria entrevista + formas de acesso + composição + trabalho + educacional + deficiências + **gestantes** + `saudeFamilia` (transação) |
| `GET` | `/entrevistas-assistido/:id` | Detalhe com **assistido completo** (objeto `pessoa`), formas, composição, trabalho, educacional, deficiências, **`gestantesFamilia`** e `saudeFamilia` |
| `PUT` | `/entrevistas-assistido/:id` | Atualiza entrevista e filhos (transação; substitui todas as linhas filhas, gestantes e questionário de saúde) |
| `DELETE` | `/entrevistas-assistido/:id` | Exclusão permanente da entrevista e registros filhos |

Permissão: programa `entrevista_assistido` (`podeIncluir` no POST; `podeAlterar` no PUT; `podeExcluir` no DELETE; GET aceita qualquer flag no programa, como demais recursos).

**Exemplo — registrar entrevista:**

```json
POST /entrevistas-assistido
{
  "pessoaId": "uuid-do-assistido",
  "dataEntrevista": "18/05/26",
  "formasAcesso": ["DEMANDA_ESPONTANEA", "OUTROS"],
  "outrosTexto": "Indicação de vizinho",
  "composicaoFamiliar": [
    {
      "nome": "João Silva",
      "cpf": "12345678909",
      "dtNascimento": "10/05/2010",
      "parentesco": "Filho"
    }
  ],
  "condicoesTrabalho": [
    {
      "nome": "Maria Silva",
      "ocupacao": "EMPREGADO_COM_CARTEIRA",
      "condicoesTrabalho": "CLT, 40h",
      "vrBeneficioSocial": "0",
      "rendaMensal": "2500,00"
    }
  ],
  "condicoesEducacionais": [
    {
      "nome": "João Silva",
      "idade": 14,
      "escolaridadeCodigo": 1,
      "sabeLerEscrever": true,
      "frequentaEscola": true
    }
  ],
  "deficienciasFamilia": [
    {
      "nome": "João Silva",
      "tipoDeficiencia": "DEFICIENCIA_MENTAL_INTELECTUAL",
      "necessitaCuidadosConstantes": true,
      "quemECuidador": "Maria Silva"
    }
  ],
  "programasSociais": {
    "bolsaFamilia": true,
    "peti": false,
    "bpc": false,
    "outrosProgramas": false,
    "cras": true,
    "creas": false
  },
  "saudeFamilia": {
    "remediosControladosMental": "NAO",
    "usoAbusivoAlcool": "NAO",
    "usoAbusivoDrogas": "NAO",
    "temGestante": "SIM"
  },
  "gestantesFamilia": [
    {
      "nome": "Ana Silva",
      "mesesGestacao": 6,
      "iniciouPreNatal": "SIM"
    },
    {
      "nome": "Maria Silva",
      "mesesGestacao": 4,
      "iniciouPreNatal": "NAO"
    }
  ]
}
```

**Validação — gestantes**

| `saudeFamilia.temGestante` | `gestantesFamilia` |
|----------------------------|-------------------|
| `SIM` | Ao menos um item; cada item exige `nome`, `mesesGestacao` (0–10) e `iniciouPreNatal` (`SIM` / `NAO`) |
| `NAO` ou omitido | Array vazio ou omitido; enviar gestantes retorna **400** |

Arrays `composicaoFamiliar`, `condicoesTrabalho`, `condicoesEducacionais`, `deficienciasFamilia` e `gestantesFamilia` podem ser omitidos ou vazios quando não se aplicam. `programasSociais` e `saudeFamilia` podem ser `{}` ou omitidos. Em `programasSociais`, se `outrosProgramas` ou `outrosAtendimentoFamilia` for `true`, o texto correspondente (`outrosProgramasSociais` / `outrosOrgaosSociais`, até 30 caracteres) é obrigatório. Valores monetários aceitam número ou string no formato brasileiro (`1.234,56`).

**Resposta `GET /:id` (trecho):** objeto `pessoa` (assistido) no **mesmo formato** de `GET /pessoas/:id` (`mapPessoa`: nome, documentos formatados, endereço, `bairroNome`, `cidadeNome`, `cidadeEstado`, telefones formatados, `urbanoRural`, etc.); mais `formasAcesso` com rótulos, `programasSociais` (booleans de programas/órgãos + textos `outrosProgramasSociais` / `outrosOrgaosSociais`), `composicaoFamiliar` (`cpfFormatado` quando houver CPF), `condicoesTrabalho` (`ocupacaoRotulo`), `condicoesEducacionais` (`escolaridadeRotulo`), `deficienciasFamilia` (`tipoDeficienciaRotulo`), `gestantesFamilia` (`iniciouPreNatalRotulo`), `saudeFamilia` (com rótulos `*Rotulo` para enums Sim/Não).

**Resposta `GET` lista (trecho):** `pessoa` resumida do assistido (`id`, `nome`, `cpf`, `cpfFormatado`) e contadores (`totalComposicaoFamiliar`, `totalCondicoesTrabalho`, `totalCondicoesEducacionais`, `totalDeficienciasFamilia`, `totalGestantesFamilia`, `totalFormasAcesso`, …).

Se as tabelas de entrevista não existirem no banco, o POST pode retornar **500** com orientação para executar `npx prisma migrate deploy`.

### Submissões

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/submissoes` | Lista resumos (`?tipoFormularioId=`, `?pessoaId=` do assistido, `?nome=`, `?cpf=` do assistido) |
| `POST` | `/submissoes` | Cria submissão + respostas preenchidas (transação; respostas opcionais) |
| `GET` | `/submissoes/:id` | Detalhe com respostas e `opcao.rotulo` (inclui inativas) |

**Exemplo — enviar formulário (respostas parciais):**

```json
POST /submissoes
{
  "tipoFormularioId": "uuid-do-tipo",
  "pessoaId": "uuid-do-assistido",
  "respostas": [
    { "perguntaId": "uuid-1", "valorData": "20/10/2026" },
    { "perguntaId": "uuid-2", "valorTexto": "Comentário" }
  ]
}
```

Perguntas **omitidas** ou com **todos os valores vazios** não precisam aparecer em `respostas`. O array pode ser **`[]`** (submissão só com assistido e tipo).

**Exemplo — envio sem nenhuma resposta:**

```json
POST /submissoes
{
  "tipoFormularioId": "uuid-do-tipo",
  "pessoaId": "uuid-do-assistido",
  "respostas": []
}
```

**Exemplo — listar submissões:**

```
GET /submissoes?tipoFormularioId=uuid&nome=Maria
```

### Regras de negócio (API)

1. **`tipoCampo` imutável** após existirem respostas para a pergunta (HTTP 409).
2. **`tamanhoCampo`** (1–5000) e **`linhasCampo`** (1–20) obrigatórios apenas para `TEXTO`; proibidos para outros tipos. No lançamento, o texto da resposta não pode exceder `tamanhoCampo` da pergunta. Coluna `respostas.valor_texto` é **`TEXT`** no PostgreSQL (migration `20260520110000_texto_linhas_e_valor_text`).
3. **`ordem` única** por `tipoFormularioId` em perguntas (HTTP 409 se duplicada).
4. **Opções LISTA:** mínimo uma opção ativa; opção inativa não aceita novas respostas; opções não são apagadas.
5. **Submissão transacional:** se qualquer resposta **enviada** falhar na validação, nada é gravado. Itens sem valor (pergunta omitida no lançamento) são ignorados; `respostas` pode ser `[]`. Cada item enviado deve ter **no máximo um** campo de valor preenchido.
6. **Sem delete em cascata:** exclusões não removem registros vinculados; dependências retornam **409** (ver `.cursor/rules/sem-delete-cascade.mdc`). **Exceção de estilo:** `cidades` e `bairros` usam soft delete no `DELETE` (registro permanece; `ativo = false`).
7. **CORS** liberado para desenvolvimento (emulador, Chrome, dispositivo na rede).
8. **Autenticação JWT** em todas as rotas exceto `/health` e `POST /auth/login`.
9. **Autorização:** rotas mapeadas em `backend/src/lib/programas.ts` (`PROGRAMA_POR_ROTA`). POST/PUT/DELETE exigem a flag correspondente; **GET** aceita qualquer permissão no programa (ver tabela em Permissões). Negação retorna **403**.
10. **Exclusão de tipo de usuário** bloqueada se houver usuários vinculados (**409**).
11. **Exclusão de usuário** bloqueada se for o último administrador ativo (**409**).
12. **Exclusão de módulo** bloqueada se houver programas vinculados (**409**).
13. **Auditoria automática:** POST/PUT preenchem usuário e data/hora (UTC) conforme usuário do JWT; ver [Auditoria (todas as tabelas)](./modelo-dados.md#auditoria-todas-as-tabelas).
14. **Alunos (`/alunos`):** programa `alunos`; tabela `alunos` (sem vínculo com `pessoas`); `DELETE` desativa (`ativo = false`); `cpf` único quando informado; `naturalidadeCodigo`, `cidadeCodigo` e `escolaridadeCodigo` devem referenciar município/escolaridade **ativos**; telefones 10–11 dígitos; CEP 8 dígitos; `GET /alunos` (lista) retorna só `id`, `nome`, `cpf`, `cpfFormatado`, `dtNascimento`, `idade`, `ativo` — sem joins; detalhe e gravação usam `mapAluno` com todos os campos e `idade` calculada de `dtNascimento`.
15. **Turmas (`/turmas`):** programa `turmas`; tabela `turmas`; `codigo` sequencial; `situacao` `ABERTA`/`FECHADA`; no máximo uma turma **aberta** por `cursoCodigo` + `periodo` (**409** com orientação para finalizar a existente); `DELETE` desativa — **409** se houver inscrições ativas; migration `20260611100000`.
16. **Inscrições (`/inscricoes`):** programa `inscricoes`; tabela `inscricoes_aluno_curso` + `inscricao_renda_familiar`; vínculo via `turmaCodigo` (curso/período vêm da turma); listagem (`mapInscricaoLista`) aceita filtros e retorna `matriculado` e `matriculaCancelada`; `POST`/`PUT`/`GET /:id`/`DELETE` retornam corpo completo mapeado por `mapInscricao`; novas inscrições exigem turma **aberta**; `tomaMedicacao` + `quaisMedicacoes`; `rendaPerCapita` calculada (soma ÷ quantidade de linhas); campo `dtCurso` — rótulo na UI: **Data de inscrição**; matrícula: `matriculado`, `dtInicioCurso`, `usuarioMatriculaId`, `dataHoraMatricula`; cancelamento: `matriculaCancelada`, `usuarioCancelamentoMatriculaId`, `dataHoraCancelamentoMatricula`.
17. **Matrícula (`/inscricoes/matricula`):** programa `matricula_alunos`; candidatos por `turmaCodigo` (encaminhamento → renda per capita); **exclui** `matriculaCancelada=true`; `POST` com `vagas`, `dtInicioCurso` (UI: **Data da matrícula**) e `inscricaoIds` (somente inscrições novas — já matriculados ignorados); **400** se tentar matricular quem teve matrícula cancelada na turma; app não carrega candidatos ao abrir a tela; **409** se não houver vagas disponíveis; migration `20260611110000`.
18. **Cancelamento de matrícula (`/inscricoes/cancelamento-matricula`):** programa `cancelamento_matricula_alunos`; lista matriculados ativos por turma; `POST` grava cancelamento com auditoria; aluno cancelado **não** volta à tela de matrícula; migration `20260611130000`.
19. **Atendimentos (`/inscricao-atendimentos`):** programa `atendimento_alunos`; tabela `inscricao_atendimentos`; **`POST`** exige matrícula ativa; **`GET`/`PUT`/`DELETE`** permitem histórico com matrícula cancelada; pesquisa de alunos inclui matriculados e cancelados; `DELETE` físico do atendimento; desativar inscrição **409** se houver atendimento; migration `20260611120000`.
20. **Inscrições — listagem no app:** programa `inscricoes`; tela não chama `GET /inscricoes` ao abrir; exige ao menos um filtro (`alunoId`, `cursoCodigo` ou `turmaCodigo`) para habilitar **Buscar**; card exibe ** - MATRICULADO** ou ** - Matricula Cancelada** após o período quando aplicável.
21. **Relatório — alunos matriculados (PDF):** `matriculados_pdf.dart`; dados de `GET /inscricoes/cancelamento-matricula/matriculados` (inclui CPF); telas **Matricular** e **Cancelar matrícula**; ver [relatorios.md §7](./relatorios.md#7-alunos-matriculados--lista-em-fluxo-implementado).
22. **Relatório de Alunos da Turma:** programa `relatorio_alunos_turma`; `GET /inscricoes/relatorio-alunos-turma` (+ `/cursos` e `/turmas` para filtros); PDF resumido (retrato) ou detalhado (paisagem) em `relatorio_alunos_turma_pdf.dart`; ver [relatorios.md §8](./relatorios.md#8-relatório-de-alunos-da-turma-implementado).
23. **Home — ordem dos atalhos:** módulos pela API (`ordem` + nome); programas do módulo selecionado em ordem **alfabética** pelo rótulo no app.

---
