# API REST

## 4. API REST

**Assistidos:** recurso exposto em `/pessoas` (corpo JSON com `pessoaId` onde aplicável). Mensagens de erro e documentação de negócio usam o termo **assistido**; nomes de rotas e campos permanecem `pessoas` / `pessoa`. Ver [Terminologia](./modelo-dados.md#terminologia-assistido--pessoa).

Base URL local: `http://localhost:3000` — produção (Render): `https://cefa-api.onrender.com` ([deploy-render.md](./deploy-render.md))

Rotas protegidas exigem header `Authorization: Bearer <token>` (exceto `/health` e `POST /auth/login`).

### Campos de auditoria nas respostas JSON

Em recursos criados ou atualizados via API autenticada, o JSON inclui (além dos dados do recurso):

```json
{
  "usuarioInclusaoId": "uuid-do-usuario",
  "dataHoraInclusao": "2026-05-18T14:30:00.000Z",
  "usuarioAlteracaoId": "uuid-do-usuario",
  "dataHoraAlteracao": "2026-05-18T15:00:00.000Z",
  "createdAt": "2026-05-18T14:30:00.000Z"
}
```

`createdAt` repete `dataHoraInclusao` para o app Flutter legado. O cliente **não** envia esses campos no body de POST/PUT.

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
| `GET` | `/programas` | Lista para liberação e cadastro de módulos (inclui `moduloSistemaId`, `moduloCodigo`, `moduloNome`) |
| `GET` | `/programas/:id` | Detalhe |
| `POST` | `/programas` | Cria programa (`codigo`, `nome`, `autoListagem`, `moduloSistemaId` opcional) — permissão `modulos_sistema` incluir |
| `PUT` | `/programas/:id` | Atualiza nome, `autoListagem` e vínculo ao módulo — permissão `modulos_sistema` alterar |

**Exemplo — criar programa:**

```json
POST /programas
{
  "codigo": "meu_relatorio",
  "nome": "Meu relatório",
  "autoListagem": true,
  "moduloSistemaId": "uuid-do-modulo-opcional"
}
```

O código é único e imutável após a criação. Programas criados pela API aparecem na **liberação de acesso** e na lista de **Módulos do sistema** (mesma consulta `GET /programas`).

### Módulos do sistema

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/modulos-sistema/menu` | Menu da Home: módulos ativos + programas acessíveis ao usuário (**só autenticação**, sem flag de programa) |
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
| `DELETE` | `/cursos/:id` | Desativa (`ativo = false`) |

**Exemplo — criar curso:**

```json
POST /cursos
{
  "descricao": "Informática básica"
}
```

### Alunos de capacitação profissional

Cadastro com abas (dados pessoais, endereço/contato, informações adicionais, renda familiar). Resposta inclui `idade` (calculada de `dtNascimento`) e `rendaPerCapita` (soma das rendas ÷ quantidade de integrantes com nome).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/alunos-capacitacao` | Lista (`?ativo=`; `?nome=`; `?cpf=`) |
| `GET` | `/alunos-capacitacao/:id` | Detalhe com `rendasFamiliares[]` |
| `POST` | `/alunos-capacitacao` | Cria (body completo + `rendasFamiliares`) |
| `PUT` | `/alunos-capacitacao/:id` | Atualiza (substitui linhas de renda) |
| `DELETE` | `/alunos-capacitacao/:id` | Desativa (`ativo = false`) |

`estadoCivil`: `CASADO`, `DIVORCIADO`, `SEPARADO`, `SOLTEIRO`, `VIUVO`. `tipoCasa`: `PROPRIA`, `CEDIDA`, `ALUGUEL` (com `valorAluguel` obrigatório se `ALUGUEL`).

**Exemplo — criar aluno (trecho):**

```json
POST /alunos-capacitacao
{
  "nome": "João da Silva",
  "nomeSocial": "João",
  "estadoCivil": "SOLTEIRO",
  "dtNascimento": "10/05/1990",
  "naturalidadeCodigo": 1,
  "escolaridadeCodigo": 2,
  "cidadeCodigo": 1,
  "tipoCasa": "ALUGUEL",
  "valorAluguel": 850.00,
  "jaFezCursoSenacSenai": true,
  "cursoSenacSenaiDescricao": "Eletricista",
  "cursoSenacSenaiAno": 2018,
  "rendasFamiliares": [
    { "nome": "Maria Silva", "idade": 45, "renda": 1500, "parentesco": "Mãe", "profissao": "Doméstica" }
  ]
}
```

**Resposta (trecho):** inclui `idade` (calculada), `rendaPerCapita`, `rendasFamiliares[]`, rótulos (`estadoCivilRotulo`, `tipoCasaRotulo`, nomes de município) e auditoria.

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

---
