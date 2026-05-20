-- Normaliza RG existentes (sem pontuação, maiúsculas) para busca consistente.
UPDATE "pessoas"
SET "rg" = UPPER(REGEXP_REPLACE("rg", '[^A-Za-z0-9]', '', 'g'))
WHERE "rg" IS NOT NULL AND "rg" <> '';
