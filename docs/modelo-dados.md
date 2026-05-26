# Modelo de dados

## 3. Modelo de dados

### Terminologia: Assistido × Pessoa

| Contexto | Termo | Exemplos |
|----------|-------|----------|
| **Negócio e interface** (app, menus, PDF em fluxo, mensagens ao usuário) | **Assistido** | “Cadastrar assistidos”, “Selecione o assistido”, rótulo **Assistido** no PDF de submissão |
| **Banco, API, código** (sem migration) | **Pessoa** / `pessoas` | Tabela `pessoas`, rota `/pessoas`, FK `pessoaId`, modelo Prisma `Pessoa`, classe Dart `Pessoa`, chaves PDF `pessoa.*` no YAML da entrevista |

O programa de permissão continua com código `pessoas` e nome sincronizado **Cadastrar assistidos** (`backend/src/lib/programas.ts` + `syncProgramas`).

**Integrantes da família** (composição, trabalho, educação, deficiência, gestantes) não são “assistidos” no cadastro — na documentação e na UI usam **integrante** quando se referem a membros além do assistido principal.

### Auditoria (todas as tabelas)

Toda tabela do banco possui os mesmos quatro campos de rastreio, preenchidos automaticamente pela API (não vêm no body do cliente):

| Campo (API) | Coluna | Tipo | Descrição |
|-------------|--------|------|-----------|
| `usuarioInclusaoId` | `usuario_inclusao_id` | UUID, nullable | Usuário autenticado que criou o registro |
| `dataHoraInclusao` | `data_hora_inclusao` | `TIMESTAMPTZ(3)` | Data e hora da inclusão em **UTC** |
| `usuarioAlteracaoId` | `usuario_alteracao_id` | UUID, nullable | Usuário que fez a última alteração |
| `dataHoraAlteracao` | `data_hora_alteracao` | `TIMESTAMPTZ(3)`, nullable | Data e hora da última alteração em **UTC** |

**Regras:**

- **POST** (criação): grava inclusão e alteração inicial com o mesmo instante e `request.usuarioId` (JWT).
- **PUT** (atualização): atualiza apenas `usuarioAlteracaoId` e `dataHoraAlteracao`.
- **Submissão:** `submissoes` e cada linha em `respostas` recebem a mesma auditoria do envio.
- **Permissões** (`tipos_usuario_permissoes`, `usuarios_permissoes`): linhas recriadas no `PUT` de permissões recebem auditoria de inclusão do usuário que salvou.
- **Sync/seed** (módulos, programas, admin inicial): `usuario_*` pode ser `null` (operação de sistema); implementação em `backend/src/lib/auditoria.ts` e `sync-bootstrap.ts`.
- Registros migrados da versão anterior: `data_hora_inclusao` copiada do antigo `created_at`; `usuario_*` permanece `null` até nova edição.
- A API expõe também `createdAt` como alias de `dataHoraInclusao` (ISO 8601) para compatibilidade com o app.

Migration: `backend/prisma/migrations/20260518120000_auditoria/`.

### Diagrama entidade-relacionamento

No diagrama, a entidade **`Pessoa`** é o assistido cadastrado (tabela `pessoas`); ver [Terminologia](#terminologia-assistido--pessoa). **`AlunoCapacitacaoProfissional`** é cadastro próprio (não é `Pessoa`). A tabela **`cursos`** é catálogo independente — o campo “curso Senac/Senai” do aluno é texto livre, sem FK.

```mermaid
erDiagram
    TipoFormulario ||--o{ Pergunta : contem
    TipoFormulario ||--o{ Submissao : agrupa
    Pessoa ||--o{ Submissao : referencia
    Pessoa ||--o{ EntrevistaAssistido : referencia
    EntrevistaAssistido ||--o{ EntrevistaAssistidoFormaAcesso : possui
    EntrevistaAssistido ||--o{ EntrevistaComposicaoFamiliar : possui
    EntrevistaAssistido ||--o{ EntrevistaCondicaoTrabalho : possui
    EntrevistaAssistido ||--o{ EntrevistaCondicaoEducacional : possui
    EntrevistaAssistido ||--o{ EntrevistaDeficienciaFamiliar : possui
    EntrevistaAssistido ||--o{ EntrevistaGestanteFamiliar : possui
    Pergunta ||--o{ PerguntaOpcao : possui
    Pergunta ||--o{ Resposta : recebe
    PerguntaOpcao ||--o{ Resposta : selecionada_em
    Submissao ||--o{ Resposta : contem
    TipoUsuario ||--o{ Usuario : possui
    TipoUsuario ||--o{ TipoUsuarioPermissao : define
    Usuario ||--o{ UsuarioPermissao : sobrescreve
    TipoUsuario ||--o{ TipoUsuarioTipoFormulario : libera_tipos
    Usuario ||--o{ UsuarioTipoFormulario : override_tipos
    TipoFormulario ||--o{ TipoUsuarioTipoFormulario : liberado_para_tipo
    TipoFormulario ||--o{ UsuarioTipoFormulario : liberado_para_usuario
    Programa ||--o{ TipoUsuarioPermissao : referencia
    Programa ||--o{ UsuarioPermissao : referencia
    ModuloSistema ||--o{ Programa : agrupa
    Cidade ||--o{ Pessoa : municipio
    Bairro ||--o{ Pessoa : bairro
    Cidade ||--o{ Voluntario : municipio
    Cidade ||--o{ AlunoCapacitacaoProfissional : naturalidade
    Cidade ||--o{ AlunoCapacitacaoProfissional : endereco
    Escolaridade ||--o{ EntrevistaCondicaoEducacional : referencia
    Escolaridade ||--o{ AlunoCapacitacaoProfissional : escolaridade
    Departamento ||--o{ VoluntarioDepartamentoHorario : departamento
    Voluntario ||--o{ VoluntarioDepartamentoHorario : horarios
    AlunoCapacitacaoProfissional ||--o{ AlunoCapacitacaoRendaFamiliar : rendas_familiares

    ModuloSistema {
        uuid id PK
        int codigo UK
        string nome
        string descricao
        int ordem
        boolean ativo
        auditoria campos
    }

    Cidade {
        uuid id PK
        int codigo UK
        string nome_municipio
        enum estado UF
        boolean ativo
        auditoria e soft_delete
    }

    Bairro {
        uuid id PK
        int codigo UK
        string nome
        boolean ativo
        auditoria e soft_delete
    }

    Escolaridade {
        uuid id PK
        int codigo UK
        string descricao
        boolean ativo
        auditoria e soft_delete
    }

    Departamento {
        uuid id PK
        int codigo UK
        string descricao
        boolean ativo
        auditoria inclusao_alteracao
    }

    Curso {
        uuid id PK
        int codigo UK
        string descricao
        boolean ativo
        auditoria inclusao_alteracao
    }

    AlunoCapacitacaoProfissional {
        uuid id PK
        string nome
        dados_pessoais documentos
        int naturalidade_codigo FK
        int escolaridade_codigo FK
        endereco contato
        int cidade_codigo FK
        enum tipo_casa
        decimal valor_aluguel
        flags e textos adicionais
        boolean ativo
        auditoria inclusao_alteracao
    }

    AlunoCapacitacaoRendaFamiliar {
        uuid id PK
        uuid aluno_capacitacao_id FK
        int ordem
        string nome
        int idade
        decimal renda
        string parentesco profissao
        auditoria inclusao_alteracao
    }

    Voluntario {
        uuid id PK
        int codigo UK
        string nome
        string nome_cracha
        endereco documentos contato contribuicao
        boolean ativo
        auditoria inclusao_alteracao
    }

    VoluntarioDepartamentoHorario {
        uuid id PK
        uuid voluntario_id FK
        int departamento_codigo FK
        enum dia_semana
        time hora_inicio
        time hora_termino
        auditoria inclusao_alteracao
    }

    Pessoa {
        uuid id PK
        string nome
        string nome_social
        string nome_mae
        string nome_pai
        date dt_nascimento
        string cpf UK
        string rg
        string nis
        string endereco
        int bairro_codigo FK
        int cidade_codigo FK
        enum urbano_rural
        boolean ativo
        auditoria campos
    }

    TipoFormulario {
        uuid id PK
        string nome
        string descricao
        boolean ativo
        auditoria campos
    }

    Pergunta {
        uuid id PK
        string enunciado
        enum tipo_campo
        int tamanho_campo
        int linhas_campo
        uuid tipo_formulario_id FK
        int ordem UK_com_tipo
        boolean ativo
        auditoria campos
    }

    PerguntaOpcao {
        uuid id PK
        uuid pergunta_id FK
        string rotulo
        int ordem
        boolean ativo
        auditoria campos
    }

    Submissao {
        uuid id PK
        uuid tipo_formulario_id FK
        uuid pessoa_id FK
        auditoria campos
    }

    EntrevistaAssistido {
        uuid id PK
        uuid pessoa_id FK
        date data_entrevista
        string outros_texto
        bool bolsa_familia peti bpc outros_programas
        string outros_programas_sociais
        bool cras centro_pop conselho_tutelar ubs creas caps craf
        bool outros_atendimento_familia
        string outros_orgaos_sociais
        enum remedios_controlados_mental
        string remedios_controlados_quais
        enum uso_abusivo_alcool
        enum uso_abusivo_drogas
        string uso_abusivo_drogas_quais
        enum tem_gestante
        auditoria campos
    }

    EntrevistaAssistidoFormaAcesso {
        uuid id PK
        uuid entrevista_id FK
        enum forma_acesso
        auditoria campos
    }

    EntrevistaComposicaoFamiliar {
        uuid id PK
        uuid entrevista_id FK
        int ordem
        string nome
        string cpf
        date dt_nascimento
        string parentesco
        auditoria campos
    }

    EntrevistaCondicaoTrabalho {
        uuid id PK
        uuid entrevista_id FK
        int ordem
        string nome
        enum ocupacao
        string condicoes_trabalho
        decimal vr_beneficio_social
        decimal renda_mensal
        auditoria campos
    }

    EntrevistaCondicaoEducacional {
        uuid id PK
        uuid entrevista_id FK
        int ordem
        string nome
        int idade
        int escolaridade_codigo FK
        boolean sabe_ler_escrever
        boolean frequenta_escola
        auditoria campos
    }

    EntrevistaDeficienciaFamiliar {
        uuid id PK
        uuid entrevista_id FK
        int ordem
        string nome
        enum tipo_deficiencia
        boolean necessita_cuidados_constantes
        string quem_e_cuidador
        auditoria campos
    }

    EntrevistaGestanteFamiliar {
        uuid id PK
        uuid entrevista_id FK
        int ordem
        string nome
        int meses_gestacao
        enum iniciou_pre_natal
        auditoria campos
    }

    Resposta {
        uuid id PK
        uuid submissao_id FK
        uuid pergunta_id FK
        int valor_inteiro
        decimal valor_decimal
        text valor_texto
        boolean valor_logico
        date valor_data
        uuid valor_opcao_id FK
        auditoria campos
    }

    Programa {
        uuid id PK
        string codigo UK
        string nome
        boolean auto_listagem
        uuid modulo_sistema_id FK
        auditoria campos
    }

    TipoUsuario {
        uuid id PK
        string descricao
        enum perfil
        boolean ativo
        auditoria campos
    }

    Usuario {
        uuid id PK
        string nome_usuario UK
        string nome
        string email UK
        string senha_hash
        uuid tipo_usuario_id FK
        boolean ativo
        auditoria campos
    }

    TipoUsuarioPermissao {
        uuid id PK
        uuid tipo_usuario_id FK
        uuid programa_id FK
        boolean flags_permissao
        auditoria campos
    }

    UsuarioPermissao {
        uuid id PK
        uuid usuario_id FK
        uuid programa_id FK
        boolean flags_permissao
        auditoria campos
    }
```

**Campos calculados (não persistidos):** `idade` do aluno (a partir de `dt_nascimento`); `rendaPerCapita` (soma das `renda` na tabela filha ÷ quantidade de integrantes com `nome` preenchido).

**Unicidade:** `(tipo_formulario_id, ordem)` é único em `perguntas` — não podem existir duas perguntas do mesmo formulário com o mesmo número de ordem. `cpf` único em `pessoas`, `voluntarios` e `alunos_capacitacao_profissional` quando informado.

**Desativação vs exclusão:** catálogos `cursos`, `departamentos`, `voluntarios` e `alunos_capacitacao_profissional` usam `ativo = false` no `DELETE`. `escolaridades` e `bairros` usam soft delete com campos de exclusão. Demais exclusões definitivas validam vínculos (HTTP **409**).

### Tipo de Formulário (`tipos_formulario`)

Agrupa perguntas em “formulários” lógicos. Exemplos: “Checklist de entrada”, “Avaliação mensal”.

| Campo | Descrição |
|-------|-----------|
| `nome` | Nome exibido no app |
| `descricao` | Texto opcional |
| `ativo` | Se `false`, não aparece ao responder |

**Acesso por tipo de formulário** (camada além das permissões de programa):

| Tabela | Uso |
|--------|-----|
| `tipos_usuario_tipos_formulario` | Tipos liberados para cada **tipo de usuário** |
| `usuarios_tipos_formulario` | Override por **usuário** (quando `usuarios.override_tipos_formulario = true`) |

| Regra | Comportamento |
|-------|----------------|
| **Administrador** | Todos os tipos (sem checklist na liberação) |
| **Lista vazia** (tipo ou override de usuário) | Nenhum tipo nas telas operacionais |
| **Override de usuário** | Após `PUT /usuarios/:id/tipos-formulario-acesso`, usa só `usuarios_tipos_formulario` |
| **Sem override** | Usa `tipos_usuario_tipos_formulario` do tipo do usuário |
| **Criação de tipo** | Quem cria (`POST /tipos-formulario`) ganha o tipo no **tipo de usuário** do criador |
| **Cadastro administrativo** | `GET /tipos-formulario?todos=true` (programa `tipos_formulario`) lista **todos** os tipos |
| **Operacional** | `GET /tipos-formulario` sem `todos` filtra pelos tipos liberados ao usuário logado |

Filtragem também em `GET /perguntas`, `GET /submissoes`, `POST /submissoes` e validação em `GET /tipos-formulario/:id` (exceto cadastro com programa `tipos_formulario`).

**Migration:** `20260521100000_tipos_formulario_acesso`.

**Implementação:** `backend/src/services/tipos-formulario-acesso.ts` (`resolveTiposFormularioIds`, `assertUsuarioAcessoTipoFormulario`).

### Pergunta (`perguntas`)

| Campo | Descrição |
|-------|-----------|
| `enunciado` | Texto da pergunta |
| `tipoCampo` | Tipo do valor esperado (ver tabela abaixo) |
| `tamanhoCampo` | Obrigatório só para `TEXTO` (1–5000 caracteres) — limite por pergunta na validação do lançamento |
| `linhasCampo` | Obrigatório só para `TEXTO` (1–20) — altura do campo de resposta no app (quantidade de linhas visíveis) |
| `tipoFormularioId` | FK para o tipo de formulário |
| `ordem` | Ordem de exibição no formulário (única por `tipoFormularioId`) |
| `ativo` | Se `false`, não aparece no formulário e não aceita novas respostas |

**Pergunta `TEXTO`:** `tamanhoCampo` e `linhasCampo` são independentes. Ex.: `tamanhoCampo: 30` com `linhasCampo: 1` (campo curto em uma linha) e, no mesmo formulário, `tamanhoCampo: 5000` com `linhasCampo: 10` (texto longo em área multilinha). Valores padrão sugeridos no app ao criar: **100** caracteres e **3** linhas. Perguntas `TEXTO` já existentes antes da migration `20260520110000` receberam `linhasCampo = 3`.

**Ordem:** ao criar pergunta nova no app, o campo **Ordem** é pré-preenchido com o próximo número disponível. É possível alterar manualmente; a API retorna **409** se a ordem já existir no mesmo tipo de formulário.

### Opção de pergunta (`pergunta_opcoes`)

Usada apenas quando `tipoCampo = LISTA`.

| Campo | Descrição |
|-------|-----------|
| `rotulo` | Texto exibido na lista suspensa |
| `ordem` | Ordem de exibição no cadastro |
| `ativo` | Se `false`, não aparece no lançamento, mas permanece em consultas de respostas antigas |

**Regras:** opções **não são excluídas** do banco — apenas desativadas. Respostas gravam `valor_opcao_id` (FK) para preservar o histórico mesmo se a opção for inativada depois.

### Tipos de campo (`tipo_campo`)

| Valor | Comportamento no cadastro | Comportamento no formulário | Armazenamento |
|-------|---------------------------|-----------------------------|---------------|
| `INTEIRO` | — | Número inteiro, até 9 dígitos | `valor_inteiro` |
| `DECIMAL` | — | Número decimal (vírgula ou ponto) | `valor_decimal` |
| `TEXTO` | Informar `tamanhoCampo` e `linhasCampo` | Campo com `maxLength` = `tamanhoCampo` e `minLines`/`maxLines` = `linhasCampo`; tecla Enter só encadeia foco se `linhasCampo = 1` | `valor_texto` (`TEXT`) |
| `LOGICO` | — | Sim / Não | `valor_logico` |
| `DATA` | — | `dd/mm/aa`; ano de 2 dígitos vira 20xx | `valor_data` |
| `LISTA` | Cadastrar `opcoes` (mín. 1 ativa) | Dropdown com opções ativas | `valor_opcao_id` |

**Regra de data:** o usuário digita por exemplo `20/10/26`; o sistema normaliza para `20/10/2026` (anos com 2 dígitos somam 2000). Datas são gravadas e lidas em **UTC** (`Date.UTC` / `getUTC*`) para evitar deslocamento de um dia por fuso horário.

**Regra de resposta:** em cada linha de `respostas` gravada, **exatamente um** dos campos de valor deve estar preenchido, conforme o `tipoCampo` da pergunta. No **lançamento**, nenhuma pergunta é obrigatória: perguntas sem resposta **não** geram linha em `respostas` (submissão pode ter zero ou mais respostas).

### Cidade (`cidades`)

Municípios usados no endereço dos assistidos (tabela `pessoas`). **Exclusão:** `DELETE` faz **soft delete** (`ativo = false`, `usuarioExclusaoId`, `dataHoraExclusao`) — o registro permanece no banco.

| Campo | Descrição |
|-------|-----------|
| `codigo` | **Inteiro** sequencial único, gerado automaticamente na API (`max(codigo) + 1`) — referenciado em `pessoas.cidadeCodigo` |
| `nomeMunicipio` | Nome do município |
| `estado` | UF (`UfBrasil`: AC, AL, …, TO) |
| `ativo` | Se `false` (soft delete), não aparece em listagens ativas |

Unicidade: par `(nomeMunicipio, estado)` e `codigo`. O código **não** é informado pelo cliente no `POST` e **não** pode ser alterado no `PUT`.

Migration: `20260518190000_cidade_codigo_inteiro`.

### Bairro (`bairros`)

Bairros referenciados no endereço dos assistidos (tabela `pessoas`). Mesmo padrão de **soft delete** que cidades.

| Campo | Descrição |
|-------|-----------|
| `codigo` | **Inteiro** sequencial único, gerado automaticamente na API — referenciado em `pessoas.bairroCodigo` |
| `nome` | Nome do bairro |
| `ativo` | Se `false`, oculto das listagens ativas |

O código **não** é informado no `POST` e **não** pode ser alterado no `PUT`.

Migration: `20260518180000_bairro_codigo_inteiro`.

### Escolaridade (`escolaridades`)

Opções de escolaridade na aba **Condições Educacionais** da entrevista. Mesmo padrão de **soft delete** que bairros/cidades.

| Campo | Descrição |
|-------|-----------|
| `codigo` | **Inteiro** sequencial único, gerado automaticamente na API — referenciado em `entrevista_condicao_educacional.escolaridade_codigo` |
| `descricao` | Texto exibido no cadastro e na lista da entrevista |
| `ativo` | Se `false`, não aparece em novas seleções (`GET ?ativo=true`); registros antigos mantêm o FK |

O código **não** é informado no `POST` e **não** pode ser alterado no `PUT`.

**Seed na migration `20260525100000`:** código `1`, descrição **Nunca Frequentou Escola** — usado para converter linhas existentes do antigo enum.

### Departamento (`departamentos`)

Cadastro de departamentos do centro. Auditoria de **inclusão** e **alteração** apenas — o `DELETE` define `ativo = false` e grava auditoria de alteração (sem `usuarioExclusaoId` / `dataHoraExclusao`).

| Campo | Descrição |
|-------|-----------|
| `codigo` | **Inteiro** sequencial único, gerado automaticamente na API |
| `descricao` | Nome do departamento |
| `ativo` | Se `false`, oculto das listagens ativas (`GET ?ativo=true`) |

O código **não** é informado no `POST` e **não** pode ser alterado no `PUT`.

Migration: `20260525110000_departamentos`.

**Vínculo com voluntários:** tabela `voluntario_departamento_horarios` (ver abaixo). Desativar departamento **409** se existir vínculo.

### Curso (`cursos`)

Catálogo de cursos. Auditoria de **inclusão** e **alteração**; o `DELETE` define `ativo = false` e grava auditoria de alteração.

| Campo | Descrição |
|-------|-----------|
| `codigo` | **Inteiro** sequencial único, gerado automaticamente na API |
| `descricao` | Nome do curso |
| `ativo` | Se `false`, oculto das listagens ativas (`GET ?ativo=true`) |
| `usuarioInclusaoId`, `dataHoraInclusao`, `usuarioAlteracaoId`, `dataHoraAlteracao` | Auditoria padrão (UTC) |

O código **não** é informado no `POST` e **não** pode ser alterado no `PUT`.

Migration: `20260525160000_cursos`.

### Aluno de capacitação profissional (`alunos_capacitacao_profissional`)

Cadastro do aluno de capacitação (sem vínculo com `pessoas`/assistidos). Tabela filha **`aluno_capacitacao_renda_familiar`** para integrantes da renda (várias linhas por aluno). **`idade`** e **`rendaPerCapita`** são calculadas na API e no app (não persistidas).

| Campo (API) | Descrição |
|-------------|-----------|
| `nome` | Obrigatório |
| `nomeSocial` | Opcional |
| `estadoCivil` | Enum `EstadoCivilVoluntario` (mesmo de voluntários) |
| `rg`, `orgaoExpedidor`, `cpf` | Documentos (`cpf` único quando informado) |
| `dtNascimento` | Data obrigatória no cadastro (`dd/mm/aa` ou `dd/mm/aaaa` na API) |
| `nacionalidade` | Texto opcional |
| `naturalidadeCodigo` | FK → `cidades.codigo` (município de naturalidade) |
| `nomeMae`, `nomePai` | Filiação |
| `escolaridadeCodigo` | FK → `escolaridades.codigo` |
| `nomeUltimaEscola` | Texto opcional |
| `endereco`, `enderecoNumero`, `bairro`, `cep` | Endereço (`bairro` texto livre) |
| `cidadeCodigo` | FK → `cidades.codigo` (município do endereço) |
| `tipoCasa` | `PROPRIA`, `CEDIDA`, `ALUGUEL` |
| `valorAluguel` | Obrigatório na API quando `tipoCasa` = `ALUGUEL` |
| `telefone`, `celular`, `telefoneRecado`, `email`, `redeSocial` | Contato |
| `jaFezCursoSenacSenai` | Boolean; se `true`, exige `cursoSenacSenaiDescricao` e `cursoSenacSenaiAno` |
| `encaminhamento`, `telefoneEncaminhamento` | Opcionais |
| `possuiNecessidadeEspecial` | Boolean; se `true`, exige `qualNecessidade` |
| `fazAcompanhamentoMedico` | Boolean; se `true`, exige `tomaMedicacao` |
| `vacinacao`, `alergias` | Texto opcional |
| `ativo` | `DELETE` define `ativo = false` |
| Auditoria | `usuarioInclusaoId`, `dataHoraInclusao`, `usuarioAlteracaoId`, `dataHoraAlteracao` (UTC) |

**Renda familiar** (`aluno_capacitacao_renda_familiar`): `nome` (obrigatório por linha enviada), `idade`, `renda` (decimal), `parentesco`, `profissao`, `ordem`. No `PUT`, todas as linhas são **substituídas**. **Renda per capita** = soma das `renda` ÷ quantidade de linhas com `nome` preenchido.

O campo “curso Senac/Senai” é **texto livre** — não referencia a tabela `cursos`.

Migration: `20260525170000_alunos_capacitacao_profissional`.

### Voluntário (`voluntarios`)

Cadastro de voluntários do centro. `cidadeCodigo` referencia `cidades.codigo` (`onDelete: Restrict`). CPF único quando informado. `DELETE` desativa (`ativo = false`) e grava auditoria de alteração.

| Campo | Descrição |
|-------|-----------|
| `codigo` | Inteiro sequencial único, gerado na API |
| `nome` | Nome completo (obrigatório) |
| `nomeCracha` | Nome no crachá (obrigatório) |
| `empresa`, `funcao` | Texto opcional |
| `estadoCivil` | Enum: `CASADO`, `DIVORCIADO`, `SEPARADO`, `SOLTEIRO`, `VIUVO` (rótulos na UI: Casado(a), Divorciado(a), Separado(a), Solteiro(a), Viúvo(a)) |
| `dtNascimento` | Data (`dd/mm/aa` na API) |
| `endereco`, `enderecoNumero`, `bairro`, `cep`, `enderecoComplemento` | Endereço (`bairro` é texto livre, não FK) |
| `cidadeCodigo` | FK → `cidades.codigo` (município ativo) |
| `rg`, `cpf`, `cnh` | Documentos (CPF validado; único no banco) |
| `celular`, `telefoneResidencial`, `telefoneComercial`, `email` | Contato |
| `valorContribuicao` | Decimal opcional |
| `diaVencimento` | Inteiro 1–31 (melhor dia de vencimento) |
| `tempoTrabalhoCentro` | Anos no centro (0–100) |
| `fichaMedica` | Texto até 1000 caracteres |
| `ativo` | Soft delete via `DELETE` |

Migrations: `20260525120000_voluntarios`; `20260525140000_voluntario_nome` (campo `nome` — registros existentes copiados de `nome_cracha`).

### Voluntário × departamento (`voluntario_departamento_horarios`)

Vínculo de **voluntário** (pessoa no cadastro de voluntários) a **departamento**, com dia e horário. **Sem** restrição de unicidade: o mesmo voluntário pode ter **várias linhas** no mesmo departamento (ex.: turnos diferentes).

| Campo | Descrição |
|-------|-----------|
| `voluntarioId` | FK → `voluntarios.id` (`Restrict`) |
| `departamentoCodigo` | FK → `departamentos.codigo` (`Restrict`) |
| `diaSemana` | Enum: `DOMINGO` … `SABADO` |
| `horaInicio`, `horaTermino` | `TIME` (`HH:mm` na API); término deve ser **posterior** ao início |
| Auditoria | Inclusão e alteração |

`DELETE` do vínculo é **físico**. Migration: `20260525130000_voluntario_departamento_horarios`.

**App:** horários digitados como `0800` são formatados para `08:00` ao sair do campo (`mobile/lib/utils/hora_formatter.dart`).

### Pessoa (`pessoas`) — Assistido na interface

Entidade de cadastro dos **assistidos** do centro (conceito de negócio). Na **interface** do app o termo exibido é **Assistido**; no banco, API e código permanecem `pessoas` / `pessoaId` / `Pessoa` (sem migration).

Cadastro referenciado nos lançamentos e nas entrevistas. **Exclusão:** `DELETE` **físico**; **409** se existirem **submissões** ou **entrevistas** vinculadas.

| Campo | Descrição |
|-------|-----------|
| `nome` | Nome completo |
| `nomeSocial` | Nome social (opcional) |
| `nomeMae` / `nomePai` | Filiação (opcional) |
| `dtNascimento` | Data de nascimento (`dd/mm/aaaa` na API) |
| `cpf` | 11 dígitos, único, validado por algoritmo |
| `rg` | Documento de identidade (normalizado, sem pontuação) |
| `rgOrgaoEmissao` | Órgão emissor do RG (opcional) |
| `nis` | NIS — 11 dígitos quando informado (opcional) |
| `endereco` / `enderecoNumero` / `enderecoComplemento` | Endereço (opcional) |
| `bairroCodigo` | FK → `bairros.codigo` (`Int`, opcional) |
| `cidadeCodigo` | FK → `cidades.codigo` (`Int`, opcional) |
| `telefone` / `telefone2` | 10 ou 11 dígitos na gravação (opcional) |
| `urbanoRural` | `URBANO` ou `RURAL` (opcional) |
| `ativo` | Se `false`, não aparece na seleção do lançamento |

**CPF e RG — gravação vs exibição:**

| Campo | No banco | Na API / telas |
|-------|----------|----------------|
| CPF | Apenas 11 dígitos | `cpfFormatado` (ex.: `529.982.247-25`) |
| RG | Sem pontuação, maiúsculas | `rgFormatado` quando aplicável (ex.: `12.345.678-9`) |

O app envia CPF/RG **sem máscara** (`normalizeCpf` / `normalizeRg`); máscaras existem só nos campos de entrada e na exibição. Bairro e município são escolhidos por **código inteiro** em seletores com pesquisa (`AppSearchableSelectField`), alimentados por `GET /bairros` e `GET /cidades` (apenas ativos, ordenados alfabeticamente no app).

**Composição familiar, trabalho/renda, educação, deficiências e gestantes** pertencem à **entrevista** (tabelas filhas e campos em `entrevistas_assistido`), não ao cadastro do assistido (`POST /pessoas`). Cada envio pode incluir zero ou mais linhas nas abas com listas dinâmicas; **gestantes** permitem vários registros quando `temGestante = SIM`.

### Entrevista com o Assistido (`entrevistas_assistido`)

Programa: `entrevista_assistido` (módulo **Formulários**). Registro de uma entrevista social vinculada a um **assistido** (`pessoaId` → `pessoas.id`), com data e seis abas gravadas em transação.

| Campo | Descrição |
|-------|-----------|
| `pessoaId` | FK → `pessoas.id` (assistido da entrevista) |
| `dataEntrevista` | Data da entrevista (`dd/mm/aa` ou `dd/mm/aaaa` no POST; gravada como `@db.Date` em UTC). No app, exibição preferencial **dd/mm/aaaa** (ano expandido ao sair do campo) |
| `outrosTexto` | Texto livre (até 500 caracteres) — **obrigatório** quando a forma de acesso **Outros** estiver marcada |

**Programas sociais e órgãos de atendimento** (colunas em `entrevistas_assistido`, objeto `programasSociais` na API — aba **Programas Sociais**):

| Campo API | Descrição |
|-----------|-----------|
| `bolsaFamilia`, `peti`, `bpc` | Boolean — beneficiário do programa |
| `outrosProgramas` | Boolean — **obrigatório** `outrosProgramasSociais` (até 30 caracteres) se marcado |
| `cras`, `centroPop`, `conselhoTutelar`, `ubs`, `creas`, `caps`, `craf` | Boolean — família atendida pelo órgão |
| `outrosAtendimentoFamilia` | Boolean — **obrigatório** `outrosOrgaosSociais` (até 30 caracteres) se marcado |

**Questionário de saúde da família** (colunas em `entrevistas_assistido`, objeto `saudeFamilia` na API):

| Campo API | Descrição |
|-----------|-----------|
| `remediosControladosMental` | Enum `RespostaSimNao` (`SIM` / `NAO`) |
| `remediosControladosQuais` | Texto (até 500) — **obrigatório** se `remediosControladosMental = SIM` |
| `usoAbusivoAlcool` | `RespostaSimNao` |
| `usoAbusivoDrogas` | `RespostaSimNao` |
| `usoAbusivoDrogasQuais` | Texto — **obrigatório** se `usoAbusivoDrogas = SIM` |
| `temGestante` | `RespostaSimNao` — pergunta “Tem gestante na família?” |

**Gestantes na família** (`entrevista_gestante_familiar`, API `gestantesFamilia[]`): lista dinâmica na aba **Condições de Saúde**, no mesmo padrão de composição familiar e deficiências (botão **Adicionar gestante** / remover por card).

| Regra | Descrição |
|-------|-----------|
| `temGestante = SIM` | **Obrigatório** ao menos um item em `gestantesFamilia`, cada um com nome, meses e pré-natal |
| `temGestante = NAO` (ou ausente) | `gestantesFamilia` deve ser `[]` ou omitido |

| Campo API | Descrição |
|-----------|-----------|
| `nome` | Obrigatório; dropdown no app: assistido + nomes da composição familiar |
| `mesesGestacao` | Inteiro **0–10** |
| `iniciouPreNatal` | `RespostaSimNao` — obrigatório em cada registro |

Unicidade por entrevista: várias linhas com `ordem` crescente (substituídas integralmente no `PUT`, como demais filhos).

**Formas de acesso** (`entrevista_assistido_formas_acesso`): multi-seleção (mínimo uma). Enum `FormaAcessoInstituicao`:

| Valor API | Rótulo na UI |
|-----------|--------------|
| `DEMANDA_ESPONTANEA` | Por Demanda Espontânea |
| `BUSCA_ATIVA` | Busca Ativa Realizada |
| `ENCAMINHAMENTO_ASSISTENCIA_SOCIAL` | Encaminhamento da Assistência Social |
| `ENCAMINHAMENTO_SAUDE` | Encaminhamento da Saúde |
| `ENCAMINHAMENTO_EDUCACAO` | Encaminhamento da Educação |
| `ENCAMINHAMENTO_CONSELHO_TUTELAR` | Encaminhamento do Conselho Tutelar |
| `ENCAMINHAMENTO_GARANTIA_DIREITOS` | Encaminhamento Sistema de Garantia de Direitos |
| `OUTROS` | Outros (exige `outrosTexto`) |

Unicidade: `(entrevistaId, formaAcesso)`.

**Composição familiar** (`entrevista_composicao_familiar`): linhas opcionais, ordenadas por `ordem`.

| Campo | Descrição |
|-------|-----------|
| `nome` | Obrigatório |
| `cpf` | Opcional; 11 dígitos, validado |
| `dtNascimento` | Obrigatório |
| `parentesco` | Obrigatório |

**Condições de trabalho e renda** (`entrevista_condicao_trabalho`): linhas opcionais por membro da família.

| Campo | Descrição |
|-------|-----------|
| `nome` | Nome do assistido ou integrante da composição |
| `ocupacao` | Enum `OcupacaoFamiliar` (códigos 0–11; ver `backend/src/lib/ocupacao-familiar.ts`) |
| `condicoesTrabalho` | Texto opcional (até 500 caracteres) |
| `vrBeneficioSocial` | Decimal; padrão `0` |
| `rendaMensal` | Decimal; padrão `0` |

No app, a aba **Trabalho e Renda** calcula **Renda Total da Família** (soma de `vrBeneficioSocial` + `rendaMensal` de **todas** as linhas de condições de trabalho) e **Renda Per Capita** (total ÷ quantidade de integrantes na aba **Composição Familiar** com nome preenchido — **o assistido não entra** no divisor, mesmo que tenha linha de renda). O dropdown de **Nome** nas abas Trabalho e Renda, Educacionais, Saúde (deficiência e **gestantes**) lista o assistido e os nomes cadastrados na Composição Familiar.

**Condições educacionais** (`entrevista_condicao_educacional`): linhas opcionais por integrante (assistido ou membro da composição).

| Campo | Descrição |
|-------|-----------|
| `nome` | Obrigatório (dropdown com assistido + composição) |
| `idade` | Inteiro 0–150 |
| `escolaridadeCodigo` | FK → `escolaridades.codigo` (`Int`) — listbox carregado de `GET /escolaridades?ativo=true` |
| `sabeLerEscrever` | Boolean (tag na UI) |
| `frequentaEscola` | Boolean (tag na UI) |

As opções de escolaridade vêm do cadastro **Escolaridades** (não há mais enum fixo no código). Cadastre as descrições necessárias antes de usar a aba na entrevista.

**Deficiência na família** (`entrevista_deficiencia_familiar`): linhas opcionais.

| Campo | Descrição |
|-------|-----------|
| `nome` | Obrigatório |
| `tipoDeficiencia` | Enum `TipoDeficienciaFamiliar`: Cegueira, Baixa Visão, Surdez leve/moderada, Deficiencia Fisica, Deficiencia Mental ou Intelectual, Sindrome de Down, Transtorno Mental |
| `necessitaCuidadosConstantes` | Boolean |
| `quemECuidador` | Texto opcional (até 500) |

Ao adicionar integrante na **Composição Familiar**, o app cria linhas vinculadas nas abas Trabalho e Renda e Educacionais (nome sincronizado ao digitar).

**API:** `GET /entrevistas-assistido` (lista com filtros `nome`, `cpf`, `pessoaId`), `POST` (criação), `GET /:id` (detalhe), `PUT /:id` (alteração em transação — substitui formas de acesso e todas as linhas filhas), `DELETE /:id` (exclusão física da entrevista e filhos).

**Implementação (backend):** `backend/src/services/entrevistas-assistido.ts`. `POST`, `PUT` e `DELETE` usam `prisma.$transaction` com timeout estendido (`maxWait` / `timeout` maiores que o padrão): alterações envolvem vários `deleteMany`/`createMany` nas tabelas filhas e, em latências altas (ex.: Neon), o timeout curto do Prisma gerava erro **P2028** (“transaction already closed”). Após gravar na transação, o detalhe é relido com `getEntrevistaAssistidoById` **fora** da transação. Se o Prisma ainda encerrar a transação por tempo, a API pode responder **503** com mensagem orientando nova tentativa (`backend/src/routes/entrevistas-assistido.ts`).

**Migrations (formulários / respostas):** `20260516000000_init`, `20260516210000_tipo_campo_flexivel`, `20260520110000_texto_linhas_e_valor_text` (`linhas_campo` em `perguntas`; `valor_texto` → `TEXT`).

**Migrations (entrevista):** `20260518200000_entrevista_assistido`, `20260518220000_entrevista_familia_trabalho`, `20260518230000_entrevista_condicao_educacional`, `20260518240000_entrevista_saude_familia`, `20260519100000_entrevista_programas_sociais`, `20260520100000_entrevista_gestante_familiar`.

**PDF (app):** consulta da entrevista gera ficha com fundo institucional + mapa YAML (`mobile/assets/relatorios/entrevista_assistido_v1.yaml`), incluindo chaves `programas.*`, `gestante.linhaN.*` (até 5 linhas no molde) e legado `saude.gestante*` (1ª gestante). Fonte Unicode: `mobile/lib/utils/pdf_fonts.dart` (Open Sans). Ver [relatorios.md](./relatorios.md) §6 e [mobile.md](./mobile.md).

### Submissão (`submissoes`)

Representa **um envio** de um formulário para um **assistido**. Inclui **apenas as perguntas respondidas**; campos deixados em branco no lançamento não são gravados.

| Campo | Descrição |
|-------|-----------|
| `tipoFormularioId` | Formulário que foi respondido |
| `pessoaId` | Assistido a que se referem as respostas (`pessoas.id`) |

**Consulta / PDF:** o app gera relatório em fluxo a partir do detalhe (`submissao_pdf.dart`); ver [relatorios.md](./relatorios.md).

### Resposta (`respostas`)

| Regra | Descrição |
|-------|-----------|
| Unicidade | Não pode repetir `pergunta_id` na mesma submissão |
| Pergunta ativa | Pergunta inativa não aceita novas respostas |
| Mesmo formulário | Todas as perguntas devem pertencer ao `tipoFormularioId` informado |
| Texto | Comprimento validado contra `pergunta.tamanhoCampo` (até 5000); coluna `valor_texto` é `TEXT` no PostgreSQL (sem teto fixo no tipo da coluna) |

**Armazenamento por `tipoCampo`:** em cada linha, preencher **apenas um** dos campos de valor (`valor_inteiro`, `valor_decimal`, `valor_texto`, `valor_logico`, `valor_data`, `valor_opcao_id`).

**Evolução de `valor_texto`:** `VARCHAR(100)` (v1) → `VARCHAR(1000)` (tipos flexíveis) → `TEXT` (migration `20260520110000_texto_linhas_e_valor_text`).

### Integridade referencial (FK)

Todas as FKs usam `ON DELETE RESTRICT`. Exclusões **não** propagam em cascata — ver regras na API (HTTP **409** quando houver vínculos).

| Exclusão / desativação | Bloqueio típico (409 ou regra de negócio) |
|----------------------|-------------------------------------------|
| Tipo de formulário | Perguntas ou submissões vinculadas |
| Pergunta | Respostas vinculadas |
| Assistido (`pessoas`) | Submissões ou entrevistas |
| Cidade / escolaridade | FK em pessoa, voluntário ou aluno de capacitação |
| Departamento | Vínculo em `voluntario_departamento_horarios` |
| Curso | Nenhum vínculo FK hoje — apenas desativação |
| Voluntário | Apenas desativação (`ativo = false`) |
| Aluno de capacitação | Apenas desativação; linhas de renda removidas no `PUT` (substituição) |
| Entrevista | Exclusão física das tabelas filhas na mesma transação |

### Módulo do sistema (`modulos_sistema`)

Agrupa **programas** exibidos na Home. Cada programa pertence a no máximo um módulo (`programas.modulo_sistema_id`).

| Campo | Descrição |
|-------|-----------|
| `codigo` | Número inteiro positivo único, **gerado automaticamente** na criação (`max(codigo)+1`); **imutável** após criação |
| `nome` | Nome exibido no filtro da Home |
| `descricao` | Texto opcional abaixo do filtro |
| `ordem` | Ordem no seletor de módulos |
| `ativo` | Se `false`, não aparece no menu da Home |

O `codigo` **não** é enviado no `POST` pelo cliente; a API calcula `max(codigo) + 1`. Na UI de **novo módulo** não há campo Código; na **edição** o código é somente leitura.

**Módulos padrão** (catálogo em `backend/src/lib/modulos.ts`; criados na primeira subida da API):

| `codigo` | Nome |
|----------|------|
| `1` | Formulários |
| `2` | Administração |

**Sync na subida da API** (`syncModulos` em `backend/src/lib/sync-bootstrap.ts`):

- Só **insere** módulos do catálogo que ainda não existem (por `codigo`).
- **Não** sobrescreve `nome`, `descricao` nem `ordem` de módulos já cadastrados — alterações feitas em **Módulos do sistema** na UI são preservadas ao reiniciar a API.

**Exclusão:** **409** se ainda houver programas vinculados — reassocie os programas antes.

### Programa (`programas`)

Catálogo de telas/recursos do sistema (“programas a liberar”). Cada linha em `programas` pode ser criada de três formas:

| Origem | Quando usar |
|--------|-------------|
| **Interface** | `POST /programas` — **Programas do sistema** no app (recomendado para programas novos sem alterar código da API) |
| **Sync na subida** | Entrada em `PROGRAMAS_CATALOGO` (`backend/src/lib/programas.ts`) — programas fixos do produto |
| **Vínculo ao módulo** | `PUT /modulos-sistema/:id/programas` — associa programas já existentes ao módulo |

| Campo | Descrição |
|-------|-----------|
| `codigo` | Identificador estável (ex.: `perguntas`); minúsculas, números e `_`; **imutável** após criação |
| `nome` | Nome exibido nas telas de **liberação de acesso** e checkboxes em módulos |
| `autoListagem` | `true` se o programa corresponde a uma tela de listagem cadastrada automaticamente |
| `moduloSistemaId` | FK opcional para o módulo (menu da Home) |

**API:** `GET` / `POST` `/programas`, `GET` / `PUT` `/programas/:id` — ver [api.md](./api.md#programas). Criação/edição exige permissão no programa `modulos_sistema` (incluir/alterar). Consulta de `GET /programas` também aceita liberação de acesso ou módulos.

**Implementação:** `backend/src/services/programas.ts` (`listProgramas`, `listProgramasParaPermissoes`, `createPrograma`, `updatePrograma`). Liberação de tipo e de usuário usam `listProgramasParaPermissoes()` — mesma listagem que módulos e `GET /programas`.

**Sync na subida da API** (`syncProgramas`):

- **Cria** programas do catálogo que ainda não existem (com vínculo ao módulo pelo `moduloCodigo` numérico do catálogo).
- Em programas **já existentes** presentes no catálogo, atualiza apenas `nome` e `autoListagem`.
- **Não** altera `moduloSistemaId` nem remove programas criados pela UI — vínculo definido em **Módulos do sistema** é preservado ao reiniciar a API.
- Programas criados só via `POST /programas` **não** entram no catálogo fixo; permanecem no banco até exclusão manual (não há `DELETE /programas` na v1).

#### Registrar um novo programa (checklist)

**Pela interface (recomendado):**

1. App: **Módulos do sistema** → ícone **Programas do sistema** (grade) ou **Novo programa** no formulário do módulo.
2. Preencher **código** (ex.: `meu_programa`), **nome** (exibido na liberação) e **módulo** (opcional).
3. API grava com `POST /programas`; o programa aparece em **Liberação por tipo** / **Liberação por usuário** e nos checkboxes do módulo.
4. Para atalho na Home e rotas protegidas: passos do catálogo fixo abaixo (`HomeMenuRegistry`, `PROGRAMA_POR_ROTA`, telas).

**Pelo catálogo fixo (funcionalidade com telas/API no código):**

1. **Backend — catálogo:** entrada em `PROGRAMAS_CATALOGO` em `backend/src/lib/programas.ts`.
2. **Backend — rotas:** registrar em `PROGRAMA_POR_ROTA` e implementar rotas/serviço/validador.
3. **Migration Prisma** se houver nova tabela ou campo.
4. **Flutter — constante:** `Programas.*` em `mobile/lib/auth/programas.dart`.
5. **Flutter — Home:** entrada em `mobile/lib/home/home_menu_registry.dart`.
6. Reiniciar a API (`npm run dev`) para o `syncProgramas` criar/atualizar o registro do catálogo.
7. Liberar o programa para tipos/usuários em **Liberação de acesso**.

### Tipo de usuário (`tipos_usuario`)

| Campo | Descrição |
|-------|-----------|
| `descricao` | Nome do tipo |
| `perfil` | `ADMINISTRADOR` \| `SISTEMA` \| `COMUM` (exclusivo) |
| `ativo` | Se inativo, usuários do tipo não entram no sistema |

Tipo com `perfil = ADMINISTRADOR` possui **permissão total** em todos os programas.

### Usuário (`usuarios`)

| Campo | Descrição |
|-------|-----------|
| `nomeUsuario` | Login (único) |
| `nome` | Nome de exibição |
| `email` | E-mail (único) |
| `senhaHash` | Senha com bcrypt (nunca retornada na API) |
| `tipoUsuarioId` | FK para o tipo |
| `ativo` | Usuário inativo não autentica |

**Usuário seed:** `admin` / senha inicial em `ADMIN_INITIAL_PASSWORD` (padrão `admin123` no `.env.example`).

### Permissões

O acesso é em **duas camadas** (ambas necessárias nas telas operacionais):

| Camada | Tabelas / mecanismo | Controla |
|--------|---------------------|----------|
| **Programa** | `tipos_usuario_permissoes`, `usuarios_permissoes` | Pode abrir a tela e usar incluir/alterar/consultar/excluir no recurso |
| **Tipo de formulário** | `tipos_usuario_tipos_formulario`, `usuarios_tipos_formulario` | Quais tipos aparecem em lançamento, perguntas (filtro) e consulta de respostas |

Por programa, quatro flags independentes: `podeIncluir`, `podeAlterar`, `podeConsultar`, `podeExcluir`.

- **Por tipo de usuário:** `tipos_usuario_permissoes` (padrão do tipo de usuário)
- **Por usuário (override de programa):** `usuarios_permissoes` — se existir linha para o programa, **substitui** a do tipo (não faz união)
- **Tipos de formulário por tipo de usuário:** `tipos_usuario_tipos_formulario`
- **Tipos de formulário por usuário:** após `PUT /usuarios/:id/tipos-formulario-acesso`, `override_tipos_formulario = true` e só vale `usuarios_tipos_formulario`

**Listagem na liberação (API + app):**

- `GET /tipos-usuario/:id/permissoes` e `GET /usuarios/:id/permissoes` retornam **uma linha por programa** em `programas` (via `listProgramasParaPermissoes`), mesclando flags já salvas ou `false`.
- No app, `liberacao_*_screen.dart` ainda combina essa resposta com `GET /programas` (`mergePermissaoLinhasComProgramas` em `mobile/lib/utils/permissao_linhas_merge.dart`) para garantir que programas recém-criados apareçam antes de reabrir a tela.
- Ao salvar (`PUT …/permissoes`), só entram no banco programas com **ao menos uma** flag `true`; programas sem nenhuma flag não geram linha em `tipos_usuario_permissoes` / `usuarios_permissoes`.
- Tipo com `perfil = ADMINISTRADOR`: a API devolve `perfilAdmin: true`; o app exibe mensagem de permissão total e **não** lista os programas individualmente.

| `codigo` | Nome | `autoListagem` |
|----------|------|----------------|
| `tipos_formulario` | Tipos de formulário | sim |
| `perguntas` | Cadastrar perguntas | sim |
| `pessoas` | Cadastrar assistidos (UI; código `pessoas`) | sim |
| `cidades` | Cadastrar cidades | sim |
| `bairros` | Cadastrar bairros | sim |
| `escolaridades` | Cadastrar escolaridades | sim |
| `departamentos` | Cadastrar departamentos | sim |
| `cursos` | Cadastrar cursos | sim |
| `alunos_capacitacao` | Alunos de Capacitação Profissional | sim |
| `voluntarios` | Cadastrar voluntários | sim |
| `submissoes` | Consultar respostas | sim |
| `lancamento` | Responder Questionários (UI; código `lancamento`) | não |
| `entrevista_assistido` | Entrevista com o Assistido | sim |
| `usuarios` | Cadastro de usuários | não |
| `tipos_usuario` | Tipos de usuário | não |
| `liberacao_usuario` | Liberação de acesso (usuário) | não |
| `liberacao_tipo_usuario` | Liberação de acesso (tipo) | não |
| `modulos_sistema` | Módulos do sistema | não |

**Vínculo programa → módulo (padrão no catálogo, apenas na criação):**

| Módulo (`codigo`) | Programas |
|-------------------|-----------|
| `1` (Formulários) | `tipos_formulario`, `perguntas`, `pessoas`, `cidades`, `bairros`, `escolaridades`, `departamentos`, `cursos`, `alunos_capacitacao`, `voluntarios`, `submissoes`, `lancamento`, `entrevista_assistido` |
| `2` (Administração) | `usuarios`, `tipos_usuario`, `liberacao_usuario`, `liberacao_tipo_usuario`, `modulos_sistema` |

Ao subir a API: `syncModulos()` → `syncProgramas()` → `ensureAdminUser()` (`backend/src/lib/sync-bootstrap.ts`).

#### Regras de acesso (menu, telas e API)

| Situação | Regra |
|----------|--------|
| **Ver item na Home** | Qualquer flag ativa no programa (`podeAcessar` / `temAcesso`) — não exige só Consultar |
| **Abrir tela de listagem** | Idem: `PermissaoGate` usa `podeAcessar` |
| **GET** (lista/detalhe) | Permitido se `podeConsultar` **ou** qualquer outra flag do programa (`podeAcaoHttp` no backend) |
| **POST** | Exige `podeIncluir` |
| **PUT** | Exige `podeAlterar` |
| **DELETE** | Exige `podeExcluir` |
| **FAB “Novo”** | Exige `podeIncluir` |
| **Ícone alterar** | Exige `podeAlterar` |
| **Ícone excluir** | Exige `podeExcluir` |
| **Enviar questionário** | Exige `podeIncluir` no programa `lancamento` (UI: Responder Questionários) |
| **Tipo ADMINISTRADOR** | Todas as flags `true` em todos os programas; na API ignora checagem por rota; no app `isAdmin` libera todas as ações de UI |
| **Menu da Home (`GET /modulos-sistema/menu`)** | Qualquer usuário autenticado; retorna módulos ativos com programas que o usuário pode acessar (admin vê todos os programas de cada módulo) |

Exemplo: usuário com só **Alterar** em `perguntas` vê o atalho no módulo **Formulários**, abre a lista e edita registros, mas não vê FAB de inclusão nem exclusão.

Implementação: `backend/src/services/permissoes.ts`; `backend/src/plugins/auth.ts` (registrado com **`fastify-plugin`** para aplicar JWT em todas as rotas); no app `authProvider` (`podeAcessar`, `isAdmin`).

**Liberação de tipos de formulário (app):** abas **Programas** e **Tipos de formulário** em `liberacao_tipo_usuario_screen.dart` e `liberacao_usuario_screen.dart`. API: `backend/src/services/tipos-formulario-acesso.ts`.

---
