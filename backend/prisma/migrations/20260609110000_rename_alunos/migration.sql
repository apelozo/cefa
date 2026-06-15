-- Renomeia tabela de alunos e programa do sistema (mescla permissões se ambos existirem).

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'alunos_capacitacao_profissional'
  ) THEN
    ALTER TABLE "alunos_capacitacao_profissional" RENAME TO "alunos";
  END IF;
END $$;

DO $$
DECLARE
  old_prog_id UUID;
  new_prog_id UUID;
BEGIN
  SELECT id INTO old_prog_id FROM programas WHERE codigo = 'alunos_capacitacao';
  SELECT id INTO new_prog_id FROM programas WHERE codigo = 'alunos';

  IF old_prog_id IS NOT NULL AND new_prog_id IS NOT NULL AND old_prog_id <> new_prog_id THEN
    UPDATE tipos_usuario_permissoes tup
    SET programa_id = new_prog_id
    WHERE tup.programa_id = old_prog_id
      AND NOT EXISTS (
        SELECT 1 FROM tipos_usuario_permissoes t2
        WHERE t2.tipo_usuario_id = tup.tipo_usuario_id
          AND t2.programa_id = new_prog_id
      );

    DELETE FROM tipos_usuario_permissoes WHERE programa_id = old_prog_id;

    UPDATE usuarios_permissoes up
    SET programa_id = new_prog_id
    WHERE up.programa_id = old_prog_id
      AND NOT EXISTS (
        SELECT 1 FROM usuarios_permissoes u2
        WHERE u2.usuario_id = up.usuario_id
          AND u2.programa_id = new_prog_id
      );

    DELETE FROM usuarios_permissoes WHERE programa_id = old_prog_id;

    DELETE FROM programas WHERE id = old_prog_id;
  ELSIF old_prog_id IS NOT NULL AND new_prog_id IS NULL THEN
    UPDATE programas
    SET codigo = 'alunos', nome = 'Cadastro de Alunos'
    WHERE id = old_prog_id;
  END IF;

  UPDATE programas SET nome = 'Cadastro de Alunos' WHERE codigo = 'alunos';
END $$;
