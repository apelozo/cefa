-- Código do município: texto opcional -> inteiro sequencial obrigatório

ALTER TABLE "pessoas" DROP CONSTRAINT IF EXISTS "pessoas_cidade_codigo_fkey";

ALTER TABLE "cidades" ADD COLUMN "codigo_int" INTEGER;

WITH numerar AS (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY "nome_municipio", "estado")::INTEGER AS novo_codigo
  FROM "cidades"
)
UPDATE "cidades" c
SET "codigo_int" = n.novo_codigo
FROM numerar n
WHERE c.id = n.id;

ALTER TABLE "cidades" ALTER COLUMN "codigo_int" SET NOT NULL;

ALTER TABLE "pessoas" ADD COLUMN "cidade_codigo_int" INTEGER;

UPDATE "pessoas" p
SET "cidade_codigo_int" = c."codigo_int"
FROM "cidades" c
WHERE p."cidade_codigo" IS NOT NULL
  AND p."cidade_codigo" = c."codigo";

DROP INDEX IF EXISTS "cidades_codigo_key";
ALTER TABLE "cidades" DROP COLUMN "codigo";
ALTER TABLE "cidades" RENAME COLUMN "codigo_int" TO "codigo";
CREATE UNIQUE INDEX "cidades_codigo_key" ON "cidades"("codigo");

ALTER TABLE "pessoas" DROP COLUMN "cidade_codigo";
ALTER TABLE "pessoas" RENAME COLUMN "cidade_codigo_int" TO "cidade_codigo";

ALTER TABLE "pessoas" ADD CONSTRAINT "pessoas_cidade_codigo_fkey"
  FOREIGN KEY ("cidade_codigo") REFERENCES "cidades"("codigo")
  ON DELETE RESTRICT ON UPDATE CASCADE;
