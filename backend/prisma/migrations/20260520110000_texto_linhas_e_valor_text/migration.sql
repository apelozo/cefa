-- Respostas: texto sem teto VARCHAR fixo (limite por pergunta na aplicação)
ALTER TABLE "respostas" ALTER COLUMN "valor_texto" TYPE TEXT;

-- Perguntas TEXTO: altura do campo no lançamento (linhas visíveis)
ALTER TABLE "perguntas" ADD COLUMN "linhas_campo" INTEGER;

UPDATE "perguntas"
SET "linhas_campo" = 3
WHERE "tipo_campo" = 'TEXTO' AND "linhas_campo" IS NULL;
