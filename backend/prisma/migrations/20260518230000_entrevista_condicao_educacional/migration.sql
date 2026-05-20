-- CreateEnum
CREATE TYPE "EscolaridadeFamiliar" AS ENUM (
    'NUNCA_FREQUENTOU_ESCOLA',
    'CRECHE',
    'EDUCACAO_INFANTIL',
    'EF_1_ANO',
    'EF_2_ANO',
    'EF_3_ANO',
    'EF_4_ANO',
    'EF_5_ANO',
    'EF_6_ANO',
    'EF_7_ANO',
    'EF_8_ANO',
    'EF_9_ANO',
    'EM_1_ANO',
    'EM_2_ANO',
    'EM_3_ANO',
    'SUPERIOR_INCOMPLETO',
    'SUPERIOR_COMPLETO',
    'EJA_EF',
    'EJA_EM',
    'OUTROS'
);

-- CreateTable
CREATE TABLE "entrevista_condicao_educacional" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "idade" INTEGER NOT NULL,
    "escolaridade" "EscolaridadeFamiliar" NOT NULL,
    "sabe_ler_escrever" BOOLEAN NOT NULL DEFAULT false,
    "frequenta_escola" BOOLEAN NOT NULL DEFAULT false,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_condicao_educacional_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "entrevista_condicao_educacional" ADD CONSTRAINT "entrevista_condicao_educacional_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
