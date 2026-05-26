-- Nome completo do voluntário (distinto do nome no crachá).

ALTER TABLE "voluntarios" ADD COLUMN "nome" TEXT;

UPDATE "voluntarios" SET "nome" = "nome_cracha" WHERE "nome" IS NULL;

ALTER TABLE "voluntarios" ALTER COLUMN "nome" SET NOT NULL;
