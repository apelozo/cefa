-- AlterEnum
ALTER TYPE "TipoCampo" ADD VALUE 'LISTA';

-- CreateTable
CREATE TABLE "pergunta_opcoes" (
    "id" UUID NOT NULL,
    "pergunta_id" UUID NOT NULL,
    "rotulo" TEXT NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pergunta_opcoes_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "respostas" ADD COLUMN "valor_opcao_id" UUID;

-- AddForeignKey
ALTER TABLE "pergunta_opcoes" ADD CONSTRAINT "pergunta_opcoes_pergunta_id_fkey" FOREIGN KEY ("pergunta_id") REFERENCES "perguntas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "respostas" ADD CONSTRAINT "respostas_valor_opcao_id_fkey" FOREIGN KEY ("valor_opcao_id") REFERENCES "pergunta_opcoes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
