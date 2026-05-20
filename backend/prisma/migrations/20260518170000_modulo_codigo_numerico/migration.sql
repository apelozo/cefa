-- Código do módulo: texto -> inteiro único
ALTER TABLE "modulos_sistema" ADD COLUMN "codigo_num" INTEGER;

UPDATE "modulos_sistema" SET "codigo_num" = 1 WHERE "codigo" = 'formularios';
UPDATE "modulos_sistema" SET "codigo_num" = 2 WHERE "codigo" = 'administracao';

WITH numerar AS (
  SELECT
    id,
    (ROW_NUMBER() OVER (ORDER BY "ordem", "nome") + 100)::INTEGER AS novo_codigo
  FROM "modulos_sistema"
  WHERE "codigo_num" IS NULL
)
UPDATE "modulos_sistema" m
SET "codigo_num" = n.novo_codigo
FROM numerar n
WHERE m.id = n.id;

ALTER TABLE "modulos_sistema" ALTER COLUMN "codigo_num" SET NOT NULL;

DROP INDEX IF EXISTS "modulos_sistema_codigo_key";
ALTER TABLE "modulos_sistema" DROP COLUMN "codigo";
ALTER TABLE "modulos_sistema" RENAME COLUMN "codigo_num" TO "codigo";
CREATE UNIQUE INDEX "modulos_sistema_codigo_key" ON "modulos_sistema"("codigo");
