-- Sem delete em cascata: RESTRICT em todas as FKs de negócio
ALTER TABLE "perguntas" DROP CONSTRAINT IF EXISTS "perguntas_tipo_formulario_id_fkey";
ALTER TABLE "perguntas" ADD CONSTRAINT "perguntas_tipo_formulario_id_fkey"
  FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "submissoes" DROP CONSTRAINT IF EXISTS "submissoes_tipo_formulario_id_fkey";
ALTER TABLE "submissoes" ADD CONSTRAINT "submissoes_tipo_formulario_id_fkey"
  FOREIGN KEY ("tipo_formulario_id") REFERENCES "tipos_formulario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "submissoes" DROP CONSTRAINT IF EXISTS "submissoes_pessoa_id_fkey";
ALTER TABLE "submissoes" ADD CONSTRAINT "submissoes_pessoa_id_fkey"
  FOREIGN KEY ("pessoa_id") REFERENCES "pessoas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "respostas" DROP CONSTRAINT IF EXISTS "respostas_pergunta_id_fkey";
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_pergunta_id_fkey"
  FOREIGN KEY ("pergunta_id") REFERENCES "perguntas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "respostas" DROP CONSTRAINT IF EXISTS "respostas_submissao_id_fkey";
ALTER TABLE "respostas" ADD CONSTRAINT "respostas_submissao_id_fkey"
  FOREIGN KEY ("submissao_id") REFERENCES "submissoes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
