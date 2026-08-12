-- Impede agendamentos duplicados do mesmo aluno no mesmo horário/data.
-- Seguro em produção: só falha se já existirem duplicatas (limpe antes se necessário).

-- Remover duplicatas mantendo o menor id
DELETE FROM agendamentos a
USING agendamentos b
WHERE a.aluno_id IS NOT NULL
  AND a.aluno_id = b.aluno_id
  AND a.horario_id = b.horario_id
  AND a.data = b.data
  AND a.id > b.id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_agendamentos_aluno_horario_data
  ON agendamentos (aluno_id, horario_id, data)
  WHERE aluno_id IS NOT NULL;
