-- Gestantes da família: lista dinâmica (antes: um único registro em entrevistas_assistido).

CREATE TABLE "entrevista_gestante_familiar" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "meses_gestacao" INTEGER NOT NULL,
    "iniciou_pre_natal" "RespostaSimNao" NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_gestante_familiar_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "entrevista_gestante_familiar" ADD CONSTRAINT "entrevista_gestante_familiar_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Migra registro único legado para a nova tabela.
INSERT INTO "entrevista_gestante_familiar" (
    "id",
    "entrevista_id",
    "ordem",
    "nome",
    "meses_gestacao",
    "iniciou_pre_natal",
    "usuario_inclusao_id",
    "data_hora_inclusao",
    "usuario_alteracao_id",
    "data_hora_alteracao"
)
SELECT
    gen_random_uuid(),
    e."id",
    0,
    e."gestante_nome",
    e."gestante_meses_gestacao",
    e."gestante_iniciou_pre_natal",
    e."usuario_inclusao_id",
    e."data_hora_inclusao",
    e."usuario_alteracao_id",
    e."data_hora_alteracao"
FROM "entrevistas_assistido" e
WHERE e."tem_gestante" = 'SIM'
  AND e."gestante_nome" IS NOT NULL
  AND TRIM(e."gestante_nome") <> ''
  AND e."gestante_meses_gestacao" IS NOT NULL
  AND e."gestante_iniciou_pre_natal" IS NOT NULL;

ALTER TABLE "entrevistas_assistido" DROP COLUMN "gestante_nome";
ALTER TABLE "entrevistas_assistido" DROP COLUMN "gestante_meses_gestacao";
ALTER TABLE "entrevistas_assistido" DROP COLUMN "gestante_iniciou_pre_natal";
