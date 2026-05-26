-- Cadastro de escolaridades; FK na entrevista (substitui enum EscolaridadeFamiliar).

CREATE TABLE "escolaridades" (
    "id" UUID NOT NULL,
    "codigo" INTEGER NOT NULL,
    "descricao" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),
    "usuario_exclusao_id" UUID,
    "data_hora_exclusao" TIMESTAMPTZ(3),

    CONSTRAINT "escolaridades_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "escolaridades_codigo_key" ON "escolaridades"("codigo");

INSERT INTO "escolaridades" (
    "id",
    "codigo",
    "descricao",
    "ativo",
    "data_hora_inclusao"
) VALUES (
    gen_random_uuid(),
    1,
    'Nunca Frequentou Escola',
    true,
    CURRENT_TIMESTAMP
);

ALTER TABLE "entrevista_condicao_educacional" ADD COLUMN "escolaridade_codigo" INTEGER;

UPDATE "entrevista_condicao_educacional"
SET "escolaridade_codigo" = 1
WHERE "escolaridade_codigo" IS NULL;

ALTER TABLE "entrevista_condicao_educacional" ALTER COLUMN "escolaridade_codigo" SET NOT NULL;

ALTER TABLE "entrevista_condicao_educacional" DROP COLUMN "escolaridade";

DROP TYPE "EscolaridadeFamiliar";

ALTER TABLE "entrevista_condicao_educacional" ADD CONSTRAINT "entrevista_condicao_educacional_escolaridade_codigo_fkey" FOREIGN KEY ("escolaridade_codigo") REFERENCES "escolaridades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
