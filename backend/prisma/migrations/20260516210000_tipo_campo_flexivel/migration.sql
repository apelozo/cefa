-- CreateEnum
CREATE TYPE "TipoCampo" AS ENUM ('INTEIRO', 'DECIMAL', 'TEXTO', 'LOGICO', 'DATA');

-- AlterTable perguntas
ALTER TABLE "perguntas" ADD COLUMN "tipo_campo" "TipoCampo";
ALTER TABLE "perguntas" ADD COLUMN "tamanho_campo" INTEGER;

UPDATE "perguntas" SET "tipo_campo" = 'LOGICO' WHERE "tipo_resposta" = 'SIM_NAO';
UPDATE "perguntas" SET "tipo_campo" = 'TEXTO', "tamanho_campo" = 100 WHERE "tipo_resposta" = 'TEXTO_100';

ALTER TABLE "perguntas" ALTER COLUMN "tipo_campo" SET NOT NULL;
ALTER TABLE "perguntas" DROP COLUMN "tipo_resposta";

-- AlterTable respostas
ALTER TABLE "respostas" ADD COLUMN "valor_inteiro" INTEGER;
ALTER TABLE "respostas" ADD COLUMN "valor_decimal" DECIMAL(18,4);
ALTER TABLE "respostas" ADD COLUMN "valor_logico" BOOLEAN;
ALTER TABLE "respostas" ADD COLUMN "valor_data" DATE;

UPDATE "respostas" SET "valor_logico" = "valor_sim_nao" WHERE "valor_sim_nao" IS NOT NULL;

ALTER TABLE "respostas" DROP COLUMN "valor_sim_nao";
ALTER TABLE "respostas" ALTER COLUMN "valor_texto" TYPE VARCHAR(1000);

-- DropEnum
DROP TYPE "TipoResposta";
