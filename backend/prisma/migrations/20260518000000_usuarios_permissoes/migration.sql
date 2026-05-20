-- CreateEnum
CREATE TYPE "PerfilTipoUsuario" AS ENUM ('ADMINISTRADOR', 'SISTEMA', 'COMUM');

-- CreateTable
CREATE TABLE "programas" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "auto_listagem" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "programas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tipos_usuario" (
    "id" UUID NOT NULL,
    "descricao" TEXT NOT NULL,
    "perfil" "PerfilTipoUsuario" NOT NULL DEFAULT 'COMUM',
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tipos_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" UUID NOT NULL,
    "nome_usuario" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "senha_hash" TEXT NOT NULL,
    "tipo_usuario_id" UUID NOT NULL,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tipos_usuario_permissoes" (
    "id" UUID NOT NULL,
    "tipo_usuario_id" UUID NOT NULL,
    "programa_id" UUID NOT NULL,
    "pode_incluir" BOOLEAN NOT NULL DEFAULT false,
    "pode_alterar" BOOLEAN NOT NULL DEFAULT false,
    "pode_consultar" BOOLEAN NOT NULL DEFAULT false,
    "pode_excluir" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "tipos_usuario_permissoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuarios_permissoes" (
    "id" UUID NOT NULL,
    "usuario_id" UUID NOT NULL,
    "programa_id" UUID NOT NULL,
    "pode_incluir" BOOLEAN NOT NULL DEFAULT false,
    "pode_alterar" BOOLEAN NOT NULL DEFAULT false,
    "pode_consultar" BOOLEAN NOT NULL DEFAULT false,
    "pode_excluir" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "usuarios_permissoes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "programas_codigo_key" ON "programas"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_nome_usuario_key" ON "usuarios"("nome_usuario");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "tipos_usuario_permissoes_tipo_usuario_id_programa_id_key" ON "tipos_usuario_permissoes"("tipo_usuario_id", "programa_id");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_permissoes_usuario_id_programa_id_key" ON "usuarios_permissoes"("usuario_id", "programa_id");

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_tipo_usuario_id_fkey" FOREIGN KEY ("tipo_usuario_id") REFERENCES "tipos_usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tipos_usuario_permissoes" ADD CONSTRAINT "tipos_usuario_permissoes_tipo_usuario_id_fkey" FOREIGN KEY ("tipo_usuario_id") REFERENCES "tipos_usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tipos_usuario_permissoes" ADD CONSTRAINT "tipos_usuario_permissoes_programa_id_fkey" FOREIGN KEY ("programa_id") REFERENCES "programas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuarios_permissoes" ADD CONSTRAINT "usuarios_permissoes_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usuarios_permissoes" ADD CONSTRAINT "usuarios_permissoes_programa_id_fkey" FOREIGN KEY ("programa_id") REFERENCES "programas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
