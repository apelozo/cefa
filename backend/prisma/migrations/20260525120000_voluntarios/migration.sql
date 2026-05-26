-- Cadastro de voluntários (código sequencial, dados pessoais, endereço, contribuição, auditoria).

CREATE TYPE "EstadoCivilVoluntario" AS ENUM ('CASADO', 'DIVORCIADO', 'SOLTEIRO', 'VIUVO');

CREATE TABLE "voluntarios" (
    "id" UUID NOT NULL,
    "codigo" INTEGER NOT NULL,
    "empresa" TEXT,
    "funcao" TEXT,
    "estado_civil" "EstadoCivilVoluntario",
    "dt_nascimento" DATE,
    "endereco" TEXT,
    "endereco_numero" TEXT,
    "bairro" TEXT,
    "cep" TEXT,
    "cidade_codigo" INTEGER,
    "endereco_complemento" TEXT,
    "rg" TEXT,
    "cpf" TEXT,
    "cnh" TEXT,
    "celular" TEXT,
    "telefone_residencial" TEXT,
    "telefone_comercial" TEXT,
    "email" TEXT,
    "valor_contribuicao" DECIMAL(12,2),
    "dia_vencimento" INTEGER,
    "tempo_trabalho_centro" INTEGER,
    "nome_cracha" TEXT NOT NULL,
    "ficha_medica" VARCHAR(1000),
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "voluntarios_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "voluntarios_codigo_key" ON "voluntarios"("codigo");
CREATE UNIQUE INDEX "voluntarios_cpf_key" ON "voluntarios"("cpf");

ALTER TABLE "voluntarios" ADD CONSTRAINT "voluntarios_cidade_codigo_fkey" FOREIGN KEY ("cidade_codigo") REFERENCES "cidades"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
