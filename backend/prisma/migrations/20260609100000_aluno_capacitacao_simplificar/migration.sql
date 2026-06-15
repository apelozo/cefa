-- Simplifica ficha de aluno de capacitação: remove endereço, adicionais e renda familiar.

DROP TABLE IF EXISTS "aluno_capacitacao_renda_familiar";

ALTER TABLE "alunos_capacitacao_profissional"
  DROP CONSTRAINT IF EXISTS "alunos_capacitacao_profissional_cidade_codigo_fkey";

ALTER TABLE "alunos_capacitacao_profissional"
  DROP COLUMN IF EXISTS "endereco",
  DROP COLUMN IF EXISTS "endereco_numero",
  DROP COLUMN IF EXISTS "bairro",
  DROP COLUMN IF EXISTS "cep",
  DROP COLUMN IF EXISTS "cidade_codigo",
  DROP COLUMN IF EXISTS "tipo_casa",
  DROP COLUMN IF EXISTS "valor_aluguel",
  DROP COLUMN IF EXISTS "telefone",
  DROP COLUMN IF EXISTS "celular",
  DROP COLUMN IF EXISTS "telefone_recado",
  DROP COLUMN IF EXISTS "email",
  DROP COLUMN IF EXISTS "rede_social",
  DROP COLUMN IF EXISTS "ja_fez_curso_senac_senai",
  DROP COLUMN IF EXISTS "curso_senac_senai_descricao",
  DROP COLUMN IF EXISTS "curso_senac_senai_ano",
  DROP COLUMN IF EXISTS "encaminhamento",
  DROP COLUMN IF EXISTS "telefone_encaminhamento",
  DROP COLUMN IF EXISTS "possui_necessidade_especial",
  DROP COLUMN IF EXISTS "qual_necessidade",
  DROP COLUMN IF EXISTS "faz_acompanhamento_medico",
  DROP COLUMN IF EXISTS "toma_medicacao",
  DROP COLUMN IF EXISTS "vacinacao",
  DROP COLUMN IF EXISTS "alergias";

DROP TYPE IF EXISTS "TipoCasaAlunoCapacitacao";
