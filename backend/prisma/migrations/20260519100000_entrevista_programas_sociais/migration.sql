-- Programas sociais e órgãos de atendimento (aba Programas Sociais)
ALTER TABLE "entrevistas_assistido" ADD COLUMN "bolsa_familia" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "peti" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "bpc" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "outros_programas" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "outros_programas_sociais" VARCHAR(30);
ALTER TABLE "entrevistas_assistido" ADD COLUMN "cras" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "centro_pop" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "conselho_tutelar" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "ubs" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "creas" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "caps" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "craf" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "outros_atendimento_familia" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "entrevistas_assistido" ADD COLUMN "outros_orgaos_sociais" VARCHAR(30);
