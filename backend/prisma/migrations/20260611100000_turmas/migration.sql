-- CreateEnum
CREATE TYPE "SituacaoTurma" AS ENUM ('ABERTA', 'FECHADA');

-- CreateTable
CREATE TABLE "turmas" (
    "id" UUID NOT NULL,
    "codigo" INTEGER NOT NULL,
    "nome" TEXT NOT NULL,
    "curso_codigo" INTEGER NOT NULL,
    "periodo" "PeriodoInscricao" NOT NULL,
    "situacao" "SituacaoTurma" NOT NULL DEFAULT 'ABERTA',
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "turmas_pkey" PRIMARY KEY ("id")
);

-- Turmas a partir das inscrições existentes (uma por curso + período)
INSERT INTO "turmas" (
    "id",
    "codigo",
    "nome",
    "curso_codigo",
    "periodo",
    "situacao",
    "ativo"
)
SELECT
    gen_random_uuid(),
    ROW_NUMBER() OVER (ORDER BY d."curso_codigo", d."periodo")::INTEGER,
    'Turma ' || d."periodo"::TEXT || ' — ' || c."descricao",
    d."curso_codigo",
    d."periodo",
    'FECHADA'::"SituacaoTurma",
    true
FROM (
    SELECT DISTINCT "curso_codigo", "periodo"
    FROM "inscricoes_aluno_curso"
) d
INNER JOIN "cursos" c ON c."codigo" = d."curso_codigo";

-- Inscrições: turma_codigo
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "turma_codigo" INTEGER;

UPDATE "inscricoes_aluno_curso" i
SET "turma_codigo" = t."codigo"
FROM "turmas" t
WHERE t."curso_codigo" = i."curso_codigo"
  AND t."periodo" = i."periodo";

ALTER TABLE "inscricoes_aluno_curso" ALTER COLUMN "turma_codigo" SET NOT NULL;

ALTER TABLE "inscricoes_aluno_curso" DROP CONSTRAINT IF EXISTS "inscricoes_aluno_curso_curso_codigo_fkey";
ALTER TABLE "inscricoes_aluno_curso" DROP COLUMN "curso_codigo";
ALTER TABLE "inscricoes_aluno_curso" DROP COLUMN "periodo";

-- Indexes e FKs
CREATE UNIQUE INDEX "turmas_codigo_key" ON "turmas"("codigo");

CREATE UNIQUE INDEX "turmas_curso_periodo_aberta_unique"
ON "turmas" ("curso_codigo", "periodo")
WHERE "situacao" = 'ABERTA' AND "ativo" = true;

ALTER TABLE "turmas" ADD CONSTRAINT "turmas_curso_codigo_fkey"
FOREIGN KEY ("curso_codigo") REFERENCES "cursos"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "inscricoes_aluno_curso" ADD CONSTRAINT "inscricoes_aluno_curso_turma_codigo_fkey"
FOREIGN KEY ("turma_codigo") REFERENCES "turmas"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
