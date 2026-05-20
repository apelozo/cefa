# API REST

## 4. API REST

Base URL padrão: `http://localhost:3000`

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
| `GET` | `/tipos-usuario/:id/permissoes` | Grid de permissões |
| `PUT` | `/tipos-usuario/:id/permissoes` | Salva permissões do tipo |

### Usuários

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/usuarios` | Lista (`?ativo=`) |
| `GET` | `/usuarios/:id` | Detalhe |
| `POST` | `/usuarios` | Cria (campo `senha` obrigatório) |
| `PUT` | `/usuarios/:id` | Atualiza (`senha` opcional) |
| `DELETE` | `/usuarios/:id` | Exclusão; **409** se for o último admin ativo |
| `GET` | `/usuarios/:id/permissoes` | Permissões individuais |
| `PUT` | `/usuarios/:id/permissoes` | Salva override por usuário |

### Programas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/programas` | Lista para liberação e cadastro de módulos (inclui `moduloSistemaId`, `moduloCodigo`, `moduloNome`) |

### Módulos do sistema

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/modulos-sistema/menu` | Menu da Home: módulos ativos + programas acessíveis ao usuário (**só autenticação**, sem flag de programa) |
| `GET` | `/modulos-sistema` | Lista (`?ativo=`) com programas vinculados |
| `GET` | `/modulos-sistema/:id` | Detalhe com programas |
| `POST` | `/modulos-sistema` | Cria (`codigo`, `nome`, `descricao`, `ordem`, `ativo`) |
| `PUT` | `/modulos-sistema/:id` | Atualiza |
| `DELETE` | `/modulos-sistema/:id` | Exclusão; **409** se houver programas vinculados |
| `PUT` | `/modulos-sistema/:id/programas` | Body: `{ "programaIds": ["uuid", ...] }` — associa programas ao módulo |

**Exemplo — criar módulo:**

```json
POST /modulos-sistema
{
  "codigo": 3,
  "nome": "Relatórios",
  "descricao": "Consultas e exportações",
  "ordem": 3,
  "ativo": true
}
```

O campo `codigo` não pode ser alterado no `PUT` (apenas na criação).

### Tipos de formulário

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/tipos-formulario` | Lista (`?ativo=true`) |
| `GET` | `/tipos-formulario/:id` | Detalhe |
| `POST` | `/tipos-formulario` | Cria |
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

### Pessoas

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/pessoas` | Lista (`?ativo=`, `?nome=`, `?cpf=`, `?rg=`; `?q=` legado) |
| `GET` | `/pessoas/:id` | Detalhe |
| `POST` | `/pessoas` | Cria |
| `PUT` | `/pessoas/:id` | Atualiza |
| `DELETE` | `/pessoas/:id` | Exclusão permanente; **409** se houver lançamentos ou entrevistas |

**Exemplo — criar pessoa:**

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

### Entrevistas com o assistido

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/entrevistas-assistido` | Lista resumos (`?nome=`, `?cpf=`, `?pessoaId=`) |
| `POST` | `/entrevistas-assistido` | Cria entrevista + formas de acesso + composição + trabalho + educacional + deficiências + **gestantes** + `saudeFamilia` (transação) |
| `GET` | `/entrevistas-assistido/:id` | Detalhe com **pessoa completa**, formas, composição, trabalho, educacional, deficiências, **`gestantesFamilia`** e `saudeFamilia` |
| `PUT` | `/entrevistas-assistido/:id` | Atualiza entrevista e filhos (transação; substitui todas as linhas filhas, gestantes e questionário de saúde) |
| `DELETE` | `/entrevistas-assistido/:id` | Exclusão permanente da entrevista e registros filhos |

Permissão: programa `entrevista_assistido` (`podeIncluir` no POST; `podeAlterar` no PUT; `podeExcluir` no DELETE; GET aceita qualquer flag no programa, como demais recursos).

**Exemplo — registrar entrevista:**

```json
POST /entrevistas-assistido
{
  "pessoaId": "uuid-da-pessoa",
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
      "escolaridade": "EF_8_ANO",
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

**Resposta `GET /:id` (trecho):** `pessoa` no **mesmo formato** de `GET /pessoas/:id` (`mapPessoa`: nome, documentos formatados, endereço, `bairroNome`, `cidadeNome`, `cidadeEstado`, telefones formatados, `urbanoRural`, etc.); mais `formasAcesso` com rótulos, `programasSociais` (booleans de programas/órgãos + textos `outrosProgramasSociais` / `outrosOrgaosSociais`), `composicaoFamiliar` (`cpfFormatado` quando houver CPF), `condicoesTrabalho` (`ocupacaoRotulo`), `condicoesEducacionais` (`escolaridadeRotulo`), `deficienciasFamilia` (`tipoDeficienciaRotulo`), `gestantesFamilia` (`iniciouPreNatalRotulo`), `saudeFamilia` (com rótulos `*Rotulo` para enums Sim/Não).

**Resposta `GET` lista (trecho):** `pessoa` resumida (`id`, `nome`, `cpf`, `cpfFormatado`) e contadores (`totalComposicaoFamiliar`, `totalCondicoesTrabalho`, `totalCondicoesEducacionais`, `totalDeficienciasFamilia`, `totalGestantesFamilia`, `totalFormasAcesso`, …).

Se as tabelas de entrevista não existirem no banco, o POST pode retornar **500** com orientação para executar `npx prisma migrate deploy`.

### Submissões

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/submissoes` | Lista resumos (`?tipoFormularioId=`, `?pessoaId=`, `?nome=`, `?cpf=`) |
| `POST` | `/submissoes` | Cria submissão + respostas preenchidas (transação; respostas opcionais) |
| `GET` | `/submissoes/:id` | Detalhe com respostas e `opcao.rotulo` (inclui inativas) |

**Exemplo — enviar formulário (respostas parciais):**

```json
POST /submissoes
{
  "tipoFormularioId": "uuid-do-tipo",
  "pessoaId": "uuid-da-pessoa",
  "respostas": [
    { "perguntaId": "uuid-1", "valorData": "20/10/2026" },
    { "perguntaId": "uuid-2", "valorTexto": "Comentário" }
  ]
}
```

Perguntas **omitidas** ou com **todos os valores vazios** não precisam aparecer em `respostas`. O array pode ser **`[]`** (submissão só com pessoa e tipo).

**Exemplo — envio sem nenhuma resposta:**

```json
POST /submissoes
{
  "tipoFormularioId": "uuid-do-tipo",
  "pessoaId": "uuid-da-pessoa",
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
