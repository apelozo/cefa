-- Liberação de acesso por tipo de formulário (tipo de usuário e usuário)

ALTER TABLE "usuarios" ADD COLUMN "override_tipos_formulario" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE "tipos_usuario_tipos_formulario" (
    "id" UUID NOT NULL,
    "tipo_usuario_id" UUID NOT NULL,
    "tipo_formulario_id" UUID NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "tipos_usuario_tipos_formulario_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "usuarios_tipos_formulario" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "tipo_formulario_id" UUID NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "usuarios_tipos_formulario_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "tipos_usuario_tipos_formulario_tipo_usuario_id_tipo_formulario_id_key" ON "tipos_usuario_tipos_formulario"("tipo_usuario_id", "tipo_formulario_id");

CREATE UNIQUE INDEX "usuarios_tipos_formulario_usuario_id_tipo_formulario_id_key" ON "usuarios_tipos_formulario"("usuario_id", "tipo_formulario_id");

ALTER TABLE "tipos_usuario_tipos_formulario" ADD CONSTRAINT "tipos_usuario_tipos_formulario_tipo_usuario_id_fkey" FOREIGN KEY ("tipo_usuario_id") REFERENCES "tipos_usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "tipos_usuario_tipos_formulario" ADD CONSTRAINT "tipos_usuario_tipos_formulario_tipo_formulario_id_fkey" FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "usuarios_tipos_formulario" ADD CONSTRAINT "usuarios_tipos_formulario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "usuarios_tipos_formulario" ADD CONSTRAINT "usuarios_tipos_formulario_tipo_formulario_id_fkey" FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
