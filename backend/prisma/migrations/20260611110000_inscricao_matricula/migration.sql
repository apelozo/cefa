-- AlterTable
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "matriculado" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "dt_inicio_curso" DATE;
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "usuario_matricula_id" UUID;
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "data_hora_matricula" TIMESTAMPTZ(3);
