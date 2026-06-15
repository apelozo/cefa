-- AlterTable
ALTER TABLE "alunos" ADD COLUMN "dt_expedicao_rg" DATE;
ALTER TABLE "alunos" ADD COLUMN "endereco" TEXT;
ALTER TABLE "alunos" ADD COLUMN "endereco_numero" TEXT;
ALTER TABLE "alunos" ADD COLUMN "bairro" TEXT;
ALTER TABLE "alunos" ADD COLUMN "cep" TEXT;
ALTER TABLE "alunos" ADD COLUMN "cidade_codigo" INTEGER;
ALTER TABLE "alunos" ADD COLUMN "telefone" TEXT;
ALTER TABLE "alunos" ADD COLUMN "celular" TEXT;
ALTER TABLE "alunos" ADD COLUMN "telefone_recado" TEXT;
ALTER TABLE "alunos" ADD COLUMN "email" TEXT;

-- AddForeignKey
ALTER TABLE "alunos" ADD CONSTRAINT "alunos_cidade_codigo_fkey" FOREIGN KEY ("cidade_codigo") REFERENCES "cidades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
