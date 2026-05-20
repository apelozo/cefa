-- DropTables (dados de pessoa migrados incorretamente; entrevista passa a ser o vínculo)
DROP TABLE IF EXISTS "pessoa_condicao_trabalho";
DROP TABLE IF EXISTS "pessoa_composicao_familiar";

-- CreateTable
CREATE TABLE "entrevista_composicao_familiar" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "cpf" TEXT,
    "dt_nascimento" DATE NOT NULL,
    "parentesco" TEXT NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_composicao_familiar_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "entrevista_condicao_trabalho" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "ocupacao" "OcupacaoFamiliar" NOT NULL,
    "condicoes_trabalho" TEXT,
    "vr_beneficio_social" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "renda_mensal" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_condicao_trabalho_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "entrevista_composicao_familiar" ADD CONSTRAINT "entrevista_composicao_familiar_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "entrevista_condicao_trabalho" ADD CONSTRAINT "entrevista_condicao_trabalho_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
