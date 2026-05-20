-- CreateEnum
CREATE TYPE "TipoDeficienciaFamiliar" AS ENUM (
    'CEGUEIRA',
    'BAIXA_VISAO',
    'SURDEZ_LEVE_MODERADA',
    'DEFICIENCIA_FISICA',
    'DEFICIENCIA_MENTAL_INTELECTUAL',
    'SINDROME_DOWN',
    'TRANSTORNO_MENTAL'
);

CREATE TYPE "RespostaSimNao" AS ENUM ('SIM', 'NAO');

-- AlterTable
ALTER TABLE "entrevistas_assistido" ADD COLUMN "remedios_controlados_mental" "RespostaSimNao",
ADD COLUMN "remedios_controlados_quais" VARCHAR(500),
ADD COLUMN "uso_abusivo_alcool" "RespostaSimNao",
ADD COLUMN "uso_abusivo_drogas" "RespostaSimNao",
ADD COLUMN "uso_abusivo_drogas_quais" VARCHAR(500),
ADD COLUMN "tem_gestante" "RespostaSimNao",
ADD COLUMN "gestante_nome" VARCHAR(200),
ADD COLUMN "gestante_meses_gestacao" INTEGER,
ADD COLUMN "gestante_iniciou_pre_natal" "RespostaSimNao";

-- CreateTable
CREATE TABLE "entrevista_deficiencia_familiar" (
    "id" UUID NOT NULL,
    "entrevista_id" UUID NOT NULL,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "nome" TEXT NOT NULL,
    "tipo_deficiencia" "TipoDeficienciaFamiliar" NOT NULL,
    "necessita_cuidados_constantes" BOOLEAN NOT NULL DEFAULT false,
    "quem_e_cuidador" VARCHAR(500),
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "entrevista_deficiencia_familiar_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "entrevista_deficiencia_familiar" ADD CONSTRAINT "entrevista_deficiencia_familiar_entrevista_id_fkey" FOREIGN KEY ("entrevista_id") REFERENCES "entrevistas_assistido"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
