-- Dados demo opcionais — execute APÓS schema.sql em banco vazio ou para popular ambiente de teste.
-- Idempotente: pode reexecutar sem duplicar registros.

-- Seed: admin padrão
INSERT INTO admins (email, senha, nome) VALUES
  ('admin@pulguinha.com', 'admin123', 'Pulguinha Admin')
ON CONFLICT (email) DO NOTHING;

-- Seed: horários (antes dos alunos, pois horario_id referencia horarios)
INSERT INTO horarios (hora, dias, capacidade)
SELECT v.hora, v.dias, v.capacidade
FROM (VALUES
  ('06:00', 'Seg/Qua/Sex', 12),
  ('07:00', 'Seg/Qua/Sex', 12),
  ('08:00', 'Ter/Qui', 10),
  ('09:00', 'Seg a Sex', 8),
  ('18:00', 'Seg a Sex', 15),
  ('19:00', 'Seg a Sex', 15),
  ('20:00', 'Seg/Qua/Sex', 12)
) AS v(hora, dias, capacidade)
WHERE NOT EXISTS (
  SELECT 1 FROM horarios h WHERE h.hora = v.hora AND h.dias = v.dias
);

-- Seed: alunos demo
INSERT INTO alunos (nome, email, senha, telefone, plano, vencimento, status, avatar, data_nascimento, anamnese, streak_presenca, pulguinha_points, horario_id)
SELECT v.nome, v.email, v.senha, v.telefone, v.plano, v.vencimento::date, v.status, v.avatar,
       v.data_nascimento::date, v.anamnese::jsonb, v.streak_presenca, v.pulguinha_points, h.id
FROM (VALUES
  ('Ana Costa', 'ana@email.com', '1234', '(11) 98765-0001', 'Mensal', '2026-06-20', 'Ativo', 'AC', '1995-06-13', '{"objetivo_treino":"Condicionamento","nivel_experiencia":"Intermediário"}', 5, 50, '18:00'),
  ('Bruno Lima', 'bruno@email.com', '1234', '(11) 98765-0002', 'Trimestral', '2026-08-10', 'Ativo', 'BL', '1990-03-22', '{"objetivo_treino":"Emagrecer","nivel_experiencia":"Iniciante"}', 3, 30, '18:00'),
  ('Carla Dias', 'carla@email.com', '1234', '(11) 98765-0003', 'Mensal', '2026-06-05', 'Inadimplente', 'CD', '1988-11-08', '{}', 0, 0, '09:00'),
  ('Diego Souza', 'diego@email.com', '1234', '(11) 98765-0004', 'Anual', '2027-01-15', 'Ativo', 'DS', '1992-07-04', '{"restricoes_medicas":"Joelho direito","nivel_experiencia":"Avançado"}', 8, 80, '20:00'),
  ('Elisa Rocha', 'elisa@email.com', '1234', '(11) 98765-0005', 'Mensal', '2026-06-28', 'Ativo', 'ER', '1998-06-18', '{"objetivo_treino":"Força","nivel_experiencia":"Intermediário"}', 2, 20, '06:00')
) AS v(nome, email, senha, telefone, plano, vencimento, status, avatar, data_nascimento, anamnese, streak_presenca, pulguinha_points, hora_ref)
LEFT JOIN horarios h ON h.hora = v.hora_ref
ON CONFLICT (email) DO NOTHING;

-- Seed: produtos
INSERT INTO produtos (nome, descricao, preco, tipo, emoji)
SELECT v.nome, v.descricao, v.preco, v.tipo, v.emoji
FROM (VALUES
  ('Plano Mensal', 'Acesso ilimitado por 30 dias', 150, 'plano', '📅'),
  ('Plano Trimestral', '3 meses com 10% de desconto', 400, 'plano', '🗓️'),
  ('Plano Semestral', '6 meses com 20% de desconto', 720, 'plano', '📆'),
  ('Plano Anual', '12 meses com 30% de desconto', 1300, 'plano', '🏆'),
  ('Camiseta Pulguinha', 'Dry-fit tamanhos P/M/G/GG', 69, 'produto', '👕'),
  ('Squeeze 700ml', 'Alumínio com logo bordado', 49, 'produto', '🥤'),
  ('Aula Avulsa', '1 treino funcional à la carte', 40, 'avulso', '🎟️')
) AS v(nome, descricao, preco, tipo, emoji)
WHERE NOT EXISTS (SELECT 1 FROM produtos p WHERE p.nome = v.nome);

-- Seed: presenças demo — resolve aluno_id/horario_id por e-mail e hora (não usa IDs fixos)
INSERT INTO presencas (aluno_id, horario_id, data, horario, tipo, nome_aluno)
SELECT a.id, h.id, d.data::date, d.horario, d.tipo, a.nome
FROM (VALUES
  ('ana@email.com', '18:00', CURRENT_DATE - 4, '18:00', 'scan_professor'),
  ('ana@email.com', '18:00', CURRENT_DATE - 3, '18:00', 'scan_aluno'),
  ('ana@email.com', '18:00', CURRENT_DATE - 2, '18:00', 'scan_professor'),
  ('ana@email.com', '18:00', CURRENT_DATE - 1, '18:00', 'scan_aluno'),
  ('bruno@email.com', '18:00', CURRENT_DATE - 2, '18:00', 'scan_professor'),
  ('bruno@email.com', '19:00', CURRENT_DATE - 1, '19:00', 'scan_aluno'),
  ('diego@email.com', '06:00', CURRENT_DATE - 1, '06:00', 'scan_professor'),
  ('elisa@email.com', '06:00', CURRENT_DATE, '06:00', 'scan_aluno')
) AS d(email, hora_ref, data, horario, tipo)
JOIN alunos a ON a.email = d.email
JOIN horarios h ON h.hora = d.hora_ref
ON CONFLICT (aluno_id, horario_id, data) DO NOTHING;
