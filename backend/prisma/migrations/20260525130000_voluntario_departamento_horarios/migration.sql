-- Vínculo voluntário ↔ departamento com dia da semana e horário (permite repetir o mesmo par).

CREATE TYPE "DiaSemana" AS ENUM (
    'DOMINGO',
    'SEGUNDA_FEIRA',
    'TERCA_FEIRA',
    'QUARTA_FEIRA',
    'QUINTA_FEIRA',
    'SEXTA_FEIRA',
    'SABADO'
);

CREATE TABLE "voluntario_departamento_horarios" (
    "id" UUID NOT NULL,
    "voluntario_id" UUID NOT NULL,
    "departamento_codigo" INTEGER NOT NULL,
    "dia_semana" "DiaSemana" NOT NULL,
    "hora_inicio" TIME(0) NOT NULL,
    "hora_termino" TIME(0) NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "voluntario_departamento_horarios_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "voluntario_departamento_horarios" ADD CONSTRAINT "voluntario_departamento_horarios_voluntario_id_fkey" FOREIGN KEY ("voluntario_id") REFERENCES "voluntarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "voluntario_departamento_horarios" ADD CONSTRAINT "voluntario_departamento_horarios_departamento_codigo_fkey" FOREIGN KEY ("departamento_codigo") REFERENCES "departamentos"("codigo") ON DELETE RESTRICT ON UPDATE CASCADE;
