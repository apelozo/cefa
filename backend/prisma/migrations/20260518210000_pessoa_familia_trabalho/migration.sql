-- CreateEnum
CREATE TYPE "OcupacaoFamiliar" AS ENUM (
  'NAO_TRABALHA',
  'CONTA_PROPRIA',
  'TEMPORARIO_RURAL',
  'EMPREGADO_SEM_CARTEIRA',
  'EMPREGADO_COM_CARTEIRA',
  'DOMESTICO_SEM_CARTEIRA',
  'DOMESTICO_COM_CARTEIRA',
  'NAO_REMUNERADO',
  'MILITAR_SERVIDOR_PUBLICO',
  'EMPREGADOR',
  'ESTAGIARIO',
  'APRENDIZ'
);

-- CreateTable
CREATE TABLE "pessoa_composicao_familiar" (
    "id" UUID NOT NULL,
    "pessoa_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "cpf" TEXT,
    "dt_nascimento" DATE NOT NULL,
    "parentesco" TEXT NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "pessoa_composicao_familiar_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pessoa_condicao_trabalho" (
    "id" UUID NOT NULL,
    "pessoa_id" UUID NOT NULL,
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

    CONSTRAINT "pessoa_condicao_trabalho_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "pessoa_composicao_familiar" ADD CONSTRAINT "pessoa_composicao_familiar_pessoa_id_fkey" FOREIGN KEY ("pessoa_id") REFERENCES "pessoas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pessoa_condicao_trabalho" ADD CONSTRAINT "pessoa_condicao_trabalho_pessoa_id_fkey" FOREIGN KEY ("pessoa_id") REFERENCES "pessoas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
