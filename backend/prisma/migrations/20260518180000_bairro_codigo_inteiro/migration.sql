-- Código do bairro: texto -> inteiro automático (sequencial por ordem do código antigo)

ALTER TABLE "pessoas" DROP CONSTRAINT IF EXISTS "pessoas_bairro_codigo_fkey";

ALTER TABLE "bairros" ADD COLUMN "codigo_int" INTEGER;

WITH numerar AS (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY "codigo")::INTEGER AS novo_codigo
  FROM "bairros"
)
UPDATE "bairros" b
SET "codigo_int" = n.novo_codigo
FROM numerar n
WHERE b.id = n.id;

ALTER TABLE "bairros" ALTER COLUMN "codigo_int" SET NOT NULL;

ALTER TABLE "pessoas" ADD COLUMN "bairro_codigo_int" INTEGER;

UPDATE "pessoas" p
SET "bairro_codigo_int" = b."codigo_int"
FROM "bairros" b
WHERE p."bairro_codigo" IS NOT NULL
  AND p."bairro_codigo" = b."codigo";

DROP INDEX IF EXISTS "bairros_codigo_key";
ALTER TABLE "bairros" DROP COLUMN "codigo";
ALTER TABLE "bairros" RENAME COLUMN "codigo_int" TO "codigo";
CREATE UNIQUE INDEX "bairros_codigo_key" ON "bairros"("codigo");

ALTER TABLE "pessoas" DROP COLUMN "bairro_codigo";
ALTER TABLE "pessoas" RENAME COLUMN "bairro_codigo_int" TO "bairro_codigo";

ALTER TABLE "pessoas" ADD CONSTRAINT "pessoas_bairro_codigo_fkey"
  FOREIGN KEY ("bairro_codigo") REFERENCES "bairros"("codigo")
  ON DELETE RESTRICT ON UPDATE CASCADE;
