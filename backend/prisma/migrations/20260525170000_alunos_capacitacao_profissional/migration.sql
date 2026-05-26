-- Alunos de Capacitação Profissional + renda familiar.

CREATE TYPE "TipoCasaAlunoCapacitacao" AS ENUM ('PROPRIA', 'CEDIDA', 'ALUGUEL');

CREATE TABLE "alunos_capacitacao_profissional" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "nome_social" TEXT,
    "estado_civil" "EstadoCivilVoluntario",
    "rg" TEXT,
    "orgao_expedidor" TEXT,
    "cpf" TEXT,
    "dt_nascimento" DATE,
    "nacionalidade" TEXT,
    "naturalidade_codigo" INTEGER,
    "nome_mae" TEXT,
    "nome_pai" TEXT,
    "escolaridade_codigo" INTEGER,
    "nome_ultima_escola" TEXT,
    "endereco" TEXT,
    "endereco_numero" TEXT,
    "bairro" TEXT,
    "cep" TEXT,
    "cidade_codigo" INTEGER,
    "tipo_casa" "TipoCasaAlunoCapacitacao",
    "valor_aluguel" DECIMAL(12,2),
    "telefone" TEXT,
    "celular" TEXT,
    "telefone_recado" TEXT,
    "email" TEXT,
    "rede_social" TEXT,
    "ja_fez_curso_senac_senai" BOOLEAN NOT NULL DEFAULT false,
    "curso_senac_senai_descricao" TEXT,
    "curso_senac_senai_ano" INTEGER,
    "encaminhamento" TEXT,
    "telefone_encaminhamento" TEXT,
    "possui_necessidade_especial" BOOLEAN NOT NULL DEFAULT false,
    "qual_necessidade" TEXT,
    "faz_acompanhamento_medico" BOOLEAN NOT NULL DEFAULT false,
    "toma_medicacao" TEXT,
    "vacinacao" TEXT,
    "alergias" TEXT,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "alunos_capacitacao_profissional_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "alunos_capacitacao_profissional_cpf_key" ON "alunos_capacitacao_profissional"("cpf");

ALTER TABLE "alunos_capacitacao_profissional" ADD CONSTRAINT "alunos_capacitacao_profissional_naturalidade_codigo_fkey" FOREIGN KEY ("naturalidade_codigo") REFERENCES "cidades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "alunos_capacitacao_profissional" ADD CONSTRAINT "alunos_capacitacao_profissional_cidade_codigo_fkey" FOREIGN KEY ("cidade_codigo") REFERENCES "cidades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "alunos_capacitacao_profissional" ADD CONSTRAINT "alunos_capacitacao_profissional_escolaridade_codigo_fkey" FOREIGN KEY ("escolaridade_codigo") REFERENCES "escolaridades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "aluno_capacitacao_renda_familiar" (
    "id" UUID NOT NULL,
    "aluno_capacitacao_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "idade" INTEGER,
    "renda" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "parentesco" TEXT,
    "profissao" TEXT,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "aluno_capacitacao_renda_familiar_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "aluno_capacitacao_renda_familiar" ADD CONSTRAINT "aluno_capacitacao_renda_familiar_aluno_capacitacao_id_fkey" FOREIGN KEY ("aluno_capacitacao_id") REFERENCES "alunos_capacitacao_profissional"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
