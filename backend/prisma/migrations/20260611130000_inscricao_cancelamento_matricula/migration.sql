-- Cancelamento de matrícula (inscrições)
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "matricula_cancelada" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "usuario_cancelamento_matricula_id" UUID;
ALTER TABLE "inscricoes_aluno_curso" ADD COLUMN "data_hora_cancelamento_matricula" TIMESTAMPTZ(3);
