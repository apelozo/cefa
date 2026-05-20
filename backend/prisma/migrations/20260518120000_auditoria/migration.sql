-- Auditoria: usuário e data/hora (UTC) de inclusão e alteração em todas as tabelas.

-- tipos_formulario
ALTER TABLE "tipos_formulario" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "tipos_formulario" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "tipos_formulario" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "tipos_formulario" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "tipos_formulario" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "tipos_formulario" DROP COLUMN "created_at";

-- perguntas
ALTER TABLE "perguntas" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "perguntas" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "perguntas" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "perguntas" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "perguntas" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "perguntas" DROP COLUMN "created_at";

-- pergunta_opcoes
ALTER TABLE "pergunta_opcoes" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "pergunta_opcoes" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "pergunta_opcoes" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "pergunta_opcoes" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "pergunta_opcoes" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "pergunta_opcoes" DROP COLUMN "created_at";

-- pessoas
ALTER TABLE "pessoas" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "pessoas" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "pessoas" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "pessoas" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "pessoas" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "pessoas" DROP COLUMN "created_at";

-- submissoes
ALTER TABLE "submissoes" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "submissoes" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "submissoes" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "submissoes" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "submissoes" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "submissoes" DROP COLUMN "created_at";

-- respostas
ALTER TABLE "respostas" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "respostas" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "respostas" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "respostas" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);

-- modulos_sistema
ALTER TABLE "modulos_sistema" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "modulos_sistema" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "modulos_sistema" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "modulos_sistema" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "modulos_sistema" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "modulos_sistema" DROP COLUMN "created_at";

-- programas
ALTER TABLE "programas" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "programas" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "programas" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "programas" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "programas" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "programas" DROP COLUMN "created_at";

-- tipos_usuario
ALTER TABLE "tipos_usuario" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "tipos_usuario" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "tipos_usuario" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "tipos_usuario" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "tipos_usuario" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "tipos_usuario" DROP COLUMN "created_at";

-- usuarios
ALTER TABLE "usuarios" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "usuarios" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "usuarios" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "usuarios" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "usuarios" SET "data_hora_inclusao" = "created_at", "data_hora_alteracao" = "created_at";
ALTER TABLE "usuarios" DROP COLUMN "created_at";

-- tipos_usuario_permissoes
ALTER TABLE "tipos_usuario_permissoes" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "tipos_usuario_permissoes" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "tipos_usuario_permissoes" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "tipos_usuario_permissoes" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "tipos_usuario_permissoes" SET "data_hora_alteracao" = "data_hora_inclusao";

-- usuarios_permissoes
ALTER TABLE "usuarios_permissoes" ADD COLUMN "usuario_inclusao_id" UUID;
ALTER TABLE "usuarios_permissoes" ADD COLUMN "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "usuarios_permissoes" ADD COLUMN "usuario_alteracao_id" UUID;
ALTER TABLE "usuarios_permissoes" ADD COLUMN "data_hora_alteracao" TIMESTAMPTZ(3);
UPDATE "usuarios_permissoes" SET "data_hora_alteracao" = "data_hora_inclusao";
