-- CreateEnum
CREATE TYPE "FormaAcessoInstituicao" AS ENUM (
  'DEMANDA_ESPONTANEA',
  'BUSCA_ATIVA',
  'ENCAMINHAMENTO_ASSISTENCIA_SOCIAL',
  'ENCAMINHAMENTO_SAUDE',
  'ENCAMINHAMENTO_EDUCACAO',
  'ENCAMINHAMENTO_CONSELHO_TUTELAR',
  'ENCAMINHAMENTO_GARANTIA_DIREITOS',
  'OUTROS'
);

-- CreateTable
CREATE TABLE "entrevistas_assistido" (
    "id" UUID NOT NULL,
    "pessoa_id" UUID NOT NULL,
    "data_entrevista" DATE NOT NULL,
    "outros_texto" VARCHAR(500),
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevistas_assistido_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "entrevista_assistido_formas_acesso" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "forma_acesso" "FormaAcessoInstituicao" NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_assistido_formas_acesso_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "entrevista_assistido_formas_acesso_entrevista_id_forma_acesso_key" ON "entrevista_assistido_formas_acesso"("entrevista_id", "forma_acesso");

-- AddForeignKey
ALTER TABLE "entrevistas_assistido" ADD CONSTRAINT "entrevistas_assistido_pessoa_id_fkey" FOREIGN KEY ("pessoa_id") REFERENCES "pessoas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "entrevista_assistido_formas_acesso" ADD CONSTRAINT "entrevista_assistido_formas_acesso_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
