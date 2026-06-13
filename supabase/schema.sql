-- Schema do Pulguinha — execute no SQL Editor do Supabase

-- Admin
CREATE TABLE IF NOT EXISTS admins (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  nome TEXT NOT NULL
);

-- Alunos
CREATE TABLE IF NOT EXISTS alunos (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  telefone TEXT NOT NULL DEFAULT '',
  plano TEXT NOT NULL DEFAULT 'Mensal',
  vencimento DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'Ativo',
  avatar TEXT NOT NULL DEFAULT ''
);

-- Horários de aula
CREATE TABLE IF NOT EXISTS horarios (
  id BIGSERIAL PRIMARY KEY,
  hora TEXT NOT NULL,
  dias TEXT NOT NULL,
  capacidade INT NOT NULL DEFAULT 12
);

-- Agendamentos
CREATE TABLE IF NOT EXISTS agendamentos (
  id BIGSERIAL PRIMARY KEY,
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  nome_aluno TEXT NOT NULL,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  horario TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Confirmado'
);

-- Produtos / planos da loja
CREATE TABLE IF NOT EXISTS produtos (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL DEFAULT '',
  preco NUMERIC(10, 2) NOT NULL,
  tipo TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '📦'
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON agendamentos(data);
CREATE INDEX IF NOT EXISTS idx_agendamentos_aluno ON agendamentos(aluno_id);
CREATE INDEX IF NOT EXISTS idx_alunos_email ON alunos(email);

-- RLS permissivo (app usa auth customizada; reforce em produção)
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE alunos ENABLE ROW LEVEL SECURITY;
ALTER TABLE horarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all_admins" ON admins FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_alunos" ON alunos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_horarios" ON horarios FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_agendamentos" ON agendamentos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_produtos" ON produtos FOR ALL USING (true) WITH CHECK (true);

-- Seed: admin padrão
INSERT INTO admins (email, senha, nome) VALUES
  ('admin@pulguinha.com', 'admin123', 'Pulguinha Admin')
ON CONFLICT (email) DO NOTHING;

-- Seed: alunos demo
INSERT INTO alunos (nome, email, senha, telefone, plano, vencimento, status, avatar) VALUES
  ('Ana Costa', 'ana@email.com', '1234', '(11) 98765-0001', 'Mensal', '2026-06-20', 'Ativo', 'AC'),
  ('Bruno Lima', 'bruno@email.com', '1234', '(11) 98765-0002', 'Trimestral', '2026-08-10', 'Ativo', 'BL'),
  ('Carla Dias', 'carla@email.com', '1234', '(11) 98765-0003', 'Mensal', '2026-06-05', 'Inadimplente', 'CD'),
  ('Diego Souza', 'diego@email.com', '1234', '(11) 98765-0004', 'Anual', '2027-01-15', 'Ativo', 'DS'),
  ('Elisa Rocha', 'elisa@email.com', '1234', '(11) 98765-0005', 'Mensal', '2026-06-28', 'Ativo', 'ER')
ON CONFLICT (email) DO NOTHING;

-- Seed: horários
INSERT INTO horarios (hora, dias, capacidade) VALUES
  ('06:00', 'Seg/Qua/Sex', 12),
  ('07:00', 'Seg/Qua/Sex', 12),
  ('08:00', 'Ter/Qui', 10),
  ('09:00', 'Seg a Sex', 8),
  ('18:00', 'Seg a Sex', 15),
  ('19:00', 'Seg a Sex', 15),
  ('20:00', 'Seg/Qua/Sex', 12);

-- Seed: produtos
INSERT INTO produtos (nome, descricao, preco, tipo, emoji) VALUES
  ('Plano Mensal', 'Acesso ilimitado por 30 dias', 150, 'plano', '📅'),
  ('Plano Trimestral', '3 meses com 10% de desconto', 400, 'plano', '🗓️'),
  ('Plano Semestral', '6 meses com 20% de desconto', 720, 'plano', '📆'),
  ('Plano Anual', '12 meses com 30% de desconto', 1300, 'plano', '🏆'),
  ('Camiseta Pulguinha', 'Dry-fit tamanhos P/M/G/GG', 69, 'produto', '👕'),
  ('Squeeze 700ml', 'Alumínio com logo bordado', 49, 'produto', '🥤'),
  ('Aula Avulsa', '1 treino funcional à la carte', 40, 'avulso', '🎟️');
