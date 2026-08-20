-- Wellhub (Gympass) e TotalPass — vínculo de alunos e config do estúdio
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS wellhub_id TEXT;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS totalpass_cpf TEXT;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS beneficio_origem TEXT;

CREATE INDEX IF NOT EXISTS idx_alunos_wellhub_id ON alunos(wellhub_id) WHERE wellhub_id IS NOT NULL AND wellhub_id <> '';
CREATE INDEX IF NOT EXISTS idx_alunos_totalpass_cpf ON alunos(totalpass_cpf) WHERE totalpass_cpf IS NOT NULL AND totalpass_cpf <> '';

COMMENT ON COLUMN alunos.wellhub_id IS 'ID Gympass/Wellhub (13 dígitos) para login via Access Control API';
COMMENT ON COLUMN alunos.totalpass_cpf IS 'CPF só dígitos para login TotalPass';
COMMENT ON COLUMN alunos.beneficio_origem IS 'wellhub | totalpass | avulso | vazio (mensalidade)';
