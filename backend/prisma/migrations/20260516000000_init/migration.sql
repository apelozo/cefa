-- CreateEnum
CREATE TYPE "TipoResposta" AS ENUM ('SIM_NAO', 'TEXTO_100');

-- CreateTable
CREATE TABLE "perguntas" (
    "id" UUID NOT NULL,
    "enunciado" TEXT NOT NULL,
    "tipo_resposta" "TipoResposta" NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "perguntas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "submissoes" (
    "id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "submissoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "respostas" (
    "id" UUID NOT NULL,
    "submissao_id" UUID NOT NULL,
    "pergunta_id" UUID NOT NULL,
    "valor_sim_nao" BOOLEAN,
    "valor_texto" VARCHAR(100),

    CONSTRAINT "respostas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "respostas_submissao_id_pergunta_id_key" ON "respostas"("submissao_id", "pergunta_id");

-- AddForeignKey
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_submissao_id_fkey" FOREIGN KEY ("submissao_id") REFERENCES "submissoes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_pergunta_id_fkey" FOREIGN KEY ("pergunta_id") REFERENCES "perguntas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
