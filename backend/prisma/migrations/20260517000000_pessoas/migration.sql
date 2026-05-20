-- CreateTable
CREATE TABLE "pessoas" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "dt_nascimento" DATE NOT NULL,
    "cpf" TEXT NOT NULL,
    "rg" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pessoas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "pessoas_cpf_key" ON "pessoas"("cpf");

-- AlterTable: submissões existentes são removidas (v1 sem dados de produção críticos)
DELETE FROM "respostas";
DELETE FROM "submissoes";

ALTER TABLE "submissoes" ADD COLUMN "pessoa_id" UUID NOT NULL;

-- AddForeignKey
ALTER TABLE "submissoes" ADD CONSTRAINT "submissoes_pessoa_id_fkey" FOREIGN KEY ("pessoa_id") REFERENCES "pessoas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
