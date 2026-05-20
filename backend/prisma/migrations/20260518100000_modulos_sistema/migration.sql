-- CreateTable
CREATE TABLE "modulos_sistema" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "modulos_sistema_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "modulos_sistema_codigo_key" ON "modulos_sistema"("codigo");

-- AlterTable
ALTER TABLE "programas" ADD COLUMN "modulo_sistema_id" UUID;

-- AddForeignKey
ALTER TABLE "programas" ADD CONSTRAINT "programas_modulo_sistema_id_fkey" FOREIGN KEY ("modulo_sistema_id") REFERENCES "modulos_sistema"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Seed módulos padrão
INSERT INTO "modulos_sistema" ("id", "codigo", "nome", "descricao", "ordem", "ativo", "created_at")
VALUES
  (gen_random_uuid(), 'formularios', 'Formulários', 'Cadastros, lançamento e consulta de respostas', 1, true, CURRENT_TIMESTAMP),
  (gen_random_uuid(), 'administracao', 'Administração', 'Usuários, permissões e configuração do sistema', 2, true, CURRENT_TIMESTAMP);

-- Vincular programas existentes aos módulos
UPDATE "programas" p
SET "modulo_sistema_id" = m.id
FROM "modulos_sistema" m
WHERE m.codigo = 'formularios'
  AND p.codigo IN ('tipos_formulario', 'perguntas', 'pessoas', 'submissoes', 'lancamento');

UPDATE "programas" p
SET "modulo_sistema_id" = m.id
FROM "modulos_sistema" m
WHERE m.codigo = 'administracao'
  AND p.codigo IN ('usuarios', 'tipos_usuario', 'liberacao_usuario', 'liberacao_tipo_usuario');
