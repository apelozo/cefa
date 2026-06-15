-- Toma medicação: checkbox + texto das medicações (antes era só texto em toma_medicacao).

ALTER TABLE "inscricoes_aluno_curso" RENAME COLUMN "toma_medicacao" TO "quais_medicacoes";

ALTER TABLE "inscricoes_aluno_curso"
ADD COLUMN "toma_medicacao" BOOLEAN NOT NULL DEFAULT false;

UPDATE "inscricoes_aluno_curso"
SET "toma_medicacao" = true
WHERE "quais_medicacoes" IS NOT NULL AND TRIM("quais_medicacoes") <> '';
