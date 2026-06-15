-- Submódulos de relatórios (agrupamento no módulo Relatórios)

CREATE TABLE "relatorio_submodulos" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "relatorio_submodulos_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "relatorio_submodulos_codigo_key" ON "relatorio_submodulos"("codigo");

ALTER TABLE "programas" ADD COLUMN "relatorio_submodulo_id" UUID;

ALTER TABLE "programas" ADD CONSTRAINT "programas_relatorio_submodulo_id_fkey"
    FOREIGN KEY ("relatorio_submodulo_id") REFERENCES "relatorio_submodulos"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Módulo Relatórios (código 3) — só insere se ainda não existir
INSERT INTO "modulos_sistema" (
    "id",
    "codigo",
    "nome",
    "descricao",
    "ordem",
    "ativo",
    "data_hora_inclusao"
)
SELECT
    gen_random_uuid(),
    3,
    'Relatórios',
    'Relatórios agrupados por submódulo',
    3,
    true,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM "modulos_sistema" WHERE "codigo" = 3
);

-- Submódulo inicial IEFA
INSERT INTO "relatorio_submodulos" (
    "id",
    "codigo",
    "nome",
    "descricao",
    "ordem",
    "ativo",
    "data_hora_inclusao"
)
VALUES (
    gen_random_uuid(),
    'iefa',
    'IEFA',
    'Relatórios do Instituto de Educação Francisco de Assis',
    1,
    true,
    CURRENT_TIMESTAMP
)
ON CONFLICT ("codigo") DO NOTHING;

-- Relatório de alunos da turma → módulo Relatórios + submódulo IEFA
UPDATE "programas" AS p
SET
    "modulo_sistema_id" = m."id",
    "relatorio_submodulo_id" = s."id"
FROM "modulos_sistema" AS m,
     "relatorio_submodulos" AS s
WHERE p."codigo" = 'relatorio_alunos_turma'
  AND m."codigo" = 3
  AND s."codigo" = 'iefa';
