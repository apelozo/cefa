-- Inscrição de aluno em curso + renda familiar.

CREATE TYPE "PeriodoInscricao" AS ENUM ('MANHA', 'TARDE', 'NOITE');

CREATE TABLE "inscricoes_aluno_curso" (
    "id" UUID NOT NULL,
    "codigo" INTEGER NOT NULL,
    "aluno_id" UUID NOT NULL,
    "curso_codigo" INTEGER NOT NULL,
    "dt_curso" DATE NOT NULL,
    "periodo" "PeriodoInscricao" NOT NULL,
    "ja_fez_curso_senac_senai" BOOLEAN NOT NULL DEFAULT false,
    "curso_senac_senai_descricao" TEXT,
    "possui_encaminhamento" BOOLEAN NOT NULL DEFAULT false,
    "orgao_encaminhamento" TEXT,
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

    CONSTRAINT "inscricoes_aluno_curso_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "inscricoes_aluno_curso_codigo_key" ON "inscricoes_aluno_curso"("codigo");

ALTER TABLE "inscricoes_aluno_curso" ADD CONSTRAINT "inscricoes_aluno_curso_aluno_id_fkey" FOREIGN KEY ("aluno_id") REFERENCES "alunos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "inscricoes_aluno_curso" ADD CONSTRAINT "inscricoes_aluno_curso_curso_codigo_fkey" FOREIGN KEY ("curso_codigo") REFERENCES "cursos"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "inscricao_renda_familiar" (
    "id" UUID NOT NULL,
    "inscricao_id" UUID NOT NULL,
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

    CONSTRAINT "inscricao_renda_familiar_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "inscricao_renda_familiar" ADD CONSTRAINT "inscricao_renda_familiar_inscricao_id_fkey" FOREIGN KEY ("inscricao_id") REFERENCES "inscricoes_aluno_curso"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
