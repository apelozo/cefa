-- CreateTable
CREATE TABLE "inscricao_atendimentos" (
    "id" UUID NOT NULL,
    "inscricao_id" UUID NOT NULL,
    "data_atendimento" DATE NOT NULL,
    "descricao" VARCHAR(2000) NOT NULL,
    "usuario_inclusao_id" UUID,
    "data_hora_inclusao" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_alteracao_id" UUID,
    "data_hora_alteracao" TIMESTAMPTZ(3),

    CONSTRAINT "inscricao_atendimentos_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "inscricao_atendimentos" ADD CONSTRAINT "inscricao_atendimentos_inscricao_id_fkey" FOREIGN KEY ("inscricao_id") REFERENCES "inscricoes_aluno_curso"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "inscricao_atendimentos_inscricao_id_idx" ON "inscricao_atendimentos"("inscricao_id");
