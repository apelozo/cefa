-- CreateEnum
CREATE TYPE "UfBrasil" AS ENUM ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO');

-- CreateTable
CREATE TABLE "cidades" (
    "id" UUID NOT NULL,
    "nome_municipio" TEXT NOT NULL,
    "estado" "UfBrasil" NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),
    "usuario_exclusao_id" UUID,
    "data_hora_exclusao" TIMESTAMPTZ(3),

    CONSTRAINT "cidades_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cidades_nome_municipio_estado_key" ON "cidades"("nome_municipio", "estado");
