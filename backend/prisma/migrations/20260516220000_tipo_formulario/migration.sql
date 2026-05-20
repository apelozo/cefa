-- CreateTable
CREATE TABLE "tipos_formulario" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tipos_formulario_pkey" PRIMARY KEY ("id")
);

-- Tipo padrão para perguntas existentes
INSERT INTO "tipos_formulario" ("id", "nome", "descricao", "ativo", "created_at")
VALUES ('00000000-0000-4000-8000-000000000001', 'Geral', 'Formulário padrão', true, CURRENT_TIMESTAMP);

-- AlterTable perguntas
ALTER TABLE "perguntas" ADD COLUMN "tipo_formulario_id" UUID;
UPDATE "perguntas" SET "tipo_formulario_id" = '00000000-0000-4000-8000-000000000001';
ALTER TABLE "perguntas" ALTER COLUMN "tipo_formulario_id" SET NOT NULL;

-- AlterTable submissoes
ALTER TABLE "submissoes" ADD COLUMN "tipo_formulario_id" UUID;
UPDATE "submissoes" SET "tipo_formulario_id" = '00000000-0000-4000-8000-000000000001';
ALTER TABLE "submissoes" ALTER COLUMN "tipo_formulario_id" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "perguntas" ADD CONSTRAINT "perguntas_tipo_formulario_id_fkey" FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "submissoes" ADD CONSTRAINT "submissoes_tipo_formulario_id_fkey" FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
