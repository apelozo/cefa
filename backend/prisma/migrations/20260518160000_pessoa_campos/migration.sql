-- CreateEnum
CREATE TYPE "UrbanoRural" AS ENUM ('URBANO', 'RURAL');

-- AlterTable cidades: código do município
ALTER TABLE "cidades" ADD COLUMN "codigo" TEXT;
CREATE UNIQUE INDEX "cidades_codigo_key" ON "cidades"("codigo");

-- AlterTable pessoas
ALTER TABLE "pessoas" ADD COLUMN "nome_social" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "nome_mae" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "nome_pai" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "rg_orgao_emissao" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "nis" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "endereco" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "endereco_numero" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "endereco_complemento" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "bairro_codigo" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "cidade_codigo" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "telefone" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "telefone_2" TEXT;
ALTER TABLE "pessoas" ADD COLUMN "urbano_rural" "UrbanoRural";

-- AddForeignKey
ALTER TABLE "pessoas" ADD CONSTRAINT "pessoas_bairro_codigo_fkey" FOREIGN KEY ("bairro_codigo") REFERENCES "bairros"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pessoas" ADD CONSTRAINT "pessoas_cidade_codigo_fkey" FOREIGN KEY ("cidade_codigo") REFERENCES "cidades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
