-- Cadastro de departamentos (código sequencial, descrição, ativo, auditoria inclusão/alteração).

CREATE TABLE "departamentos" (
    "id" UUID NOT NULL,
    "codigo" INTEGER NOT NULL,
    "descricao" TEXT NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "departamentos_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "departamentos_codigo_key" ON "departamentos"("codigo");
